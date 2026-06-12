// lib/screens/evidence_detail_widgets.dart
import 'package:flutter/material.dart';
import '../components/asset_image_widget.dart';
import '../components/image_viewer_modal.dart';
import '../components/ms_kicker.dart';
import '../components/ms_pill.dart';
import '../components/states.dart';
import '../models/case.dart';
import '../models/play_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import 'evidence_detail_meta.dart';

// ── 히어로 아이콘 썸네일 ──────────────────────────────────────────────────────
class EvidenceHero extends StatelessWidget {
  const EvidenceHero({required this.evidence, super.key});
  final Evidence evidence;
  @override
  Widget build(BuildContext context) {
    final imageKey = evidence.imageUrl ?? evidence.imageAssetKey;
    final hasImage = imageKey != null && imageKey.isNotEmpty;

    final fallback = Container(
      width: 86, height: 86,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [AppColors.tealBase, AppColors.skyBase],
        ),
        borderRadius: BorderRadius.circular(AppTokens.r6),
        border: Border.all(color: AppColors.ink0.withValues(alpha: .14)),
      ),
      alignment: Alignment.center,
      child: Icon(evidence.icon, size: 34, color: AppColors.ink0),
    );

    if (!hasImage) {
      return Center(child: fallback);
    }

    return Center(
      child: GestureDetector(
        onTap: () {
          ImageViewerModal.show(
            context,
            imageUrl: imageKey,
            label: evidence.name,
          );
        },
        child: AssetImageWidget(
          assetKey: imageKey,
          width: 86,
          height: 86,
          fit: BoxFit.cover,
          borderRadius: BorderRadius.circular(AppTokens.r6),
          fallback: fallback,
        ),
      ),
    );
  }
}

