import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'calories.dart';

part 'database.g.dart';

enum MealType { breakfast, lunch, dinner, snack }

/// How much of a food was eaten. Scales saved calories, or stands in for a
/// number entirely when none is known (see `resolveCalories`).
enum Portion { small, normal, large }

class FoodEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  IntColumn get mealType => intEnum<MealType>()();
  IntColumn get calories => integer().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get loggedAt => dateTime()();
  IntColumn get portion => intEnum<Portion>().nullable()();

  /// True when [calories] is a guess (portion size or AI), not a known value.
  BoolColumn get isEstimate => boolean().withDefault(const Constant(false))();
}

/// Foods the user has logged before. Calories are for a normal portion and are
/// entered once, then reused by every later one-tap log.
class SavedFoods extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200).unique()();
  IntColumn get calories => integer().nullable()();
  BoolColumn get isEstimate => boolean().withDefault(const Constant(false))();
  TextColumn get portionLabel => text().nullable()();
  TextColumn get barcode => text().nullable()();
  IntColumn get useCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastUsedAt => dateTime()();
}

class MealTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100).unique()();
  IntColumn get mealType => intEnum<MealType>()();
}

class TemplateItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get templateId => integer().references(MealTemplates, #id)();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  IntColumn get calories => integer().nullable()();
}

