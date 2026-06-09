// lib/screens/evidence_detail_widgets.dart
// EvidenceDetailScreen 에서 분리된 하위 위젯들

import 'package:flutter/material.dart';
import '../components/ms_kicker.dart';
import '../components/ms_pill.dart';
import '../models/case.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

// ── 히어로 아이콘 썸네일 ──────────────────────────────────────────────────────

class EvidenceHero extends StatelessWidget {
  const EvidenceHero({required this.evidence, super.key});

  final Evidence evidence;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 86,
        height: 86,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.tealBase, AppColors.skyBase],
          ),
          borderRadius: BorderRadius.circular(AppTokens.r6),
          border: Border.all(color: AppColors.ink0.withValues(alpha: .14)),
        ),
        alignment: Alignment.center,
        child: Icon(evidence.icon, size: 34, color: AppColors.ink0),
      ),
    );
  }
}

// ── 상태 + 페이즈 행 ─────────────────────────────────────────────────────────

class EvidenceStatusRow extends StatelessWidget {
  const EvidenceStatusRow({
    required this.statusLabel,
    required this.phase,
    required this.effectiveLocked,
    super.key,
  });

  final String statusLabel;
  final EvidencePhase phase;
  final bool effectiveLocked;

  static MSPillTone _tone(String s) => switch (s) {
        'UNLOCKED' => MSPillTone.success,
        'ANALYZED' => MSPillTone.success,
        'NEW' => MSPillTone.primary,
        _ => MSPillTone.mute,
      };

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MSPill(statusLabel, tone: _tone(statusLabel)),
          if (!effectiveLocked && phase != EvidencePhase.phase0) ...[
            const SizedBox(width: AppTokens.sp2),
            MSPill(phase.label, tone: MSPillTone.mute),
          ],
        ],
      ),
    );
  }
}

// ── 입증 차원 뱃지 행 ─────────────────────────────────────────────────────────

class ProofDimensionRow extends StatelessWidget {
  const ProofDimensionRow({required this.dimensions, super.key});

  final List<ProofDimension> dimensions;

  static MSPillTone _tone(ProofDimension d) => switch (d) {
        ProofDimension.timeProof => MSPillTone.primary,
        ProofDimension.methodProof => MSPillTone.danger,
        ProofDimension.motiveProof => MSPillTone.success,
        ProofDimension.coverUpProof => MSPillTone.mute,
      };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppTokens.sp2,
      runSpacing: AppTokens.sp2,
      children: dimensions.map((d) => MSPill(d.label, tone: _tone(d))).toList(),
    );
  }
}

// ── 관찰 정보 카드 ────────────────────────────────────────────────────────────

class ObservationCard extends StatelessWidget {
  const ObservationCard({
    required this.evidence,
    required this.effectiveLocked,
    required this.statusLabel,
    super.key,
  });

  final Evidence evidence;
  final bool effectiveLocked;
  final String statusLabel;

  String get _bodyText {
    if (effectiveLocked) {
      return '이 증거는 잠겨 있습니다. 수사가 진행되면 자동으로 공개됩니다.';
    }
    if (evidence.isAnalyzed) return '분석이 완료되었습니다. 해당 정보로 사건을 추리하세요.';
    return '확보된 증거입니다. 용의자 심문 시 제시하거나 타임라인과 교차 검토하세요.';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Container(
      padding: const EdgeInsets.all(AppTokens.sp4),
      decoration: BoxDecoration(
        color: c.bgElev,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppTokens.r4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const MSKicker('관찰 정보'),
          const SizedBox(height: AppTokens.sp3),
          Text(_bodyText,
              style: AppText.body.copyWith(color: c.text, height: 1.6)),
          const SizedBox(height: AppTokens.sp4),
          Row(
            children: [
              Expanded(
                  child: EvidenceMetaCell(
                      label: 'EVIDENCE ID',
                      value: evidence.id.toUpperCase())),
              const SizedBox(width: AppTokens.sp3),
              Expanded(
                  child:
                      EvidenceMetaCell(label: 'STATUS', value: statusLabel)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 메타 셀 ───────────────────────────────────────────────────────────────────

class EvidenceMetaCell extends StatelessWidget {
  const EvidenceMetaCell({required this.label, required this.value, super.key});

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
          Text(label,
              style: AppText.monoLabel
                  .copyWith(color: c.textMute, fontSize: AppTokens.fsSm)),
          const SizedBox(height: AppTokens.sp1),
          Text(value,
              style: AppText.bodySm
                  .copyWith(color: c.text, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
