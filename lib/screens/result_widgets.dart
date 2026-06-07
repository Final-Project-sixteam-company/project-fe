// lib/screens/result_widgets.dart
import 'package:flutter/material.dart';
import '../components/ms_button.dart';
import '../components/ms_kicker.dart';
import '../components/ms_pill.dart';
import '../components/states.dart';
import '../models/play_models.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import 'result_cards.dart';
import 'result_screen.dart' show CaseResult;

// ── ResultBody (로딩·에러·성공 세 상태 통합) ──────────────────────────────────

class ResultBody extends StatelessWidget {
  const ResultBody({
    required this.loading,   required this.error,
    required this.exhausted, required this.data,
    required this.fallback,  required this.fade,
    required this.slide,     required this.onHome,
    this.onRetry,
    super.key,
  });
  final bool              loading;
  final String?           error;
  final bool              exhausted;
  final DeductionResult?  data;
  final CaseResult        fallback;
  final Animation<double> fade;
  final Animation<Offset> slide;
  final VoidCallback?     onRetry;
  final VoidCallback      onHome;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (loading) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const MSSpinner(size: AppTokens.sp6),
        const SizedBox(height: AppTokens.sp4),
        Text('채점 결과를 불러오는 중...',
            style: AppText.bodySm.copyWith(color: c.textSub)),
      ]));
    }
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(AppTokens.sp4),
        child: MSEmpty(
          icon: exhausted ? Icons.hourglass_bottom_outlined : Icons.cloud_off,
          title: exhausted ? '채점 결과 대기 중' : '결과를 불러오지 못했습니다',
          subtitle: error,
          action: onRetry != null
              ? MSButton(label: '결과 다시 확인',
                  variant: MSButtonVariant.primary, onPressed: onRetry)
              : null,
          secondaryAction: MSButton(label: '홈으로 돌아가기',
              variant: MSButtonVariant.ghost, onPressed: onHome),
        ),
      );
    }
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.sp4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: AppTokens.sp6),
        FadeTransition(opacity: fade,
          child: AnimatedBuilder(animation: slide,
            builder: (_, child) =>
                Transform.translate(offset: slide.value, child: child),
            child: ResultGradeHeader(
              grade:      data?.grade      ?? fallback.grade,
              totalScore: data?.score      ?? fallback.totalScore,
            ),
          ),
        ),
        const SizedBox(height: AppTokens.sp8),
        ResultSections(data: data, fallback: fallback),
        const SizedBox(height: AppTokens.sp8),
        MSButton(label: '홈으로 돌아가기', variant: MSButtonVariant.primary,
            expanded: true, onPressed: onHome),
        const SizedBox(height: AppTokens.sp10),
      ]),
    );
  }
}

// ── ResultSections ────────────────────────────────────────────────────────────

class ResultSections extends StatelessWidget {
  const ResultSections({required this.data, required this.fallback, super.key});
  final DeductionResult? data;
  final CaseResult       fallback;

  @override
  Widget build(BuildContext context) {
    final d = data;
    if (d != null) return _ServerSections(data: d);
    return _SampleSections(result: fallback);
  }
}

class _ServerSections extends StatelessWidget {
  const _ServerSections({required this.data});
  final DeductionResult data;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const MSKicker('추리 채점 결과'),
      const SizedBox(height: AppTokens.sp3),
      ResultMatchCard(matched: data.matched),
      if (data.matchedParts.isNotEmpty || data.missedParts.isNotEmpty) ...[
        const SizedBox(height: AppTokens.sp8),
        const MSKicker('맞춘 추리 · 놓친 추리'),
        const SizedBox(height: AppTokens.sp3),
        ResultPartsCard(matched: data.matchedParts, missed: data.missedParts),
      ],
      const SizedBox(height: AppTokens.sp8),
      const MSKicker('사건의 진상 · 해설'),
      const SizedBox(height: AppTokens.sp3),
      ResultRevelationCard(culpritName: data.correctCulprit?.name ?? '미상',
          culpritRole: data.correctCulprit?.role,
          feedback: data.feedback, fullExplanation: data.fullExplanation),
      if (data.keyEvidences.isNotEmpty) ...[
        const SizedBox(height: AppTokens.sp8),
        const MSKicker('핵심 증거'),
        const SizedBox(height: AppTokens.sp3),
        Wrap(spacing: AppTokens.sp2, runSpacing: AppTokens.sp2,
            children: data.keyEvidences
                .map((e) => MSPill(e.title, tone: MSPillTone.primary))
                .toList()),
      ],
    ],
  );
}

class _SampleSections extends StatelessWidget {
  const _SampleSections({required this.result});
  final CaseResult result;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const MSKicker('추리 채점 결과'),
      const SizedBox(height: AppTokens.sp3),
      ResultScoreCard(items: result.scoreItems),
      const SizedBox(height: AppTokens.sp8),
      const MSKicker('사건의 진상 · 해설'),
      const SizedBox(height: AppTokens.sp3),
      ResultRevelationCard(culpritName: result.culpritName,
          feedback: result.revelation, fullExplanation: ''),
    ],
  );
}

// ── ResultGradeHeader ─────────────────────────────────────────────────────────

class ResultGradeHeader extends StatelessWidget {
  const ResultGradeHeader(
      {required this.grade, required this.totalScore, super.key});
  final String grade;
  final int    totalScore;
  bool get _isTop => grade == 'S' || grade == 'A';

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(children: [
      Text(grade,
          style: AppText.display.copyWith(
              fontSize: AppTokens.fsD3,
              color: _isTop ? c.success : c.text, height: 1.0)),
      const SizedBox(height: AppTokens.sp3),
      Text('$totalScore / 100 PTS',
          style: AppText.monoLabel.copyWith(
              fontSize: AppTokens.fsLg, color: c.primary,
              letterSpacing: AppTokens.fsLg * 0.14)),
    ]);
  }
}
