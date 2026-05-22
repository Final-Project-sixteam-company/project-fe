import 'package:flutter/material.dart';

class AppColors {
  static const Color ink950 = Color(0xFF020617);
  static const Color ink900 = Color(0xFF0F172A);
  static const Color ink800 = Color(0xFF1E293B);
  static const Color ink700 = Color(0xFF334155);
  static const Color ink600 = Color(0xFF475569);
  static const Color ink500 = Color(0xFF64748B);
  static const Color ink400 = Color(0xFF94A3B8);
  static const Color ink300 = Color(0xFFCBD5E1);
  static const Color ink200 = Color(0xFFE2E8F0);
  static const Color ink100 = Color(0xFFF1F5F9);
  static const Color ink50 = Color(0xFFF8FAFC);
  static const Color ink25 = Color(0xFFFCFDFD);
  static const Color ink15 = Color(0xFFFEFEFE);
  static const Color ink0 = Color(0xFFFFFFFF);

  // Sky
  static const Color skySoft = Color(0x2438BDF8);
  static const Color skyBase = Color(0xFF38BDF8);
  static const Color skyStrong = Color(0xFF0284C7);

  // Teal
  static const Color tealSoft = Color(0x240D9488);
  static const Color tealBase = Color(0xFF0D9488);
  static const Color tealStrong = Color(0xFF0F766E);

  // Rose
  static const Color roseSoft = Color(0x24F43F5E);
  static const Color roseBase = Color(0xFFF43F5E);
  static const Color roseStrong = Color(0xFFE11D48);
}

@immutable
class AppColorsScheme {
  final Color bg;
  final Color bgElev;
  final Color bgHover;
  final Color line;
  final Color lineSoft;
  final Color text;
  final Color textSub;
  final Color textMute;
  final Color primary;
  final Color primarySoft;
  final Color primaryInk;
  final Color success;
  final Color successSoft;
  final Color danger;
  final Color dangerSoft;
  final Color scrim;
  final Color shadowCard;

  const AppColorsScheme({
    required this.bg,
    required this.bgElev,
    required this.bgHover,
    required this.line,
    required this.lineSoft,
    required this.text,
    required this.textSub,
    required this.textMute,
    required this.primary,
    required this.primarySoft,
    required this.primaryInk,
    required this.success,
    required this.successSoft,
    required this.danger,
    required this.dangerSoft,
    required this.scrim,
    required this.shadowCard,
  });

  static const AppColorsScheme dark = AppColorsScheme(
    bg: AppColors.ink950,
    bgElev: AppColors.ink900,
    bgHover: AppColors.ink800,
    line: AppColors.ink700,
    lineSoft: AppColors.ink800,
    text: AppColors.ink50,
    textSub: AppColors.ink300,
    textMute: AppColors.ink500,
    primary: AppColors.skyBase,
    primarySoft: AppColors.skySoft,
    primaryInk: AppColors.ink950,
    success: AppColors.tealBase,
    successSoft: AppColors.tealSoft,
    danger: AppColors.roseBase,
    dangerSoft: AppColors.roseSoft,
    scrim: Colors.black54,
    shadowCard: Colors.black87,
  );

  static const AppColorsScheme light = AppColorsScheme(
    bg: AppColors.ink50,
    bgElev: AppColors.ink0,
    bgHover: AppColors.ink100,
    line: AppColors.ink300,
    lineSoft: AppColors.ink200,
    text: AppColors.ink900,
    textSub: AppColors.ink600,
    textMute: AppColors.ink400,
    primary: AppColors.skyStrong,
    primarySoft: AppColors.skySoft,
    primaryInk: AppColors.ink0,
    success: AppColors.tealStrong,
    successSoft: AppColors.tealSoft,
    danger: AppColors.roseStrong,
    dangerSoft: AppColors.roseSoft,
    scrim: Colors.black26,
    shadowCard: Colors.black12,
  );
}
