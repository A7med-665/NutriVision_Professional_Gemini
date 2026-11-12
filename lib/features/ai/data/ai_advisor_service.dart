import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/config/app_config.dart';

class AiAdvisorService {
  AiAdvisorService({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 12),
    receiveTimeout: const Duration(seconds: 25),
    sendTimeout: const Duration(seconds: 12),
    headers: const {'Accept': 'application/json', 'Content-Type': 'application/json'},
  )) {
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) async {
      options.headers['X-Request-Id'] = DateTime.now().microsecondsSinceEpoch.toString();
      if (AppConfig.firebaseReady) {
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
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

  Future<String> mealAdvice({required String mealDescription, String dietaryRestrictions = ''}) async {
    if (AppConfig.aiBackendUrl.isEmpty) return localAdvice(mealDescription, dietaryRestrictions);
    try {
      final response = await _dio.post(AppConfig.aiBackendUrl, data: {
        'task': 'meal_analysis', 'meal_description': mealDescription,
        'dietary_restrictions': dietaryRestrictions,
      });
      final data = response.data;
      if (data is Map && data['advice'] is String) return (data['advice'] as String).trim();
      throw const FormatException('Unexpected AI response: expected an advice string.');
    } on DioException {
      return 'تعذر الاتصال بخدمة الذكاء الاصطناعي الآن، لذلك لم يتم إنشاء تحليل مولّد. يمكنك المحاولة لاحقًا. هذه معلومات عامة وليست نصيحة طبية.';
    }
  }

  String localAdvice(String description, String restrictions) {
    final restrictionText = restrictions.trim().isEmpty
      ? 'لم تُحدد قيود غذائية.' : 'راعِ القيود التالية عند اختيار الطعام: $restrictions.';
    return 'إرشادات محلية عامة (ليست مولدة بالذكاء الاصطناعي) لوجبة "$description": حاول تضمين مصدر بروتين وخضروات أو فاكهة، واختر الحبوب الكاملة عند الإمكان، وانتبه لحجم الحصة والصلصات عالية السعرات. $restrictionText التقديرات تعتمد على المكونات والكميات الفعلية. هذه إرشادات عامة وليست تشخيصًا طبيًا.';
  }

  Future<List<String>> snackAlternatives(String snack, {String restrictions = ''}) async {
    if (AppConfig.aiBackendUrl.isEmpty) {
      return _localAlternatives().map((item) => 'اقتراح محلي غير مولّد بالذكاء الاصطناعي: $item').toList(growable: false);
    }
    try {
      final response = await _dio.post(AppConfig.aiBackendUrl, data: {
        'task': 'snack_alternatives', 'snack': snack, 'dietary_restrictions': restrictions,
      });
      final list = response.data is Map ? response.data['alternatives'] : null;
      if (list is List && list.isNotEmpty) return list.map((e) => e.toString()).take(5).toList();
    } on DioException {
      return _localAlternatives().map((item) => 'اقتراح محلي غير مولّد بالذكاء الاصطناعي: $item').toList(growable: false);
    }
    return _localAlternatives().map((item) => 'اقتراح محلي غير مولّد بالذكاء الاصطناعي: $item').toList(growable: false);
  }

  Future<String> generateRecipe({required List<String> ingredients, String restrictions = ''}) async {
    final cleaned = ingredients.map((item) => item.trim()).where((item) => item.isNotEmpty).take(30).toList();
    if (cleaned.isEmpty) throw ArgumentError('At least one ingredient is required.');
    if (AppConfig.aiBackendUrl.isEmpty) {
      return 'وصفة مبدئية باستخدام: ${cleaned.join('، ')}\n\n1. حضّر المكونات واغسل ما يحتاج إلى غسل.\n2. اطهُ المكونات المناسبة معًا بطريقة صحية وبكمية زيت معتدلة.\n3. اضبط التتبيل حسب رغبتك والقيود الغذائية (${restrictions.trim().isEmpty ? 'لم تُحدد قيود' : restrictions.trim()}).\n\nهذه فكرة محلية عامة وليست وصفة مولدة من نموذج AI؛ تحقّق من المكونات ومسببات الحساسية ودرجة الطهي الآمنة.';
    }
    try {
      final response = await _dio.post(AppConfig.aiBackendUrl, data: {
        'task': 'recipe_generation', 'ingredients': cleaned, 'dietary_restrictions': restrictions,
      });
      final recipe = response.data is Map ? response.data['recipe'] : null;
      if (recipe is String && recipe.trim().isNotEmpty) return recipe.trim();
      throw const FormatException('Unexpected AI response: expected a recipe string.');
    } on DioException {
      throw Exception('تعذر الاتصال بخدمة الوصفات الآن. حاول مرة أخرى لاحقًا.');
    }
  }

  List<String> _localAlternatives() => const [
    'فاكهة طازجة مع زبادي طبيعي إذا كان مناسبًا لك',
    'فشار منزلي قليل الملح',
    'خضروات مقطعة مع حمص إذا لم توجد حساسية من مكوناته',
  ];
}
