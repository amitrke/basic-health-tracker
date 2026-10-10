import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart' show SizedBox;
import 'package:flutter_test/flutter_test.dart';

import 'package:wellbite/data/database.dart';
import 'package:wellbite/main.dart';
import 'package:wellbite/services/health_service.dart';
import 'package:wellbite/services/services.dart';

class FakeHealth implements HealthSource {
  FakeHealth({this.burned = const EnergyBurned()});

  final EnergyBurned burned;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> requestAccess() async => true;

  @override
  Future<EnergyBurned> energyBurned(DateTime day) async => burned;

  @override
  Future<BodyStats> bodyStats() async =>
      const BodyStats(weightKg: 70, heightCm: 175);
}

void main() {
  test('bestSourceTotal does not add a phone and a watch together', () {
    final total = bestSourceTotal([
      (source: 'watch', value: 200),
      (source: 'watch', value: 150),
      (source: 'phone', value: 300),
    ]);
    expect(total, 350);
  });

  test('restingKcal follows Mifflin-St Jeor and needs every input', () {
    expect(
      restingKcal(weightKg: 70, heightCm: 175, age: 30, sex: Sex.male),
      1649,
    );
    expect(
      restingKcal(weightKg: 60, heightCm: 165, age: 30, sex: Sex.female),
      1320,
    );
    expect(restingKcal(weightKg: 70, heightCm: 175, age: 30), isNull);
    expect(restingKcal(weightKg: 70, age: 30, sex: Sex.male), isNull);
  });

  testWidgets('with only active calories, resting burn is estimated', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    final prefs = MemoryHealthPrefsStore(true);
    await prefs.writeProfile(const BodyProfile(age: 30, sex: Sex.male));
    await tester.pumpWidget(
      BasicHealthTrackerApp(
        database: db,
        services: AppServices(
          settingsStore: MemoryAiSettingsStore(),
          health: FakeHealth(burned: const EnergyBurned(active: 300)),
          healthPrefs: prefs,
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();
    await tester.pump();

    // 70 kg, 175 cm, 30, male = 1649 resting, plus 300 active.
    expect(find.text('~1949 kcal'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(db.close);
  });

  test('bestSourceTotal is null with no data', () {
    expect(bestSourceTotal(const []), isNull);
  });

  testWidgets('day screen shows calories burned and the net', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(
      () => db.addEntry(
        FoodEntriesCompanion.insert(
          name: 'Oatmeal',
          mealType: MealType.breakfast,
          loggedAt: DateTime.now(),
          calories: const Value(500),
        ),
      ),
    );
    await tester.pumpWidget(
      BasicHealthTrackerApp(
        database: db,
        services: AppServices(
          settingsStore: MemoryAiSettingsStore(),
          health: FakeHealth(
            burned: const EnergyBurned(active: 300, total: 2100),
          ),
          healthPrefs: MemoryHealthPrefsStore(true),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Calories burned'), findsOneWidget);
    expect(find.text('2100 kcal'), findsOneWidget);
    expect(find.text('Active 300 kcal · Net -1600 kcal'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(db.close);
  });

  testWidgets('burned row is hidden when health is off', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      BasicHealthTrackerApp(
        database: db,
        services: AppServices(
          settingsStore: MemoryAiSettingsStore(),
          health: FakeHealth(burned: const EnergyBurned(active: 300)),
          healthPrefs: MemoryHealthPrefsStore(false),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Calories burned'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(db.close);
  });
}
