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
        splashColor: c.primary.withOpacity(.08),
        highlightColor: c.primary.withOpacity(.04),
        borderRadius: BorderRadius.circular(AppTokens.r4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            color: c.bg,
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(AppTokens.r4),
            boxShadow: evidence.isNew
                ? [
              BoxShadow(
                color: c.primarySoft,
                spreadRadius: 2,
                blurRadius: 0,
              )
            ]
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
              MSPill(
                evidence.isAnalyzed
                    ? '분석완료'
                    : (evidence.isNew ? 'NEW' : '대기'),
                tone: evidence.isAnalyzed
                    ? MSPillTone.success
                    : (evidence.isNew ? MSPillTone.primary : MSPillTone.mute),
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