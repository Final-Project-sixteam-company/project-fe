// lib/screens/suspect_detail_widgets.dart
// SuspectDetailScreen 에서 분리된 하위 위젯들

import 'package:flutter/material.dart';
import '../models/case.dart';
import '../models/play_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

// ── 큰 아바타 ─────────────────────────────────────────────────────────────────

class SuspectLargeAvatar extends StatelessWidget {
  const SuspectLargeAvatar({
    required this.name,
    this.isWitness = false,
    super.key,
  });

  final String name;
  final bool isWitness;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.characters.first : '?';

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: isWitness
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.ink700, AppColors.ink500],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.tealBase, AppColors.skyBase],
              ),
        borderRadius: BorderRadius.circular(AppTokens.r5),
        border: Border.all(color: AppColors.ink0.withValues(alpha: .14)),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: AppText.titleL.copyWith(
          fontSize: 32,
          color: AppColors.ink950,
          height: 1.0,
        ),
      ),
    );
  }
}

// ── 성격 톤 뱃지 ──────────────────────────────────────────────────────────────

class PersonalityBadge extends StatelessWidget {
  const PersonalityBadge({required this.tone, super.key});

  final String tone;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.sp2,
        vertical: AppTokens.sp1,
      ),
      decoration: BoxDecoration(
        color: c.bgHover,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppTokens.rPill),
      ),
      child: Text(
        tone,
        style: AppText.monoLabel.copyWith(
          fontSize: AppTokens.fsSm,
          color: c.textMute,
          height: 1.0,
        ),
      ),
    );
  }
}

// ── 의심도 패널 ───────────────────────────────────────────────────────────────

class SuspicionPanel extends StatelessWidget {
  const SuspicionPanel({required this.suspicion, super.key});

  final int suspicion;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final double ratio = (suspicion / 100).clamp(0.0, 1.0);

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
          Text('SUSPICION',
              style: AppText.monoLabel.copyWith(color: c.textMute)),
          const SizedBox(height: AppTokens.sp1),
          Text(
            '$suspicion',
            style: AppText.monoNum.copyWith(
              fontSize: 48,
              fontWeight: FontWeight.w700,
              color: c.danger,
              height: 1.0,
            ),
          ),
          const SizedBox(height: AppTokens.sp3),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.r1),
            child: SizedBox(
              height: 8,
              child: LayoutBuilder(
                builder: (_, constraints) => Stack(
                  children: [
                    Positioned.fill(child: ColoredBox(color: c.bgHover)),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: constraints.maxWidth * ratio,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.skyBase, AppColors.roseBase],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 진술 카드 ─────────────────────────────────────────────────────────────────


