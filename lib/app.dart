import 'dart:async';

import 'package:flutter/material.dart';

import 'screens/auth/email_verify_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'services/auth_storage.dart';
import 'services/settings_storage.dart';

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _hydrated = false;

  @override
  void initState() {
    super.initState();
    AuthStorage.instance.addListener(_onAuthTick);
    _warmBoot();
  }

  @override
  void dispose() {
    AuthStorage.instance.removeListener(_onAuthTick);
    super.dispose();
  }

  void _onAuthTick() => setState(() {});

  Future<void> _warmBoot() async {
    await Future.wait<void>([
      AuthStorage.instance.load(),
      SettingsStorage.instance.load(),
      Future<void>.delayed(const Duration(milliseconds: 1450)),
    ]);

    if (!mounted) return;
    setState(() => _hydrated = true);
  }

  Widget _resolveHome() {
    final s = AuthStorage.instance.state;
    if (!s.completedRegistration) return const WelcomeScreen();
    if (!s.emailVerified) {
      return EmailVerifyScreen(email: s.email.isEmpty ? 'بريدك' : s.email);
    }
    return const HomeScreen();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      child: !_hydrated
          ? const SplashScreen(key: ValueKey('splash'))
          : KeyedSubtree(
              key: const ValueKey('app-shell'),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: KeyedSubtree(
                  key: ValueKey<String>(
                    '${AuthStorage.instance.state.completedRegistration}-'
                    '${AuthStorage.instance.state.emailVerified}-'
                    '${AuthStorage.instance.state.email}',
                  ),
                  child: _resolveHome(),
                ),
              ),
            ),
    );
  }
}
