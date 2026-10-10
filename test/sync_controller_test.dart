import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wellbite/data/database.dart';
import 'package:wellbite/screens/settings_screen.dart';
import 'package:wellbite/services/health_service.dart';
import 'package:wellbite/services/services.dart';
import 'package:wellbite/services/user_prefs.dart';
import 'package:wellbite/sync/sync_backend.dart';
import 'package:wellbite/sync/sync_controller.dart';
import 'package:wellbite/theme.dart';

class _NoHealth implements HealthSource {
  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<bool> requestAccess() async => false;

  @override
  Future<EnergyBurned> energyBurned(DateTime day) async =>
      const EnergyBurned();

  @override
  Future<BodyStats> bodyStats() async => const BodyStats();

  @override
  Future<List<WeightReading>> weightHistory(DateTime from) async => const [];
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late MemorySyncBackend backend;
  late MemorySyncPrefsStore prefs;
  late SyncController sync;
  final at = DateTime(2026, 5, 1, 12);

  SyncController make({Duration debounce = const Duration(milliseconds: 40)}) =>
      SyncController(
        database: db,
        backend: backend,
        prefsStore: prefs,
        debounce: debounce,
      );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    backend = MemorySyncBackend();
    prefs = MemorySyncPrefsStore();
    sync = make();
  });

  tearDown(() async {
    sync.dispose();
    await db.close();
  });

  test('starts off and does nothing until turned on', () async {
    await sync.load();
    await sync.syncNow();
    expect(sync.enabled, isFalse);
    expect(backend.text, isNull);
  });

  test('turning on signs in, syncs and remembers it', () async {
    await db.logFood(name: 'Egg', meal: MealType.breakfast, at: at);
    await sync.enable();

    expect(sync.enabled, isTrue);
    expect(sync.error, isNull);
    expect(sync.lastSynced, isNotNull);
    expect(backend.snapshot!.tables['food_entries'], hasLength(1));

    // A restart picks the choice back up.
    final again = make();
    addTearDown(again.dispose);
    await again.load();
    expect(again.enabled, isTrue);
    expect(again.lastSynced, isNotNull);
    // Loading also kicks off a catch-up sync; let it finish.
    await Future<void>.delayed(const Duration(milliseconds: 200));
  });

  test('a declined sign-in leaves sync off with a reason', () async {
    backend.connectError = 'Sign-in was cancelled.';
    await sync.enable();
    expect(sync.enabled, isFalse);
    expect(sync.error, 'Sign-in was cancelled.');
    expect(backend.text, isNull);
  });

  test('no network keeps sync on and shows the error until it works', () async {
    backend.networkError = 'Could not reach Google Drive.';
    await sync.enable();
    expect(sync.enabled, isTrue);
    expect(sync.error, contains('Could not reach'));
    expect(sync.lastSynced, isNull);

    backend.networkError = null;
    await sync.syncNow();
    expect(sync.error, isNull);
    expect(sync.lastSynced, isNotNull);
  });

  test('a change on this device uploads on its own', () async {
    await sync.enable();
    await db.logFood(name: 'Rice', meal: MealType.lunch, at: at);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(
      backend.snapshot!.tables['food_entries']!.map((r) => r['name']),
      ['Rice'],
    );
  });

  test('turning off stops uploading and signs out', () async {
    await sync.enable();
    await sync.disable();
    expect(sync.enabled, isFalse);

    await db.logFood(name: 'Rice', meal: MealType.lunch, at: at);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(backend.snapshot!.tables['food_entries'], isEmpty);
    expect((await prefs.read()).enabled, isFalse);
  });

  test('turning on again later does not lose or double anything', () async {
    await db.logFood(name: 'Egg', meal: MealType.breakfast, at: at);
    await sync.enable();
    await sync.disable();
    await sync.enable();
    expect(await db.select(db.foodEntries).get(), hasLength(1));
    expect(backend.snapshot!.tables['food_entries'], hasLength(1));
  });

  testWidgets('settings shows the toggle, status and sync now', (tester) async {
    final services = AppServices(
      settingsStore: MemoryAiSettingsStore(),
      userPrefs: MemoryUserPrefsStore(),
      health: _NoHealth(),
      healthPrefs: MemoryHealthPrefsStore(),
      sync: sync,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: SettingsScreen(services: services),
      ),
    );
    await tester.pump();
    await tester.dragUntilVisible(
      find.text('Sync between devices'),
      find.byType(Scrollable).first,
      const Offset(0, -200),
    );
    expect(find.text('Sync between devices'), findsOneWidget);
    expect(find.textContaining('with Memory'), findsOneWidget);
    expect(find.text('Sync now'), findsNothing);

    await tester.tap(find.byType(Switch).last);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();
    expect(sync.enabled, isTrue);
    expect(find.textContaining('Last synced'), findsOneWidget);
    expect(find.text('Sync now'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
