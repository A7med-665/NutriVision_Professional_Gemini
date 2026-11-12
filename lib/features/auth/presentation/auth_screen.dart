import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _register = false, _busy = false, _obscure = true;
  String? _error;

  @override
  void dispose() { _email.dispose(); _password.dispose(); _confirm.dispose(); super.dispose(); }

  String _friendlyError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email': return 'البريد الإلكتروني غير صحيح.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential': return 'بيانات الدخول غير صحيحة.';
        case 'email-already-in-use': return 'هذا البريد مسجل بالفعل.';
        case 'weak-password': return 'اختر كلمة مرور أقوى (6 أحرف على الأقل).';
        case 'too-many-requests': return 'محاولات كثيرة. حاول لاحقًا.';
        case 'network-request-failed': return 'تحقق من اتصال الإنترنت.';
      }
    }
    return 'حدث خطأ. تحقق من إعداد Firebase ثم حاول مرة أخرى.';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });
    try {
      final auth = FirebaseAuth.instance;
      if (_register) {
        final credential = await auth.createUserWithEmailAndPassword(email: _email.text.trim(), password: _password.text);
        try {
          await credential.user?.sendEmailVerification();
        } finally {
          // Do not leave a newly-created, unverified account inside the authenticated app.
          await auth.signOut();
        }
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنشاء الحساب. تحقق من بريدك الإلكتروني لتأكيده.')));
      } else {
        final credential = await auth.signInWithEmailAndPassword(email: _email.text.trim(), password: _password.text);
        if (credential.user != null && !credential.user!.emailVerified) {
          await auth.signOut();
          if (mounted) setState(() => _error = 'أكد بريدك الإلكتروني من الرابط المرسل قبل تسجيل الدخول.');
        }
      }
    } catch (error) { if (mounted) setState(() => _error = _friendlyError(error)); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) { setState(() => _error = 'اكتب بريدك الإلكتروني أولًا لإرسال رابط إعادة التعيين.'); return; }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) setState(() => _error = 'تم إرسال رابط إعادة التعيين إذا كان البريد مسجلًا.');
    } catch (error) { if (mounted) setState(() => _error = _friendlyError(error)); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440), child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Icon(Icons.eco_rounded, color: AppTheme.green, size: 58),
          const SizedBox(height: 12),
          const Text('NutriVision', textAlign: TextAlign.center, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppTheme.ink)),
          const SizedBox(height: 8),
          Text(_register ? 'أنشئ حسابك لمزامنة سجل وجباتك' : 'سجّل الدخول لمتابعة رحلتك الغذائية', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 30),
          TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.email], decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email_outlined)), validator: (v) => v == null || !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim()) ? 'أدخل بريدًا إلكترونيًا صحيحًا.' : null),
          const SizedBox(height: 14),
          TextFormField(controller: _password, obscureText: _obscure, autofillHints: [_register ? AutofillHints.newPassword : AutofillHints.password], decoration: InputDecoration(labelText: 'كلمة المرور', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off))), validator: (v) => v == null || v.length < 6 ? 'كلمة المرور يجب ألا تقل عن 6 أحرف.' : null),
          if (_register) ...[const SizedBox(height: 14), TextFormField(controller: _confirm, obscureText: true, decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور', prefixIcon: Icon(Icons.lock_reset)), validator: (v) => v != _password.text ? 'كلمتا المرور غير متطابقتين.' : null)],
          if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center)],
          const SizedBox(height: 22),
          FilledButton(onPressed: _busy ? null : _submit, child: Padding(padding: const EdgeInsets.all(14), child: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_register ? 'إنشاء حساب' : 'تسجيل الدخول'))),
          if (!_register) TextButton(onPressed: _busy ? null : _resetPassword, child: const Text('نسيت كلمة المرور؟')),
          TextButton(onPressed: _busy ? null : () => setState(() { _register = !_register; _error = null; }), child: Text(_register ? 'لديك حساب بالفعل؟ سجّل الدخول' : 'ليس لديك حساب؟ أنشئ حسابًا')),
          const SizedBox(height: 14), const Text('الإرشادات الغذائية عامة ولا تغني عن استشارة مختص مؤهل.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.black54)),
        ]),
      )),
    )),
  ));
}
