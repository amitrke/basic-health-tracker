import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'health_service.dart' show Sex, restingKcal;

enum WeightUnit { kg, lb }

enum HeightUnit { cm, ftIn }

enum EnergyUnit { kcal, kJ }

enum WeightGoal { lose, maintain, gain }

/// Goals, units and onboarding state.
@immutable
class UserPrefs {
  const UserPrefs({
    this.onboarded = false,
    this.weightUnit = WeightUnit.kg,
    this.heightUnit = HeightUnit.cm,
    this.energyUnit = EnergyUnit.kcal,
    this.calorieGoal = 2000,
    this.proteinGoal = 120,
    this.carbsGoal = 220,
    this.fatGoal = 65,
    this.goal = WeightGoal.maintain,
    this.goalWeightKg,
    this.paceKgPerWeek = 0.25,
    this.heightCm,
    this.addActiveToBudget = true,
  });

  final bool onboarded;
  final WeightUnit weightUnit;
  final HeightUnit heightUnit;
  final EnergyUnit energyUnit;

  /// Daily budget in kcal, before any exercise is added.
  final int calorieGoal;
  final int proteinGoal;
  final int carbsGoal;
  final int fatGoal;

  final WeightGoal goal;
  final double? goalWeightKg;
  final double paceKgPerWeek;

  /// Entered during onboarding; Health's value wins when it has one.
  final double? heightCm;

  /// Exercise calories from Health raise the day's budget.
  final bool addActiveToBudget;

  UserPrefs copyWith({
    bool? onboarded,
    WeightUnit? weightUnit,
    HeightUnit? heightUnit,
    EnergyUnit? energyUnit,
    int? calorieGoal,
    int? proteinGoal,
    int? carbsGoal,
    int? fatGoal,
    WeightGoal? goal,
    double? goalWeightKg,
    bool clearGoalWeight = false,
    double? paceKgPerWeek,
    double? heightCm,
    bool? addActiveToBudget,
  }) => UserPrefs(
    onboarded: onboarded ?? this.onboarded,
    weightUnit: weightUnit ?? this.weightUnit,
    heightUnit: heightUnit ?? this.heightUnit,
    energyUnit: energyUnit ?? this.energyUnit,
    calorieGoal: calorieGoal ?? this.calorieGoal,
    proteinGoal: proteinGoal ?? this.proteinGoal,
    carbsGoal: carbsGoal ?? this.carbsGoal,
    fatGoal: fatGoal ?? this.fatGoal,
    goal: goal ?? this.goal,
    goalWeightKg: clearGoalWeight ? null : goalWeightKg ?? this.goalWeightKg,
    paceKgPerWeek: paceKgPerWeek ?? this.paceKgPerWeek,
    heightCm: heightCm ?? this.heightCm,
    addActiveToBudget: addActiveToBudget ?? this.addActiveToBudget,
  );

  Map<String, Object?> toJson() => {
    'onboarded': onboarded,
    'weightUnit': weightUnit.name,
    'heightUnit': heightUnit.name,
    'energyUnit': energyUnit.name,
    'calorieGoal': calorieGoal,
    'proteinGoal': proteinGoal,
    'carbsGoal': carbsGoal,
    'fatGoal': fatGoal,
    'goal': goal.name,
    'goalWeightKg': goalWeightKg,
    'paceKgPerWeek': paceKgPerWeek,
    'heightCm': heightCm,
    'addActiveToBudget': addActiveToBudget,
  };

