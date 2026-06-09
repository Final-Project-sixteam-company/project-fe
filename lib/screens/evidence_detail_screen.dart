// lib/screens/evidence_detail_screen.dart
import 'package:flutter/material.dart';
import '../models/case.dart';
import '../models/play_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import '../components/ms_button.dart';
import 'evidence_detail_widgets.dart';

export 'evidence_detail_widgets.dart'
    show EvidenceStatusRow, ProofDimensionRow, ObservationCard;

class EvidenceDetailScreen extends StatelessWidget {
  const EvidenceDetailScreen({
    required this.evidence,
    this.isUnlocked = false,
    this.sessionId,
    this.listData,
    this.onPresent,
    super.key,
  });

  final Evidence evidence;
  final bool isUnlocked;
  final int? sessionId;
  final PlayEvidence? listData;
  final VoidCallback? onPresent;

  bool get _effectiveLocked => evidence.isLocked && !isUnlocked;

  String get _statusLabel {
    if (isUnlocked && evidence.isLocked) return 'UNLOCKED';
    if (_effectiveLocked) return 'LOCKED';
    if (evidence.isAnalyzed) return 'ANALYZED';
    return evidence.isNew ? 'NEW' : 'PENDING';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: AppTokens.sp4,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'EVIDENCE',
          style: AppText.monoLabel.copyWith(color: c.textMute),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.sp4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppTokens.sp6),
                      EvidenceHero(evidence: evidence),
                      const SizedBox(height: AppTokens.sp4),
                      Center(
                        child: Text(
                          _effectiveLocked ? '잠긴 증거' : evidence.name,
                          style: AppText.titleL.copyWith(color: c.text),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: AppTokens.sp2),
                      Center(
                        child: Text(
                          _effectiveLocked
                              ? '해금 후 위치 정보가 공개됩니다'
                              : evidence.location,
                          style: AppText.monoLabel.copyWith(
                            color: _effectiveLocked ? c.textMute : c.textSub,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: AppTokens.sp6),
                      EvidenceStatusRow(
                        statusLabel: _statusLabel,
                        phase: evidence.phase,
                        effectiveLocked: _effectiveLocked,
                      ),
                      if (!_effectiveLocked &&
                          evidence.proofDimensions.isNotEmpty) ...[
                        const SizedBox(height: AppTokens.sp3),
                        ProofDimensionRow(dimensions: evidence.proofDimensions),
                      ],
                      const SizedBox(height: AppTokens.sp6),
                      ObservationCard(
                        evidence: evidence,
                        effectiveLocked: _effectiveLocked,
                        statusLabel: _statusLabel,
                      ),
                      const SizedBox(height: AppTokens.sp10),
                    ],
                  ),
                ),
              ),
              // ── 증거 제시 모달을 통해 진입한 경우에만 노출되는 하단 액션 영역 ──
              if (onPresent != null && !_effectiveLocked) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppTokens.sp4),
                  child: MSButton(
                    label: '이 증거 제시하기',
                    variant: MSButtonVariant.primary,
                    expanded: true,
                    onPressed: () {
                      onPresent!();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}