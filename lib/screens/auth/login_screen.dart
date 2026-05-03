import 'package:flutter/material.dart';

import '../../services/auth_storage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _ob = true;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    final ok = await AuthStorage.instance.login(_email.text, _pass.text);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('بيانات الدخول غير صحيحة')),
      );
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل الدخول')),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'البريد',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'أدخل البريد';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pass,
                obscureText: _ob,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _ob = !_ob),
                    icon: Icon(_ob ? Icons.visibility : Icons.visibility_off),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'أدخل كلمة المرور';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _login,
                child: const Text('دخول'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
