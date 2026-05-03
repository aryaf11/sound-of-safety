import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app.dart';
import 'services/deeplink_registrar.dart';
import 'services/local_notifications.dart';
import 'theme/sos_ios_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalNotificationsService.init();
  try {
    await DeeplinkRegistrar.instance.start();
  } catch (e, st) {
    debugPrint('[صوت الأمان] تهيئة الروابط العميقة: $e');
    debugPrint('$st');
  }
  runApp(const SoundOfSafetyApp());
}

class SoundOfSafetyApp extends StatelessWidget {
  const SoundOfSafetyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'صوت الأمان',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildSosIosAccessibilityTheme(),
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final clamped =
            mq.textScaler.clamp(minScaleFactor: 1.0, maxScaleFactor: 1.7);
        return MediaQuery(
          data: mq.copyWith(textScaler: clamped),
          child: FocusTraversalGroup(child: child ?? const SizedBox.shrink()),
        );
      },
      home: const AppRoot(),
    );
  }
}
