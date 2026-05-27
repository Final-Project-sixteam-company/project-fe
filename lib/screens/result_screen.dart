import 'package:flutter/material.dart';
import '../components/ms_button.dart';
import '../components/ms_kicker.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

// ── 데이터 모델 ───────────────────────────────────────────────────────────────

class ScoreItem {
  final String label;
  final int score;
  final int maxScore;

  const ScoreItem({
    required this.label,
    required this.score,
    required this.maxScore,
  });
}

class CaseResult {
  final String grade;
  final int totalScore;
  final int maxScore;
  final List<ScoreItem> scoreItems;
  final String culpritName;
  final String revelation;

  const CaseResult({
    required this.grade,
    required this.totalScore,
    required this.maxScore,
    required this.scoreItems,
    required this.culpritName,
    required this.revelation,
  });
}

// ── 샘플 결과 ─────────────────────────────────────────────────────────────────

const _sampleResult = CaseResult(
  grade: 'S',
  totalScore: 95,
  maxScore: 100,
  scoreItems: [
    ScoreItem(label: '진범 지목', score: 30, maxScore: 30),
    ScoreItem(label: '범행 방법', score: 23, maxScore: 25),
    ScoreItem(label: '범행 동기', score: 20, maxScore: 20),
    ScoreItem(label: '은폐 방법', score: 10, maxScore: 10),
    ScoreItem(label: '결정적 증거', score: 15, maxScore: 15),
    ScoreItem(label: '힌트 감점', score: -3, maxScore: 0),
  ],
  culpritName: '박재민',
  revelation:
  '박재민 CTO는 투자 유치 실패와 공동창업자와의 지분 갈등으로 인해 범행을 계획했다. '
      '그는 데모룸 행사 당일 밤 22시 이전 퇴장한 것처럼 기록을 조작한 뒤, '
      '비상계단을 통해 서버실에 재진입해 핵심 계약 데이터가 담긴 USB를 파쇄했다. '
      '아몬드라떼 컵에 남은 지문과 삭제된 슬랙 메시지 복원본이 결정적 증거가 됐으며, '
      '출입 기록 로그의 시간 불일치가 알리바이 모순을 입증했다.',
);

// ── 화면 ──────────────────────────────────────────────────────────────────────

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    this.result = _sampleResult,
    super.key,
  });

  final CaseResult result;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppMotion.dur3);
    _opacity = CurvedAnimation(parent: _ctrl, curve: AppMotion.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 10),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: AppMotion.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.sp4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppTokens.sp6),
            // ── 1. 등급 및 점수 (애니메이션) ──────────────────────────
            FadeTransition(
              opacity: _opacity,
              child: AnimatedBuilder(
                animation: _slide,
                builder: (context, child) => Transform.translate(
                  offset: _slide.value,
                  child: child,
                ),
                child: _GradeHeader(result: widget.result),
              ),
            ),
            const SizedBox(height: AppTokens.sp8),
            // ── 2. 채점 결과 ───────────────────────────────────────
            const MSKicker('추리 채점 결과'),
            const SizedBox(height: AppTokens.sp3),
            _ScoreCard(items: widget.result.scoreItems),
            const SizedBox(height: AppTokens.sp8),
            // ── 3. 사건의 진상 ─────────────────────────────────────
            const MSKicker('사건의 진상 · 해설'),
            const SizedBox(height: AppTokens.sp3),
            _RevelationCard(result: widget.result),
            const SizedBox(height: AppTokens.sp8),
            // ── 4. 하단 액션 ───────────────────────────────────────
            MSButton(
              label: '홈으로 돌아가기',
              variant: MSButtonVariant.primary,
              expanded: true,
              onPressed: () => Navigator.of(context)
                  .popUntil((route) => route.isFirst),
            ),
            const SizedBox(height: AppTokens.sp2),
            MSButton(
              label: '내 기록 보기',
              variant: MSButtonVariant.ghost,
              expanded: true,
              onPressed: () {},
            ),
            const SizedBox(height: AppTokens.sp10),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final c = context.c;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: AppTokens.sp4,
      title: Text(
        'CASE CLOSED',
        style: AppText.monoLabel.copyWith(color: c.textMute),
      ),
    );
  }
}

// ── 등급 헤더 ─────────────────────────────────────────────────────────────────

class _GradeHeader extends StatelessWidget {
  const _GradeHeader({required this.result});

  final CaseResult result;

  bool get _isTopGrade =>
      result.grade == 'S' || result.grade == 'A';

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Column(
      children: [
        Text(
          result.grade,
          style: AppText.display.copyWith(
            fontSize: 96,
            color: _isTopGrade ? c.success : c.text,
            height: 1.0,
          ),
        ),
        const SizedBox(height: AppTokens.sp3),
        Text(
          '${result.totalScore} / ${result.maxScore} PTS',
          style: AppText.monoLabel.copyWith(
            fontSize: 14,
            color: c.primary,
            letterSpacing: 14 * 0.14,
          ),
        ),
      ],
    );
  }
}

// ── 점수 카드 ─────────────────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.items});

  final List<ScoreItem> items;

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
        children: items.map((item) {
          final bool isDeduc = item.score < 0;
          final Color scoreColor =
          isDeduc ? c.danger : c.success;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.label,
                    style: AppText.body.copyWith(color: c.textSub),
                  ),
                ),
                Text(
                  isDeduc
                      ? '${item.score}점'
                      : '+${item.score}점',
                  style: AppText.monoNum.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: scoreColor,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── 사건 해설 카드 ────────────────────────────────────────────────────────────

class _RevelationCard extends StatelessWidget {
  const _RevelationCard({required this.result});

  final CaseResult result;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Container(
      padding: const EdgeInsets.all(AppTokens.sp4),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border.all(color: c.primarySoft),
        borderRadius: BorderRadius.circular(AppTokens.r4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '진범: ${result.culpritName}',
            style: AppText.titleM.copyWith(color: c.danger),
          ),
          const SizedBox(height: AppTokens.sp3),
          Text(
            result.revelation,
            style: AppText.body.copyWith(
              color: c.text,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}