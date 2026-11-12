import 'package:equatable/equatable.dart';

class Meal extends Equatable {
  const Meal({required this.id, required this.name, required this.calories, required this.protein,
    required this.carbs, required this.fats, required this.createdAt, this.notes = '', this.advice = '',
    this.portionGrams = 100, this.fiber = 0, this.sugar = 0, this.sodiumMg = 0,
    this.saturatedFat = 0, this.cholesterolMg = 0, this.nutritionSource = 'manual'});
  final String id, name, notes, advice, nutritionSource;
  final double calories, protein, carbs, fats, portionGrams, fiber, sugar, sodiumMg, saturatedFat, cholesterolMg;
  final DateTime createdAt;
  @override
  List<Object?> get props => [id, name, calories, protein, carbs, fats, createdAt, notes, advice,
    portionGrams, fiber, sugar, sodiumMg, saturatedFat, cholesterolMg, nutritionSource];
  Map<String, dynamic> toMap() => {'id':id,'name':name,'calories':calories,'protein':protein,'carbs':carbs,'fats':fats,
    'createdAt':createdAt.toIso8601String(),'notes':notes,'advice':advice,'portionGrams':portionGrams,
    'fiber':fiber,'sugar':sugar,'sodiumMg':sodiumMg,'saturatedFat':saturatedFat,
    'cholesterolMg':cholesterolMg,'nutritionSource':nutritionSource};
  factory Meal.fromMap(Map<String, dynamic> map) => Meal(id: map['id'] as String? ?? '', name: map['name'] as String? ?? 'Meal',
    calories: _num(map['calories']), protein: _num(map['protein']), carbs: _num(map['carbs']), fats: _num(map['fats']),
    createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
    notes: map['notes'] as String? ?? '', advice: map['advice'] as String? ?? '',
    portionGrams: _num(map['portionGrams'], fallback: 100), fiber: _num(map['fiber']), sugar: _num(map['sugar']),
    sodiumMg: _num(map['sodiumMg']), saturatedFat: _num(map['saturatedFat']), cholesterolMg: _num(map['cholesterolMg']),
    nutritionSource: map['nutritionSource'] as String? ?? 'legacy');
  static double _num(dynamic v, {double fallback = 0}) => v is num ? v.toDouble() : double.tryParse('$v') ?? fallback;
}
