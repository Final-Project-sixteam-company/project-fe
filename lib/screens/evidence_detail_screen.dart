// lib/screens/evidence_detail_screen.dart
import 'package:flutter/material.dart';
import '../components/asset_image_widget.dart';
import '../components/ms_kicker.dart';
import '../components/ms_pill.dart';
import '../models/case.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import 'evidence_image_viewer.dart';

class EvidenceDetailScreen extends StatelessWidget {
  const EvidenceDetailScreen({
    required this.evidence,
    this.isUnlocked = false,
    super.key,
  });

  final Evidence evidence;
  final bool isUnlocked;

  bool get _effectiveLocked => evidence.isLocked && !isUnlocked;

  String get _statusLabel {
    if (isUnlocked && evidence.isLocked) return 'UNLOCKED';
    if (_effectiveLocked) return 'LOCKED';
    if (evidence.isAnalyzed) return 'ANALYZED';
    return evidence.isNew ? 'NEW' : 'PENDING';
  }

  String get _heroTag => 'evidence_image_${evidence.id}';

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
                _ImageOrIcon(
                  evidence: evidence,
                  effectiveLocked: _effectiveLocked,
                  heroTag: _heroTag,
                ),
                const SizedBox(height: AppTokens.sp4),
                // ── 이름 ────────────────────────────────────────
                Center(
                  child: Text(
                    _effectiveLocked ? '잠긴 증거' : evidence.name,
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
                        : evidence.location,
                    style: AppText.monoLabel.copyWith(
                      color: _effectiveLocked ? c.textMute : c.textSub,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppTokens.sp6),
                // ── 상태 필 ──────────────────────────────────────
                Center(
                  child: _StatusPill(
                    statusLabel: _statusLabel,
                  ),
                ),
                const SizedBox(height: AppTokens.sp6),
                // ── 관찰 정보 카드 ───────────────────────────────
                _ObservationCard(
                  evidence: evidence,
                  effectiveLocked: _effectiveLocked,
                  statusLabel: _statusLabel,
                ),
                // ── 이미지 있으면 열기 안내 ──────────────────────
                if (!_effectiveLocked &&
                    evidence.imageAssetKey != null &&
                    evidence.imageAssetKey!.isNotEmpty) ...[
                  const SizedBox(height: AppTokens.sp4),
                  _ViewImageButton(
                    evidence: evidence,
                    heroTag: _heroTag,
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
    final c = context.c;

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
  });

  final Evidence evidence;
  final bool effectiveLocked;
  final String statusLabel;

  String get _bodyText {
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
          Text(
            _bodyText,
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