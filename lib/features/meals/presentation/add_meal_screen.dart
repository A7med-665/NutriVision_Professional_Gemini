import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../nutrition/data/nutrition_catalog_service.dart';
import 'meal_cubit.dart';

class AddMealScreen extends StatefulWidget {
  const AddMealScreen({super.key});
  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _notes = TextEditingController();
  final _restrictions = TextEditingController();
  final _grams = TextEditingController(text: '100');
  final _cal = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fats = TextEditingController();
  final _catalog = NutritionCatalogService();
  Timer? _searchTimer;
  List<FoodNutrition> _matches = const [];
  FoodNutrition? _selectedFood;
  bool _searching = false;
  bool _busy = false;
  String? _searchMessage;
  bool _manualMode = false;

  @override
  void dispose() {
    _searchTimer?.cancel();
    for (final controller in [_name, _notes, _restrictions, _grams, _cal, _protein, _carbs, _fats]) {
      controller.dispose();
    }
    super.dispose();
  }

  double get _portion => (double.tryParse(_grams.text.trim()) ?? 100).clamp(1, 10000).toDouble();
  double _number(TextEditingController controller) => double.tryParse(controller.text.trim()) ?? 0;
  double? _scaled(double? value) => value == null ? null : value * _portion / 100;
  String _fmt(double? value, {int digits = 1}) => value == null ? 'غير متاح' : value.toStringAsFixed(digits);

  void _onNameChanged(String value) {
    _searchTimer?.cancel();
    setState(() {
      _selectedFood = null;
      _matches = const [];
      _searchMessage = null;
    });
    if (value.trim().length < 2) return;
    _searchTimer = Timer(const Duration(milliseconds: 650), () => _searchFood(value.trim()));
  }

  Future<void> _searchFood(String query) async {
    if (!mounted) return;
    setState(() { _searching = true; _searchMessage = null; });
    try {
      final results = await _catalog.search(query);
      if (!mounted || _name.text.trim() != query) return;
      setState(() {
        _matches = results;
        if (results.isEmpty) _searchMessage = 'لم نعثر على تطابق واضح. جرّب اسمًا إنجليزيًا أو اختر الإدخال اليدوي.';
      });
    } on DioException catch (error) {
      if (!mounted || _name.text.trim() != query) return;
      final status = error.response?.statusCode;
      setState(() => _searchMessage = switch (status) {
        401 => 'رفض الخادم الطلب (401). للتطوير المحلي اضبط REQUIRE_FIREBASE_AUTH=false داخل backend/.env ثم أعد تشغيل Backend. للإنتاج، فعّل Firebase Admin والتحقق من التوكن.',
        403 => 'الخادم رفض الطلب (403). راجع CORS_ORIGINS وإعدادات أمان الخادم.',
        429 => 'تم تجاوز حد الطلبات مؤقتًا. انتظر دقيقة ثم حاول مرة أخرى.',
        503 => 'خدمة بيانات USDA غير مهيأة. تأكد من USDA_API_KEY داخل backend/.env.',
        502 => 'USDA لم يستجب بنجاح. راجع نافذة Backend لمعرفة سبب الخطأ.',
        _ => 'تعذر الاتصال بقاعدة USDA (HTTP ${status ?? 'غير متاح'}). تحقق من عنوان Backend واتصاله ثم حاول مرة أخرى.',
      });
    } catch (error) {
      if (!mounted || _name.text.trim() != query) return;
      setState(() => _searchMessage = error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted && _name.text.trim() == query) setState(() => _searching = false);
    }
  }

