// lib/screens/evidence_detail_screen.dart
import 'package:flutter/material.dart';
import '../components/ms_button.dart';
import '../components/ms_kicker.dart';
import '../components/ms_pill.dart';
import '../components/states.dart';
import '../core/api/api_exception.dart';
import '../models/case.dart';
import '../models/play_models.dart';
import '../repositories/play_session_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

class EvidenceDetailScreen extends StatefulWidget {
  const EvidenceDetailScreen({
    required this.evidence,

    /// 목록(`/evidences`)에서 받아 둔 원본. 상세 API 응답 전/실패 시
    /// 본문(description)·관련 용의자를 즉시 채우는 graceful 폴백 소스.
    this.listData,

    /// 서버 세션 ID. 있으면 상세 API(`…/evidences/{id}`)로 풍부한 본문을 받는다.
    this.sessionId,

    /// 세션에서 시간 해금된 경우 true 를 전달한다.
    /// Evidence.isLocked 는 정적 데이터이므로 이 값으로 재정의한다.
    /// 전달하지 않으면 evidence.isLocked 를 그대로 따른다.
    this.isUnlocked = false,

    /// 확보된 증거에서 '용의자 심문하기' 다음 단계 경로를 제공할 때 전달한다.
    /// null 이면 CTA 를 표시하지 않는다(세션 외부에서 열람한 경우 등).
    this.onInterrogate,
    super.key,
  });

  final Evidence evidence;
  final PlayEvidence? listData;
  final int? sessionId;
  final bool isUnlocked;
  final VoidCallback? onInterrogate;

  @override
  State<EvidenceDetailScreen> createState() => _EvidenceDetailScreenState();
}

class _EvidenceDetailScreenState extends State<EvidenceDetailScreen> {
  EvidenceDetail? _detail;
  bool _loadingDetail = false;

  /// 실제 잠금 여부 — 정적 플래그와 세션 해금 상태를 합산한 단일 진실
  bool get _effectiveLocked =>
      widget.evidence.isLocked && !widget.isUnlocked;

  String get _statusLabel {
    if (widget.isUnlocked && widget.evidence.isLocked) return 'UNLOCKED';
    if (_effectiveLocked) return 'LOCKED';
    if (widget.evidence.isAnalyzed) return 'ANALYZED';
    return widget.evidence.isNew ? 'NEW' : 'PENDING';
  }

  // ── 표시용 합성 데이터(상세 API > 목록 폴백 순) ──────────────────────────
  String? get _description =>
      _detail?.description ?? widget.listData?.description;
  List<RelatedSuspect> get _relatedSuspects =>
      _detail?.relatedSuspects ?? widget.listData?.relatedSuspects ?? const [];
  List<RelatedTimelineEvent> get _relatedTimelineEvents =>
      _detail?.relatedTimelineEvents ?? const [];
  String get _locationName =>
      _detail?.locationName ?? widget.evidence.location;
  String? get _imageUrl => _detail?.imageUrl;

  @override
  void initState() {
    super.initState();
    _maybeFetchDetail();
  }

