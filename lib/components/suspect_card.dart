// lib/components/suspect_card.dart
import 'package:flutter/material.dart';
import '../components/asset_image_widget.dart';
import '../components/ms_pill.dart';
import '../models/case.dart';
import '../models/sample_case.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

class SuspectCard extends StatelessWidget {
  const SuspectCard(this.suspect, {this.onTap, super.key});

  final Suspect suspect;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final countLabel = suspect.interrogationCount > 0
        ? ', 심문 ${suspect.interrogationCount}회'
        : '';

    return Semantics(
      button: true,
      label: '${suspect.name}, ${suspect.role}$countLabel',
      child: Material(
        color: c.bg,
        borderRadius: BorderRadius.circular(AppTokens.r4),
        child: InkWell(
          onTap: onTap,
          splashColor: c.primary.withValues(alpha: .08),
          highlightColor: c.primary.withValues(alpha: .04),
          borderRadius: BorderRadius.circular(AppTokens.r4),
          child: Container(
            padding: const EdgeInsets.all(AppTokens.sp4),
            decoration: BoxDecoration(
              border: Border.all(color: c.line),
              borderRadius: BorderRadius.circular(AppTokens.r4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── 프로필 사진 / 이니셜 아바타 ─────────────
                    Hero(
                      tag: suspect.id,
                      child: CharacterPortrait(
                        name: suspect.name,
                        size: 40,
                        assetKey: suspect.portraitUrl,
                        borderRadius: AppTokens.r3,
                        isWitness: suspect.isWitness,
                      ),
                    ),
                    const SizedBox(width: AppTokens.sp3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  suspect.name,
                                  style: AppText.titleM.copyWith(
                                    fontSize: 14,
                                    color: c.text,
                                  ),
                                ),
                              ),
                              // 증인 뱃지
                              if (suspect.isWitness)
                                const MSPill('증인', tone: MSPillTone.mute),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            suspect.role,
                            style: AppText.bodySm.copyWith(color: c.textSub),
                          ),
                          if (suspect.interrogationCount > 0) ...[
                            const SizedBox(height: AppTokens.sp2),
                            _InterrogationChip(
                              count: suspect.interrogationCount,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 심문 횟수 칩 ──────────────────────────────────────────────────────────────

class _InterrogationChip extends StatelessWidget {
  const _InterrogationChip({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.sp2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: c.primarySoft,
        borderRadius: BorderRadius.circular(AppTokens.r2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.forum_outlined, size: 11, color: c.primary),
          const SizedBox(width: AppTokens.sp1),
          Text(
            '심문 $count회',
            style: AppText.monoLabel.copyWith(color: c.primary, height: 1.0),
          ),
        ],
      ),
    );
  }
}

// ── 사용 예시 ─────────────────────────────────────────────────────────────────

class SuspectCardExample extends StatelessWidget {
  const SuspectCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTokens.sp4),
      child: Column(
        children: [
          for (final s in sampleCase.suspects)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTokens.sp3),
              child: SuspectCard(s, onTap: () {}),
            ),
        ],
      ),
    );
  }
}
