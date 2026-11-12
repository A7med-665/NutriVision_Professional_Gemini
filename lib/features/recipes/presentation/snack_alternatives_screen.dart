import 'package:flutter/material.dart';
import '../../ai/data/ai_advisor_service.dart';

class SnackAlternativesScreen extends StatefulWidget {
  const SnackAlternativesScreen({super.key});

  @override
  State<SnackAlternativesScreen> createState() => _SnackAlternativesScreenState();
}

class _SnackAlternativesScreenState extends State<SnackAlternativesScreen> {
  final _snack = TextEditingController();
  final _restrictions = TextEditingController();
  final _service = AiAdvisorService();
  bool _loading = false;
  List<String> _items = const [];
  String? _error;

  @override
  void dispose() {
    _snack.dispose();
    _restrictions.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final snack = _snack.text.trim();
    if (snack.length < 2) {
      setState(() => _error = 'اكتب اسم الوجبة الخفيفة في حرفين على الأقل.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _items = const [];
    });
    try {
      final result = await _service.snackAlternatives(
        snack,
        restrictions: _restrictions.text.trim(),
      );
      if (mounted) setState(() => _items = result);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'تعذر إعداد البدائل الآن. تحقق من الاتصال ثم حاول مجددًا.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('اكتشف بدائل صحية')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Icon(Icons.auto_awesome, size: 42, color: Color(0xFF247A58)),
              const SizedBox(height: 12),
              const Text('بدائل تناسبك', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('أدخل وجبتك الخفيفة المفضلة للحصول على أفكار بديلة، مع مراعاة القيود التي تذكرها.'),
              const SizedBox(height: 22),
              TextField(
                controller: _snack,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'الوجبة الخفيفة', hintText: 'رقائق البطاطس أو الشوكولاتة'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _restrictions,
                decoration: const InputDecoration(labelText: 'قيود غذائية (اختياري)', hintText: 'حساسية المكسرات، نباتي...'),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loading ? null : _search,
                icon: _loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.search),
                label: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_loading ? 'جارٍ إعداد البدائل...' : 'اعرض البدائل'),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              if (_loading) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
              if (_items.isNotEmpty) ...[
                const SizedBox(height: 22),
                const Text('اقتراحات لك', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ..._items.map((item) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.check_circle_outline, color: Color(0xFF247A58)),
                        title: Text(item),
                      ),
                    )),
                const SizedBox(height: 8),
                const Text(
                  'تحقق من المكونات ومسببات الحساسية. الاقتراحات عامة وليست خطة علاجية أو ضمانًا لملاءمة الطعام لحالتك.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ],
          ),
        ),
      );
}
