// lib/screens/evidence_detail_meta.dart
// 증거 상세 하위 위젯 — 타임라인 행, 메타 셀
import 'package:flutter/material.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

class EvidenceTimelineRow extends StatelessWidget {
  const EvidenceTimelineRow({
    required this.time,
    required this.title,
    super.key,
  });

  final String time;
  final String title;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.sp2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            time,
            style: AppText.monoNum.copyWith(
              fontSize: 13,
              color: c.primary,
              height: 1.5,
            ),
          ),
          const SizedBox(width: AppTokens.sp3),
          Expanded(
            child: Text(
              title,
              style: AppText.body.copyWith(color: c.text, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class EvidenceMetaCell extends StatelessWidget {
  const EvidenceMetaCell({
    required this.label,
    required this.value,
    super.key,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(AppTokens.sp3),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppTokens.r3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppText.monoLabel
                .copyWith(color: c.textMute, fontSize: AppTokens.fsSm),
          ),
          const SizedBox(height: AppTokens.sp1),
          Text(
            value,
            style: AppText.bodySm
                .copyWith(color: c.text, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