  void _selectFood(FoodNutrition food) {
    setState(() {
      _selectedFood = food;
      _name.text = food.name;
      _matches = const [];
      _searchMessage = null;
      _manualMode = false;
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('إضافة وجبة ذكية')),
    body: SafeArea(child: Form(key: _formKey, child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('سجّل وجبتك بذكاء', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('اكتب اسم الطعام، وسنبحث تلقائيًا عن بياناته الغذائية. اختر نتيجة مطابقة ثم حدّد الوزن.'),
        const SizedBox(height: 22),
        TextFormField(
          controller: _name,
          onChanged: _onNameChanged,
          validator: (value) => value == null || value.trim().isEmpty ? 'اكتب اسم الطعام' : null,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: 'اسم الطعام', hintText: 'مثال: cooked rice, apple, chicken breast',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searching
              ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
              : IconButton(tooltip: 'إعادة البحث', onPressed: _busy || _name.text.trim().length < 2 ? null : () => _searchFood(_name.text.trim()), icon: const Icon(Icons.refresh)),
          ),
        ),
        if (_matches.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('اختر أقرب تطابق من قاعدة البيانات', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          ..._matches.map((food) => Card(
            child: ListTile(
              dense: true,
              leading: const CircleAvatar(child: Icon(Icons.restaurant_menu)),
              title: Text(food.name, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text('${food.caloriesKcal?.round() ?? '—'} kcal / 100 g  •  بروتين ${_fmt(food.proteinG)} g'),
              trailing: const Icon(Icons.add_circle_outline),
              onTap: () => _selectFood(food),
            ),
          )),
        ],
        if (_searchMessage != null) ...[
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)), child: Text(_searchMessage!, style: const TextStyle(fontSize: 12))),
        ],
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: TextFormField(
            controller: _grams,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            validator: (value) { final n = double.tryParse(value?.trim() ?? ''); return n == null || !n.isFinite || n <= 0 || n > 10000 ? 'أدخل وزنًا بين 1 و10000 جرام' : null; },
            decoration: const InputDecoration(labelText: 'الكمية بالجرام', suffixText: 'g', prefixIcon: Icon(Icons.scale_outlined)),
          )),
          const SizedBox(width: 10),
          Wrap(spacing: 4, children: [
            _gramChip(50), _gramChip(100), _gramChip(200),
          ]),
        ]),
        const SizedBox(height: 12),
        if (_selectedFood != null) _nutritionCard(_selectedFood!)
        else Card(color: Theme.of(context).colorScheme.surfaceContainerLow, child: const Padding(
          padding: EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.info_outline), SizedBox(width: 10), Expanded(child: Text('بعد اختيار نتيجة من البحث ستُحسب القيم تلقائيًا حسب الوزن. اسم الطعام وحده لا يكفي لضمان قيم دقيقة؛ إذا كانت الوجبة مركبة، اختر أقرب مكونات أو استخدم الإدخال اليدوي.')),
          ]),
        )),
        const SizedBox(height: 12),
        TextFormField(controller: _notes, maxLines: 2, decoration: const InputDecoration(labelText: 'ملاحظات أو طريقة التحضير (اختياري)', prefixIcon: Icon(Icons.notes))),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _manualMode,
          onChanged: (value) => setState(() => _manualMode = value),
          title: const Text('إدخال القيم يدويًا'),
          subtitle: const Text('استخدمه إذا لم تجد طعامك في قاعدة البيانات.'),
        ),
        if (_manualMode) ...[
          const SizedBox(height: 4),
          _manualField(_cal, 'السعرات الحرارية (kcal)'),
          const SizedBox(height: 10),
          Row(children: [Expanded(child: _manualField(_protein, 'بروتين (g)')), const SizedBox(width: 8), Expanded(child: _manualField(_carbs, 'كربوهيدرات (g)'))]),
          const SizedBox(height: 10), _manualField(_fats, 'دهون (g)'),
        ],
        const SizedBox(height: 12),
        TextFormField(controller: _restrictions, maxLines: 2, decoration: const InputDecoration(labelText: 'قيود غذائية للنصيحة الذكية (اختياري)', hintText: 'مثل: نباتي أو خالٍ من اللاكتوز', prefixIcon: Icon(Icons.health_and_safety_outlined))),
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: _busy ? null : _save,
          icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome),
          label: Padding(padding: const EdgeInsets.all(14), child: Text(_busy ? 'جارٍ تحليل وحفظ الوجبة...' : 'حفظ الوجبة وتحليلها')),
        ),
        const SizedBox(height: 12),
        const Text('القيم الغذائية تقديرية وتعتمد على تطابق الطعام والوزن وطريقة التحضير. إرشادات AI عامة وليست تشخيصًا أو بديلًا عن اختصاصي تغذية.', style: TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    ))),
  );

  Widget _gramChip(int grams) => ActionChip(label: Text('$grams g'), onPressed: _busy ? null : () { _grams.text = '$grams'; setState(() {}); });

  Widget _nutritionCard(FoodNutrition food) {
    final theme = Theme.of(context);
    Widget metric(String label, double? value, String unit, IconData icon) => Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary), const SizedBox(height: 6),
        Text(_fmt(_scaled(value), digits: 1), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        Text('$label ($unit)', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
      ]),
    );
    return Card(
      color: theme.colorScheme.primaryContainer.withValues(alpha: .45),
      child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.verified_outlined), const SizedBox(width: 8), const Expanded(child: Text('التقدير الغذائي حسب الكمية', style: TextStyle(fontWeight: FontWeight.w800))), Chip(label: Text('${_portion.round()} g'))]),
        const SizedBox(height: 10),
        GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, childAspectRatio: 2.15, mainAxisSpacing: 8, crossAxisSpacing: 8, children: [
          metric('السعرات', food.caloriesKcal, 'kcal', Icons.local_fire_department),
          metric('البروتين', food.proteinG, 'g', Icons.fitness_center),
          metric('الكربوهيدرات', food.carbsG, 'g', Icons.grain),
          metric('الدهون', food.fatG, 'g', Icons.opacity),
          metric('الألياف', food.fiberG, 'g', Icons.eco_outlined),
          metric('السكر', food.sugarG, 'g', Icons.bubble_chart_outlined),
          metric('الصوديوم', food.sodiumMg, 'mg', Icons.science_outlined),
          metric('دهون مشبعة', food.saturatedFatG, 'g', Icons.water_drop_outlined),
          metric('الكوليسترول', food.cholesterolMg, 'mg', Icons.monitor_heart_outlined),
        ]),
        if (food.servingNote != null) ...[const SizedBox(height: 8), Text(food.servingNote!, style: const TextStyle(fontSize: 11))],
      ])),
    );
  }

  Widget _manualField(TextEditingController controller, String label) => TextFormField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    validator: (value) {
      if (!_manualMode) return null;
      if (value == null || value.trim().isEmpty) return 'أدخل القيمة أو اكتب 0 إذا كانت صفرًا';
      final parsed = double.tryParse(value.trim());
      return parsed == null || !parsed.isFinite || parsed < 0 || parsed > 1000000 ? 'أدخل رقمًا صالحًا' : null;
    },
    decoration: InputDecoration(labelText: label),
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final food = _selectedFood;
    final manual = _manualMode || food == null;
    if (food == null && !_manualMode) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختر نتيجة غذائية أو فعّل الإدخال اليدوي أولًا.')));
      return;
    }
    setState(() => _busy = true);
    try {
      final scale = _portion / 100;
      await context.read<MealCubit>().addMeal(
        name: _name.text.trim(),
        calories: manual ? _number(_cal) : (food.caloriesKcal ?? 0) * scale,
        protein: manual ? _number(_protein) : (food.proteinG ?? 0) * scale,
        carbs: manual ? _number(_carbs) : (food.carbsG ?? 0) * scale,
        fats: manual ? _number(_fats) : (food.fatG ?? 0) * scale,
        fiber: manual ? 0 : (food.fiberG ?? 0) * scale,
        sugar: manual ? 0 : (food.sugarG ?? 0) * scale,
        sodiumMg: manual ? 0 : (food.sodiumMg ?? 0) * scale,
        saturatedFat: manual ? 0 : (food.saturatedFatG ?? 0) * scale,
        cholesterolMg: manual ? 0 : (food.cholesterolMg ?? 0) * scale,
        portionGrams: _portion,
        nutritionSource: manual ? 'manual' : 'USDA FoodData Central',
        notes: [if (_notes.text.trim().isNotEmpty) _notes.text.trim(), if (!manual) 'الكمية: ${_portion.round()} جم', if (!manual) 'المصدر: USDA FoodData Central'].join(' • '),
        restrictions: _restrictions.text.trim(),
      );
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الوجبة وقيمها الغذائية'))); Navigator.pop(context); }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر حفظ الوجبة. راجع الاتصال وإعدادات Firebase ثم حاول مرة أخرى.')));
    } finally { if (mounted) setState(() => _busy = false); }
  }
}
