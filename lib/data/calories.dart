import 'database.dart';

/// Scales a normal portion's calories to a smaller or larger one.
const portionFactor = {
  Portion.small: 0.7,
  Portion.normal: 1.0,
  Portion.large: 1.4,
};

/// Rough whole-meal calories, used only when a food has no number at all.
const _coarseKcal = {
  MealType.breakfast: {
    Portion.small: 250,
    Portion.normal: 400,
    Portion.large: 600,
  },
  MealType.lunch: {Portion.small: 400, Portion.normal: 600, Portion.large: 850},
  MealType.dinner: {
    Portion.small: 450,
    Portion.normal: 700,
    Portion.large: 950,
  },
  MealType.snack: {Portion.small: 100, Portion.normal: 200, Portion.large: 350},
};

class CalorieResult {
  const CalorieResult(this.kcal, {this.isEstimate = false});

  final int? kcal;
  final bool isEstimate;
}

/// Works out what to store for a log.
///
/// - Known [base] calories are scaled by [portion] (normal when unset).
/// - No [base] but a [portion] gives a coarse per-[meal] estimate.
/// - Neither means "just log what I ate", with no number.
CalorieResult resolveCalories({
  int? base,
  bool baseIsEstimate = false,
  Portion? portion,
  required MealType meal,
}) {
  if (base != null) {
    final kcal = (base * portionFactor[portion ?? Portion.normal]!).round();
    return CalorieResult(kcal, isEstimate: baseIsEstimate);
  }
  if (portion != null) {
    return CalorieResult(_coarseKcal[meal]![portion], isEstimate: true);
  }
  return const CalorieResult(null);
}
