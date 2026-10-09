import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

enum MealType { breakfast, lunch, dinner, snack }

class FoodEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  IntColumn get mealType => intEnum<MealType>()();
  IntColumn get calories => integer().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get loggedAt => dateTime()();
}

@DriftDatabase(tables: [FoodEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'wellbite'));

  @override
  int get schemaVersion => 1;

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
}
