// lib/components/evidence_tile.dart
import '../components/image_viewer_modal.dart';
import 'package:flutter/material.dart';
import 'states.dart';
import '../controllers/game_session_provider.dart';
import '../models/case.dart';
import '../screens/evidence_detail_screen.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import 'ms_pill.dart';

/// CaseScreen 바텀 탭 중 용의자(심문) 탭 인덱스. _kScreens 순서와 일치해야 한다.
const int _kSuspectsTabIndex = 2;

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
              child: Icon(
                Icons.lock_outline,
                size: 16,
                color: c.textMute,
              ),
            ),
          ],
        ),
      );
    }

    // 증거 상세는 별도 push 라우트라 GameSessionProvider 하위가 아니다.
    // 탭 전환은 컨트롤러(인텐트 버스)를 통해 위임한다. 컨트롤러는 provider 트리
    // 안인 이 타일에서 미리 읽어 둔다.
    final session = GameSessionProvider.read(context);

    return _Tile(
      evidence: evidence,
      isNewlyUnlocked: isNewlyUnlocked,
      onTap: onTap ??
              () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EvidenceDetailScreen(
                evidence: evidence,
                // 상세 API 호출용 세션 ID + 목록 폴백 데이터(이미 받아 둔 원본).
                sessionId: session.backendSessionId,
                listData: session.rawEvidence(evidence.id),
                // isTimeLocked == false 이면서 evidence.isLocked == true
                // 인 경우가 시간 해금 상태다.
                isUnlocked: isNewlyUnlocked,
                // 확보된 증거 상세에서 용의자 심문 탭으로 이동하는 다음 단계 경로.
                onInterrogate: () => session.requestTab(_kSuspectsTabIndex),
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
                color: isNewlyUnlocked
                    ? c.successSoft
                    : c.primarySoft,
                spreadRadius: 2,
                blurRadius: 0,
              ),
            ]
                : null,
          ),
          child: Row(
            children: [
              _IconThumb(
                icon: evidence.icon,
                color: isNewlyUnlocked
                    ? c.success
                    : (evidence.isAnalyzed ? c.success : c.primary),
                imageUrl: evidence.imageUrl,
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
                    // 한 줄 요약 티저(있을 때만). 잠긴 증거는 보통 비어 있어 생략된다.
                    if (evidence.oneLine != null &&
                        evidence.oneLine!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        evidence.oneLine!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodySm.copyWith(
                          fontSize: 11,
                          height: 1.3,
                          color: c.textSub,
                        ),
                      ),
                    ],
                    const SizedBox(height: 3),
                    Text(
                      evidence.location,
                      style: AppText.monoLabel.copyWith(
                        fontSize: 9.5,
                        letterSpacing: 9.5 * 0.06,
                        color: c.textMute,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.sp2),
              // 배지 어휘는 증거 탭 필터 칩·상세 상태 필과 일관: 확보됨/핵심 증거.
              // '해금'은 이번 세션에 막 풀린 증거를 강조하는 실제 전이 상태다.
              if (isNewlyUnlocked)
                const MSPill('해금', tone: MSPillTone.success)
              else if (evidence.isAnalyzed)
                const MSPill('핵심 증거', tone: MSPillTone.success)
              else
                const MSPill('확보됨', tone: MSPillTone.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconThumb extends StatelessWidget {
  const _IconThumb({required this.icon, required this.color, this.imageUrl});

  final IconData icon;
  final Color color;
  // 증거 썸네일 URL. null/빈값/로딩 실패 시 importance 아이콘으로 폴백.
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final iconFallback = Icon(icon, size: 17, color: color);
    final url = imageUrl;
    final hasImage = url != null && url.isNotEmpty;

    return Container(
      width: 34,
      height: 34,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.bgHover,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppTokens.r2),
      ),
      alignment: Alignment.center,
      child: hasImage
          ? Image.network(
        url,
        width: 34,
        height: 34,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return const MSSkeleton(width: 34, height: 34, radius: AppTokens.r2);
        },
        errorBuilder: (_, __, ___) => iconFallback,
      )
          : iconFallback,
    );
  }
}