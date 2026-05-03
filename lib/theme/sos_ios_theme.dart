import 'package:flutter/material.dart';

/// مظهر كبير وواضح لـ VoiceOver وقارئ الشاشة؛ يحترم مقياس خط النظام ضمن حدود معقولة.
ThemeData buildSosIosAccessibilityTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF0D47A1),
    brightness: Brightness.light,
    surface: const Color(0xFFFAFAFA),
  );
  final base = Typography.material2021();
  final dense = base.black.apply(
    fontSizeFactor: 1.15,
    bodyColor: scheme.onSurface,
    displayColor: scheme.onSurface,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    visualDensity: VisualDensity.standard,
    textTheme: dense.copyWith(
      titleLarge:
          dense.titleLarge?.copyWith(fontSize: 26, fontWeight: FontWeight.bold),
      titleMedium:
          dense.titleMedium?.copyWith(fontSize: 21, fontWeight: FontWeight.w600),
      bodyLarge: dense.bodyLarge?.copyWith(fontSize: 20, height: 1.45),
      bodyMedium: dense.bodyMedium?.copyWith(fontSize: 18, height: 1.42),
      labelLarge: dense.labelLarge?.copyWith(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 54),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 54),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        textStyle: const TextStyle(fontSize: 18),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      filled: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      labelStyle: TextStyle(fontSize: 17),
      floatingLabelStyle: TextStyle(fontSize: 17),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
