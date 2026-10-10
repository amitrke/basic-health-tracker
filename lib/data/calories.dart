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

/// Protein, carbs and fat in grams. Any of them may be unknown.
class Macros {
  const Macros({this.protein, this.carbs, this.fat});

  static const none = Macros();

  /// Reads the macro fields of a food entry, saved food or template item.
  factory Macros.of(Object row) => switch (row) {
    FoodEntry e => Macros(protein: e.protein, carbs: e.carbs, fat: e.fat),
    SavedFood f => Macros(protein: f.protein, carbs: f.carbs, fat: f.fat),
    TemplateItem i => Macros(protein: i.protein, carbs: i.carbs, fat: i.fat),
    _ => none,
  };

  final int? protein;
  final int? carbs;
  final int? fat;

  bool get isEmpty => protein == null && carbs == null && fat == null;

  Macros scaled(double factor) => Macros(
    protein: protein == null ? null : (protein! * factor).round(),
    carbs: carbs == null ? null : (carbs! * factor).round(),
    fat: fat == null ? null : (fat! * factor).round(),
  );

  Macros operator +(Macros o) => Macros(
    protein: _add(protein, o.protein),
    carbs: _add(carbs, o.carbs),
    fat: _add(fat, o.fat),
  );

  static int? _add(int? a, int? b) =>
      a == null && b == null ? null : (a ?? 0) + (b ?? 0);

  /// Summed over [entries]; unknown values count as nothing.
  static Macros total(Iterable<FoodEntry> entries) =>
      entries.fold(none, (sum, e) => sum + Macros.of(e));
}
