import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'states.dart';
import '../models/case.dart';
import '../models/sample_case.dart';
import '../theme/app_colors.dart';
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
      label: '${suspect.name}, ${suspect.role}, 의심도 ${suspect.suspicion}'
          '$countLabel',
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
                  _Avatar(
                    initial:
                        suspect.name.isNotEmpty ? suspect.name.characters.first : '?',
                    imageUrl: suspect.portraitUrl,
                  ),
                  const SizedBox(width: AppTokens.sp3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          suspect.name,
                          style: AppText.titleM.copyWith(
                            fontSize: 14,
                            color: c.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          suspect.role,
                          style: AppText.bodySm.copyWith(color: c.textSub),
                        ),
                        if (suspect.interrogationCount > 0) ...[
                          const SizedBox(height: AppTokens.sp2),
                          _InterrogationChip(count: suspect.interrogationCount),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTokens.sp3),
                  _SuspicionNum(suspicion: suspect.suspicion),
                ],
              ),
              const SizedBox(height: AppTokens.sp3),
              _Meter(percent: suspect.suspicion),
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
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.sp2, vertical: 2),
      decoration: BoxDecoration(
        color: c.primarySoft,
        borderRadius: BorderRadius.circular(AppTokens.r2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.forum_outlined, size: 11, color: c.primary),
          const SizedBox(width: 4),
          Text(
            '심문 $count회',
            style: AppText.monoLabel.copyWith(color: c.primary, height: 1.0),
          ),
        ],
      ),
    );
  }
}

// ── 아바타 ────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initial, this.imageUrl});

  final String initial;
  // 공식 초상 URL. null/빈값이거나 로딩 실패 시 이니셜 그라데이션으로 폴백.
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final initialFallback = Text(
      initial,
      style: AppText.titleM.copyWith(
        fontSize: 16,
        color: AppColors.ink950,
        height: 1.0,
      ),
    );

    final url = imageUrl;
    final hasImage = url != null && url.isNotEmpty;

    return Container(
      width: 40,
      height: 40,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.tealBase, AppColors.skyBase],
        ),
        borderRadius: BorderRadius.circular(AppTokens.r3),
        border: Border.all(
          color: const Color(0x24FFFFFF),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: hasImage
          ? CachedNetworkImage(
              imageUrl: url,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              // 로딩 중엔 스켈레톤, 실패 시 이니셜 그라데이션 폴백.
              placeholder: (_, _) =>
                  const MSSkeleton(width: 40, height: 40, radius: AppTokens.r3),
              errorWidget: (_, _, _) => initialFallback,
            )
          : initialFallback,
    );
  }
}

// ── 의심도 수치 ───────────────────────────────────────────────────────────────

class _SuspicionNum extends StatelessWidget {
  const _SuspicionNum({required this.suspicion});

  final int suspicion;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'SUSPICION',
          style: AppText.monoLabel.copyWith(
            color: c.textMute,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$suspicion',
          style: AppText.monoNum.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: c.danger,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

// ── 의심도 미터 ───────────────────────────────────────────────────────────────

class _Meter extends StatelessWidget {
  const _Meter({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final double ratio = (percent / 100).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.r1),
      child: SizedBox(
        height: 5,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // 배경
                Positioned.fill(
                  child: ColoredBox(color: c.bgHover),
                ),
                // 채움
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: constraints.maxWidth * ratio,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.skyBase, AppColors.roseBase],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
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