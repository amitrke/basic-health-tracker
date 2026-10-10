import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:health/health.dart';

/// Calories burned on one day, as reported by Apple Health or Health Connect.
class EnergyBurned {
  const EnergyBurned({this.active, this.total, this.totalIsEstimate = false});

  /// Exercise and movement only.
  final int? active;

  /// Active plus resting energy, when the platform reports it.
  final int? total;

  /// [total] was worked out from weight, height, age and sex rather than
  /// reported by Health.
  final bool totalIsEstimate;

  bool get isEmpty => active == null && total == null;
}

enum Sex { female, male }

/// What Health does not hand over, entered once in Settings.
class BodyProfile {
  const BodyProfile({this.age, this.sex});

  final int? age;
  final Sex? sex;

  Map<String, Object?> toJson() => {'age': age, 'sex': sex?.name};

  factory BodyProfile.fromJson(Map<String, dynamic> json) => BodyProfile(
    age: json['age'] as int?,
    sex: Sex.values.where((s) => s.name == json['sex']).firstOrNull,
  );
}

/// Calories the body burns at rest in a day (Mifflin-St Jeor), or null when
/// any input is missing.
int? restingKcal({double? weightKg, double? heightCm, int? age, Sex? sex}) {
  if (weightKg == null || heightCm == null || age == null || sex == null) {
    return null;
  }
  final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
  return (base + (sex == Sex.male ? 5 : -161)).round();
}

/// The person's body measurements, as last recorded in Health.
class BodyStats {
  const BodyStats({this.weightKg, this.heightCm});

  final double? weightKg;
  final double? heightCm;

  bool get isEmpty => weightKg == null && heightCm == null;
}

/// Read-only access to the phone's health data. Faked in tests.
abstract class HealthSource {
  /// False when Health Connect is missing or the platform has no health store.
  Future<bool> isAvailable();

  /// Asks for read access. Apple does not say whether read access was granted,
  /// so a true here only means the request went through.
  Future<bool> requestAccess();

  Future<EnergyBurned> energyBurned(DateTime day);

  Future<BodyStats> bodyStats();

  /// Weight readings since [from], oldest first. Empty when there are none
  /// or access is missing.
  Future<List<WeightReading>> weightHistory(DateTime from);
}

/// One weigh-in, from Health or typed into the app.
class WeightReading {
  const WeightReading({
    required this.at,
    required this.kg,
    this.fromHealth = false,
    this.id,
  });

  final DateTime at;
  final double kg;
  final bool fromHealth;

  /// The app's own row id, so a typed entry can be deleted.
  final int? id;
}

/// Where the on/off choice is remembered.
abstract class HealthPrefsStore {
  Future<bool> readEnabled();
  Future<void> writeEnabled(bool enabled);
  Future<BodyProfile> readProfile();
  Future<void> writeProfile(BodyProfile profile);
}

class SecureHealthPrefsStore implements HealthPrefsStore {
  static const _storage = FlutterSecureStorage();
  static const _name = 'health_enabled';
  static const _profileName = 'body_profile';

  @override
  Future<bool> readEnabled() async => await _storage.read(key: _name) == '1';

  @override
  Future<void> writeEnabled(bool enabled) =>
      _storage.write(key: _name, value: enabled ? '1' : '0');

  @override
  Future<BodyProfile> readProfile() async {
    final stored = await _storage.read(key: _profileName);
    if (stored == null) return const BodyProfile();
    try {
      return BodyProfile.fromJson(jsonDecode(stored) as Map<String, dynamic>);
    } catch (_) {
      return const BodyProfile();
    }
  }

  @override
  Future<void> writeProfile(BodyProfile profile) =>
      _storage.write(key: _profileName, value: jsonEncode(profile.toJson()));
}

class MemoryHealthPrefsStore implements HealthPrefsStore {
  MemoryHealthPrefsStore([this._enabled = false]);

  bool _enabled;
  BodyProfile _profile = const BodyProfile();

  @override
  Future<bool> readEnabled() async => _enabled;

  @override
  Future<void> writeEnabled(bool enabled) async => _enabled = enabled;

  @override
  Future<BodyProfile> readProfile() async => _profile;

  @override
  Future<void> writeProfile(BodyProfile profile) async => _profile = profile;
}

/// Sums [points] per source and returns the largest sum.
///
/// A phone and a watch both record the same walk. Adding them would double
/// count, so only the fullest single source is used.
double? bestSourceTotal(Iterable<({String source, double value})> points) {
  final bySource = <String, double>{};
  for (final p in points) {
    bySource[p.source] = (bySource[p.source] ?? 0) + p.value;
  }
  if (bySource.isEmpty) return null;
  return bySource.values.reduce((a, b) => a > b ? a : b);
}

