import 'package:flutter/material.dart';

/// صفحة افتتاحية: اسم التطبيق والشعار قبل التوجيه لباقي التدفق.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              cs.primaryContainer.withValues(alpha: 0.95),
              cs.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Semantics(
                label:
                    'صوت الأمان، شعار التطبيق: درع أمان بلون الموضوع الأساسي',
                child: ExcludeSemantics(
                  child: Hero(
                    tag: 'sos_logo',
                    child: CircleAvatar(
                      radius: 72,
                      backgroundColor: cs.primaryContainer,
                      child: Icon(
                        Icons.health_and_safety_rounded,
                        size: 88,
                        color: cs.primary,
                        semanticLabel: '',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'صوت الأمان',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'تطبيق آيفون لفحص الروابط وسماع النتيجة',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 36),
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