  static UserPrefs decode(String source) {
    try {
      final j = jsonDecode(source) as Map<String, dynamic>;
      T byName<T extends Enum>(List<T> values, Object? name, T fallback) =>
          values.where((v) => v.name == name).firstOrNull ?? fallback;
      const d = UserPrefs();
      return UserPrefs(
        onboarded: j['onboarded'] as bool? ?? d.onboarded,
        weightUnit: byName(WeightUnit.values, j['weightUnit'], d.weightUnit),
        heightUnit: byName(HeightUnit.values, j['heightUnit'], d.heightUnit),
        energyUnit: byName(EnergyUnit.values, j['energyUnit'], d.energyUnit),
        calorieGoal: (j['calorieGoal'] as num?)?.round() ?? d.calorieGoal,
        proteinGoal: (j['proteinGoal'] as num?)?.round() ?? d.proteinGoal,
        carbsGoal: (j['carbsGoal'] as num?)?.round() ?? d.carbsGoal,
        fatGoal: (j['fatGoal'] as num?)?.round() ?? d.fatGoal,
        goal: byName(WeightGoal.values, j['goal'], d.goal),
        goalWeightKg: (j['goalWeightKg'] as num?)?.toDouble(),
        paceKgPerWeek:
            (j['paceKgPerWeek'] as num?)?.toDouble() ?? d.paceKgPerWeek,
        heightCm: (j['heightCm'] as num?)?.toDouble(),
        addActiveToBudget:
            j['addActiveToBudget'] as bool? ?? d.addActiveToBudget,
      );
    } catch (_) {
      return const UserPrefs();
    }
  }

  String encode() => jsonEncode(toJson());
}

/// A starting daily budget in kcal: resting burn for a mostly seated day
/// (exercise is added from Health), moved by the chosen pace. 7,700 kcal is
/// about 1 kg.
int suggestCalories({
  required double weightKg,
  required double heightCm,
  required int age,
  required Sex sex,
  required WeightGoal goal,
  required double paceKgPerWeek,
}) {
  final resting = restingKcal(
    weightKg: weightKg,
    heightCm: heightCm,
    age: age,
    sex: sex,
  )!;
  final change = (paceKgPerWeek * 7700 / 7).round();
  final kcal =
      (resting * 1.2).round() +
      switch (goal) {
        WeightGoal.lose => -change,
        WeightGoal.maintain => 0,
        WeightGoal.gain => change,
      };
  // Stay out of crash-diet territory and land on a round number.
  return (kcal.clamp(1200, 4000) / 50).round() * 50;
}

/// Macro goals in grams for [kcal]: 25% protein, 45% carbs, 30% fat.
({int protein, int carbs, int fat}) macrosFor(int kcal) => (
  protein: (kcal * 0.25 / 4).round(),
  carbs: (kcal * 0.45 / 4).round(),
  fat: (kcal * 0.30 / 9).round(),
);

abstract class UserPrefsStore {
  Future<UserPrefs> read();
  Future<void> write(UserPrefs prefs);
}

class SecureUserPrefsStore implements UserPrefsStore {
  static const _storage = FlutterSecureStorage();
  static const _name = 'user_prefs';

  @override
  Future<UserPrefs> read() async {
    final stored = await _storage.read(key: _name);
    return stored == null ? const UserPrefs() : UserPrefs.decode(stored);
  }

  @override
  Future<void> write(UserPrefs prefs) =>
      _storage.write(key: _name, value: prefs.encode());
}

class MemoryUserPrefsStore implements UserPrefsStore {
  MemoryUserPrefsStore([this._prefs = const UserPrefs(onboarded: true)]);

  UserPrefs _prefs;

  @override
  Future<UserPrefs> read() async => _prefs;

  @override
  Future<void> write(UserPrefs prefs) async => _prefs = prefs;
}

/// The loaded prefs, shared by every screen. Changes save straight away.
class PrefsController extends ChangeNotifier {
  PrefsController(this._store);

  final UserPrefsStore _store;
  UserPrefs _value = const UserPrefs();
  bool _loaded = false;

  UserPrefs get value => _value;
  bool get loaded => _loaded;

  Future<void> load() async {
    try {
      _value = await _store.read();
    } catch (_) {
      // An unreadable keystore must not lock the person out of the app.
      _value = const UserPrefs(onboarded: true);
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> update(UserPrefs Function(UserPrefs) change) async {
    _value = change(_value);
    notifyListeners();
    try {
      await _store.write(_value);
    } catch (_) {
      // Kept in memory for this session.
    }
  }
}
