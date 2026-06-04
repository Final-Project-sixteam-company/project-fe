// lib/screens/scenario_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/ms_button.dart';
import '../components/ms_kicker.dart';
import '../components/ms_pill.dart';
import '../models/review_models.dart';
import '../models/scenario.dart';
import '../repositories/scenario_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import 'case_briefing_screen.dart';

// 현재 백엔드에 플레이 데이터(용의자/증거/정답)가 완전히 시드돼 끝까지 플레이 가능한 시나리오.
// 1 = 데모데이 전야, 4 = 서월채의 마지막 처방.
// 5(studio9)는 정답(solution) 미시드로 최종추리에서 AI011이 떠 제외. 백엔드 seed 후 재추가.
// (백엔드 목록 응답에 canPlay가 채워지면 이 하드코딩을 제거하고 detail.canPlay로 대체)
const _kPlayableIds = {'1', '4'};
const _kBookmarkPrefix = 'bookmark_';

class ScenarioDetailScreen extends StatefulWidget {
  const ScenarioDetailScreen({required this.scenario, super.key});

  final Scenario scenario;

  @override
  State<ScenarioDetailScreen> createState() =>
      _ScenarioDetailScreenState();
}

class _ScenarioDetailScreenState
    extends State<ScenarioDetailScreen> {
  bool _bookmarked = false;
  // 상세 진입 시 목록에서 전달받은 요약(synopsis=description, tags=[], creator 없음)을
  // 우선 표시하고, GET /api/scenarios/{id} 로 풀데이터를 받아 교체한다(progressive).
  late Scenario _scenario = widget.scenario;

  // canPlay 백엔드 값은 신뢰 불가(스텁 3·정답 미시드 5도 canPlay=true) →
  // 끝까지 플레이 가능한 화이트리스트로 게이트 유지. (백엔드 정리 후 제거)
  bool get _isPlayable => _kPlayableIds.contains(_scenario.id);

  @override
  void initState() {
    super.initState();
    _loadBookmark();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final full = await scenarioRepo.detail(widget.scenario.id);
      if (mounted) setState(() => _scenario = full);
    } catch (_) {
      // 상세 조회 실패 시 목록 요약 데이터를 그대로 사용(graceful)
    }
  }

  Future<void> _loadBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    final saved =
        prefs.getBool('$_kBookmarkPrefix${widget.scenario.id}') ?? false;
    if (mounted) setState(() => _bookmarked = saved);
  }

  Future<void> _toggleBookmark() async {
    final next = !_bookmarked;
    setState(() => _bookmarked = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_kBookmarkPrefix${widget.scenario.id}', next);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = _scenario;
    // CL-001처럼 같은 사건이 백엔드 id('1')와 샘플 id('demoday-eve')로 나뉘어도
    // 리뷰가 한 버킷으로 모이도록 정규화 키로 비교한다(작성·열람 경로 키 불일치 수정).
    final reviews = sampleReviews
        .where((r) => canonicalScenarioId(r.scenarioId) == canonicalScenarioId(s.id))
        .toList();

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _bookmarked ? Icons.bookmark : Icons.bookmark_outline,
              color: _bookmarked ? c.primary : c.textSub,
            ),
            onPressed: _toggleBookmark,
          ),
          // 더보기(more_vert)는 연결할 메뉴가 없어 무동작이었으므로 제거.
        ],
      ),
      bottomNavigationBar: _BottomCta(
        bookmarked: _bookmarked,
        scenario: s,
        isPlayable: _isPlayable,
        onBookmark: _toggleBookmark,
        onStart: _isPlayable
            ? () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CaseBriefingScreen(scenario: s),
                  ),
                )
            : null,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeroArt(scenario: s),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.sp4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppTokens.sp4),
                  Row(
                    children: [
                      if (s.type == ScenarioType.official)
                        const MSPill('공식', tone: MSPillTone.danger),
                      const SizedBox(width: AppTokens.sp2),
                      MSPill(
                        s.difficultyLabel,
                        tone: switch (s.difficulty) {
                          Difficulty.easy => MSPillTone.success,
                          Difficulty.medium => MSPillTone.primary,
                          Difficulty.hard => MSPillTone.danger,
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.sp3),
                  Text(
                    s.title,
                    style: AppText.titleL.copyWith(color: c.text),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${s.subtitle} · ${s.code}',
                    style: AppText.monoLabel.copyWith(
                        color: c.textMute),
                  ),
                  const SizedBox(height: AppTokens.sp6),
                  _MetaGrid(scenario: s),
                  const SizedBox(height: AppTokens.sp6),
                  const MSKicker('시놉시스 · SYNOPSIS'),
                  const SizedBox(height: AppTokens.sp3),
                  Text(
                    s.synopsis,
                    style: AppText.body
                        .copyWith(color: c.textSub, height: 1.7),
                  ),
                  const SizedBox(height: AppTokens.sp6),
                  const MSKicker('태그'),
                  const SizedBox(height: AppTokens.sp3),
                  Wrap(
                    spacing: AppTokens.sp2,
                    runSpacing: AppTokens.sp2,
                    children: s.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          border: Border.all(color: c.line),
                          borderRadius:
                              BorderRadius.circular(AppTokens.rPill),
                        ),
                        child: Text(
                          '#$tag',
                          style: AppText.monoLabel.copyWith(
                            color: c.textSub,
                            height: 1.0,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppTokens.sp6),
                  const MSKicker('평점 · REVIEWS'),
                  const SizedBox(height: AppTokens.sp3),
                  _RatingSection(scenario: s),
                  const SizedBox(height: AppTokens.sp4),
                  // ── 리뷰 목록 ──────────────────────────────────
                  // 리뷰 '작성'은 플레이 완료 후(결과 화면)로 이전했다.
                  // 여기서는 기존 리뷰 열람만 제공한다.
                  if (reviews.isNotEmpty) ...[
                    ...reviews.map(
                      (r) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppTokens.sp3),
                        child: _ReviewCard(review: r),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppTokens.sp10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

// ── 리뷰 카드 ─────────────────────────────────────────────────────────────────

class _ReviewCard extends StatefulWidget {
  const _ReviewCard({required this.review});

  final ScenarioReview review;

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  bool _spoilerRevealed = false;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final r = widget.review;

    return Container(
      padding: const EdgeInsets.all(AppTokens.sp3),
      decoration: BoxDecoration(
        color: c.bgElev,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppTokens.r4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                r.authorName,
                style: AppText.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: c.text,
                ),
              ),
              const Spacer(),
              Text(
                '★ ${r.rating.toStringAsFixed(1)}',
                style: AppText.monoLabel.copyWith(color: c.primary),
              ),
              const SizedBox(width: AppTokens.sp3),
              Text(
                '${r.createdAt.month}.${r.createdAt.day}',
                style: AppText.monoLabel.copyWith(
                  fontSize: 9.5,
                  color: c.textMute,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.sp2),
          if (r.isSpoiler && !_spoilerRevealed)
            GestureDetector(
              onTap: () => setState(() => _spoilerRevealed = true),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.sp3,
                  vertical: AppTokens.sp2,
                ),
                decoration: BoxDecoration(
                  color: c.dangerSoft,
                  border: Border.all(color: c.danger),
                  borderRadius: BorderRadius.circular(AppTokens.r2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_outlined,
                        size: 14, color: c.danger),
                    const SizedBox(width: AppTokens.sp2),
                    Text(
                      '스포일러 포함 — 탭하면 공개',
                      style: AppText.bodySm
                          .copyWith(color: c.danger),
                    ),
                  ],
                ),
              ),
            )
          else
            Text(
              r.body,
              style: AppText.body
                  .copyWith(color: c.textSub, height: 1.6),
            ),
        ],
      ),
    );
  }
}