/// Apple HealthKit on iOS, Health Connect on Android. Anywhere else (desktop,
/// web) it reports itself unavailable and returns nothing.
class PlatformHealthSource implements HealthSource {
  PlatformHealthSource([Health? health]) : _health = health ?? Health();

  final Health _health;
  bool _configured = false;

  static bool get _supported => Platform.isIOS || Platform.isAndroid;

  // Android has one total-energy record; iOS splits it into active and resting.
  static List<HealthDataType> get _energyTypes => Platform.isIOS
      ? [
          HealthDataType.ACTIVE_ENERGY_BURNED,
          HealthDataType.BASAL_ENERGY_BURNED,
        ]
      : [
          HealthDataType.ACTIVE_ENERGY_BURNED,
          HealthDataType.TOTAL_CALORIES_BURNED,
        ];

  static const _bodyTypes = [HealthDataType.WEIGHT, HealthDataType.HEIGHT];

  static List<HealthDataType> get _allTypes => [..._energyTypes, ..._bodyTypes];

  Future<void> _configure() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  @override
  Future<bool> isAvailable() async {
    if (!_supported) return false;
    try {
      await _configure();
      return await _health.isHealthConnectAvailable();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestAccess() async {
    if (!_supported) return false;
    try {
      await _configure();
      return await _health.requestAuthorization(
        _allTypes,
        permissions: List.filled(_allTypes.length, HealthDataAccess.READ),
      );
    } catch (_) {
      return false;
    }
  }

  @override
  Future<EnergyBurned> energyBurned(DateTime day) async {
    if (!_supported) return const EnergyBurned();
    try {
      await _configure();
      final start = DateTime(day.year, day.month, day.day);
      final end = DateTime(day.year, day.month, day.day + 1);
      final points = await _health.getHealthDataFromTypes(
        types: _energyTypes,
        startTime: start,
        endTime: end,
        preferredUnits: {
          for (final t in _energyTypes) t: HealthDataUnit.KILOCALORIE,
        },
      );
      double? sum(HealthDataType type) => bestSourceTotal(
        points
            .where((p) => p.type == type && p.value is NumericHealthValue)
            .map(
              (p) => (
                source: p.sourceId,
                value: (p.value as NumericHealthValue).numericValue.toDouble(),
              ),
            ),
      );

      final active = sum(HealthDataType.ACTIVE_ENERGY_BURNED);
      final double? total;
      if (Platform.isIOS) {
        final resting = sum(HealthDataType.BASAL_ENERGY_BURNED);
        total = active == null && resting == null
            ? null
            : (active ?? 0) + (resting ?? 0);
      } else {
        total = sum(HealthDataType.TOTAL_CALORIES_BURNED);
      }
      return EnergyBurned(active: active?.round(), total: total?.round());
    } catch (_) {
      return const EnergyBurned();
    }
  }

  @override
  Future<BodyStats> bodyStats() async {
    if (!_supported) return const BodyStats();
    try {
      await _configure();
      final now = DateTime.now();
      final points = await _health.getHealthDataFromTypes(
        types: _bodyTypes,
        startTime: now.subtract(const Duration(days: 365)),
        endTime: now,
        preferredUnits: {
          HealthDataType.WEIGHT: HealthDataUnit.KILOGRAM,
          HealthDataType.HEIGHT: HealthDataUnit.METER,
        },
      );
      double? latest(HealthDataType type) {
        final matching =
            points
                .where((p) => p.type == type && p.value is NumericHealthValue)
                .toList()
              ..sort((a, b) => b.dateTo.compareTo(a.dateTo));
        if (matching.isEmpty) return null;
        return (matching.first.value as NumericHealthValue).numericValue
            .toDouble();
      }

      final heightM = latest(HealthDataType.HEIGHT);
      return BodyStats(
        weightKg: latest(HealthDataType.WEIGHT),
        heightCm: heightM == null ? null : heightM * 100,
      );
    } catch (_) {
      return const BodyStats();
    }
  }

  @override
  Future<List<WeightReading>> weightHistory(DateTime from) async {
    if (!_supported) return const [];
    try {
      await _configure();
      final points = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.WEIGHT],
        startTime: from,
        endTime: DateTime.now(),
        preferredUnits: {HealthDataType.WEIGHT: HealthDataUnit.KILOGRAM},
      );
      final readings = [
        for (final p in points)
          if (p.value is NumericHealthValue)
            WeightReading(
              at: p.dateTo,
              kg: (p.value as NumericHealthValue).numericValue.toDouble(),
              fromHealth: true,
            ),
      ]..sort((a, b) => a.at.compareTo(b.at));
      return readings;
    } catch (_) {
      return const [];
    }
  }
}
