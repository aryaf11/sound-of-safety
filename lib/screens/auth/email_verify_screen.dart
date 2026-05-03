import 'package:flutter/material.dart';

import '../../services/auth_storage.dart';

class EmailVerifyScreen extends StatefulWidget {
  const EmailVerifyScreen({super.key, required this.email});

  final String email;

  @override
  State<EmailVerifyScreen> createState() => _EmailVerifyScreenState();
}

class _EmailVerifyScreenState extends State<EmailVerifyScreen> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _confirm() {
    final ok = AuthStorage.instance.verifyEmailCode(_code.text);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الكود غير صحيح')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم التحقق من البريد')),
    );
  }

  void _resend() {
    AuthStorage.instance.prepareEmailVerificationCode();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إنشاء كود جديد (وضع تجريبي)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التحقق من البريد')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'أرسلنا كوداً مؤقتاً إلى ${widget.email} (تجريبي محلياً، راجع الطباعة في وضع التطوير).',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Semantics(
                label: 'حقل إدخال كود التحقق المكوّن من ستة أرقام',
                child: TextField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(),
                    labelText: 'كود التحقق',
                  ),
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _confirm,
                child: const Text('تأكيد'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _resend,
                child: const Text('إعادة إرسال الكود'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
