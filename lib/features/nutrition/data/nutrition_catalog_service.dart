import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/config/app_config.dart';

/// Nutrient values are normalized by the backend to a 100 g food basis.
class FoodNutrition {
  const FoodNutrition({
    required this.id,
    required this.name,
    this.caloriesKcal,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.fiberG,
    this.sugarG,
    this.sodiumMg,
    this.saturatedFatG,
    this.cholesterolMg,
    this.servingNote,
  });

  final int id;
  final String name;
  final double? caloriesKcal, proteinG, carbsG, fatG, fiberG, sugarG;
  final double? sodiumMg, saturatedFatG, cholesterolMg;
  final String? servingNote;

  factory FoodNutrition.fromMap(Map<String, dynamic> map) => FoodNutrition(
    id: (map['id'] as num?)?.toInt() ?? 0,
    name: map['name'] as String? ?? 'Unknown food',
    caloriesKcal: _toDouble(map['caloriesKcal']),
    proteinG: _toDouble(map['proteinG']),
    carbsG: _toDouble(map['carbsG']),
    fatG: _toDouble(map['fatG']),
    fiberG: _toDouble(map['fiberG']),
    sugarG: _toDouble(map['sugarG']),
    sodiumMg: _toDouble(map['sodiumMg']),
    saturatedFatG: _toDouble(map['saturatedFatG']),
    cholesterolMg: _toDouble(map['cholesterolMg']),
    servingNote: map['servingNote'] as String?,
  );

  static double? _toDouble(dynamic value) => value is num ? value.toDouble() : null;

  double? scale(double? value, double grams) => value == null ? null : value * grams / 100;
}

/// Uses a trusted backend proxy so the USDA API key never ships inside the mobile app.
class NutritionCatalogService {
  NutritionCatalogService({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(
    baseUrl: AppConfig.nutritionApiBaseUrl.isEmpty ? '' : '${AppConfig.nutritionApiBaseUrl.replaceFirst(RegExp(r'/+$'), '')}/',
    connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 15),
  )) {
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) async {
      options.headers['Accept'] = 'application/json';
      if (AppConfig.firebaseReady) {
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            // Firebase SDK refreshes the token when it expires.
            final token = await user.getIdToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
        } catch (error) {
          return handler.reject(DioException(
            requestOptions: options,
            error: 'Could not obtain Firebase ID token: $error',
          ));
        }
      }
      handler.next(options);
    }));
  }
  final Dio _dio;

  Future<List<FoodNutrition>> search(String query) async {
    if (AppConfig.nutritionApiBaseUrl.isEmpty) {
      throw StateError('البحث التلقائي غير مهيأ. اضبط NUTRITION_API_BASE_URL على عنوان /api في Backend.');
    }
    final cleanedQuery = query.trim();
    if (cleanedQuery.length < 2) {
      throw ArgumentError('اكتب حرفين على الأقل للبحث عن الطعام.');
    }
    final response = await _dio.get<Map<String, dynamic>>(
      'foods/search',
      queryParameters: {'q': cleanedQuery},
    );
    final items = response.data?['foods'];
    if (items is! List) throw const FormatException('Unexpected food-search response.');
    return items.whereType<Map<String, dynamic>>().map(FoodNutrition.fromMap).toList(growable: false);
  }
}