// ── 상태 + 페이즈 행 ─────────────────────────────────────────────────────────
class EvidenceStatusRow extends StatelessWidget {
  const EvidenceStatusRow({
    required this.statusLabel, required this.phase,
    required this.effectiveLocked, super.key,
  });
  final String statusLabel;
  final EvidencePhase phase;
  final bool effectiveLocked;
  static MSPillTone _tone(String s) => switch (s) {
    'UNLOCKED' || 'ANALYZED' => MSPillTone.success,
    'NEW' => MSPillTone.primary,
    _ => MSPillTone.mute,
  };
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        MSPill(statusLabel, tone: _tone(statusLabel)),
        if (!effectiveLocked && phase != EvidencePhase.phase0) ...[
          const SizedBox(width: AppTokens.sp2),
          MSPill(phase.label, tone: MSPillTone.mute),
        ],
      ]),
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
      spacing: AppTokens.sp2, runSpacing: AppTokens.sp2,
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
    this.description,
    this.relatedSuspects = const [],
    this.relatedTimelineEvents = const [],
    this.guidance,
    this.loading = false,
    super.key,
  });

  final Evidence evidence;
  final bool effectiveLocked;
  final String statusLabel;
  /// 서버 상세 API 또는 목록 DTO 본문. null이면 generic 안내 문구.
  final String? description;
  final List<RelatedSuspect> relatedSuspects;
  final List<RelatedTimelineEvent> relatedTimelineEvents;
  final EvidenceGuidance? guidance;
  /// 상세 API 호출 중이며 description 미확보 상태.
  final bool loading;

  String _fallback() {
    if (effectiveLocked) return '이 증거는 잠겨 있습니다. 수사가 진행되면 자동으로 공개됩니다.';
    if (evidence.isAnalyzed) return '분석이 완료되었습니다. 해당 정보로 사건을 추리하세요.';
    return '확보된 증거입니다. 용의자 심문 시 제시하거나 타임라인과 교차 검토하세요.';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final bodyText =
    (!effectiveLocked && description != null && description!.isNotEmpty)
        ? description!
        : _fallback();
    return Container(
      padding: const EdgeInsets.all(AppTokens.sp4),
      decoration: BoxDecoration(
        color: c.bgElev, border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppTokens.r4),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const MSKicker('관찰 정보'),
        const SizedBox(height: AppTokens.sp3),
        if (loading)
          Row(children: [
            const MSSpinner(size: 14),
            const SizedBox(width: AppTokens.sp3),
            Text('상세 정보를 불러오는 중…',
                style: AppText.bodySm.copyWith(color: c.textSub)),
          ])
        else
          Text(bodyText,
              style: AppText.body.copyWith(color: c.text, height: 1.6)),
        if (!effectiveLocked && relatedSuspects.isNotEmpty) ...[
          const SizedBox(height: AppTokens.sp4),
          const MSKicker('관련 용의자'),
          const SizedBox(height: AppTokens.sp2),
          Wrap(
            spacing: AppTokens.sp2, runSpacing: AppTokens.sp2,
            children: relatedSuspects
                .map((s) => MSPill(s.name, tone: MSPillTone.primary))
                .toList(),
          ),
        ],
        if (!effectiveLocked && relatedTimelineEvents.isNotEmpty) ...[
          const SizedBox(height: AppTokens.sp4),
          const MSKicker('관련 타임라인'),
          const SizedBox(height: AppTokens.sp2),
          ...relatedTimelineEvents
              .map((e) => EvidenceTimelineRow(time: e.time, title: e.title)),
        ],
        if (!effectiveLocked && guidance != null) ...[
          if (guidance!.readingPoints.isNotEmpty) ...[
            const SizedBox(height: AppTokens.sp4),
            const MSKicker('주요 단서'),
            const SizedBox(height: AppTokens.sp2),
            ...guidance!.readingPoints.map((point) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTokens.sp2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('•', style: AppText.body.copyWith(color: c.text)),
                      const SizedBox(width: AppTokens.sp2),
                      Expanded(child: Text(point, style: AppText.body.copyWith(color: c.text))),
                    ],
                  ),
                ),
            ),
          ],
          if (guidance!.compareEvidences.isNotEmpty) ...[
            const SizedBox(height: AppTokens.sp4),
            const MSKicker('함께 볼 증거'),
            const SizedBox(height: AppTokens.sp2),
            ...guidance!.compareEvidences.map((ce) =>
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTokens.sp2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        ce.isUnlocked ? Icons.search : Icons.lock_outline,
                        size: 16,
                        color: c.textMute,
                      ),
                      const SizedBox(width: AppTokens.sp2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ce.isUnlocked ? '[이동 가능] ${ce.title}' : '[잠김] ${ce.title}',
                              style: AppText.body.copyWith(
                                color: ce.isUnlocked ? c.text : c.textMute,
                              ),
                            ),
                            if (!ce.isUnlocked && ce.unlockHint != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                '해금 힌트: ${ce.unlockHint}',
                                style: AppText.bodySm.copyWith(color: c.textSub),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ),
          ],
          if (guidance!.suggestedQuestions.isNotEmpty) ...[
            const SizedBox(height: AppTokens.sp4),
            const MSKicker('추천 질문'),
            const SizedBox(height: AppTokens.sp2),
            ...guidance!.suggestedQuestions.map((q) {
                final targetText = q.targetName != null && q.targetName!.isNotEmpty
                    ? '[${q.targetName}에게] '
                    : '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTokens.sp2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.help_outline, size: 16, color: c.textMute),
                      const SizedBox(width: AppTokens.sp2),
                      Expanded(child: Text('$targetText${q.question}', style: AppText.body.copyWith(color: c.text))),
                    ],
                  ),
                );
            }),
          ],
        ],
        const SizedBox(height: AppTokens.sp4),
        Row(children: [
          Expanded(child: EvidenceMetaCell(
              label: 'EVIDENCE ID', value: evidence.id.toUpperCase())),
          const SizedBox(width: AppTokens.sp3),
          Expanded(child: EvidenceMetaCell(label: 'STATUS', value: statusLabel)),
        ]),
      ]),
    );
  }
}