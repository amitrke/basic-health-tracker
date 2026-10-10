import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:wellbite/data/calories.dart';
import 'package:wellbite/data/database.dart';
import 'package:wellbite/main.dart';
import 'package:wellbite/services/ai_estimator.dart';
import 'package:wellbite/services/health_service.dart';
import 'package:wellbite/services/open_food_facts.dart';
import 'package:wellbite/services/services.dart';
import 'package:wellbite/services/user_prefs.dart';
import 'package:wellbite/util/units.dart';

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 200)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _unmount(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
  await tester.runAsync(db.close);
}

void main() {
  test('upgrading from v2 keeps data and adds macros and weights', () async {
    final executor = NativeDatabase.memory(
      setup: (raw) {
        raw.execute('''
          CREATE TABLE food_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            meal_type INTEGER NOT NULL,
            calories INTEGER NULL,
            notes TEXT NULL,
            logged_at INTEGER NOT NULL,
            portion INTEGER NULL,
            is_estimate INTEGER NOT NULL DEFAULT 0
          )''');
        raw.execute('''
          CREATE TABLE saved_foods (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            calories INTEGER NULL,
            is_estimate INTEGER NOT NULL DEFAULT 0,
            portion_label TEXT NULL,
            barcode TEXT NULL,
            use_count INTEGER NOT NULL DEFAULT 0,
            last_used_at INTEGER NOT NULL
          )''');
        raw.execute('''
          CREATE TABLE meal_templates (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            meal_type INTEGER NOT NULL
          )''');
        raw.execute('''
          CREATE TABLE template_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            template_id INTEGER NOT NULL REFERENCES meal_templates (id),
            name TEXT NOT NULL,
            calories INTEGER NULL
          )''');
        final t = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        raw.execute(
          "INSERT INTO food_entries (name, meal_type, calories, logged_at) "
          "VALUES ('Soup', 1, 250, $t)",
        );
        raw.execute(
          "INSERT INTO saved_foods (name, calories, use_count, last_used_at) "
          "VALUES ('Soup', 250, 3, $t)",
        );
        raw.execute('PRAGMA user_version = 2');
      },
    );
    final db = AppDatabase(executor);
    addTearDown(db.close);

    final soup = (await db.watchDay(DateTime.now()).first).single;
    expect(soup.calories, 250);
    expect(soup.protein, isNull);
    expect((await db.findFood('soup'))!.useCount, 3);

    await db.logFood(
      name: 'Soup',
      meal: MealType.lunch,
      at: DateTime.now(),
      baseCalories: 250,
      baseMacros: const Macros(protein: 12, carbs: 30, fat: 8),
    );
    expect((await db.findFood('soup'))!.protein, 12);

    await db.addWeight(80.5, DateTime.now());
    expect((await db.watchWeights().first).single.kg, 80.5);
  });

  group('macros', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('scale with the portion and are remembered for re-logs', () async {
      final now = DateTime.now();
      await db.logFood(
        name: 'Rice bowl',
        meal: MealType.lunch,
        at: now,
        baseCalories: 500,
        baseMacros: const Macros(protein: 30, carbs: 60, fat: 10),
        portion: Portion.large,
      );
      final saved = (await db.findFood('rice bowl'))!;
      expect([saved.protein, saved.carbs, saved.fat], [30, 60, 10]);

      await db.logSavedFood(saved, meal: MealType.dinner, at: now);
      final entries = await db.watchDay(now).first;
      expect(entries.map((e) => e.protein), [42, 30]);
      expect(Macros.total(entries).carbs, 84 + 60);
    });

    test('a log without macros keeps the stored ones', () async {
      final now = DateTime.now();
      await db.logFood(
        name: 'Eggs',
        meal: MealType.breakfast,
        at: now,
        baseMacros: const Macros(protein: 12),
      );
      await db.logFood(name: 'eggs', meal: MealType.breakfast, at: now);
      expect((await db.findFood('Eggs'))!.protein, 12);
    });

    test('templates carry macros', () async {
      final now = DateTime.now();
      await db.logFood(
        name: 'Toast',
        meal: MealType.breakfast,
        at: now,
        baseCalories: 100,
        baseMacros: const Macros(protein: 3, carbs: 18, fat: 1),
      );
      await db.saveTemplate(
        'Usual',
        MealType.breakfast,
        await db.watchDay(now).first,
      );
      await db.deleteSavedFood((await db.findFood('Toast'))!.id);
      final tpl = (await db.watchTemplates().first).single;
      await db.logTemplate(tpl, meal: MealType.lunch, at: now);
      final lunch = (await db.watchDay(now).first)
          .where((e) => e.mealType == MealType.lunch)
          .single;
      expect([lunch.protein, lunch.carbs, lunch.fat], [3, 18, 1]);
    });
  });

  test('AI estimate reads macros, and totals skip missing ones', () {
    final e = AiEstimator.parseEstimate(
      '{"items":[{"name":"Eggs","calories":140,"protein":12,"carbs":1,'
      '"fat":10},{"name":"Coffee","calories":5}]}',
    );
    expect(e.totalProtein, 12);
    expect(e.totalFat, 10);
    expect(
      AiEstimator.parseEstimate('{"items":[{"name":"Tea","calories":2}]}')
          .totalProtein,
      isNull,
    );
  });

  test('Open Food Facts macros follow the serving', () async {
    OpenFoodFacts off(Map<String, dynamic> product) => OpenFoodFacts(
      MockClient(
        (_) async =>
            http.Response(jsonEncode({'status': 1, 'product': product}), 200),
      ),
    );
    final perServing = await off({
      'product_name': 'Bar',
      'nutriments': {
        'energy-kcal_serving': 200,
        'proteins_serving': 10.4,
        'carbohydrates_serving': 22,
        'fat_serving': 7,
      },
    }).lookup('1');
    expect(
      [perServing!.protein, perServing.carbs, perServing.fat],
      [10, 22, 7],
    );

    final per100 = await off({
      'product_name': 'Crackers',
      'serving_quantity': 30,
      'nutriments': {
        'energy-kcal_100g': 400,
        'proteins_100g': 10,
        'carbohydrates_100g': 70,
        'fat_100g': 10,
      },
    }).lookup('2');
    expect([per100!.protein, per100.carbs, per100.fat], [3, 21, 3]);
  });

  test('units format energy and weight in the chosen units', () {
    const metric = Units(UserPrefs());
    expect(metric.energy(2100), '2,100 kcal');
    expect(metric.energy(300, estimate: true), '~300 kcal');
    expect(metric.weight(78.4), '78.4 kg');
    expect(metric.weightChange(-1.6), '−1.6 kg');

    final imperial = Units(
      const UserPrefs().copyWith(
        weightUnit: WeightUnit.lb,
        energyUnit: EnergyUnit.kJ,
        heightUnit: HeightUnit.ftIn,
      ),
    );
    expect(imperial.energy(2100), '8,786 kJ');
    expect(imperial.weight(80), '176.4 lb');
    expect(imperial.parseWeight('176.4')!, closeTo(80, 0.05));
    expect(imperial.height(180), '5 ft 11 in');
  });

  test('plan suggestion and macro split', () {
    // 70 kg, 175 cm, 30, male: 1649 resting × 1.2 = 1979, minus 275.
    expect(
      suggestCalories(
        weightKg: 70,
        heightCm: 175,
        age: 30,
        sex: Sex.male,
        goal: WeightGoal.lose,
        paceKgPerWeek: 0.25,
      ),
      1700,
    );
    expect(macrosFor(2000), (protein: 125, carbs: 225, fat: 67));
  });

  test('prefs round-trip and survive corrupt storage', () {
    final prefs = const UserPrefs().copyWith(
      onboarded: true,
      weightUnit: WeightUnit.lb,
      calorieGoal: 1800,
      goalWeightKg: 72.5,
      addActiveToBudget: false,
    );
    final back = UserPrefs.decode(prefs.encode());
    expect(back.onboarded, isTrue);
    expect(back.weightUnit, WeightUnit.lb);
    expect(back.calorieGoal, 1800);
    expect(back.goalWeightKg, 72.5);
    expect(back.addActiveToBudget, isFalse);
    expect(UserPrefs.decode('nope').onboarded, isFalse);
  });

  testWidgets('first run: onboarding sets the plan and logs the weight', (
    tester,
  ) async {
    _phone(tester);
    final db = AppDatabase(NativeDatabase.memory());
    final store = MemoryUserPrefsStore(const UserPrefs());
    final healthPrefs = MemoryHealthPrefsStore();
    await tester.pumpWidget(
      BasicHealthTrackerApp(
        database: db,
        services: AppServices(
          settingsStore: MemoryAiSettingsStore(),
          userPrefs: store,
          healthPrefs: healthPrefs,
        ),
      ),
    );
    await _settle(tester);

    await tester.tap(find.text('Get started'));
    await _settle(tester);
    await tester.tap(find.text('Continue'));
    await _settle(tester);
    expect(find.textContaining('Fill in all four'), findsOneWidget);

    await tester.tap(find.text('Male'));
    await tester.enterText(find.widgetWithText(TextField, 'Age'), '30');
    await tester.enterText(find.widgetWithText(TextField, 'Height'), '175');
    await tester.enterText(
      find.widgetWithText(TextField, 'Current weight'),
      '70',
    );
    await tester.tap(find.text('Continue'));
    await _settle(tester);

    expect(find.text('What’s your goal?'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Goal weight (optional)'),
      '65',
    );
    await tester.tap(find.text('Continue'));
    await _settle(tester);

    await tester.tap(find.text('Not now'));
    await _settle(tester);
    expect(find.text('1,700 kcal', findRichText: true), findsOneWidget);
    await tester.tap(find.byTooltip('Increase by 50 kcal'));
    await tester.pump();
    await tester.tap(find.text('Start tracking'));
    await _settle(tester);

    final saved = await store.read();
    expect(saved.onboarded, isTrue);
    expect(saved.calorieGoal, 1750);
    expect(saved.goalWeightKg, 65);
    expect(saved.heightCm, 175);
    expect((await healthPrefs.readProfile()).age, 30);
    final weights = await tester.runAsync(() => db.watchWeights().first);
    expect(weights!.single.kg, 70);
    expect(find.text('Nothing logged yet.'), findsOneWidget);

    await _unmount(tester, db);
  });

  testWidgets('skipping onboarding goes straight to Today', (tester) async {
    _phone(tester);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      BasicHealthTrackerApp(
        database: db,
        services: AppServices(
          settingsStore: MemoryAiSettingsStore(),
          userPrefs: MemoryUserPrefsStore(const UserPrefs()),
        ),
      ),
    );
    await _settle(tester);
    await tester.tap(find.text('Skip for now'));
    await _settle(tester);
    expect(find.text('Add food'), findsOneWidget);
    await _unmount(tester, db);
  });

  testWidgets('a weight logged on the Weight tab shows in the history', (
    tester,
  ) async {
    _phone(tester);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      BasicHealthTrackerApp(
        database: db,
        services: AppServices(
          settingsStore: MemoryAiSettingsStore(),
          userPrefs: MemoryUserPrefsStore(),
          healthPrefs: MemoryHealthPrefsStore(),
        ),
      ),
    );
    await _settle(tester);
    await tester.tap(find.text('Weight'));
    await _settle(tester);
    expect(find.textContaining('No weigh-ins yet'), findsOneWidget);

    await tester.tap(find.text('Log weight'));
    await _settle(tester);
    await tester.enterText(find.byType(TextField), '81.2');
    await tester.tap(find.text('Save'));
    await _settle(tester);

    expect(find.text('81.2 kg'), findsWidgets);
    await _unmount(tester, db);
  });
}
