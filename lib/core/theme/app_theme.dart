import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// GEENGREEN — Apple Fitness / Outdoor Run aesthetic (SF Pro, true black).
class AppTheme {
  static const bg = Color(0xFF000000);
  static const surface = Color(0xFF1C1C1E);
  static const surfaceElevated = Color(0xFF2C2C2E);
  static const glassFill = Color(0x33FFFFFF);
  static const glassBorder = Color(0x40FFFFFF);
  static const border = glassBorder;
  static const pixelBorder = glassBorder;
  static const ground = Color(0xFF3A3A3C);

  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF8E8E93);
  static const textTertiary = Color(0xFF636366);

  /// Outdoor Run / Activity green
  static const runGreen = Color(0xFF30D158);
  static const activityGreen = runGreen;
  static const signalGreen = runGreen;
  static const accentRun = runGreen;

  /// Activity rings (Fitness app)
  static const movePink = Color(0xFFFF375F);
  static const exerciseGreen = Color(0xFF92E82A);
  static const standCyan = Color(0xFF1EE4E1);
  static const ringCyan = Color(0xFF64D2FF);

  static const signalRed = Color(0xFFFF453A);
  static const signalAmber = Color(0xFFFFD60A);

  static const radiusLg = 28.0;
  static const radiusMd = 22.0;
  static const radiusSm = 14.0;

  static const displayFont = '.AppleSystemUIFont';
  static const bodyFont = '.AppleSystemUIFont';
  static const pixelFont = displayFont;

  static List<String> get fontFamilyFallback => const [
        'SF Pro Display',
        'SF Pro Text',
        'SF Pro Rounded',
        '-apple-system',
        'BlinkMacSystemFont',
        'Segoe UI',
        'Roboto',
        'Helvetica Neue',
        'Arial',
      ];

  static ThemeData dark() {
    final base = TextStyle(
      fontFamily: displayFont,
      fontFamilyFallback: fontFamilyFallback,
      letterSpacing: -0.2,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        surface: surface,
        primary: runGreen,
        onPrimary: Colors.black,
        secondary: standCyan,
        onSecondary: Colors.black,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: base.copyWith(
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: textPrimary, size: 22),
      ),
      textTheme: TextTheme(
        headlineLarge: base.copyWith(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
          color: textPrimary,
          height: 1.05,
        ),
        titleLarge: base.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: base.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: base.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          height: 1.25,
        ),
        bodyMedium: base.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          height: 1.35,
        ),
        labelSmall: base.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: textSecondary,
        ),
      ),
      dividerTheme: const DividerThemeData(color: surfaceElevated, thickness: 1),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: runGreen,
          foregroundColor: Colors.black,
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
          textStyle: base.copyWith(fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: glassBorder.withValues(alpha: 0.5)),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          textStyle: base.copyWith(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated.withValues(alpha: 0.65),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: runGreen, width: 1.5),
        ),
        labelStyle: base.copyWith(color: textSecondary, fontSize: 13),
        hintStyle: base.copyWith(color: textTertiary, fontSize: 15),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bg.withValues(alpha: 0.92),
        indicatorColor: surfaceElevated,
        height: 64,
        labelTextStyle: WidgetStateProperty.all(
          base.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceElevated,
        contentTextStyle: base.copyWith(color: textPrimary, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
      ),
    );
  }
}
