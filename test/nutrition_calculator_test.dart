import 'package:flutter_test/flutter_test.dart';
import 'package:nutrivision/features/meals/domain/nutrition_calculator.dart';

void main() {
  const calculator = NutritionCalculator();
  group('NutritionCalculator', () {
    test('calculates calories using 4/4/9 macro factors', () {
      expect(calculator.caloriesFromMacros(protein: 10, carbs: 20, fats: 5), 165);
    });
    test('rejects negative or non-finite macro values', () {
      expect(() => calculator.caloriesFromMacros(protein: -1, carbs: 2, fats: 3), throwsArgumentError);
      expect(() => calculator.caloriesFromMacros(protein: double.nan, carbs: 2, fats: 3), throwsArgumentError);
    });
    test('returns zero percent for invalid daily goal', () {
      expect(calculator.percentOfDailyGoal(500, goal: 0), 0);
      expect(calculator.percentOfDailyGoal(500, goal: -1), 0);
    });
    test('caps daily goal percentage at 100 and floors at zero', () {
      expect(calculator.percentOfDailyGoal(2500, goal: 2000), 100);
      expect(calculator.percentOfDailyGoal(-1, goal: 2000), 0);
    });
    test('parses invalid numbers safely', () {
      expect(calculator.safeNumber('abc'), 0);
      expect(calculator.safeNumber('-2'), 0);
      expect(calculator.safeNumber('12.5'), 12.5);
    });
  });
}