// ── 히어로 영역 ───────────────────────────────────────────────────────────────

class _HeroArt extends StatelessWidget {
  const _HeroArt({required this.scenario});

  final Scenario scenario;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.ink900,
              AppColors.tealBase.withValues(alpha: .6)
            ],
            stops: const [0.3, 1.0],
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          scenario.code,
          style: AppText.monoNum.copyWith(
            fontSize: 36,
            color: c.primary.withValues(alpha: .3),
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

// ── 메타 그리드 ───────────────────────────────────────────────────────────────

class _MetaGrid extends StatelessWidget {
  const _MetaGrid({required this.scenario});

  final Scenario scenario;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    // 백엔드가 suspectCount/evidenceCount 를 0으로 주는 경우(미집계)가 있어,
    // "0명·0개"로 오인되지 않도록 0이면 "—"로 표시한다.
    final cells = [
      ('난이도', scenario.difficultyLabel),
      ('플레이시간', '${scenario.estimatedMinutes}분'),
      ('용의자', scenario.suspectsCount > 0 ? '${scenario.suspectsCount}명' : '—'),
      ('증거', scenario.evidenceCount > 0 ? '${scenario.evidenceCount}개' : '—'),
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppTokens.r4),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: cells.asMap().entries.map((e) {
            final isLast = e.key == cells.length - 1;
            return Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: AppTokens.sp3,
                  horizontal: AppTokens.sp2,
                ),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(right: BorderSide(color: c.line)),
                ),
                child: Column(
                  children: [
                    Text(
                      e.value.$1.toUpperCase(),
                      style: AppText.monoLabel.copyWith(
                        fontSize: 9,
                        color: c.textMute,
                        height: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTokens.sp1),
                    Text(
                      e.value.$2,
                      style: AppText.monoNum.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.text,
                        height: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── 평점 섹션 ─────────────────────────────────────────────────────────────────

class _RatingSection extends StatelessWidget {
  const _RatingSection({required this.scenario});

  final Scenario scenario;

  String _formatPlays(int p) {
    if (p >= 1000) return '${(p / 1000).toStringAsFixed(1)}k ';
    return '$p ';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Container(
      padding: const EdgeInsets.all(AppTokens.sp4),
      decoration: BoxDecoration(
        color: c.bgElev,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppTokens.r4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            children: [
              Text(
                scenario.rating.toStringAsFixed(1),
                style: AppText.monoNum.copyWith(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: c.primary,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: AppTokens.sp1),
              Text(
                '${_formatPlays(scenario.plays)}플레이',
                style: AppText.monoLabel.copyWith(
                  fontSize: 9.5,
                  color: c.textMute,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppTokens.sp6),
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final ratio = star == 5
                    ? 0.68
                    : star == 4
                        ? 0.22
                        : star == 3
                            ? 0.07
                            : 0.02;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTokens.sp1,
                  ),
                  child: Row(
                    children: [
                      Text(
                        '$star',
                        style: AppText.monoLabel.copyWith(
                          fontSize: 9.5,
                          color: c.textMute,
                        ),
                      ),
                      const SizedBox(width: AppTokens.sp2),
                      Expanded(
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppTokens.r1),
                          child: SizedBox(
                            height: 6,
                            child: LayoutBuilder(
                              builder: (ctx, constraints) => Stack(
                                children: [
                                  Positioned.fill(
                                    child:
                                        ColoredBox(color: c.bgHover),
                                  ),
                                  Positioned(
                                    left: 0,
                                    top: 0,
                                    bottom: 0,
                                    width:
                                        constraints.maxWidth * ratio,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: c.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 하단 CTA ─────────────────────────────────────────────────────────────────

class _BottomCta extends StatelessWidget {
  const _BottomCta({
    required this.scenario,
    required this.bookmarked,
    required this.isPlayable,
    required this.onBookmark,
    required this.onStart,
  });

  final Scenario scenario;
  final bool bookmarked;
  final bool isPlayable;
  final VoidCallback onBookmark;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.sp4,
          vertical: AppTokens.sp3,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isPlayable) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: AppTokens.sp2,
                  horizontal: AppTokens.sp3,
                ),
                decoration: BoxDecoration(
                  color: c.bgHover,
                  border: Border.all(color: c.line),
                  borderRadius: BorderRadius.circular(AppTokens.r3),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.construction_outlined,
                      size: 14,
                      color: c.textMute,
                    ),
                    const SizedBox(width: AppTokens.sp2),
                    Expanded(
                      child: Text(
                        '${scenario.code} 시나리오는 아직 준비 중입니다. '
                        '곧 플레이할 수 있어요.',
                        style: AppText.bodySm.copyWith(
                          fontSize: 12,
                          color: c.textMute,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.sp2),
            ],
            Row(
              children: [
                MSButton(
                  label: '',
                  variant: bookmarked
                      ? MSButtonVariant.primary
                      : MSButtonVariant.secondary,
                  icon: bookmarked
                      ? Icons.bookmark
                      : Icons.bookmark_outline,
                  onPressed: onBookmark,
                ),
                const SizedBox(width: AppTokens.sp3),
                Expanded(
                  child: MSButton(
                    label: isPlayable ? '조사 시작' : '준비 중',
                    variant: MSButtonVariant.primary,
                    expanded: true,
                    icon: isPlayable
                        ? Icons.play_arrow
                        : Icons.lock_clock_outlined,
                    // 플레이 불가 시 버튼을 비활성화(라벨만 '준비 중'이고 눌리던 문제 수정).
                    onPressed: isPlayable ? onStart : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
