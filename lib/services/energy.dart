import '../data/database.dart';
import 'health_service.dart';
import 'services.dart';

/// Calories burned on [day], or null when Health is off, unavailable or has
/// nothing. When Health reports only exercise, resting burn is added from
/// weight, height, age and sex if they are known.
Future<EnergyBurned?> loadBurned(AppServices services, DateTime day) async {
  try {
    if (!await services.healthPrefs.readEnabled()) return null;
    final burned = await services.health.energyBurned(day);
    if (burned.isEmpty) return null;
    if (burned.total != null || burned.active == null) return burned;
    final body = await services.health.bodyStats();
    final profile = await services.healthPrefs.readProfile();
    final resting = restingKcal(
      weightKg: body.weightKg,
      heightCm: body.heightCm ?? services.prefs.value.heightCm,
      age: profile.age,
      sex: profile.sex,
    );
    if (resting == null) return burned;
    return EnergyBurned(
      active: burned.active,
      total: burned.active! + resting,
      totalIsEstimate: true,
    );
  } catch (_) {
    // Health is a bonus; the food log must work without it.
    return null;
  }
}

/// Health's weight readings since [from]; empty when Health is off.
Future<List<WeightReading>> healthWeights(
  AppServices services,
  DateTime from,
) async {
  try {
    if (!await services.healthPrefs.readEnabled()) return const [];
    return await services.health.weightHistory(from);
  } catch (_) {
    return const [];
  }
}

/// Weigh-ins typed into the app and read from Health, oldest first.
List<WeightReading> mergeWeights(
  Iterable<WeightEntry> app,
  Iterable<WeightReading> health,
) => [
  for (final w in app) WeightReading(at: w.measuredAt, kg: w.kg, id: w.id),
  ...health,
]..sort((a, b) => a.at.compareTo(b.at));
