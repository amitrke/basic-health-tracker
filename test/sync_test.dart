import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wellbite/data/database.dart';
import 'package:wellbite/sync/sync_backend.dart';
import 'package:wellbite/sync/sync_engine.dart';
import 'package:wellbite/sync/sync_store.dart';

/// One simulated device: its own database syncing through a shared backend.
class Device {
  Device(this.backend)
    : db = AppDatabase(NativeDatabase.memory()),
      first = true {
    engine = SyncEngine(SyncStore(db), backend);
  }

  final MemorySyncBackend backend;
  final AppDatabase db;
  late final SyncEngine engine;
  bool first;

  Future<SyncOutcome> sync() async {
    final outcome = await engine.sync(firstSync: first);
    first = false;
    return outcome;
  }

  Future<List<FoodEntry>> entries() => db.select(db.foodEntries).get();

  /// Makes the latest edit look like it happened [seconds] later. The
  /// trigger stamps whole seconds, so tests run too fast to differ otherwise.
  Future<void> later(String table, int seconds) => db.customStatement(
    'UPDATE $table SET updated_at = updated_at + $seconds',
  );
}

void main() {
  // Two devices means two databases in one process.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late MemorySyncBackend backend;
  late Device a;
  late Device b;
  final at = DateTime(2026, 5, 1, 12);

  setUp(() {
    backend = MemorySyncBackend();
    a = Device(backend);
    b = Device(backend);
  });

  tearDown(() async {
    await a.db.close();
    await b.db.close();
  });

  test('every row gets a unique id and a timestamp', () async {
    await a.db.logFood(name: 'Egg', meal: MealType.breakfast, at: at);
    await a.db.logFood(name: 'Toast', meal: MealType.breakfast, at: at);
    final rows = await a.entries();
    expect(rows.map((r) => r.uuid).toSet(), hasLength(2));
    expect(rows.every((r) => r.uuid.length == 36), isTrue);
    expect(
      rows.first.updatedAt.difference(DateTime.now()).inMinutes.abs() < 1,
      isTrue,
    );
  });

  test('an entry logged on one device appears on the other', () async {
    await a.db.logFood(
      name: 'Egg',
      meal: MealType.breakfast,
      at: at,
      baseCalories: 78,
    );
    expect(await a.sync(), SyncOutcome.uploaded);
    await b.sync();
    final got = await b.entries();
    expect(got.single.name, 'Egg');
    expect(got.single.calories, 78);
    expect(got.single.loggedAt, at);
    expect(got.single.uuid, (await a.entries()).single.uuid);
  });

  test('syncing again with nothing new changes nothing', () async {
    await a.db.logFood(name: 'Egg', meal: MealType.breakfast, at: at);
    await a.sync();
    await b.sync();
    expect(await a.sync(), SyncOutcome.unchanged);
    expect(await b.sync(), SyncOutcome.unchanged);
  });

  test('the later edit wins on both devices', () async {
    await a.db.logFood(name: 'Egg', meal: MealType.breakfast, at: at);
    await a.sync();
    await b.sync();

    final onB = (await b.entries()).single;
    await b.db.updateEntry(onB.copyWith(calories: const Value(90)));
    await b.later('food_entries', 30);
    await b.sync();
    await a.sync();

    expect((await a.entries()).single.calories, 90);
    expect((await b.entries()).single.calories, 90);
  });

  test('an older edit does not overwrite a newer one', () async {
    await a.db.logFood(name: 'Egg', meal: MealType.breakfast, at: at);
    await a.sync();
    await b.sync();

    await a.db.updateEntry(
      (await a.entries()).single.copyWith(calories: const Value(100)),
    );
    await a.later('food_entries', 60);
    await b.db.updateEntry(
      (await b.entries()).single.copyWith(calories: const Value(50)),
    );
    await b.sync();
    await a.sync();
    await b.sync();

    expect((await a.entries()).single.calories, 100);
    expect((await b.entries()).single.calories, 100);
  });

  test('a delete reaches the other device and stays deleted', () async {
    await a.db.logFood(name: 'Egg', meal: MealType.breakfast, at: at);
    await a.sync();
    await b.sync();

    await a.db.deleteEntry((await a.entries()).single.id);
    await a.sync();
    await b.sync();
    expect(await b.entries(), isEmpty);

    // B still holding nothing must not resurrect it on the next round.
    await a.sync();
    expect(await a.entries(), isEmpty);
  });

  test('a delete does not come back from a device that was behind', () async {
    await a.db.logFood(name: 'Egg', meal: MealType.breakfast, at: at);
    await a.sync();
    await b.sync();

    await a.db.deleteEntry((await a.entries()).single.id);
    await a.sync();
    // B never saw the delete but syncs again: the tombstone is already there.
    await b.sync();
    expect(await b.entries(), isEmpty);
    expect(backend.snapshot!.tables['food_entries'], isEmpty);
  });

  test('an edit made after a delete elsewhere keeps the row', () async {
    await a.db.logFood(name: 'Egg', meal: MealType.breakfast, at: at);
    await a.sync();
    await b.sync();

    await a.db.deleteEntry((await a.entries()).single.id);
    await a.sync();
    await b.db.updateEntry(
      (await b.entries()).single.copyWith(calories: const Value(120)),
    );
    await b.later('food_entries', 3600);
    await b.sync();
    await a.sync();

    expect((await a.entries()).single.calories, 120);
    expect((await b.entries()).single.calories, 120);
  });

  test('the same saved food made on both devices becomes one', () async {
    await a.db.logFood(
      name: 'Banana',
      meal: MealType.snack,
      at: at,
      baseCalories: 105,
    );
    await b.db.logFood(
      name: 'banana',
      meal: MealType.snack,
      at: at.add(const Duration(days: 1)),
    );
    await a.sync();
    await b.sync();
    await a.sync();

    final foodsA = await a.db.select(a.db.savedFoods).get();
    final foodsB = await b.db.select(b.db.savedFoods).get();
    expect(foodsA, hasLength(1));
    expect(foodsB, hasLength(1));
    expect(foodsA.single.uuid, foodsB.single.uuid);
    // Both devices logged it once and still have their own entry.
    expect(await a.entries(), hasLength(2));
    expect(await b.entries(), hasLength(2));
  });

  test('data logged on both devices before the first sync is not doubled', () async {
    for (final d in [a, b]) {
      await d.db.logFood(name: 'Oats', meal: MealType.breakfast, at: at);
      await d.db.addWeight(80.5, at);
    }
    await a.sync();
    await b.sync();
    await a.sync();

    expect(await a.entries(), hasLength(1));
    expect(await b.entries(), hasLength(1));
    expect(await a.db.select(a.db.weightEntries).get(), hasLength(1));
    expect(await b.db.select(b.db.weightEntries).get(), hasLength(1));
    expect(
      (await a.entries()).single.uuid,
      (await b.entries()).single.uuid,
    );
  });

  test('two genuine entries at the same moment both survive', () async {
    await a.db.logFood(name: 'Tea', meal: MealType.snack, at: at);
    await a.db.logFood(name: 'Tea', meal: MealType.snack, at: at);
    await a.sync();
    await b.sync();
    expect(await b.entries(), hasLength(2));
    await a.sync();
    expect(await a.entries(), hasLength(2));
  });

  test('meal templates carry their items', () async {
    await a.db.logFood(
      name: 'Egg',
      meal: MealType.breakfast,
      at: at,
      baseCalories: 78,
    );
    await a.db.logFood(
      name: 'Toast',
      meal: MealType.breakfast,
      at: at,
      baseCalories: 80,
    );
    await a.db.saveTemplate('Usual', MealType.breakfast, await a.entries());
    await a.sync();
    await b.sync();

    final template = (await b.db.select(b.db.mealTemplates).get()).single;
    expect(template.name, 'Usual');
    final items = await b.db.select(b.db.templateItems).get();
    expect(items.map((i) => i.name), unorderedEquals(['Egg', 'Toast']));
    expect(items.every((i) => i.templateId == template.id), isTrue);

    // Replacing the template on A replaces its items on B.
    await a.db.saveTemplate(
      'Usual',
      MealType.breakfast,
      (await a.entries()).where((e) => e.name == 'Egg'),
    );
    await a.later('meal_templates', 30);
    await a.sync();
    await b.sync();
    expect(
      (await b.db.select(b.db.templateItems).get()).map((i) => i.name),
      ['Egg'],
    );
    expect(await b.db.select(b.db.mealTemplates).get(), hasLength(1));
  });

  test('a write that loses a race is retried against the new file', () async {
    await a.db.logFood(name: 'Egg', meal: MealType.breakfast, at: at);
    await a.sync();
    await b.sync();

    await b.db.logFood(name: 'Pie', meal: MealType.dinner, at: at);
    final pie = (await SyncStore(b.db).export()).encode();
    await a.db.logFood(name: 'Soup', meal: MealType.dinner, at: at);
    // Another device gets its upload in between A's read and A's write.
    backend.beforeNextWrite = () => backend.overwrite(pie);

    expect(await a.sync(), SyncOutcome.uploaded);
    final names = {for (final e in await a.entries()) e.name};
    expect(names, {'Egg', 'Pie', 'Soup'});
    expect(
      {for (final r in backend.snapshot!.tables['food_entries']!) r['name']},
      names,
    );
  });

  test('applying remote changes refreshes watchers', () async {
    await a.db.logFood(name: 'Egg', meal: MealType.breakfast, at: at);
    await a.sync();

    final seen = <int>[];
    final sub = b.db.watchDay(at).listen((rows) => seen.add(rows.length));
    await pumpEventQueue();
    await b.sync();
    await pumpEventQueue();
    await sub.cancel();

    expect(seen.first, 0);
    expect(seen.last, 1);
  });

  test('a file from a newer app is refused, not overwritten', () async {
    backend.text = '{"format": 99, "tables": {}, "tombstones": []}';
    await expectLater(a.sync(), throwsA(isA<Exception>()));
    expect(backend.text, contains('99'));
  });

  test('unknown table names in the file are ignored', () async {
    backend.text =
        '{"format":1,"tables":{"sqlite_master":[{"uuid":"x","updated_at":1}]},'
        '"tombstones":[{"uuid":"y","kind":"food_entries; DROP TABLE x",'
        '"deleted_at":5}]}';
    await a.db.logFood(name: 'Egg', meal: MealType.breakfast, at: at);
    await a.sync();
    expect(await a.entries(), hasLength(1));
  });
}
