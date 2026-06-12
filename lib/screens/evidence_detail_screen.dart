// lib/screens/evidence_detail_screen.dart
import 'package:flutter/material.dart';
import '../core/api/api_exception.dart';
import '../models/case.dart';
import '../models/play_models.dart';
import '../repositories/play_session_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import 'evidence_detail_widgets.dart';

export 'evidence_detail_widgets.dart'
    show EvidenceStatusRow, ProofDimensionRow, ObservationCard;

class EvidenceDetailScreen extends StatefulWidget {
  const EvidenceDetailScreen({
    required this.evidence,

    /// 목록에서 받아 둔 원본 DTO — 상세 API 실패/미호출 시 폴백 소스.
    this.listData,

    /// 서버 세션 ID — 있으면 상세 API를 호출해 풍부한 본문을 받는다.
    this.sessionId,

    /// 세션에서 시간 해금된 경우 true.
    this.isUnlocked = false,

    /// 확보된 증거에서 '용의자 심문하기' 다음 단계 경로.
    /// null이면 CTA를 표시하지 않는다.
    this.onInterrogate,

    /// 심문 중 증거 제시 플로우에서 제시 확정 콜백.
    /// null이 아니면 '이 증거 제시하기' CTA를 노출한다.
    this.onPresent,
    super.key,
  });

  final Evidence evidence;
  final PlayEvidence? listData;
  final int? sessionId;
  final bool isUnlocked;
  final VoidCallback? onInterrogate;
  final VoidCallback? onPresent;

  @override
  State<EvidenceDetailScreen> createState() => _EvidenceDetailScreenState();
}

class _EvidenceDetailScreenState extends State<EvidenceDetailScreen> {
  EvidenceDetail? _detail;
  bool _loadingDetail = false;

  bool get _effectiveLocked => widget.evidence.isLocked && !widget.isUnlocked;

  String get _statusLabel {
    if (widget.isUnlocked && widget.evidence.isLocked) return 'UNLOCKED';
    if (_effectiveLocked) return 'LOCKED';
    if (widget.evidence.isAnalyzed) return 'ANALYZED';
    return widget.evidence.isNew ? 'NEW' : 'PENDING';
  }

  String? get _description =>
      _detail?.description ?? widget.listData?.description;

  List<RelatedSuspect> get _relatedSuspects =>
      _detail?.relatedSuspects ?? widget.listData?.relatedSuspects ?? const [];

  List<RelatedTimelineEvent> get _relatedTimelineEvents =>
      _detail?.relatedTimelineEvents ?? const [];

  EvidenceGuidance? get _guidance => _detail?.guidance;

  @override
  void initState() {
    super.initState();
    _maybeFetchDetail();
  }

  Future<void> _maybeFetchDetail() async {
    final sessionId = widget.sessionId;
    final evidenceId = int.tryParse(widget.evidence.id);
    if (_effectiveLocked || sessionId == null || evidenceId == null) return;
    setState(() => _loadingDetail = true);
    try {
      final detail = await playSessionRepo.evidenceDetail(sessionId, evidenceId);
      if (mounted) setState(() => _detail = detail);
    } on ApiException catch (_) {
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingDetail = false);
    }
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
        title: Text('EVIDENCE',
            style: AppText.monoLabel.copyWith(color: c.textMute)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.sp4),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppTokens.sp6),
                EvidenceHero(evidence: widget.evidence),
                const SizedBox(height: AppTokens.sp4),
                Center(
                  child: Text(
                    _effectiveLocked ? '잠긴 증거' : widget.evidence.name,
                    style: AppText.titleL.copyWith(color: c.text),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppTokens.sp2),
                Center(
                  child: Text(
                    _effectiveLocked
                        ? '해금 후 위치 정보가 공개됩니다'
                        : widget.evidence.location,
                    style: AppText.monoLabel.copyWith(
                      color: _effectiveLocked ? c.textMute : c.textSub,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppTokens.sp6),
                EvidenceStatusRow(
                  statusLabel: _statusLabel,
                  phase: widget.evidence.phase,
                  effectiveLocked: _effectiveLocked,
                ),
                if (!_effectiveLocked &&
                    widget.evidence.proofDimensions.isNotEmpty) ...[
                  const SizedBox(height: AppTokens.sp3),
                  ProofDimensionRow(
                      dimensions: widget.evidence.proofDimensions),
                ],
                const SizedBox(height: AppTokens.sp6),
                ObservationCard(
                  evidence: widget.evidence,
                  effectiveLocked: _effectiveLocked,
                  statusLabel: _statusLabel,
                  description: _description,
                  relatedSuspects: _relatedSuspects,
                  relatedTimelineEvents: _relatedTimelineEvents,
                  guidance: _guidance,
                  loading: _loadingDetail && _description == null,
                ),
                if (!_effectiveLocked && widget.onInterrogate != null) ...[
                  const SizedBox(height: AppTokens.sp6),
                  _CtaButton(
                    label: '용의자 심문하기',
                    icon: Icons.gavel_outlined,
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onInterrogate!();
                    },
                  ),
                ],
                if (!_effectiveLocked && widget.onPresent != null) ...[
                  const SizedBox(height: AppTokens.sp6),
                  _CtaButton(
                    label: '이 증거 제시하기',
                    icon: Icons.send,
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onPresent!();
                    },
                  ),
                ],
                const SizedBox(height: AppTokens.sp10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  const _CtaButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppTokens.sp3,
          horizontal: AppTokens.sp4,
        ),
        decoration: BoxDecoration(
          color: c.primarySoft,
          border: Border.all(color: c.primary),
          borderRadius: BorderRadius.circular(AppTokens.r3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: c.primary),
            const SizedBox(width: AppTokens.sp2),
            Text(label,
                style: AppText.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: c.primary,
                )),
          ],
        ),
      ),
    );
  }
}