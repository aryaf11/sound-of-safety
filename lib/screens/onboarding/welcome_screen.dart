import 'package:flutter/material.dart';

import '../auth/login_screen.dart';
import '../auth/register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 28),
              Semantics(
                label: 'صوت الأمان شعار التطبيق',
                child: Center(
                  child: Hero(
                    tag: 'sos_logo',
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        Icons.health_and_safety_rounded,
                        size: 72,
                        color: Theme.of(context).colorScheme.primary,
                        semanticLabel: '',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'صوت الأمان',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'فحص روابط الإنترنت لآيفون بخطوات واضحة ودعم للقراءة الصوتية',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.45,
                    ),
              ),
              const Spacer(),
              Semantics(
                label: 'زر إنشاء حساب جديد',
                button: true,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const RegisterScreen(),
                      ),
                    );
                  },
                  child: const Text('إنشاء حساب'),
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                label: 'زر تسجيل الدخول لحساب موجود',
                button: true,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  },
                  child: const Text('تسجيل الدخول'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
