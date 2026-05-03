import 'package:flutter/material.dart';

import '../../services/auth_storage.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _email2 = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  bool _ob1 = true;
  bool _ob2 = true;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _email2.dispose();
    _pass.dispose();
    _pass2.dispose();
    super.dispose();
  }

  bool _validEmail(String v) {
    final s = v.trim();
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(s);
  }

  String? _passwordErrors(String v) {
    if (v.length < 8) return 'ثمانية أحرف على الأقل';
    if (!RegExp(r'[A-Za-z]').hasMatch(v)) return 'أضف حرفاً إنجليزياً';
    if (!RegExp(r'\d').hasMatch(v)) return 'أضف رقماً واحداً على الأقل';
    return null;
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;

    await AuthStorage.instance.completeRegistration(
      username: _username.text,
      email: _email.text,
      password: _pass.text,
    );
    AuthStorage.instance.prepareEmailVerificationCode();

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      messenger.clearSnackBars();
      messenger.showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content:
              Text('تم إنشاء الحساب. أدخل كود التحقق الذي يظهر في وحدة التحكم في وضع التطوير.'),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء حساب')),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              TextFormField(
                controller: _username,
                decoration: const InputDecoration(
                  labelText: 'اسم المستخدم',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().length < 2) return 'أدخل اسماً صالحاً';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || !_validEmail(v)) return 'بريد غير صالح';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email2,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'تأكيد البريد',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim() != _email.text.trim()) {
                    return 'البريدان غير متطابقين';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pass,
                obscureText: _ob1,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _ob1 = !_ob1),
                    icon: Icon(_ob1 ? Icons.visibility : Icons.visibility_off),
                    tooltip: 'إظهار أو إخفاء',
                  ),
                ),
                textInputAction: TextInputAction.next,
                validator: (v) => _passwordErrors(v ?? ''),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pass2,
                obscureText: _ob2,
                decoration: InputDecoration(
                  labelText: 'تأكيد كلمة المرور',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _ob2 = !_ob2),
                    icon: Icon(_ob2 ? Icons.visibility : Icons.visibility_off),
                    tooltip: 'إظهار أو إخفاء',
                  ),
                ),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: (v) {
                  if (v != _pass.text) return 'كلمتا المرور غير متطابقتين';
                  return _passwordErrors(v ?? '');
                },
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submit,
                child: const Text('متابعة وإرسال كود التحقق'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
