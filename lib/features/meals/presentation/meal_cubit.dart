import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../ai/data/ai_advisor_service.dart';
import '../data/meal_repository.dart';
import '../domain/meal.dart';

class MealState {
  const MealState({
    this.meals = const [],
    this.loading = false,
    this.error,
    this.advice,
  });

  final List<Meal> meals;
  final bool loading;
  final String? error;
  final String? advice;

  MealState copyWith({
    List<Meal>? meals,
    bool? loading,
    String? error,
    String? advice,
  }) =>
      MealState(
        meals: meals ?? this.meals,
        loading: loading ?? this.loading,
        // Passing null clears a previous error; most state transitions should do so.
        error: error,
        advice: advice ?? this.advice,
      );
}

class MealCubit extends Cubit<MealState> {
  MealCubit({MealRepository? repository, AiAdvisorService? ai})
      : _repository = repository ?? MealRepository(),
        _ai = ai ?? AiAdvisorService(),
        super(const MealState());

  final MealRepository _repository;
  final AiAdvisorService _ai;
  final Uuid _uuid = const Uuid();
  StreamSubscription<List<Meal>>? _subscription;

  void startWatching() {
    if (_subscription != null) return;
    emit(state.copyWith(loading: true));
    _subscription = _repository.watchMeals().listen(
      (meals) {
        if (!isClosed) emit(state.copyWith(meals: meals, loading: false));
      },
      onError: (Object _) {
        if (!isClosed) {
          emit(state.copyWith(
            loading: false,
            error: 'تعذر تحميل الوجبات. تحقق من إعدادات Firestore.',
          ));
        }
      },
    );
  }

  Future<void> addMeal({
    required String name,
    required double calories,
    required double protein,
    required double carbs,
    required double fats,
    String notes = '',
    String restrictions = '',
    double portionGrams = 100,
    double fiber = 0,
    double sugar = 0,
    double sodiumMg = 0,
    double saturatedFat = 0,
    double cholesterolMg = 0,
    String nutritionSource = 'manual',
  }) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final advice = await _ai.mealAdvice(
        mealDescription: '$name. $notes',
        dietaryRestrictions: restrictions,
      );
      final meal = Meal(
        id: _uuid.v4(),
        name: name,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fats: fats,
        createdAt: DateTime.now(),
        notes: notes,
        advice: advice,
        portionGrams: portionGrams,
        fiber: fiber,
        sugar: sugar,
        sodiumMg: sodiumMg,
        saturatedFat: saturatedFat,
        cholesterolMg: cholesterolMg,
        nutritionSource: nutritionSource,
      );
      await _repository.save(meal);
      if (!isClosed) {
        emit(state.copyWith(
          meals: [meal, ...state.meals.where((item) => item.id != meal.id)],
          loading: false,
          advice: advice,
        ));
      }
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(
          loading: false,
          error: 'لم نتمكن من حفظ الوجبة. تحقق من الإعدادات ثم حاول مرة أخرى.',
        ));
      }
      rethrow;
    }
  }

  Future<void> deleteMeal(Meal meal) async {
    try {
      await _repository.delete(meal.id);
      if (!isClosed) {
        emit(state.copyWith(
          meals: state.meals.where((item) => item.id != meal.id).toList(growable: false),
          loading: false,
        ));
      }
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(
          loading: false,
          error: 'تعذر حذف الوجبة. حاول مرة أخرى.',
        ));
      }
      rethrow;
    }
  }

  Future<List<String>> alternatives(String snack, {String restrictions = ''}) =>
      _ai.snackAlternatives(snack, restrictions: restrictions);

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await super.close();
  }
}
