// lib/screens/scenario_detail_screen.dart
import 'package:flutter/material.dart';
import '../components/ms_button.dart';
import '../components/ms_kicker.dart';
import '../components/ms_pill.dart';
import '../models/scenario.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import 'case_briefing_screen.dart';

/// CaseScreen에 하드코딩된 케이스 데이터가 존재하는 시나리오 ID 목록.
/// 새 시나리오에 실제 데이터를 붙이면 이 set에 추가한다.
const _kPlayableIds = {'demoday-eve'};

class ScenarioDetailScreen extends StatefulWidget {
  const ScenarioDetailScreen({required this.scenario, super.key});

  final Scenario scenario;

  @override
  State<ScenarioDetailScreen> createState() => _ScenarioDetailScreenState();
}

class _ScenarioDetailScreenState extends State<ScenarioDetailScreen> {
  bool _bookmarked = false;

  bool get _isPlayable => _kPlayableIds.contains(widget.scenario.id);

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = widget.scenario;

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
            onPressed: () => setState(() => _bookmarked = !_bookmarked),
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: c.textSub),
            onPressed: () {},
          ),
        ],
      ),
      bottomNavigationBar: _BottomCta(
        bookmarked: _bookmarked,
        scenario: s,
        isPlayable: _isPlayable,
        onBookmark: () => setState(() => _bookmarked = !_bookmarked),
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
            // ── 히어로 ────────────────────────────────────────────
            _HeroArt(scenario: s),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.sp4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppTokens.sp4),
                  // ── 배지 ──────────────────────────────────────
                  Row(
                    children: [
                      if (s.type == ScenarioType.official)
                        MSPill('공식', tone: MSPillTone.danger),
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
                  // ── 제목 ──────────────────────────────────────
                  Text(
                    s.title,
                    style: AppText.titleL.copyWith(color: c.text),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${s.subtitle} · ${s.code}',
                    style: AppText.monoLabel.copyWith(color: c.textMute),
                  ),
                  const SizedBox(height: AppTokens.sp6),
                  // ── 메타 그리드 ───────────────────────────────
                  _MetaGrid(scenario: s),
                  const SizedBox(height: AppTokens.sp6),
                  // ── 시놉시스 ──────────────────────────────────
                  const MSKicker('시놉시스 · SYNOPSIS'),
                  const SizedBox(height: AppTokens.sp3),
                  Text(
                    s.synopsis,
                    style: AppText.body.copyWith(color: c.textSub, height: 1.7),
                  ),
                  const SizedBox(height: AppTokens.sp6),
                  // ── 태그 ──────────────────────────────────────
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
                  // ── 평점 ──────────────────────────────────────
                  const MSKicker('평점 · REVIEWS'),
                  const SizedBox(height: AppTokens.sp3),
                  _RatingSection(scenario: s),
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
            colors: [AppColors.ink900, AppColors.tealBase.withValues(alpha: .6)],
            stops: const [0.3, 1.0],
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              scenario.code,
              style: AppText.monoNum.copyWith(
                fontSize: 36,
                color: c.primary.withValues(alpha: .3),
                height: 1.0,
              ),
            ),
          ],
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

    final cells = [
      ('난이도', scenario.difficultyLabel),
      ('플레이시간', '${scenario.estimatedMinutes}분'),
      ('용의자', '${scenario.suspectsCount}명'),
      ('증거', '${scenario.evidenceCount}개'),
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
                  padding: const EdgeInsets.symmetric(vertical: 2),
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
                          borderRadius: BorderRadius.circular(AppTokens.r1),
                          child: SizedBox(
                            height: 6,
                            child: LayoutBuilder(
                              builder: (ctx, constraints) => Stack(
                                children: [
                                  Positioned.fill(
                                    child: ColoredBox(color: c.bgHover),
                                  ),
                                  Positioned(
                                    left: 0,
                                    top: 0,
                                    bottom: 0,
                                    width: constraints.maxWidth * ratio,
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

  String _formatPlays(int p) {
    if (p >= 1000) return '${(p / 1000).toStringAsFixed(1)}k ';
    return '$p ';
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
                        '${scenario.code} 시나리오 데이터가 준비 중입니다. '
                            'CL-001만 현재 플레이 가능합니다.',
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
                    onPressed: onStart,
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