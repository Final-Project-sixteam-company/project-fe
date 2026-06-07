// lib/theme/app_tokens.dart
abstract final class AppTokens {
  // ── 간격 (4px grid) ────────────────────────────────────────────────────────
  static const double sp1  = 4;
  static const double sp2  = 8;
  static const double sp3  = 12;
  static const double sp4  = 16;
  static const double sp5  = 20;
  static const double sp6  = 24;
  static const double sp7  = 28;
  static const double sp8  = 32;
  static const double sp9  = 36;
  static const double sp10 = 40;
  static const double sp12 = 48;
  static const double sp16 = 64;

  /// 리스트 행 사이 수직 여백 (6px — 4px grid 사이값)
  static const double rowGap = 6;

  // ── 컴포넌트 전용 패딩 ────────────────────────────────────────────────────
  static const double chipPadH = 10;
  static const double chipPadV = 5;
  static const double cardPadH = 16;
  static const double cardPadV = 12;

  // ── 버튼 전용 ─────────────────────────────────────────────────────────────
  /// 버튼 기본 높이
  static const double btnH = 48;

  /// 버튼 내부 아이콘-텍스트 간격
  static const double btnIconGap = 6;

  /// 버튼 내 로딩 스피너 크기
  static const double btnSpinnerSize = 18;

  // ── 반경 ───────────────────────────────────────────────────────────────────
  static const double r1    = 2;
  static const double r2    = 4;
  static const double r3    = 8;
  static const double r4    = 10;
  static const double r5    = 12;
  static const double r6    = 14;
  static const double r7    = 20;
  static const double rPill = 999;

  // ── fontSize (AppText.copyWith 전용) ───────────────────────────────────────
  static const double fsXs   = 9;
  static const double fsSm   = 9.5;
  static const double fsMd   = 12;
  static const double fsBase = 13;
  static const double fsLg   = 14;
  static const double fsXl   = 15;
  static const double fsXl2  = 16;
  static const double fsD1   = 36;
  static const double fsD2   = 40;
  static const double fsD3   = 96;
}