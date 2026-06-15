// lib/screens/interrogation_bubbles.dart
import 'package:flutter/material.dart';
import '../models/case.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 용의자 말풍선
// ─────────────────────────────────────────────────────────────────────────────
class SuspectBubble extends StatelessWidget {
  const SuspectBubble({
    required this.text,
    required this.suspect,
    super.key,
  });

  final String text;
  final Suspect suspect;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final initial =
        suspect.name.isNotEmpty ? suspect.name.characters.first : '?';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 아바타
        Container(
          width: AppTokens.sp6,
          height: AppTokens.sp6,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.tealBase, AppColors.skyBase],
            ),
            borderRadius: BorderRadius.circular(AppTokens.r2),
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: AppText.monoLabel.copyWith(
              fontSize: AppTokens.fsXxs,
              color: AppColors.ink950,
              height: AppTokens.lhLabel,
            ),
          ),
        ),
        const SizedBox(width: AppTokens.sp2),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.sp3,
              vertical: AppTokens.sp2,
            ),
            decoration: BoxDecoration(
              color: c.bgElev,
              border: Border.all(color: c.line),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTokens.r1),
                topRight: Radius.circular(AppTokens.r4),
                bottomLeft: Radius.circular(AppTokens.r4),
                bottomRight: Radius.circular(AppTokens.r4),
              ),
            ),
            child: Text(
              text,
              style: AppText.body.copyWith(
                fontSize: AppTokens.fsBase,
                color: c.text,
                height: AppTokens.lhBody,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppTokens.sp10),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 탐정(유저) 말풍선
// ─────────────────────────────────────────────────────────────────────────────
class DetectiveBubble extends StatelessWidget {
  const DetectiveBubble({
    required this.text,
    this.evidenceId,
    super.key,
  });

  final String text;
  final String? evidenceId;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isEvidence = evidenceId != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(width: AppTokens.sp10),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.sp3,
              vertical: AppTokens.sp2,
            ),
            decoration: BoxDecoration(
              color: isEvidence ? c.successSoft : c.primarySoft,
              border: Border.all(
                color: isEvidence ? c.success : c.primary,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTokens.r4),
                topRight: Radius.circular(AppTokens.r1),
                bottomLeft: Radius.circular(AppTokens.r4),
                bottomRight: Radius.circular(AppTokens.r4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isEvidence) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: AppTokens.iconXs,
                        color: c.success,
                      ),
                      const SizedBox(width: AppTokens.sp1),
                      Text(
                        '증거 제시',
                        style: AppText.monoLabel.copyWith(
                          fontSize: AppTokens.fsXxs,
                          color: c.success,
                          height: AppTokens.lhLabel,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.sp1),
                ],
                Text(
                  text,
                  style: AppText.body.copyWith(
                    fontSize: AppTokens.fsBase,
                    color: isEvidence ? c.text : c.primary,
                    height: AppTokens.lhBody,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 대기 말풍선 (AI 응답 중)
