import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../data/nutrition_catalog_service.dart';

class FoodSearchScreen extends StatefulWidget {
  const FoodSearchScreen({super.key});
  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final _query = TextEditingController();
  final _service = NutritionCatalogService();
  List<FoodNutrition> _foods = const [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() { _query.dispose(); super.dispose(); }

  Future<void> _search() async {
    if (_query.text.trim().length < 2) {
      setState(() => _error = 'اكتب حرفين على الأقل للبحث.');
      return;
    }
    setState(() { _loading = true; _error = null; _foods = const []; });
    try {
      final result = await _service.search(_query.text);
      if (mounted) setState(() => _foods = result);
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (mounted) setState(() => _error = switch (status) {
        401 => 'رفض الخادم الطلب (401). راجع إعداد REQUIRE_FIREBASE_AUTH وتسجيل الدخول.',
        403 => 'الخادم رفض الطلب (403). راجع إعدادات CORS.',
        429 => 'تم تجاوز حد الطلبات. انتظر دقيقة ثم حاول مرة أخرى.',
        503 => 'خدمة USDA غير مهيأة. تحقق من USDA_API_KEY داخل backend/.env.',
        502 => 'تعذر الوصول إلى USDA. راجع نافذة Backend.',
        _ => 'تعذر الاتصال بقاعدة الأغذية (HTTP ${status ?? 'غير متاح'}). تحقق من عنوان Backend.',
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString().replaceFirst('Bad state: ', ''));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('البحث عن غذاء')),
    body: SafeArea(child: Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Expanded(child: TextField(controller: _query, textInputAction: TextInputAction.search,
          onSubmitted: (_) => _search(), decoration: const InputDecoration(labelText: 'مثال: oatmeal, chicken, apple', prefixIcon: Icon(Icons.search)))),
        const SizedBox(width: 8), IconButton.filled(onPressed: _loading ? null : _search, icon: const Icon(Icons.search), tooltip: 'بحث'),
      ])),
      const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('اختر نتيجة لإدراج القيم الغذائية في نموذج الوجبة. تحقق من حجم الحصة؛ بيانات المصدر قد تكون لكل 100 غرام أو حصة محددة.', style: TextStyle(fontSize: 12, color: Colors.black54))),
      const SizedBox(height: 8),
      if (_loading) const Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()),
      if (_error != null) Padding(padding: const EdgeInsets.all(20), child: Text(_error!, style: const TextStyle(color: Colors.red))),
      Expanded(child: _foods.isEmpty && !_loading && _error == null
        ? const Center(child: Text('ابحث عن طعام لعرض بياناته الغذائية.'))
        : ListView.separated(padding: const EdgeInsets.all(16), itemCount: _foods.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (context, index) {
          final food = _foods[index];
          return Card(child: ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFFE1F2E8), child: Icon(Icons.restaurant, color: AppTheme.green)),
            title: Text(food.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('السعرات: ${food.caloriesKcal?.round() ?? '—'} kcal  •  بروتين: ${food.proteinG?.toStringAsFixed(1) ?? '—'} g\nكربوهيدرات: ${food.carbsG?.toStringAsFixed(1) ?? '—'} g  •  دهون: ${food.fatG?.toStringAsFixed(1) ?? '—'} g\n${food.servingNote ?? ''}'),
            isThreeLine: true, trailing: const Icon(Icons.add_circle_outline), onTap: () => Navigator.pop(context, food),
          ));
        })),
    ])),
  );
}
