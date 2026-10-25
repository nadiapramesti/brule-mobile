import 'package:flutter/material.dart';

class Brule {
  static const bg = Color(0xFF121212);
  static const field = Color(0xFF1A1A1A);
  static const cream = Color(0xFFFFFBF2);
  static const kraft = Color(0xFFD8C5A6);
  static const blue = Color(0xFF234E94);
  static const blueText = Color(0xFF9DBBEF);
  static const amber = Color(0xFFF2A266);
  static const red = Color(0xFFE26D6D);

  static TextStyle mono(double size, {Color color = kraft}) => TextStyle(
      fontFamily: 'IBMPlexMono',
      fontSize: size,
      color: color,
      letterSpacing: 1.1);

  static TextStyle condensed(double size,
          {FontWeight weight = FontWeight.w600,
          Color color = cream,
          double spacing = 0}) =>
      TextStyle(
          fontFamily: 'IBMPlexSansCondensed',
          fontSize: size,
          fontWeight: weight,
          color: color,
          letterSpacing: spacing);
}

ThemeData buildTheme() {
  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(6),
    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
  );

  return base.copyWith(
    scaffoldBackgroundColor: Brule.bg,
    colorScheme: const ColorScheme.dark(
      primary: Brule.blue,
      onPrimary: Brule.cream,
      secondary: Brule.amber,
      surface: Brule.bg,
      onSurface: Brule.cream,
      error: Brule.red,
    ),
    textTheme: base.textTheme.apply(
      fontFamily: 'IBMPlexSans',
      bodyColor: Brule.cream,
      displayColor: Brule.cream,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Brule.field,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      hintStyle: TextStyle(color: Brule.kraft.withValues(alpha: 0.5)),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: Brule.blueText, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Brule.blue,
        foregroundColor: Brule.cream,
        disabledBackgroundColor: Brule.blue.withValues(alpha: 0.5),
        disabledForegroundColor: Brule.cream.withValues(alpha: 0.7),
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: Brule.condensed(16, spacing: 1.4),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Brule.cream,
        minimumSize: const Size.fromHeight(50),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: Brule.condensed(15, spacing: 1.2),
      ),
    ),
  );
}
