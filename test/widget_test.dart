import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart' show ActionChip;
import 'package:flutter/widgets.dart' show SizedBox;
import 'package:flutter_test/flutter_test.dart';

import 'package:wellbite/data/database.dart';
import 'package:wellbite/main.dart';
import 'package:wellbite/services/services.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('watchDay returns only entries from that local day', () async {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    await db.addEntry(
      FoodEntriesCompanion.insert(
        name: 'Oatmeal',
        mealType: MealType.breakfast,
        loggedAt: today,
        calories: const Value(300),
      ),
    );
    await db.addEntry(
      FoodEntriesCompanion.insert(
        name: 'Pasta',
        mealType: MealType.dinner,
        loggedAt: yesterday,
      ),
    );

    final entries = await db.watchDay(today).first;
    expect(entries.map((e) => e.name), ['Oatmeal']);
    expect(entries.single.calories, 300);
  });

  test('update and delete', () async {
    final id = await db.addEntry(
      FoodEntriesCompanion.insert(
        name: 'Toast',
        mealType: MealType.breakfast,
        loggedAt: DateTime.now(),
      ),
    );
    var entry = (await db.watchDay(DateTime.now()).first).single;
    await db.updateEntry(entry.copyWith(name: 'Toast with jam'));
    entry = (await db.watchDay(DateTime.now()).first).single;
    expect(entry.name, 'Toast with jam');

    await db.deleteEntry(id);
    expect(await db.watchDay(DateTime.now()).first, isEmpty);
  });

  testWidgets('empty day shows placeholder and add button', (tester) async {
    await tester.pumpWidget(
      BasicHealthTrackerApp(
        database: db,
        services: AppServices(keyStore: MemoryApiKeyStore()),
      ),
    );
    // Drift runs queries on real async I/O, which the fake clock won't advance.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();
    expect(find.text('Nothing logged yet.'), findsOneWidget);
    expect(find.text('Add food'), findsOneWidget);
    // Unmount so drift's stream cleanup timers don't outlive the test.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('one tap on a saved food logs it, and Undo removes it', (
    tester,
  ) async {
    await tester.runAsync(
      () => db.logFood(
        name: 'Oatmeal',
        meal: MealType.breakfast,
        at: DateTime.now().subtract(const Duration(days: 2)),
        baseCalories: 300,
      ),
    );
    final services = AppServices(keyStore: MemoryApiKeyStore());
    await tester.pumpWidget(
      BasicHealthTrackerApp(database: db, services: services),
    );
    Future<void> settle() async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    await settle();
    await tester.tap(find.text('Add food'));
    await settle();
    await tester.tap(find.widgetWithText(ActionChip, 'Oatmeal'));
    await settle();

    expect(find.text('300 kcal'), findsWidgets);
    expect(find.text('Logged Oatmeal'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await settle();
    expect(find.text('Nothing logged yet.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
