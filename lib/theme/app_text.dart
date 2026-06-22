import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

class AppText {
  static TextStyle get display => const TextStyle(
        fontFamily: 'Pretendard',
        fontSize: 48,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
      );

  static TextStyle get titleL => const TextStyle(
        fontFamily: 'Pretendard',
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 24 * -0.015,
      );

  static TextStyle get titleM => const TextStyle(
        fontFamily: 'Pretendard',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 18 * -0.01,
      );

  static TextStyle get body => const TextStyle(
        fontFamily: 'Pretendard',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.6,
      );

  static TextStyle get bodySm => const TextStyle(
        fontFamily: 'Pretendard',
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.55,
      );

  static TextStyle get caption => const TextStyle(
        fontFamily: 'Pretendard',
        fontSize: 11.5,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get monoLabel => GoogleFonts.jetBrainsMono(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 11 * 0.18,
      );

  static TextStyle get monoNum => GoogleFonts.jetBrainsMono(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
