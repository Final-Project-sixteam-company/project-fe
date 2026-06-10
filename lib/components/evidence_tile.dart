// lib/components/evidence_tile.dart
import 'package:flutter/material.dart';
import '../controllers/game_session_provider.dart';
import '../models/case.dart';
import '../screens/evidence_detail_screen.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import 'evidence_tile_helpers.dart';
import 'ms_pill.dart';

/// 증거 유형 문자열 → 한국어 라벨
String _categoryLabel(String? cat) => switch (cat) {
  'PHYSICAL' => '물적',
  'DOCUMENT' => '문서',
  'DIGITAL_LOG' => '디지털',
  'TESTIMONY' => '증언',
  _ => '기타',
};

class EvidenceTile extends StatelessWidget {
  const EvidenceTile({
    required this.evidence,
    this.onTap,
    this.isTimeLocked = false,
    this.isNewlyUnlocked = false,
    super.key,
  });

  final Evidence evidence;
  final VoidCallback? onTap;
  final bool isTimeLocked;
  final bool isNewlyUnlocked;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    if (isTimeLocked) {
      return Opacity(
        opacity: 0.5,
        child: Stack(
          alignment: Alignment.centerRight,
          children: [
            _Tile(evidence: evidence),
            Padding(
              padding: const EdgeInsets.only(right: AppTokens.sp4),
              child: Icon(Icons.lock_outline, size: 16, color: c.textMute),
            ),
          ],
        ),
      );
    }

    // sessionId·listData를 주입해 상세 화면이 서버 데이터를 받을 수 있도록 한다.
    // GameSessionProvider가 없는 컨텍스트(미리보기 등)에서는 null로 폴백한다.
    VoidCallback resolvedTap;
    if (onTap != null) {
      resolvedTap = onTap!;
    } else {
      int? sessionId;
      dynamic rawEvidence;
      try {
        final session = GameSessionProvider.read(context);
        sessionId = session.backendSessionId;
        rawEvidence = session.rawEvidence(evidence.id);
      } catch (_) {
        // GameSessionProvider 없는 컨텍스트 — sessionId/rawEvidence 없이 열람
      }
      resolvedTap = () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EvidenceDetailScreen(
            evidence: evidence,
            isUnlocked: isNewlyUnlocked,
            sessionId: sessionId,
            listData: rawEvidence,
          ),
        ),
      );
    }

    return _Tile(
      evidence: evidence,
      isNewlyUnlocked: isNewlyUnlocked,
      onTap: resolvedTap,
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.evidence,
    this.onTap,
    this.isNewlyUnlocked = false,
  });

  final Evidence evidence;
  final VoidCallback? onTap;
  final bool isNewlyUnlocked;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Material(
      color: c.bg,
      borderRadius: BorderRadius.circular(AppTokens.r4),
      child: InkWell(
        onTap: onTap,
        splashColor: c.primary.withValues(alpha: .08),
        highlightColor: c.primary.withValues(alpha: .04),
        borderRadius: BorderRadius.circular(AppTokens.r4),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.cardPadH,
            vertical: AppTokens.cardPadV,
          ),
          decoration: BoxDecoration(
            color: c.bg,
            border: Border.all(
              color: isNewlyUnlocked ? c.success : c.line,
              width: isNewlyUnlocked ? 1.5 : 1.0,
            ),
            borderRadius: BorderRadius.circular(AppTokens.r4),
            boxShadow: (evidence.isNew || isNewlyUnlocked)
                ? [
              BoxShadow(
                color: isNewlyUnlocked ? c.successSoft : c.primarySoft,
                spreadRadius: 2,
                blurRadius: 0,
              ),
            ]
                : null,
          ),
          child: Row(
            children: [
              EvidenceIconThumb(
                icon: evidence.icon,
                color: isNewlyUnlocked
                    ? c.success
                    : (evidence.isAnalyzed ? c.success : c.primary),
              ),
              const SizedBox(width: AppTokens.sp3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      evidence.name,
                      style: AppText.body.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                        color: c.text,
                      ),
                    ),
                    const SizedBox(height: AppTokens.rowGap),
                    Row(
                      children: [
                        Text(
                          evidence.location,
                          style: AppText.monoLabel.copyWith(
                            fontSize: AppTokens.fsSm,
                            letterSpacing: AppTokens.fsSm * 0.06,
                            color: c.textMute,
                            height: 1.0,
                          ),
                        ),
                        if (evidence.category != null) ...[
                          const SizedBox(width: AppTokens.sp2),
                          EvidenceCategoryBadge(
                            category: _categoryLabel(evidence.category),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.sp2),
              if (isNewlyUnlocked)
                const MSPill('해금', tone: MSPillTone.success)
              else if (evidence.isAnalyzed)
                const MSPill('분석완료', tone: MSPillTone.success)
              else if (evidence.isNew)
                  const MSPill('NEW', tone: MSPillTone.primary),
            ],
          ),
        ),
      ),
    );
  }
}