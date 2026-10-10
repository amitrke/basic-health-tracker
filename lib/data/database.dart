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

  // Macros in grams, when known.
  IntColumn get protein => integer().nullable()();
  IntColumn get carbs => integer().nullable()();
  IntColumn get fat => integer().nullable()();
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

  // Macros in grams for a normal portion, when known.
  IntColumn get protein => integer().nullable()();
  IntColumn get carbs => integer().nullable()();
  IntColumn get fat => integer().nullable()();
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
  IntColumn get protein => integer().nullable()();
  IntColumn get carbs => integer().nullable()();
  IntColumn get fat => integer().nullable()();
}

/// Weigh-ins entered in the app. Readings from Health are not copied here;
/// the weight screen merges them in when Health is on.
class WeightEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get measuredAt => dateTime()();
  RealColumn get kg => real()();
}

@DriftDatabase(
  tables: [
    FoodEntries,
    SavedFoods,
    MealTemplates,
    TemplateItems,
    WeightEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'wellbite'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(foodEntries, foodEntries.portion);
        await m.addColumn(foodEntries, foodEntries.isEstimate);
      }
      if (from < 3) {
        // Before the v2 backfill, which reads every food_entries column.
        await m.addColumn(foodEntries, foodEntries.protein);
        await m.addColumn(foodEntries, foodEntries.carbs);
        await m.addColumn(foodEntries, foodEntries.fat);
      }
      if (from < 2) {
        // Created from the current schema, so they already have macros.
        await m.createTable(savedFoods);
        await m.createTable(mealTemplates);
        await m.createTable(templateItems);
        await _backfillSavedFoods();
      } else if (from < 3) {
        await m.addColumn(savedFoods, savedFoods.protein);
        await m.addColumn(savedFoods, savedFoods.carbs);
        await m.addColumn(savedFoods, savedFoods.fat);
        await m.addColumn(templateItems, templateItems.protein);
        await m.addColumn(templateItems, templateItems.carbs);
        await m.addColumn(templateItems, templateItems.fat);
      }
      if (from < 3) await m.createTable(weightEntries);
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
        macros: Macros.of(e),
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

  /// Entries from the start of [from]'s day up to the end of [to]'s day.
  Stream<List<FoodEntry>> watchRange(DateTime from, DateTime to) {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day + 1);
    return (select(foodEntries)
          ..where((e) => e.loggedAt.isBiggerOrEqualValue(start))
          ..where((e) => e.loggedAt.isSmallerThanValue(end))
          ..orderBy([(e) => OrderingTerm.asc(e.loggedAt)]))
        .watch();
  }

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
    Macros macros = Macros.none,
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
          protein: Value(macros.protein),
          carbs: Value(macros.carbs),
          fat: Value(macros.fat),
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
        // Macros come as a set; a log that knows none keeps the stored ones.
        protein: macros.isEmpty ? const Value.absent() : Value(macros.protein),
        carbs: macros.isEmpty ? const Value.absent() : Value(macros.carbs),
        fat: macros.isEmpty ? const Value.absent() : Value(macros.fat),
        useCount: Value(existing.useCount + uses),
        lastUsedAt: Value(at),
      ),
    );
  }

  /// Logs a food and remembers it for next time. [baseCalories] and
  /// [baseMacros] are for a normal portion; the stored entry is scaled by
  /// [portion]. With no calories at all, a [portion] gives a rough meal-based
  /// estimate instead.
  Future<int> logFood({
    required String name,
    required MealType meal,
    required DateTime at,
    int? baseCalories,
    Macros baseMacros = Macros.none,
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
        macros: baseMacros,
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
      final macros = baseMacros.scaled(
        portionFactor[portion ?? Portion.normal]!,
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
          protein: Value(macros.protein),
          carbs: Value(macros.carbs),
          fat: Value(macros.fat),
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
      baseMacros: Macros.of(food),
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
            protein: Value(e.protein),
            carbs: Value(e.carbs),
            fat: Value(e.fat),
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
            baseMacros: saved == null || Macros.of(saved).isEmpty
                ? Macros.of(item)
                : Macros.of(saved),
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

  // --- Weight ------------------------------------------------------------

  /// Weigh-ins since [from], oldest first.
  Stream<List<WeightEntry>> watchWeights({DateTime? from}) {
    final q = select(weightEntries)
      ..orderBy([(w) => OrderingTerm.asc(w.measuredAt)]);
    if (from != null) q.where((w) => w.measuredAt.isBiggerOrEqualValue(from));
    return q.watch();
  }

  Future<int> addWeight(double kg, DateTime at) =>
      into(weightEntries)
          .insert(WeightEntriesCompanion.insert(measuredAt: at, kg: kg));

  Future<int> deleteWeight(int id) =>
      (delete(weightEntries)..where((w) => w.id.equals(id))).go();
}
