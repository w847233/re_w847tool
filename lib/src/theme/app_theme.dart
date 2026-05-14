import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xfffafaf9);
  static const fg = Color(0xff1c1b1a);
  static const muted = Color(0xff6b6964);
  static const border = Color(0xffe6e4e0);
  static const accent = Color(0xffc96442);
  static const surface = Color(0xffffffff);
  static const good = Color(0xff2f7d4a);
  static const bad = Color(0xffb53a2a);
}

const appFontFamily = 'HarmonyOS Sans SC';

ThemeData buildAppTheme(FontWeight preferredWeight) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    brightness: Brightness.light,
    primary: AppColors.accent,
    surface: AppColors.surface,
    onSurface: AppColors.fg,
  );
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: appFontFamily,
    fontFamilyFallback: const ['Microsoft YaHei', 'SimSun', 'sans-serif'],
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.bg,
  );

  final textTheme = _weightedTextTheme(
    base.textTheme.apply(
      fontFamily: appFontFamily,
      bodyColor: AppColors.fg,
      displayColor: AppColors.fg,
    ),
    preferredWeight,
  );

  return base.copyWith(
    textTheme: textTheme,
    dividerColor: AppColors.border,
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: _outlineBorder(AppColors.border),
      focusedBorder: _outlineBorder(AppColors.accent),
      errorBorder: _outlineBorder(AppColors.bad),
      focusedErrorBorder: _outlineBorder(AppColors.bad),
      labelStyle: const TextStyle(color: AppColors.muted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(44, 44),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: TextStyle(
          fontFamily: appFontFamily,
          fontWeight: preferredWeight,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(44, 44),
        foregroundColor: AppColors.fg,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: TextStyle(
          fontFamily: appFontFamily,
          fontWeight: preferredWeight,
        ),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStatePropertyAll(
          TextStyle(fontFamily: appFontFamily, fontWeight: preferredWeight),
        ),
        side: const WidgetStatePropertyAll(BorderSide(color: AppColors.border)),
      ),
    ),
  );
}

OutlineInputBorder _outlineBorder(Color color) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: color),
  );
}

TextTheme _weightedTextTheme(TextTheme theme, FontWeight weight) {
  TextStyle? style(TextStyle? value) => value?.copyWith(fontWeight: weight);

  return theme.copyWith(
    displayLarge: style(theme.displayLarge),
    displayMedium: style(theme.displayMedium),
    displaySmall: style(theme.displaySmall),
    headlineLarge: style(theme.headlineLarge),
    headlineMedium: style(theme.headlineMedium),
    headlineSmall: style(theme.headlineSmall),
    titleLarge: style(theme.titleLarge),
    titleMedium: style(theme.titleMedium),
    titleSmall: style(theme.titleSmall),
    bodyLarge: style(theme.bodyLarge),
    bodyMedium: style(theme.bodyMedium),
    bodySmall: style(theme.bodySmall),
    labelLarge: style(theme.labelLarge),
    labelMedium: style(theme.labelMedium),
    labelSmall: style(theme.labelSmall),
  );
}
