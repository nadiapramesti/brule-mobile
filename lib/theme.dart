import 'package:flutter/material.dart';
import 'motion.dart';

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
      secondaryContainer: Color(0xFF262626),
      onSecondaryContainer: Brule.cream,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: BrulePageTransitions(),
      TargetPlatform.iOS: BrulePageTransitions(),
      TargetPlatform.windows: BrulePageTransitions(),
      TargetPlatform.linux: BrulePageTransitions(),
      TargetPlatform.macOS: BrulePageTransitions(),
    }),
    dividerTheme: DividerThemeData(color: Colors.white.withValues(alpha: 0.1), thickness: 1, space: 1),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: Brule.amber),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF262626),
      contentTextStyle: const TextStyle(color: Brule.cream, fontSize: 14, height: 1.35),
      actionTextColor: Brule.amber,
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Brule.blue : Colors.transparent),
      checkColor: const WidgetStatePropertyAll(Brule.cream),
      side: BorderSide(color: Brule.kraft.withValues(alpha: 0.6), width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF1C1C1C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Brule.kraft,
        textStyle: Brule.condensed(15, spacing: 1.2),
      ),
    ),
    splashFactory: InkSparkle.splashFactory,
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
    appBarTheme: AppBarTheme(
      backgroundColor: Brule.bg,
      foregroundColor: Brule.cream,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: Brule.mono(12),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF161616),
      indicatorColor: Brule.blue,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((states) => Brule.mono(
            10,
            color: states.contains(WidgetState.selected) ? Brule.cream : Brule.kraft,
          )),
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? Brule.cream : Brule.kraft,
          )),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Brule.field,
      selectedColor: Brule.blue,
      checkmarkColor: Brule.cream,
      labelStyle: const TextStyle(color: Brule.cream),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? Brule.blue : Colors.transparent),
        foregroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? Brule.cream : Brule.kraft),
        side: WidgetStatePropertyAll(
            BorderSide(color: Colors.white.withValues(alpha: 0.2))),
        shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
        textStyle: WidgetStatePropertyAll(Brule.mono(11)),
      ),
    ),
  );
}
