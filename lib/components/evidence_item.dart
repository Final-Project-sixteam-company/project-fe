// lib/components/evidence_item.dart
import 'package:flutter/material.dart';
import '../models/case.dart';
import '../models/sample_case.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import 'ms_pill.dart';

class EvidenceItem extends StatelessWidget {
  const EvidenceItem(this.evidence, {this.onTap, super.key});

  final Evidence evidence;
  final VoidCallback? onTap;

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
            horizontal: AppTokens.evidencePadH,
            vertical: AppTokens.evidencePadV,
          ),
          decoration: BoxDecoration(
            color: c.bg,
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(AppTokens.r4),
            boxShadow: evidence.isNew
                ? [BoxShadow(color: c.primarySoft, spreadRadius: 2, blurRadius: 0)]
                : null,
          ),
          child: Row(
            children: [
              _Thumb(
                icon: evidence.icon,
                color: evidence.isAnalyzed ? c.success : c.primary,
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
                        fontSize: AppTokens.fsBase,
                        fontWeight: FontWeight.w600,
                        height: AppTokens.lhBody,
                        color: c.text,
                      ),
                    ),
                    const SizedBox(height: AppTokens.rowGap),
                    Text(
                      evidence.location,
                      style: AppText.monoLabel.copyWith(
                        fontSize: AppTokens.fsSm,
                        letterSpacing: AppTokens.fsSm * 0.06,
                        color: c.textMute,
                        height: AppTokens.lhLabel,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.sp2),
              MSPill(
                evidence.isAnalyzed ? '핵심 증거' : '확보됨',
                tone: evidence.isAnalyzed
                    ? MSPillTone.success
                    : MSPillTone.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 아이콘 썸네일 ─────────────────────────────────────────────────────────────

class _Thumb extends StatelessWidget {
  const _Thumb({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Container(
      width: AppTokens.thumbSize,
      height: AppTokens.thumbSize,
      decoration: BoxDecoration(
        color: c.bgHover,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppTokens.r2),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: AppTokens.thumbIconSize, color: color),
    );
  }
}

// ── 사용 예시 ─────────────────────────────────────────────────────────────────

class EvidenceItemExample extends StatelessWidget {
  const EvidenceItemExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTokens.sp4),
      child: Column(
        children: [
          for (final e in sampleCase.evidences)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTokens.sp3),
              child: EvidenceItem(e, onTap: () {}),
            ),
        ],
      ),
    );
  }
}