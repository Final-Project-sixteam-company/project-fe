// lib/screens/suspect_detail_cards.dart
// 용의자 상세 - 진술 카드, 심문 기록 카드, 단순 정보 카드
import 'package:flutter/material.dart';
import '../models/play_models.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

// ── 진술 카드 ─────────────────────────────────────────────────────────────────

class SuspectStatementCard extends StatelessWidget {
  const SuspectStatementCard({
    this.statement,
    this.alibi,
    this.publicAlibi,
    super.key,
  });

  final String? statement;
  final String? alibi;
  final String? publicAlibi;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final text = (statement != null && statement!.isNotEmpty)
        ? '"$statement"'
        : '아직 확보된 진술이 없습니다.';

    return Container(
      padding: const EdgeInsets.all(AppTokens.sp4),
      decoration: BoxDecoration(
        color: c.bgElev,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppTokens.r6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text,
              style: AppText.body.copyWith(color: c.text, height: 1.6)),
          if (alibi != null && alibi!.isNotEmpty) ...[
            const SizedBox(height: AppTokens.sp3),
            Text('알리바이',
                style: AppText.monoLabel.copyWith(color: c.textMute)),
            const SizedBox(height: AppTokens.sp1),
            Text(alibi!,
                style: AppText.bodySm.copyWith(color: c.textSub, height: 1.5)),
          ],
          if (publicAlibi != null && publicAlibi!.isNotEmpty) ...[
            const SizedBox(height: AppTokens.sp3),
            Text('공개 알리바이',
                style: AppText.monoLabel.copyWith(color: c.textMute)),
            const SizedBox(height: AppTokens.sp1),
            Text(publicAlibi!,
                style: AppText.bodySm.copyWith(color: c.textSub, height: 1.5)),
          ],
        ],
      ),
    );
  }
}

// ── 심문 기록 카드 ────────────────────────────────────────────────────────────

class SuspectLogCard extends StatelessWidget {
  const SuspectLogCard({required this.log, super.key});

  final InterrogationResult log;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.sp2),
      padding: const EdgeInsets.all(AppTokens.sp3),
      decoration: BoxDecoration(
        color: c.bgElev,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppTokens.r4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (log.presentedEvidence != null) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.description_outlined, size: 12, color: c.success),
                const SizedBox(width: AppTokens.sp1),
                Flexible(
                  child: Text(
                    '증거 제시 · ${log.presentedEvidence!.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.monoLabel.copyWith(
                      fontSize: AppTokens.fsXs,
                      color: c.success,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.sp1),
          ],
          Text('Q. ${log.question}',
              style: AppText.bodySm.copyWith(
                color: c.primary,
                fontWeight: FontWeight.w600,
                height: 1.5,
              )),
          const SizedBox(height: AppTokens.sp1),
          Text('A. ${log.answer}',
              style: AppText.bodySm.copyWith(color: c.textSub, height: 1.5)),
        ],
      ),
    );
  }
}

// ── 단순 정보 카드 ────────────────────────────────────────────────────────────

class SuspectInfoCard extends StatelessWidget {
  const SuspectInfoCard({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Container(
      padding: const EdgeInsets.all(AppTokens.sp4),
      decoration: BoxDecoration(
        color: c.bgElev,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppTokens.r6),
      ),
      child: Text(text,
          style: AppText.body.copyWith(color: c.text, height: 1.6)),
    );
  }
}
