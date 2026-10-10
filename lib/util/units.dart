import 'package:intl/intl.dart';

import '../services/user_prefs.dart';

final _whole = NumberFormat('#,##0');
final _oneDecimal = NumberFormat('#,##0.0');

const _kJPerKcal = 4.184;
const _lbPerKg = 2.2046226;

/// Formats and parses numbers in the units the person picked.
class Units {
  const Units(this.prefs);

  final UserPrefs prefs;

  bool get _kJ => prefs.energyUnit == EnergyUnit.kJ;
  bool get _lb => prefs.weightUnit == WeightUnit.lb;

  String get energyLabel => _kJ ? 'kJ' : 'kcal';
  String get weightLabel => _lb ? 'lb' : 'kg';

  /// Energy as a bare number, grouped: "2,100".
  String energyNumber(num kcal) =>
      _whole.format((_kJ ? kcal * _kJPerKcal : kcal).round());

  /// "2,100 kcal" or "8,786 kJ"; [estimate] adds a leading "~".
  String energy(num kcal, {bool estimate = false}) =>
      '${estimate ? '~' : ''}${energyNumber(kcal)} $energyLabel';

  /// Signed: "+320 kcal", "-1,600 kcal".
  String energySigned(num kcal) =>
      '${kcal > 0 ? '+' : ''}${energyNumber(kcal)} $energyLabel';

  double weightValue(double kg) => _lb ? kg * _lbPerKg : kg;

  String weightNumber(double kg) => _oneDecimal.format(weightValue(kg));

  /// "78.4 kg" or "172.8 lb".
  String weight(double kg) => '${weightNumber(kg)} $weightLabel';

  /// "−1.6 kg", "+0.2 lb", "0.0 kg".
  String weightChange(double kg) {
    final v = weightValue(kg);
    final sign = v >= 0.05 ? '+' : (v <= -0.05 ? '−' : '');
    return '$sign${_oneDecimal.format(v.abs())} $weightLabel';
  }

  /// Kilograms from a number typed in the chosen weight unit.
  double? parseWeight(String text) {
    final v = double.tryParse(text.trim().replaceAll(',', '.'));
    if (v == null || v <= 0) return null;
    return _lb ? v / _lbPerKg : v;
  }

  /// Centimetres from a number typed in cm, or inches for feet and inches.
  double? parseHeight(String text) {
    final v = double.tryParse(text.trim().replaceAll(',', '.'));
    if (v == null || v <= 0) return null;
    return prefs.heightUnit == HeightUnit.cm ? v : v * 2.54;
  }

  String height(double cm) {
    if (prefs.heightUnit == HeightUnit.cm) return '${cm.round()} cm';
    final inches = (cm / 2.54).round();
    return '${inches ~/ 12} ft ${inches % 12} in';
  }
}
