// lib/theme/app_tokens.dart
import 'package:flutter/widgets.dart';

class AppTokens {
  // ── 간격 ──────────────────────────────────────────────────────────────────
  static const double sp1 = 4;
  static const double sp2 = 8;
  static const double sp3 = 12;
  static const double sp4 = 16;
  static const double sp5 = 20;
  static const double sp6 = 24;
  static const double sp8 = 32;
  static const double sp10 = 40;
  static const double sp12 = 48;
  static const double sp16 = 64;

  // ── 컴포넌트 고정 치수 ─────────────────────────────────────────────────────
  /// MSButton 기본 높이
  static const double btnH = 36;
  /// MSButton 로딩 스피너 크기
  static const double btnSpinnerSize = 14;
  /// MSButton 아이콘↔텍스트 간격
  static const double btnIconGap = 6;

  // ── 카드 내부 패딩 (기존 컴포넌트에서 반복 사용되는 값) ─────────────────
  /// 증거 아이템, 심문 말풍선 등 조밀한 카드 가로 패딩
  static const double cardPadH = 13;
  /// 증거 아이템, 심문 말풍선 등 조밀한 카드 세로 패딩
  static const double cardPadV = 11;
  /// 필터 칩 가로 패딩
  static const double chipPadH = 12;
  /// 필터 칩 세로 패딩
  static const double chipPadV = 6;

  // ── 반경 ──────────────────────────────────────────────────────────────────
  static const double r1 = 4;
  static const double r2 = 6;
  static const double r3 = 8;
  static const double r4 = 10;
  static const double r5 = 12;
  static const double r6 = 14;
  static const double r7 = 18;
  static const double rPill = 999;
}

class AppMotion {
  static const Duration dur1 = Duration(milliseconds: 120);
  static const Duration dur2 = Duration(milliseconds: 200);
  static const Duration dur3 = Duration(milliseconds: 320);

  static const Curve easeOut = Cubic(0.22, 0.61, 0.36, 1.0);
  static const Curve easeInOut = Cubic(0.65, 0.0, 0.35, 1.0);
}