// lib/screens/evidence_detail_screen.dart
import 'package:flutter/material.dart';
import '../components/ms_kicker.dart';
import '../components/ms_pill.dart';
import '../models/case.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

class EvidenceDetailScreen extends StatelessWidget {
  const EvidenceDetailScreen({
    required this.evidence,
    /// 세션에서 시간 해금된 경우 true 를 전달한다.
    /// Evidence.isLocked 는 정적 데이터이므로 이 값으로 재정의한다.
    /// 전달하지 않으면 evidence.isLocked 를 그대로 따른다.
    this.isUnlocked = false,
    super.key,
  });

  final Evidence evidence;
  final bool isUnlocked;

  /// 실제 잠금 여부 — 정적 플래그와 세션 해금 상태를 합산한 단일 진실
  bool get _effectiveLocked => evidence.isLocked && !isUnlocked;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    final statusLabel = _effectiveLocked
        ? 'LOCKED'
        : evidence.isAnalyzed
        ? 'ANALYZED'
        : (evidence.isNew ? 'NEW' : 'PENDING');

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
                // ── 아이콘 썸네일 ────────────────────────────────────
                Center(
                  child: Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.tealBase, AppColors.skyBase],
                      ),
                      borderRadius:
                      BorderRadius.circular(AppTokens.r6),
                      border: Border.all(
                          color: AppColors.ink0.withValues(alpha: .14)),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      evidence.icon,
                      size: 34,
                      color: AppColors.ink0,
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.sp4),
                // ── 이름 ────────────────────────────────────────────
                Center(
                  child: Text(
                    evidence.name,
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
                        : evidence.location,
                    style: AppText.monoLabel.copyWith(
                      color: _effectiveLocked
                          ? c.textMute
                          : c.textSub,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppTokens.sp6),
                // ── 상태 필 ──────────────────────────────────────────
                Center(
                  child: _StatusPill(
                    statusLabel: statusLabel,
                    effectiveLocked: _effectiveLocked,
                    isAnalyzed: evidence.isAnalyzed,
                    isNew: evidence.isNew,
                    isNewlyUnlocked: isUnlocked && evidence.isLocked,
                  ),
                ),
                const SizedBox(height: AppTokens.sp6),
                // ── 관찰 정보 카드 ───────────────────────────────────
                _ObservationCard(
                  evidence: evidence,
                  effectiveLocked: _effectiveLocked,
                  statusLabel: statusLabel,
                ),
                const SizedBox(height: AppTokens.sp10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 상태 필 ───────────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.statusLabel,
    required this.effectiveLocked,
    required this.isAnalyzed,
    required this.isNew,
    required this.isNewlyUnlocked,
  });

  final String statusLabel;
  final bool effectiveLocked;
  final bool isAnalyzed;
  final bool isNew;
  final bool isNewlyUnlocked;

  @override
  Widget build(BuildContext context) {
    if (isNewlyUnlocked) {
      return const MSPill('해금됨', tone: MSPillTone.success);
    }
    if (effectiveLocked) {
      return const MSPill('잠김', tone: MSPillTone.mute);
    }
    if (isAnalyzed) {
      return const MSPill('분석완료', tone: MSPillTone.success);
    }
    if (isNew) {
      return const MSPill('NEW', tone: MSPillTone.primary);
    }
    return const MSPill('대기', tone: MSPillTone.mute);
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