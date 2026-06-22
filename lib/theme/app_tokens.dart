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
  static const double btnH           = 48;
  static const double btnIconGap     = 6;
  static const double btnSpinnerSize = 18;

  // ── 하단 네비게이션 바 전용 ────────────────────────────────────────────────
  static const double navPadH     = 4;
  static const double navItemPadV = 6;
  static const double navIconSize = 22;
  static const double navLabelFs  = 11;

  // ── Pill 전용 ──────────────────────────────────────────────────────────────
  static const double pillPadH = 7;
  static const double pillPadV = 3;

  // ── 스트로크 ───────────────────────────────────────────────────────────────
  static const double strokeSm = 1.0;
  static const double strokeMd = 2.0;

  // ── 증거 아이템 전용 ────────────────────────────────────────────────────────
  static const double evidencePadH  = 13;
  static const double evidencePadV  = 11;
  static const double thumbSize     = 34;
  static const double thumbIconSize = 17;

  // ── 타임라인 전용 ──────────────────────────────────────────────────────────
  static const double timelinePadH    = 14;
  static const double timelinePadV    = 12;
  static const double timelineRowPadV = 5;
  static const double timelineColW    = 46;
  static const double conflictPadH    = 9;

  // ── 바텀시트 드래그 핸들 ───────────────────────────────────────────────────
  static const double handleW = 36;
  static const double handleH = 4;

  // ── 반경 ───────────────────────────────────────────────────────────────────
  static const double r1    = 2;
  static const double r2    = 4;
  static const double r3    = 8;
  static const double r4    = 10;
  static const double r5    = 12;
  static const double r6    = 14;
  static const double r7    = 20;
  static const double rPill = 999;

  // ── 아이콘 크기 ────────────────────────────────────────────────────────────
  /// 인라인 보조 아이콘 (badge, chip 내부 등)
  static const double iconXs = 12;
  /// 소형 아이콘 (버블 내 레이블 옆, close 버튼 등)
  static const double iconSm = 14;
  /// 기본 아이콘 (버튼, 탭바 등)
  static const double iconMd = 20;
  /// 강조 아이콘
  static const double iconLg = 24;

  // ── fontSize (AppText.copyWith 전용) ───────────────────────────────────────
  /// 최소 라벨 (아바타 이니셜, 뱃지 등)
  static const double fsXxs   = 10;
  static const double fsXxxxs = 8;     // 극소형 badge 전용
  static const double fsBadge = 8.5;   // evidence_tile badge 전용
  static const double fsXs    = 9;
  static const double fsSm    = 9.5;
  static const double fsMd    = 12;
  static const double fsBase  = 13;
  static const double fsLg    = 14;
  static const double fsXl    = 15;
  static const double fsXl2   = 16;
  static const double fsD0    = 20;    // 섹션 헤딩, 점수 숫자
  static const double fsHero  = 28;    // 히어로 타이틀
  static const double fsD1    = 36;
  static const double fsD2    = 40;
  static const double fsDisplay = 48;  // 이모지·대형 심볼 전용
  static const double fsD3    = 96;

  // ── 줄 높이 (TextStyle.height 전용) ───────────────────────────────────────
  /// 채팅 말풍선·본문 줄 높이
  static const double lhBody = 1.55;
  /// 단일 라벨·뱃지 줄 높이
  static const double lhLabel = 1.0;
}