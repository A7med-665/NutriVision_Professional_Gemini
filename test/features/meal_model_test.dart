import 'package:flutter_test/flutter_test.dart';
import 'package:nutrivision/features/meals/domain/meal.dart';
import 'package:nutrivision/features/nutrition/data/nutrition_catalog_service.dart';

void main() {
  test('Meal round-trips through its serializable map', () {
    final original = Meal(id: 'meal-1', name: 'Oats', calories: 250, protein: 10,
      carbs: 40, fats: 5, createdAt: DateTime.utc(2026, 1, 2), notes: '50 g serving', advice: 'General advice',
      portionGrams: 150, fiber: 4, sugar: 8, sodiumMg: 120, saturatedFat: 2, cholesterolMg: 15, nutritionSource: 'USDA FoodData Central');
    final decoded = Meal.fromMap(original.toMap());
    expect(decoded.id, original.id);
    expect(decoded.name, original.name);
    expect(decoded.calories, original.calories);
    expect(decoded.createdAt, original.createdAt);
    expect(decoded.notes, original.notes);
    expect(decoded.advice, original.advice);
    expect(decoded.portionGrams, 150);
    expect(decoded.fiber, 4);
    expect(decoded.sugar, 8);
    expect(decoded.sodiumMg, 120);
    expect(decoded.saturatedFat, 2);
    expect(decoded.cholesterolMg, 15);
    expect(decoded.nutritionSource, 'USDA FoodData Central');
  });

  test('Meal parser tolerates missing optional fields and numeric strings', () {
    final meal = Meal.fromMap({'id': 'x', 'name': 'Apple', 'calories': '95'});
    expect(meal.calories, 95);
    expect(meal.protein, 0);
    expect(meal.notes, isEmpty);
  });
  test('FoodNutrition scales source values to the selected portion', () {
    const food = FoodNutrition(id: 1, name: 'Apple', caloriesKcal: 52, proteinG: 0.3, fiberG: 2.4);
    expect(food.scale(food.caloriesKcal, 150), 78);
    expect(food.scale(food.proteinG, 50), closeTo(0.15, 0.0001));
    expect(food.scale(food.fiberG, 200), 4.8);
    expect(food.scale(null, 100), isNull);
  });
}