  /// 해금된 증거에 한해 상세 API 를 호출한다(잠긴 증거 본문 누출 방지).
  /// 실패해도 목록 폴백 데이터로 계속 표시하므로 오류 화면을 띄우지 않는다.
  Future<void> _maybeFetchDetail() async {
    final sessionId = widget.sessionId;
    final evidenceId = int.tryParse(widget.evidence.id);
    if (_effectiveLocked || sessionId == null || evidenceId == null) return;

    setState(() => _loadingDetail = true);
    try {
      final detail = await playSessionRepo.evidenceDetail(sessionId, evidenceId);
      if (mounted) setState(() => _detail = detail);
    } on ApiException catch (_) {
      // 상세 조회 실패는 조용히 무시(목록 폴백 데이터로 계속 표시)
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
        backgroundColor: Colors.transparent,
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppTokens.sp6),
                // ── 썸네일(이미지 있으면 노출, 없으면 아이콘 플레이스홀더) ──
                Center(child: _Thumbnail(
                  icon: widget.evidence.icon,
                  imageUrl: _effectiveLocked ? null : _imageUrl,
                )),
                const SizedBox(height: AppTokens.sp4),
                // ── 이름 ────────────────────────────────────────────
                Center(
                  child: Text(
                    _effectiveLocked ? '잠긴 증거' : widget.evidence.name,
                    style: AppText.titleL.copyWith(color: c.text),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppTokens.sp2),
                // ── 발견 위치 ────────────────────────────────────────
                Center(
                  child: Text(
                    // 잠금 상태면 위치 정보도 노출하지 않는다
                    _effectiveLocked
                        ? '해금 후 위치 정보가 공개됩니다'
                        : _locationName,
                    style: AppText.monoLabel.copyWith(
                      color: _effectiveLocked ? c.textMute : c.textSub,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppTokens.sp6),
                // ── 상태 필 ──────────────────────────────────────────
                Center(
                  child: _StatusPill(statusLabel: _statusLabel),
                ),
                const SizedBox(height: AppTokens.sp6),
                // ── 관찰 정보 카드 ───────────────────────────────────
                _ObservationCard(
                  evidence: widget.evidence,
                  effectiveLocked: _effectiveLocked,
                  statusLabel: _statusLabel,
                  description: _description,
                  loading: _loadingDetail && _description == null,
                ),
                // ── 관련 용의자 ──────────────────────────────────────
                if (!_effectiveLocked && _relatedSuspects.isNotEmpty) ...[
                  const SizedBox(height: AppTokens.sp6),
                  const MSKicker('관련 용의자'),
                  const SizedBox(height: AppTokens.sp3),
                  Wrap(
                    spacing: AppTokens.sp2,
                    runSpacing: AppTokens.sp2,
                    children: _relatedSuspects
                        .map((s) => MSPill(s.name, tone: MSPillTone.primary))
                        .toList(),
                  ),
                ],
                // ── 관련 타임라인(서버 제공 시) ──────────────────────
                if (!_effectiveLocked && _relatedTimelineEvents.isNotEmpty) ...[
                  const SizedBox(height: AppTokens.sp6),
                  const MSKicker('관련 타임라인'),
                  const SizedBox(height: AppTokens.sp3),
                  ..._relatedTimelineEvents.map(
                    (e) => _TimelineEventRow(time: e.time, title: e.title),
                  ),
                ],
                // ── 다음 단계: 용의자 심문 CTA ───────────────────────
                // 확보된(잠금 해제) 증거에 한해 '이 증거로 심문하러 가기' 경로 제공.
                if (!_effectiveLocked && widget.onInterrogate != null) ...[
                  const SizedBox(height: AppTokens.sp6),
                  MSButton(
                    label: '용의자 심문하기',
                    icon: Icons.gavel_outlined,
                    variant: MSButtonVariant.primary,
                    expanded: true,
                    onPressed: () {
                      // 상세를 닫고 용의자 탭으로 전환한다.
                      Navigator.of(context).pop();
                      widget.onInterrogate!();
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

// ── 썸네일 ────────────────────────────────────────────────────────────────────

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.icon, this.imageUrl});

  final IconData icon;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final decoration = BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.tealBase, AppColors.skyBase],
      ),
      borderRadius: BorderRadius.circular(AppTokens.r6),
      border: Border.all(color: AppColors.ink0.withValues(alpha: .14)),
    );

    final iconChild = Icon(icon, size: 34, color: AppColors.ink0);

    return Container(
      width: 86,
      height: 86,
      decoration: decoration,
      clipBehavior: Clip.hardEdge,
      alignment: Alignment.center,
      child: (url != null && url.isNotEmpty)
          ? Image.network(
              url,
              fit: BoxFit.cover,
              width: 86,
              height: 86,
              // 이미지 로드 실패 시 아이콘 플레이스홀더로 graceful 폴백(S3 키 조합 금지).
              errorBuilder: (_, _, _) => iconChild,
            )
          : iconChild,
    );
  }
}

// ── 상태 필 ───────────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.statusLabel});

  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    final tone = switch (statusLabel) {
      'UNLOCKED' => MSPillTone.success,
      'LOCKED' => MSPillTone.mute,
      'ANALYZED' => MSPillTone.success,
      'NEW' => MSPillTone.primary,
      _ => MSPillTone.mute,
    };

    return MSPill(statusLabel, tone: tone);
  }
}

// ── 관찰 정보 카드 ────────────────────────────────────────────────────────────

class _ObservationCard extends StatelessWidget {
  const _ObservationCard({
    required this.evidence,
    required this.effectiveLocked,
    required this.statusLabel,
    required this.description,
    required this.loading,
  });

  final Evidence evidence;
  final bool effectiveLocked;
  final String statusLabel;

  /// 서버 본문(상세 API 또는 목록 폴백). null 이면 일반 안내 문구로 대체.
  final String? description;
  final bool loading;

  /// 서버 본문이 없을 때만 쓰는 일반 안내(상태별).
  String get _genericText {
    if (effectiveLocked) {
      return '이 증거는 잠겨 있습니다. 수사가 진행되면 자동으로 공개됩니다.';
    }
    if (evidence.isAnalyzed) {
      return '분석이 완료되었습니다. 해당 정보로 사건을 추리하세요.';
    }
    return '확보된 증거입니다. 용의자 심문 시 제시하거나 타임라인과 교차 검토하세요.';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    // 잠금 상태에선 서버 본문을 노출하지 않는다(누출 방지).
    final bodyText =
        (!effectiveLocked && description != null && description!.isNotEmpty)
            ? description!
            : _genericText;

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
          // 서버 본문을 아직 받지 못했고 폴백 본문도 없으면 로딩 표시.
          if (loading)
            Row(
              children: [
                const MSSpinner(size: 14),
                const SizedBox(width: AppTokens.sp3),
                Text(
                  '상세 정보를 불러오는 중…',
                  style: AppText.bodySm.copyWith(color: c.textSub),
                ),
              ],
            )
          else
            Text(
              bodyText,
              style: AppText.body.copyWith(color: c.text, height: 1.6),
            ),
          const SizedBox(height: AppTokens.sp4),
          Row(
            children: [
              Expanded(
                child: _MetaCell(
                  label: 'EVIDENCE ID',
                  value: evidence.id.toUpperCase(),
                ),
              ),
              const SizedBox(width: AppTokens.sp3),
              Expanded(
                child: _MetaCell(
                  label: 'STATUS',
                  value: statusLabel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 관련 타임라인 행 ──────────────────────────────────────────────────────────

class _TimelineEventRow extends StatelessWidget {
  const _TimelineEventRow({required this.time, required this.title});

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

// ── 메타 셀 ───────────────────────────────────────────────────────────────────

class _MetaCell extends StatelessWidget {
  const _MetaCell({required this.label, required this.value});

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
            style: AppText.monoLabel.copyWith(
              color: c.textMute,
              fontSize: 9.5,
            ),
          ),
          const SizedBox(height: AppTokens.sp1),
          Text(
            value,
            style: AppText.bodySm.copyWith(
              color: c.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
