import 'package:flutter/material.dart';

/// Nike Run–inspired minimal palette (no volt orange — white / gray only).
class AppTheme {
  static const bg = Color(0xFF000000);
  static const surface = Color(0xFF111111);
  static const surfaceElevated = Color(0xFF1A1A1A);
  static const border = Color(0xFF2E2E2E);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF8E8E8E);
  static const accent = Color(0xFFCCCCCC);

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        surface: surface,
        primary: accent,
        onPrimary: bg,
        secondary: textSecondary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: textPrimary,
          foregroundColor: bg,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: border),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        labelStyle: const TextStyle(color: textSecondary),
      ),
    );
  }
}
