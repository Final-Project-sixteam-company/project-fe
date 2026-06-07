// lib/screens/scenario_detail_cards.dart
import 'package:flutter/material.dart';
import '../models/review_models.dart';
import '../models/scenario.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

export 'scenario_detail_rating.dart';

// ── 히어로 아트 ───────────────────────────────────────────────────────────────

class ScenarioHeroArt extends StatelessWidget {
  const ScenarioHeroArt({required this.scenario, super.key});
  final Scenario scenario;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c.bg, c.primary.withValues(alpha: .25)],
            stops: const [0.3, 1.0],
          ),
        ),
        child: Center(
          child: Text(
            scenario.code,
            style: AppText.monoNum.copyWith(
                fontSize: AppTokens.fsD1,
                color: c.primary.withValues(alpha: .3),
                height: 1.0),
          ),
        ),
      ),
    );
  }
}

// ── 메타 그리드 ───────────────────────────────────────────────────────────────

class ScenarioMetaGrid extends StatelessWidget {
  const ScenarioMetaGrid({required this.scenario, super.key});
  final Scenario scenario;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final cells = [
      ('난이도',    scenario.difficultyLabel),
      ('플레이시간', '${scenario.estimatedMinutes}분'),
      ('용의자',    scenario.suspectsCount > 0 ? '${scenario.suspectsCount}명' : '—'),
      ('증거',     scenario.evidenceCount  > 0 ? '${scenario.evidenceCount}개'  : '—'),
    ];
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(AppTokens.r4)),
      child: IntrinsicHeight(
        child: Row(
          children: cells.asMap().entries.map((e) {
            final isLast = e.key == cells.length - 1;
            return Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: AppTokens.sp3, horizontal: AppTokens.sp2),
                decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : Border(right: BorderSide(color: c.line))),
                child: Column(children: [
                  Text(e.value.$1.toUpperCase(),
                      style: AppText.monoLabel.copyWith(
                          fontSize: AppTokens.fsXs,
                          color: c.textMute, height: 1.0),
                      textAlign: TextAlign.center),
                  const SizedBox(height: AppTokens.sp1),
                  Text(e.value.$2,
                      style: AppText.monoNum.copyWith(
                          fontSize: AppTokens.fsLg,
                          fontWeight: FontWeight.w600,
                          color: c.text, height: 1.0),
                      textAlign: TextAlign.center),
                ]),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── 리뷰 카드 ─────────────────────────────────────────────────────────────────

class ScenarioReviewCard extends StatefulWidget {
  const ScenarioReviewCard({required this.review, super.key});
  final ScenarioReview review;

  @override
  State<ScenarioReviewCard> createState() => _ScenarioReviewCardState();
}

class _ScenarioReviewCardState extends State<ScenarioReviewCard> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final r = widget.review;
    return Container(
      padding: const EdgeInsets.all(AppTokens.sp3),
      decoration: BoxDecoration(
          color: c.bgElev,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(AppTokens.r4)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(r.authorName,
              style: AppText.body.copyWith(
                  fontWeight: FontWeight.w600, color: c.text)),
          const Spacer(),
          Text('★ ${r.rating.toStringAsFixed(1)}',
              style: AppText.monoLabel.copyWith(color: c.primary)),
          const SizedBox(width: AppTokens.sp3),
          Text('${r.createdAt.month}.${r.createdAt.day}',
              style: AppText.monoLabel.copyWith(
                  fontSize: AppTokens.fsSm, color: c.textMute)),
        ]),
        const SizedBox(height: AppTokens.sp2),
        if (r.isSpoiler && !_revealed)
          GestureDetector(
            onTap: () => setState(() => _revealed = true),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.sp3, vertical: AppTokens.sp2),
              decoration: BoxDecoration(
                  color: c.dangerSoft,
                  border: Border.all(color: c.danger),
                  borderRadius: BorderRadius.circular(AppTokens.r2)),
              child: Row(children: [
                Icon(Icons.warning_amber_outlined,
                    size: AppTokens.sp3 + AppTokens.sp1, color: c.danger),
                const SizedBox(width: AppTokens.sp2),
                Text('스포일러 포함 — 탭하면 공개',
                    style: AppText.bodySm.copyWith(color: c.danger)),
              ]),
            ),
          )
        else
          Text(r.body,
              style: AppText.body.copyWith(color: c.textSub, height: 1.6)),
      ]),
    );
  }
}
