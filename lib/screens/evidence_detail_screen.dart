// lib/screens/evidence_detail_screen.dart
import 'package:flutter/material.dart';
import '../components/asset_image_widget.dart';
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
import 'evidence_image_viewer.dart';

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

    /// 심문 중 증거 제시 플로우에서 상세를 먼저 보여줄 때 전달한다.
    /// null 이 아니면 '이 증거 제시하기' CTA 를 노출한다(제시 확정 콜백).
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

  /// 실제 잠금 여부 — 정적 플래그와 세션 해금 상태를 합산한 단일 진실
  bool get _effectiveLocked =>
      widget.evidence.isLocked && !widget.isUnlocked;

  /// 상태 필 — 서버가 주는 라이프사이클이 아니라 증거의 성격을 알리는 라벨.
  /// (과거 'PENDING'/'NEW'/'ANALYZED'는 트리거 없는 가짜 단계라 제거했다.)
  /// 잠김(시간 해금 전) → 확보됨(일반) → 핵심 증거(CORE 중요도)의 3분류로,
  /// 증거 탭 필터 칩·타일 배지와 동일한 어휘를 쓴다.
  String get _statusLabel {
    if (_effectiveLocked) return '시간 잠금';
    if (widget.evidence.isAnalyzed) return '핵심 증거';
    return '확보됨';
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

  String get _heroTag => 'evidence_image_${widget.evidence.id}';

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
                const SizedBox(height: AppTokens.sp4),
                // ── 이미지 또는 아이콘 썸네일 ────────────────────
                // 이미지가 있으면 탭하여 전체화면 확대 뷰어(Hero·핀치줌)로 본다.
                // 로딩 중에는 AssetImageWidget 내부 스켈레톤이 표시된다.
                _ImageOrIcon(
                  evidence: widget.evidence,
                  effectiveLocked: _effectiveLocked,
                  heroTag: _heroTag,
                ),
                const SizedBox(height: AppTokens.sp4),
                // ── 이름 ────────────────────────────────────────
                Center(
                  child: Text(
                    _effectiveLocked ? '잠긴 증거' : widget.evidence.name,
                    style: AppText.titleL.copyWith(color: c.text),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppTokens.sp2),
                // ── 발견 위치 ────────────────────────────────────
                Center(
                  child: Text(
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
                // ── 상태 필 ──────────────────────────────────────
                Center(
                  child: _StatusPill(statusLabel: _statusLabel),
                ),
                const SizedBox(height: AppTokens.sp6),
                // ── 관찰 정보 카드 ───────────────────────────────
                _ObservationCard(
                  evidence: widget.evidence,
                  effectiveLocked: _effectiveLocked,
                  description: _description,
                  loading: _loadingDetail && _description == null,
                ),
                // ── 이미지 있으면 크게 보기 버튼 ──────────────────────
                if (!_effectiveLocked &&
                    widget.evidence.imageAssetKey != null &&
                    widget.evidence.imageAssetKey!.isNotEmpty) ...[
                  const SizedBox(height: AppTokens.sp4),
                  _ViewImageButton(
                    evidence: widget.evidence,
                    heroTag: _heroTag,
                  ),
                ],
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
                // ── 증거 제시 CTA(심문 중 제시 플로우) ───────────────────
                // 상세를 읽어본 뒤 이 버튼으로 제시를 확정한다.
                if (!_effectiveLocked && widget.onPresent != null) ...[
                  const SizedBox(height: AppTokens.sp6),
                  MSButton(
                    label: '이 증거 제시하기',
                    icon: Icons.send,
                    variant: MSButtonVariant.primary,
                    expanded: true,
                    onPressed: () {
                      // 상세를 닫고 제시를 확정한다(콜백이 시트를 닫고 심문에 제시).
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

// ── 이미지 / 아이콘 썸네일 ────────────────────────────────────────────────────

class _ImageOrIcon extends StatelessWidget {
  const _ImageOrIcon({
    required this.evidence,
    required this.effectiveLocked,
    required this.heroTag,
  });

  final Evidence evidence;
  final bool effectiveLocked;
  final String heroTag;

  bool get _hasImage =>
      !effectiveLocked &&
          evidence.imageAssetKey != null &&
          evidence.imageAssetKey!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (_hasImage) {
      return Center(
        child: GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EvidenceImageViewer(
                heroTag: heroTag,
                assetKey: evidence.imageAssetKey!,
                title: evidence.name,
                location: evidence.location,
                categoryLabel: evidence.categoryLabel,
              ),
            ),
          ),
          child: Hero(
            tag: heroTag,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTokens.r6),
              child: Stack(
                children: [
                  AssetImageWidget(
                    assetKey: evidence.imageAssetKey,
                    width: 240,
                    height: 160,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(AppTokens.r6),
                    fallback: _GradientIconBox(
                      icon: evidence.icon,
                      width: 240,
                      height: 160,
                    ),
                  ),
                  // 확대 힌트 오버레이
                  Positioned(
                    right: AppTokens.sp2,
                    bottom: AppTokens.sp2,
                    child: Container(
                      padding: const EdgeInsets.all(AppTokens.sp1),
                      decoration: BoxDecoration(
                        color: AppColors.ink950.withValues(alpha: .6),
                        borderRadius: BorderRadius.circular(AppTokens.r2),
                      ),
                      child: const Icon(
                        Icons.zoom_in,
                        size: 16,
                        color: AppColors.ink50,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Center(
      child: _GradientIconBox(
        icon: evidence.icon,
        width: 86,
        height: 86,
      ),
    );
  }
}

class _GradientIconBox extends StatelessWidget {
  const _GradientIconBox({
    required this.icon,
    required this.width,
    required this.height,
  });
  final IconData icon;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
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
      child: Icon(icon, size: width * 0.38, color: AppColors.ink0),
    );
  }
}

// ── 이미지 열기 버튼 ─────────────────────────────────────────────────────────

class _ViewImageButton extends StatelessWidget {
  const _ViewImageButton({
    required this.evidence,
    required this.heroTag,
  });
  final Evidence evidence;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EvidenceImageViewer(
            heroTag: heroTag,
            assetKey: evidence.imageAssetKey!,
            title: evidence.name,
            location: evidence.location,
            categoryLabel: evidence.categoryLabel,
          ),
        ),
      ),
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
            Icon(Icons.zoom_in, size: 16, color: c.primary),
            const SizedBox(width: AppTokens.sp2),
            Text(
              '증거 이미지 크게 보기',
              style: AppText.body.copyWith(
                fontWeight: FontWeight.w600,
                color: c.primary,
              ),
            ),
          ],
        ),
      ),
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
      '핵심 증거' => MSPillTone.success,
      '확보됨' => MSPillTone.primary,
      _ => MSPillTone.mute, // 시간 잠금
    };
    return MSPill(statusLabel, tone: tone);
  }
}

// ── 관찰 정보 카드 ────────────────────────────────────────────────────────────

class _ObservationCard extends StatelessWidget {
  const _ObservationCard({
    required this.evidence,
    required this.effectiveLocked,
    required this.description,
    required this.loading,
  });

  final Evidence evidence;
  final bool effectiveLocked;

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
