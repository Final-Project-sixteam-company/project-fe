// lib/screens/result_cards.dart
import 'package:flutter/material.dart';
import '../models/play_models.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

// ── 채점 매칭 카드 ────────────────────────────────────────────────────────────

class ResultMatchCard extends StatelessWidget {
  const ResultMatchCard({required this.matched, super.key});
  final MatchedParts matched;

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
      child: Column(
        children: [
          _MatchRow(label: '진범 지목', matched: matched.culprit),
          _MatchRow(label: '범행 동기', matched: matched.motive),
          _MatchRow(label: '범행 방법', matched: matched.method),
          _MatchRow(label: '은폐 방법', matched: matched.coverUp),
          _MatchRow(
            label: '핵심 증거',
            matched: matched.keyEvidences > 0,
            trailing: '${matched.keyEvidences}개 일치',
          ),
        ],
      ),
    );
  }
}

class _MatchRow extends StatelessWidget {
  const _MatchRow({required this.label, required this.matched, this.trailing});
  final String label;
  final bool matched;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.rowGap),
      child: Row(
        children: [
          Icon(
            matched ? Icons.check_circle : Icons.cancel_outlined,
            size: AppTokens.sp4 + AppTokens.sp1,
            color: matched ? c.success : c.danger,
          ),
          const SizedBox(width: AppTokens.sp3),
          Expanded(
            child: Text(label, style: AppText.body.copyWith(color: c.textSub)),
          ),
          Text(
            trailing ?? (matched ? '정답' : '오답'),
            style: AppText.monoLabel.copyWith(
              color: matched ? c.success : c.danger,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 맞춘/놓친 추리 카드 ───────────────────────────────────────────────────────

class ResultPartsCard extends StatelessWidget {
  const ResultPartsCard({
    required this.matched,
    required this.missed,
    super.key,
  });
  final List<String> matched;
  final List<String> missed;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...matched.map((p) => _PartRow(text: p, matched: true)),
          ...missed.map((p) => _PartRow(text: p, matched: false)),
        ],
      ),
    );
  }
}

class _PartRow extends StatelessWidget {
  const _PartRow({required this.text, required this.matched});
  final String text;
  final bool matched;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.rowGap),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            matched ? Icons.check_circle : Icons.cancel_outlined,
            size: AppTokens.sp4 + AppTokens.sp1,
            color: matched ? c.success : c.danger,
          ),
          const SizedBox(width: AppTokens.sp3),
          Expanded(
            child: Text(
              text,
              style: AppText.body.copyWith(
                color: matched ? c.text : c.textSub,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 사건 해설 카드 ────────────────────────────────────────────────────────────

class ResultRevelationCard extends StatelessWidget {
  const ResultRevelationCard({
    required this.culpritName,
    required this.feedback,
    required this.fullExplanation,
    this.culpritRole,
    super.key,
  });
  final String culpritName;
  final String? culpritRole;
  final String feedback;
  final String fullExplanation;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final label = (culpritRole?.isNotEmpty ?? false)
        ? '진범: $culpritName · $culpritRole'
        : '진범: $culpritName';
    return Container(
      padding: const EdgeInsets.all(AppTokens.sp4),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border.all(color: c.primarySoft),
        borderRadius: BorderRadius.circular(AppTokens.r4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.titleM.copyWith(color: c.danger)),
          if (feedback.isNotEmpty) ...[
            const SizedBox(height: AppTokens.sp3),
            Text(
              feedback,
              style: AppText.body.copyWith(color: c.text, height: 1.6),
            ),
          ],
          if (fullExplanation.isNotEmpty) ...[
            const SizedBox(height: AppTokens.sp3),
            Text(
              fullExplanation,
              style: AppText.body.copyWith(color: c.textSub, height: 1.6),
            ),
          ],
        ],
      ),
    );
  }
}
