import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text.dart';
import 'app_tokens.dart';

class AppTheme {
  static ThemeData buildTheme(AppColorsScheme c) {
    final Brightness brightness =
        c == AppColorsScheme.dark ? Brightness.dark : Brightness.light;

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: c.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: c.primary,
        brightness: brightness,
        surface: c.bgElev,
      ),
      textTheme: TextTheme(
        displayLarge: AppText.display,
        titleLarge: AppText.titleL,
        titleMedium: AppText.titleM,
        bodyMedium: AppText.body,
        bodySmall: AppText.bodySm,
        labelSmall: AppText.caption,
      ),
      cardTheme: CardThemeData(
        color: c.bgElev,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.r6),
          side: BorderSide(color: c.line),
        ),
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.primaryInk,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.r3),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: AppTokens.sp4,
            horizontal: AppTokens.sp3,
          ),
          textStyle: AppText.body.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.text,
          side: BorderSide(color: c.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.r3),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.textSub,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.r3),
          borderSide: BorderSide(color: c.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.r3),
          borderSide: BorderSide(color: c.line),
        ),
        focusColor: c.primary,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.r3),
          borderSide: BorderSide(color: c.primary, width: 1.5),
        ),
      ),
      iconTheme: IconThemeData(
        color: c.textSub,
        size: 20,
      ),
      dividerTheme: DividerThemeData(
        color: c.lineSoft,
        thickness: 1,
      ),
    );
  }

  static final ThemeData dark = buildTheme(AppColorsScheme.dark);
  static final ThemeData light = buildTheme(AppColorsScheme.light);
}

extension ColorsX on BuildContext {
  AppColorsScheme get c => Theme.of(this).brightness == Brightness.dark
      ? AppColorsScheme.dark
      : AppColorsScheme.light;
}
