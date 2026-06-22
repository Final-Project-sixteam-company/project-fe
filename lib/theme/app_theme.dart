// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

// ── Motion 상수 ───────────────────────────────────────────────────────────────

abstract final class AppMotion {
  static const Duration dur1     = Duration(milliseconds: 120);
  static const Duration dur2     = Duration(milliseconds: 200);
  static const Duration dur3     = Duration(milliseconds: 320);
  static const Curve    easeOut  = Cubic(0.22, 0.61, 0.36, 1.0);
  static const Curve    easeInOut = Cubic(0.65, 0.00, 0.35, 1.0);
}

// ── Color Scheme ──────────────────────────────────────────────────────────────

class AppColorScheme {
  const AppColorScheme._dark()
      : bg          = AppColors.darkBg,
        bgElev      = AppColors.darkBgElev,
        bgHover     = AppColors.darkBgHover,
        line        = AppColors.darkLine,
        lineSoft    = AppColors.darkLineSoft,
        text        = AppColors.darkText,
        textSub     = AppColors.darkTextSub,
        textMute    = AppColors.darkTextMute,
        primary     = AppColors.darkPrimary,
        primaryInk  = AppColors.darkPrimaryInk,
        primarySoft = AppColors.darkPrimarySoft,
        success     = AppColors.darkSuccess,
        successSoft = AppColors.darkSuccessSoft,
        danger      = AppColors.darkDanger,
        dangerSoft  = AppColors.darkDangerSoft,
        shadowCard  = AppColors.darkShadowCard,
        scrim       = AppColors.darkScrim;

  const AppColorScheme._light()
      : bg          = AppColors.lightBg,
        bgElev      = AppColors.lightBgElev,
        bgHover     = AppColors.lightBgHover,
        line        = AppColors.lightLine,
        lineSoft    = AppColors.lightLineSoft,
        text        = AppColors.lightText,
        textSub     = AppColors.lightTextSub,
        textMute    = AppColors.lightTextMute,
        primary     = AppColors.lightPrimary,
        primaryInk  = AppColors.lightPrimaryInk,
        primarySoft = AppColors.lightPrimarySoft,
        success     = AppColors.lightSuccess,
        successSoft = AppColors.lightSuccessSoft,
        danger      = AppColors.lightDanger,
        dangerSoft  = AppColors.lightDangerSoft,
        shadowCard  = AppColors.lightShadowCard,
        scrim       = AppColors.lightScrim;

  static const AppColorScheme dark  = AppColorScheme._dark();
  static const AppColorScheme light = AppColorScheme._light();

  final Color bg;
  final Color bgElev;
  final Color bgHover;
  final Color line;

  /// 구분선보다 옅은 라인 — 섹션 내 서브 구분용
  final Color lineSoft;

  final Color text;
  final Color textSub;
  final Color textMute;
  final Color primary;

  /// primary 색을 ink 팔레트 위에 올릴 때 사용하는 보조 색
  /// 다크: sky-300 / 라이트: sky-700
  final Color primaryInk;

  final Color primarySoft;
  final Color success;
  final Color successSoft;
  final Color danger;
  final Color dangerSoft;

  /// 카드 그림자 색
  final Color shadowCard;

  final Color scrim;
}

// ── BuildContext extension ────────────────────────────────────────────────────

extension AppThemeContext on BuildContext {
  /// `context.c` — 다크/라이트 자동 분기 색상 스킴
  AppColorScheme get c {
    return Theme.of(this).brightness == Brightness.dark
        ? AppColorScheme.dark
        : AppColorScheme.light;
  }
}

// ── AppTheme ──────────────────────────────────────────────────────────────────
// main.dart: theme: AppTheme.light, darkTheme: AppTheme.dark

abstract final class AppTheme {
  static final ThemeData dark  = _build(dark: true);
  static final ThemeData light = _build(dark: false);

  static ThemeData _build({required bool dark}) {
    final cs = dark ? AppColorScheme.dark : AppColorScheme.light;
    return ThemeData(
      brightness:              dark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: cs.bg,
      colorScheme: ColorScheme(
        brightness:  dark ? Brightness.dark : Brightness.light,
        primary:     cs.primary,
        onPrimary:   cs.bg,
        secondary:   AppColors.tealBase,
        onSecondary: cs.bg,
        error:       cs.danger,
        onError:     cs.bg,
        surface:     cs.bgElev,
        onSurface:   cs.text,
      ),
      dividerColor:   cs.line,
      splashColor:    cs.primarySoft,
      highlightColor: AppColors.transparent,
      useMaterial3:   true,
    );
  }
}