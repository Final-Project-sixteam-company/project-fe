// lib/screens/scenario_detail_widgets.dart
import 'package:flutter/material.dart';
import '../components/ms_button.dart';
import '../components/ms_kicker.dart';
import '../components/ms_pill.dart';
import '../models/review_models.dart';
import '../models/scenario.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import 'scenario_detail_cards.dart';

export 'scenario_detail_cards.dart';

// ── 타입 배지 행 ──────────────────────────────────────────────────────────────

class ScenarioTypeBadgeRow extends StatelessWidget {
  const ScenarioTypeBadgeRow({required this.scenario, super.key});
  final Scenario scenario;

  @override
  Widget build(BuildContext context) => Row(children: [
    if (scenario.type == ScenarioType.official)
      const MSPill('공식', tone: MSPillTone.danger),
    const SizedBox(width: AppTokens.sp2),
    MSPill(scenario.difficultyLabel,
        tone: switch (scenario.difficulty) {
          Difficulty.easy   => MSPillTone.success,
          Difficulty.medium => MSPillTone.primary,
          Difficulty.hard   => MSPillTone.danger,
        }),
  ]);
}

// ── 시놉시스 섹션 ─────────────────────────────────────────────────────────────

class ScenarioSynopsisSection extends StatelessWidget {
  const ScenarioSynopsisSection({required this.scenario, super.key});
  final Scenario scenario;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const MSKicker('시놉시스 · SYNOPSIS'),
      const SizedBox(height: AppTokens.sp3),
      Text(scenario.synopsis,
          style: AppText.body.copyWith(color: c.textSub, height: 1.7)),
    ]);
  }
}

// ── 태그 섹션 ─────────────────────────────────────────────────────────────────

class ScenarioTagsSection extends StatelessWidget {
  const ScenarioTagsSection({required this.scenario, super.key});
  final Scenario scenario;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const MSKicker('태그'),
      const SizedBox(height: AppTokens.sp3),
      Wrap(
        spacing: AppTokens.sp2, runSpacing: AppTokens.sp2,
        children: scenario.tags.map((tag) => Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.sp2 + AppTokens.sp1,
              vertical: AppTokens.sp1),
          decoration: BoxDecoration(
              border: Border.all(color: c.line),
              borderRadius: BorderRadius.circular(AppTokens.rPill)),
          child: Text('#$tag',
              style: AppText.monoLabel.copyWith(color: c.textSub, height: 1.0)),
        )).toList(),
      ),
    ]);
  }
}

// ── 리뷰 섹션 ─────────────────────────────────────────────────────────────────

class ScenarioReviewsSection extends StatelessWidget {
  const ScenarioReviewsSection({
    required this.scenario,
    required this.reviews,
    required this.onShowReview,
    super.key,
  });
  final Scenario             scenario;
  final List<ScenarioReview> reviews;
  final VoidCallback         onShowReview;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const MSKicker('평점 · REVIEWS'),
      const SizedBox(height: AppTokens.sp3),
      ScenarioRatingCard(scenario: scenario),
      const SizedBox(height: AppTokens.sp4),
      ...reviews.map((r) => Padding(
        padding: const EdgeInsets.only(bottom: AppTokens.sp3),
        child: ScenarioReviewCard(review: r),
      )),
      MSButton(label: '리뷰 작성하기', variant: MSButtonVariant.secondary,
          expanded: true, icon: Icons.rate_review_outlined,
          onPressed: onShowReview),
    ],
  );
}

// ── 하단 CTA ─────────────────────────────────────────────────────────────────

class ScenarioBottomCta extends StatelessWidget {
  const ScenarioBottomCta({
    required this.scenario,   required this.bookmarked,
    required this.isPlayable, required this.onBookmark,
    required this.onStart,    super.key,
  });
  final Scenario      scenario;
  final bool          bookmarked;
  final bool          isPlayable;
  final VoidCallback  onBookmark;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.sp4, vertical: AppTokens.sp3),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (!isPlayable) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                  vertical: AppTokens.sp2, horizontal: AppTokens.sp3),
              decoration: BoxDecoration(color: c.bgHover,
                  border: Border.all(color: c.line),
                  borderRadius: BorderRadius.circular(AppTokens.r3)),
              child: Row(children: [
                Icon(Icons.construction_outlined,
                    size: AppTokens.sp3 + AppTokens.sp1, color: c.textMute),
                const SizedBox(width: AppTokens.sp2),
                Expanded(child: Text(
                    '${scenario.code} 시나리오는 아직 준비 중입니다.',
                    style: AppText.bodySm.copyWith(
                        fontSize: AppTokens.fsMd,
                        color: c.textMute, height: 1.45))),
              ]),
            ),
            const SizedBox(height: AppTokens.sp2),
          ],
          Row(children: [
            MSButton(label: '',
                variant: bookmarked
                    ? MSButtonVariant.primary : MSButtonVariant.secondary,
                icon: bookmarked ? Icons.bookmark : Icons.bookmark_outline,
                onPressed: onBookmark),
            const SizedBox(width: AppTokens.sp3),
            Expanded(child: MSButton(
                label: isPlayable ? '조사 시작' : '준비 중',
                variant: MSButtonVariant.primary, expanded: true,
                icon: isPlayable
                    ? Icons.play_arrow : Icons.lock_clock_outlined,
                onPressed: isPlayable ? onStart : null)),
          ]),
        ]),
      ),
    );
  }
}
