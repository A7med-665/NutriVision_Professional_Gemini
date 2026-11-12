import 'package:flutter/material.dart';
import '../../ai/data/ai_advisor_service.dart';

class RecipeGeneratorScreen extends StatefulWidget {
  const RecipeGeneratorScreen({super.key});
  @override
  State<RecipeGeneratorScreen> createState() => _RecipeGeneratorScreenState();
}

class _RecipeGeneratorScreenState extends State<RecipeGeneratorScreen> {
  final _ingredients = TextEditingController();
  final _restrictions = TextEditingController();
  final _service = AiAdvisorService();
  bool _loading = false;
  String? _recipe, _error;

  @override
  void dispose() { _ingredients.dispose(); _restrictions.dispose(); super.dispose(); }

  Future<void> _generate() async {
    final items = _ingredients.text.split(RegExp(r'[,،\n]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (items.isEmpty) { setState(() => _error = 'أدخل مكونًا واحدًا على الأقل.'); return; }
    setState(() { _loading = true; _error = null; _recipe = null; });
    try {
      final recipe = await _service.generateRecipe(ingredients: items, restrictions: _restrictions.text.trim());
      if (mounted) setState(() => _recipe = recipe);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ابتكر وصفة صحية')),
    body: SafeArea(child: ListView(padding: const EdgeInsets.all(20), children: [
      const Icon(Icons.soup_kitchen_outlined, size: 44, color: Color(0xFF247A58)),
      const SizedBox(height: 12),
      const Text('ماذا يوجد في مطبخك؟', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      const Text('اكتب المكونات وافصل بينها بفاصلة. ستحصل على فكرة وصفة مع مراعاة القيود التي تذكرها.'),
      const SizedBox(height: 20),
      TextField(controller: _ingredients, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'المكونات', hintText: 'بيض، طماطم، سبانخ')),
      const SizedBox(height: 12),
      TextField(controller: _restrictions, decoration: const InputDecoration(labelText: 'قيود أو تفضيلات غذائية (اختياري)', hintText: 'نباتي، دون سكر مضاف')),
      const SizedBox(height: 16),
      FilledButton.icon(onPressed: _loading ? null : _generate, icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome), label: Padding(padding: const EdgeInsets.all(12), child: Text(_loading ? 'جارٍ إعداد الوصفة...' : 'اقترح وصفة'))),
      if (_error != null) ...[const SizedBox(height: 16), Text(_error!, style: const TextStyle(color: Colors.red))],
      if (_recipe != null) ...[const SizedBox(height: 20), Card(child: Padding(padding: const EdgeInsets.all(18), child: SelectableText(_recipe!, style: const TextStyle(height: 1.6)))), const SizedBox(height: 12), const Text('تحقق من مسببات الحساسية ودرجة الطهي. المحتوى عام وليس نصيحة طبية أو خطة علاجية.', style: TextStyle(fontSize: 12, color: Colors.black54))],
    ])),
  );
}
