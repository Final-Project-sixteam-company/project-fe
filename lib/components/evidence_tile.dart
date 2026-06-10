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
// 용의자(심문) 탭 인덱스 — CaseScreen._kScreens 순서와 일치해야 한다.
const int _kSuspectsTabIndex = 2;
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

    if (onTap != null) {
      return _Tile(
        evidence: evidence,
        isNewlyUnlocked: isNewlyUnlocked,
        onTap: onTap,
      );
    }

    // 기본 탭 핸들러 — 세션에서 sessionId·rawEvidence를 읽어
    // 상세 화면에 주입한다. 해금된 증거에는 '용의자 심문하기' CTA도 복원한다.
    int? sessionId;
    dynamic rawEvidence;
    VoidCallback? onInterrogate;

    try {
      final session = GameSessionProvider.read(context);
      sessionId = session.backendSessionId;
      rawEvidence = session.rawEvidence(evidence.id);
      // 해금된 증거에서 용의자 탭으로 이동하는 경로를 제공한다.
      // requestTab은 CaseScreen이 소비해 바텀 탭을 전환한다.
      if (!evidence.isLocked || isNewlyUnlocked) {
        onInterrogate = () => session.requestTab(_kSuspectsTabIndex);
      }
    } catch (_) {
      // GameSessionProvider 없는 컨텍스트(미리보기 등) — null로 폴백
    }

    return _Tile(
      evidence: evidence,
      isNewlyUnlocked: isNewlyUnlocked,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EvidenceDetailScreen(
            evidence: evidence,
            isUnlocked: isNewlyUnlocked,
            sessionId: sessionId,
            listData: rawEvidence,
            onInterrogate: onInterrogate,
          ),
        ),
      ),
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