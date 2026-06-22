// lib/screens/submit_evidence_selector.dart
import 'package:flutter/material.dart';
import '../components/ms_pill.dart';
import '../models/case.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

class EvidenceSelector extends StatelessWidget {
  const EvidenceSelector({
    required this.evidences,
    required this.selected,
    required this.onToggle,
    required this.maxCount,
    super.key,
  });
  final List<Evidence> evidences;
  final List<Evidence> selected;
  final ValueChanged<Evidence> onToggle;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (evidences.isEmpty) {
      return Text(
        '제출할 수 있는 증거가 아직 없습니다.',
        style: AppText.bodySm.copyWith(color: c.textSub),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (selected.isNotEmpty) ...[
          Wrap(
            spacing: AppTokens.sp2,
            runSpacing: AppTokens.sp2,
            children: selected
                .map(
                  (e) => GestureDetector(
                    onTap: () => onToggle(e),
                    child: MSPill(e.name, tone: MSPillTone.primary),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppTokens.sp3),
        ],
        ...evidences.map((e) {
          final isSel = selected.any(
            (selectedEvidence) => selectedEvidence.id == e.id,
          );
          final isDis = !isSel && selected.length >= maxCount;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.sp2),
            child: GestureDetector(
              onTap: isDis ? null : () => onToggle(e),
              child: AnimatedContainer(
                duration: AppMotion.dur2,
                curve: AppMotion.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.sp3,
                  vertical: AppTokens.sp2,
                ),
                decoration: BoxDecoration(
                  color: isSel ? c.primarySoft : AppColors.transparent,
                  border: Border.all(color: isSel ? c.primary : c.line),
                  borderRadius: BorderRadius.circular(AppTokens.r3),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSel
                          ? Icons.check_circle_outline
                          : Icons.radio_button_unchecked,
                      size: AppTokens.sp4,
                      color: isSel
                          ? c.primary
                          : isDis
                          ? c.textMute
                          : c.textSub,
                    ),
                    const SizedBox(width: AppTokens.sp3),
                    Expanded(
                      child: Text(
                        e.name,
                        style: AppText.bodySm.copyWith(
                          fontSize: AppTokens.fsBase,
                          color: isDis ? c.textMute : c.text,
                        ),
                      ),
                    ),
                    Text(
                      e.location,
                      style: AppText.monoLabel.copyWith(
                        fontSize: AppTokens.fsSm,
                        color: c.textMute,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
