// lib/theme/app_colors.dart
import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Ink (slate) palette ───────────────────────────────────────────────────
  static const Color ink0   = Color(0xFFFFFFFF);
  static const Color ink50  = Color(0xFFF8FAFC);
  static const Color ink100 = Color(0xFFF1F5F9);
  static const Color ink200 = Color(0xFFE2E8F0);
  static const Color ink300 = Color(0xFFCBD5E1);
  static const Color ink400 = Color(0xFF94A3B8);
  static const Color ink500 = Color(0xFF64748B);
  static const Color ink600 = Color(0xFF475569);
  static const Color ink700 = Color(0xFF334155);
  static const Color ink800 = Color(0xFF1E293B);
  static const Color ink900 = Color(0xFF0F172A);
  static const Color ink950 = Color(0xFF080F1E);

  // ── Brand palette ─────────────────────────────────────────────────────────
  static const Color skyBase   = Color(0xFF38BDF8);
  static const Color skyLight  = Color(0xFF7DD3FC);
  static const Color skyStrong = Color(0xFF0284C7);
  static const Color skyDeep   = Color(0xFF075985); // sky-800

  static const Color tealBase   = Color(0xFF0D9488);
  static const Color tealLight  = Color(0xFF14B8A6);
  static const Color tealStrong = Color(0xFF0F766E);

  static const Color roseBase   = Color(0xFFF43F5E);
  static const Color roseLight  = Color(0xFFFB7185);
  static const Color roseStrong = Color(0xFFE11D48);

  static const Color gold = Color(0xFFF59E0B);

  // ── Dark semantic tokens ──────────────────────────────────────────────────
  static const Color darkBg          = ink900;
  static const Color darkBgElev      = ink800;
  static const Color darkBgHover     = ink700;
  static const Color darkLine        = ink700;
  static const Color darkLineSoft    = Color(0xFF243044); // ink700 50%
  static const Color darkText        = ink100;
  static const Color darkTextSub     = ink400;
  static const Color darkTextMute    = ink600;
  static const Color darkPrimary     = skyBase;
  static const Color darkPrimaryInk  = skyLight;          // ink 위의 sky
  static const Color darkPrimarySoft = Color(0x2638BDF8); // sky 15%
  static const Color darkSuccess     = tealLight;
  static const Color darkSuccessSoft = Color(0x2614B8A6);
  static const Color darkDanger      = roseBase;
  static const Color darkDangerSoft  = Color(0x26F43F5E);
  static const Color darkShadowCard  = Color(0x66080F1E); // ink950 40%
  static const Color darkScrim       = Color(0xB20F172A); // ink900 70%

  // ── Light semantic tokens ─────────────────────────────────────────────────
  static const Color lightBg          = ink50;
  static const Color lightBgElev      = ink100;
  static const Color lightBgHover     = ink200;
  static const Color lightLine        = ink200;
  static const Color lightLineSoft    = Color(0xFFEEF2F7); // ink200 60%
  static const Color lightText        = ink900;
  static const Color lightTextSub     = ink600;
  static const Color lightTextMute    = ink400;
  static const Color lightPrimary     = skyStrong;
  static const Color lightPrimaryInk  = skyDeep;           // ink 위의 sky
  static const Color lightPrimarySoft = Color(0x260284C7);
  static const Color lightSuccess     = tealStrong;
  static const Color lightSuccessSoft = Color(0x260F766E);
  static const Color lightDanger      = roseStrong;
  static const Color lightDangerSoft  = Color(0x26E11D48);
  static const Color lightShadowCard  = Color(0x1A94A3B8); // ink400 10%
  static const Color lightScrim       = Color(0xB2F8FAFC);

  // ── Utility ───────────────────────────────────────────────────────────────
  static const Color transparent = Color(0x00000000);
}