// lib/screens/interrogation_suggested_questions.dart
import 'package:flutter/material.dart';
import '../models/play_evidence_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 추천 질문 chip 행
//
// API Spec §10.4 + PRD §8.10 계약:
//   · chip tap → 입력창 prefill only. 자동 전송 금지.
//   · 질문 목록은 EvidenceGuidance.suggestedQuestions 에서 주입.
//   · 하드코딩 목록 사용 금지.
// ─────────────────────────────────────────────────────────────────────────────
class SuggestedQuestionsBar extends StatelessWidget {
  const SuggestedQuestionsBar({
    required this.questions,
    required this.onPrefill,
    required this.disabled,
    super.key,
  });

  final List<SuggestedQuestionInfo> questions;

  /// chip tap 시 입력창에 채울 텍스트와 연결 증거 ID 를 전달한다.
  /// 전송 콜백이 아님 — _sendMessage() 호출 금지.
  final void Function(SuggestedQuestionInfo) onPrefill;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) return const SizedBox.shrink();

    final c = context.c;

    return SizedBox(
      height: AppTokens.sp12,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.sp4),
        itemCount: questions.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppTokens.sp2),
        itemBuilder: (_, i) {
          final sq = questions[i];
          return GestureDetector(
            onTap: disabled ? null : () => onPrefill(sq),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.sp3,
                vertical: AppTokens.rowGap,
              ),
              decoration: BoxDecoration(
                color: AppColors.transparent,
                border: Border.all(color: c.line),
                borderRadius: BorderRadius.circular(AppTokens.rPill),
              ),
              alignment: Alignment.center,
              child: Text(
                sq.question,
                style: AppText.bodySm.copyWith(
                  fontSize: AppTokens.fsMd,
                  color: disabled ? c.textMute : c.textSub,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}