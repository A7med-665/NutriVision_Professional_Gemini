class NutritionCalculator {
  const NutritionCalculator();

  /// Estimate energy using the conventional 4/4/9 kcal-per-gram factors.
  /// This is an estimate; fiber, alcohol, food labels, and measurement error can change real values.
  double caloriesFromMacros({required double protein, required double carbs, required double fats}) {
    final values = [protein, carbs, fats];
    if (values.any((value) => !value.isFinite || value < 0)) {
      throw ArgumentError('Macronutrient values must be finite and non-negative.');
    }
    return protein * 4 + carbs * 4 + fats * 9;
  }

  double percentOfDailyGoal(double calories, {double goal = 2000}) {
    if (!calories.isFinite || !goal.isFinite || goal <= 0) return 0;
    return (calories / goal * 100).clamp(0, 100).toDouble();
  }

  double safeNumber(String value) {
    final parsed = double.tryParse(value.trim());
    return parsed != null && parsed.isFinite && parsed >= 0 ? parsed : 0;
  }
}