@DriftDatabase(tables: [FoodEntries, SavedFoods, MealTemplates, TemplateItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'wellbite'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(foodEntries, foodEntries.portion);
        await m.addColumn(foodEntries, foodEntries.isEstimate);
        await m.createTable(savedFoods);
        await m.createTable(mealTemplates);
        await m.createTable(templateItems);
        await _backfillSavedFoods();
      }
    },
  );

  /// Seeds the saved-food list from everything already logged, so quick-add
  /// is useful immediately after upgrading.
  Future<void> _backfillSavedFoods() async {
    final entries = await (select(
      foodEntries,
    )..orderBy([(e) => OrderingTerm.asc(e.loggedAt)])).get();
    for (final e in entries) {
      await _remember(
        name: e.name,
        calories: e.calories,
        at: e.loggedAt,
        uses: 1,
      );
    }
  }

  /// Entries logged on the local calendar day containing [day], oldest first.
  Stream<List<FoodEntry>> watchDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = DateTime(day.year, day.month, day.day + 1);
    return (select(foodEntries)
          ..where((e) => e.loggedAt.isBiggerOrEqualValue(start))
          ..where((e) => e.loggedAt.isSmallerThanValue(end))
          ..orderBy([(e) => OrderingTerm.asc(e.loggedAt)]))
        .watch();
  }

  Future<int> addEntry(FoodEntriesCompanion entry) =>
      into(foodEntries).insert(entry);

  Future<bool> updateEntry(FoodEntry entry) =>
      update(foodEntries).replace(entry);

  Future<int> deleteEntry(int id) =>
      (delete(foodEntries)..where((e) => e.id.equals(id))).go();

  Future<int> deleteEntries(Iterable<int> ids) =>
      (delete(foodEntries)..where((e) => e.id.isIn(ids))).go();

  // --- Saved foods -------------------------------------------------------

  /// Most-used foods first; what the quick-add chips show.
  Stream<List<SavedFood>> watchFrequentFoods({int limit = 8}) {
    return (select(savedFoods)
          ..orderBy([
            (f) => OrderingTerm.desc(f.useCount),
            (f) => OrderingTerm.desc(f.lastUsedAt),
          ])
          ..limit(limit))
        .watch();
  }

  /// Saved foods whose name contains [query], most-used first.
  Future<List<SavedFood>> searchFoods(String query, {int limit = 5}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return Future.value(const []);
    return (select(savedFoods)
          ..where((f) => f.name.lower().like('%$q%'))
          ..orderBy([
            (f) => OrderingTerm.desc(f.useCount),
            (f) => OrderingTerm.desc(f.lastUsedAt),
          ])
          ..limit(limit))
        .get();
  }

  Future<SavedFood?> findFood(String name) {
    return (select(savedFoods)
          ..where((f) => f.name.lower().equals(name.trim().toLowerCase()))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<SavedFood?> findFoodByBarcode(String barcode) {
    return (select(savedFoods)
          ..where((f) => f.barcode.equals(barcode))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<int> deleteSavedFood(int id) =>
      (delete(savedFoods)..where((f) => f.id.equals(id))).go();

  /// Creates or updates the saved food called [name]. Fields left null keep
  /// their stored value, so logging without calories never wipes them.
  Future<void> _remember({
    required String name,
    int? calories,
    bool isEstimate = false,
    String? portionLabel,
    String? barcode,
    required DateTime at,
    int uses = 1,
  }) async {
    final existing = await findFood(name);
    if (existing == null) {
      await into(savedFoods).insert(
        SavedFoodsCompanion.insert(
          name: name.trim(),
          lastUsedAt: at,
          calories: Value(calories),
          isEstimate: Value(calories != null && isEstimate),
          portionLabel: Value(portionLabel),
          barcode: Value(barcode),
          useCount: Value(uses),
        ),
      );
      return;
    }
    await (update(savedFoods)..where((f) => f.id.equals(existing.id))).write(
      SavedFoodsCompanion(
        calories: calories == null ? const Value.absent() : Value(calories),
        isEstimate: calories == null ? const Value.absent() : Value(isEstimate),
        portionLabel: portionLabel == null
            ? const Value.absent()
            : Value(portionLabel),
        barcode: barcode == null ? const Value.absent() : Value(barcode),
        useCount: Value(existing.useCount + uses),
        lastUsedAt: Value(at),
      ),
    );
  }

  /// Logs a food and remembers it for next time. [baseCalories] is for a
  /// normal portion; the stored entry is scaled by [portion]. With no
  /// calories at all, a [portion] gives a rough meal-based estimate instead.
  Future<int> logFood({
    required String name,
    required MealType meal,
    required DateTime at,
    int? baseCalories,
    bool baseIsEstimate = false,
    Portion? portion,
    String? notes,
    String? portionLabel,
    String? barcode,
  }) {
    return transaction(() async {
      await _remember(
        name: name,
        calories: baseCalories,
        isEstimate: baseIsEstimate,
        portionLabel: portionLabel,
        barcode: barcode,
        at: at,
      );
      final result = resolveCalories(
        base: baseCalories,
        baseIsEstimate: baseIsEstimate,
        portion: portion,
        meal: meal,
      );
      return addEntry(
        FoodEntriesCompanion.insert(
          name: name.trim(),
          mealType: meal,
          loggedAt: at,
          calories: Value(result.kcal),
          isEstimate: Value(result.isEstimate),
          portion: Value(portion),
          notes: Value(notes),
        ),
      );
    });
  }

  /// One-tap re-log of a saved food. Returns the new entry's id.
  Future<int> logSavedFood(
    SavedFood food, {
    required MealType meal,
    required DateTime at,
    Portion? portion,
  }) {
    return logFood(
      name: food.name,
      meal: meal,
      at: at,
      baseCalories: food.calories,
      baseIsEstimate: food.isEstimate,
      portion: portion,
      portionLabel: food.portionLabel,
    );
  }

  // --- Meal templates ----------------------------------------------------

  Stream<List<MealTemplate>> watchTemplates() => (select(
    mealTemplates,
  )..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();

  /// Saves [entries] as a reusable meal, replacing any template with the same
  /// name.
  Future<int> saveTemplate(
    String name,
    MealType meal,
    Iterable<FoodEntry> entries,
  ) {
    return transaction(() async {
      final old = await (select(
        mealTemplates,
      )..where((t) => t.name.lower().equals(name.trim().toLowerCase()))).get();
      for (final t in old) {
        await deleteTemplate(t.id);
      }
      final id = await into(mealTemplates).insert(
        MealTemplatesCompanion.insert(name: name.trim(), mealType: meal),
      );
      for (final e in entries) {
        await into(templateItems).insert(
          TemplateItemsCompanion.insert(
            templateId: id,
            name: e.name,
            calories: Value(e.calories),
          ),
        );
      }
      return id;
    });
  }

  /// Logs every item of [template] under [meal]. Returns the new entry ids.
  Future<List<int>> logTemplate(
    MealTemplate template, {
    required MealType meal,
    required DateTime at,
  }) {
    return transaction(() async {
      final items =
          await (select(templateItems)
                ..where((i) => i.templateId.equals(template.id))
                ..orderBy([(i) => OrderingTerm.asc(i.id)]))
              .get();
      final ids = <int>[];
      for (final item in items) {
        // Prefer the saved food's current calories over the snapshot.
        final saved = await findFood(item.name);
        ids.add(
          await logFood(
            name: item.name,
            meal: meal,
            at: at,
            baseCalories: saved?.calories ?? item.calories,
            baseIsEstimate: saved?.calories != null && saved!.isEstimate,
          ),
        );
      }
      return ids;
    });
  }

  Future<void> deleteTemplate(int id) async {
    await (delete(templateItems)..where((i) => i.templateId.equals(id))).go();
    await (delete(mealTemplates)..where((t) => t.id.equals(id))).go();
  }
}
