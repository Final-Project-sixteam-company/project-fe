// lib/components/evidence_tile.dart
import 'package:flutter/material.dart';
import '../models/case.dart';
import '../screens/evidence_detail_screen.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import 'ms_pill.dart';

class EvidenceTile extends StatelessWidget {
  const EvidenceTile({
    required this.evidence,
    this.onTap,
    this.isTimeLocked = false,
    this.isNewlyUnlocked = false,
    super.key,
  });

  final Evidence evidence;
  final VoidCallback? onTap;
  final bool isTimeLocked;
  final bool isNewlyUnlocked;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    if (isTimeLocked) {
      return Opacity(
        opacity: 0.5,
        child: Stack(
          alignment: Alignment.centerRight,
          children: [
            _Tile(evidence: evidence),
            Padding(
              padding: const EdgeInsets.only(right: AppTokens.sp4),
              child: Icon(
                Icons.lock_outline,
                size: 16,
                color: c.textMute,
              ),
            ),
          ],
        ),
      );
    }

    return _Tile(
      evidence: evidence,
      isNewlyUnlocked: isNewlyUnlocked,
      onTap: onTap ??
          () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      EvidenceDetailScreen(evidence: evidence),
                ),
              ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.evidence,
    this.onTap,
    this.isNewlyUnlocked = false,
  });

  final Evidence evidence;
  final VoidCallback? onTap;
  final bool isNewlyUnlocked;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Material(
      color: c.bg,
      borderRadius: BorderRadius.circular(AppTokens.r4),
      child: InkWell(
        onTap: onTap,
        splashColor: c.primary.withValues(alpha: .08),
        highlightColor: c.primary.withValues(alpha: .04),
        borderRadius: BorderRadius.circular(AppTokens.r4),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.cardPadH,
            vertical: AppTokens.cardPadV,
          ),
          decoration: BoxDecoration(
            color: c.bg,
            border: Border.all(
              color: isNewlyUnlocked ? c.success : c.line,
              width: isNewlyUnlocked ? 1.5 : 1.0,
            ),
            borderRadius: BorderRadius.circular(AppTokens.r4),
            boxShadow: (evidence.isNew || isNewlyUnlocked)
                ? [
                    BoxShadow(
                      color: isNewlyUnlocked
                          ? c.successSoft
                          : c.primarySoft,
                      spreadRadius: 2,
                      blurRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              _IconThumb(
                icon: evidence.icon,
                color: isNewlyUnlocked
                    ? c.success
                    : (evidence.isAnalyzed ? c.success : c.primary),
              ),
              const SizedBox(width: AppTokens.sp3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      evidence.name,
                      style: AppText.body.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                        color: c.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      evidence.location,
                      style: AppText.monoLabel.copyWith(
                        fontSize: 9.5,
                        letterSpacing: 9.5 * 0.06,
                        color: c.textMute,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.sp2),
              if (isNewlyUnlocked)
                const MSPill('해금', tone: MSPillTone.success)
              else if (evidence.isAnalyzed)
                const MSPill('분석완료', tone: MSPillTone.success)
              else if (evidence.isNew)
                const MSPill('NEW', tone: MSPillTone.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconThumb extends StatelessWidget {
  const _IconThumb({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: c.bgHover,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppTokens.r2),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 17, color: color),
    );
  }
}
