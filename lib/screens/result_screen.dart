import 'package:flutter/material.dart';
import '../components/ms_button.dart';
import '../components/ms_kicker.dart';
import '../components/ms_pill.dart';
import '../components/states.dart';
import '../core/api/api_exception.dart';
import '../models/play_models.dart';
import '../repositories/play_session_repository.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

// ── 데이터 모델 (레거시 샘플 표시용) ──────────────────────────────────────────

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

// ── 샘플 결과 (sessionId 없이 호출되는 미리보기 경로) ─────────────────────────

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
    this.sessionId,
    this.result = _sampleResult,
    super.key,
  });

  /// 서버 플레이 세션 ID. 지정 시 서버에서 채점 결과를 조회한다.
  final int? sessionId;

  /// 레거시/미리보기용 샘플 결과(서버 미연동 경로).
  final CaseResult result;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  bool _loading = false;
  String? _error;
  DeductionResult? _data;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppMotion.dur3);
    _opacity = CurvedAnimation(parent: _ctrl, curve: AppMotion.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 10),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: AppMotion.easeOut));

    if (widget.sessionId != null) {
      _fetchResult(widget.sessionId!);
    } else {
      _ctrl.forward();
    }
  }

  Future<void> _fetchResult(int sessionId) async {
    setState(() => _loading = true);
    try {
      final result = await playSessionRepo.result(sessionId);
      if (!mounted) return;
      setState(() {
        _data = result;
        _loading = false;
      });
      _ctrl.forward();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = '결과를 불러오지 못했습니다.';
          _loading = false;
        });
      }
    }
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
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: MSSpinner(size: 24));
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(AppTokens.sp4),
        child: MSEmpty(
          icon: Icons.cloud_off,
          title: '결과를 불러오지 못했습니다',
          subtitle: _error,
          action: MSButton(
            label: '홈으로 돌아가기',
            variant: MSButtonVariant.primary,
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ),
      );
    }

    final data = _data;
    return SingleChildScrollView(
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
              child: _GradeHeader(
                grade: data?.grade ?? widget.result.grade,
                totalScore: data?.score ?? widget.result.totalScore,
              ),
            ),
          ),
          const SizedBox(height: AppTokens.sp8),
          if (data != null)
            ..._buildServerSections(context, data)
          else
            ..._buildSampleSections(context),
          const SizedBox(height: AppTokens.sp8),
          // ── 하단 액션 ───────────────────────────────────────────
          MSButton(
            label: '홈으로 돌아가기',
            variant: MSButtonVariant.primary,
            expanded: true,
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
          const SizedBox(height: AppTokens.sp10),
        ],
      ),
    );
  }

  // ── 서버 결과 섹션 ──────────────────────────────────────────────────────────

  List<Widget> _buildServerSections(
    BuildContext context,
    DeductionResult data,
  ) {
    return [
      const MSKicker('추리 채점 결과'),
      const SizedBox(height: AppTokens.sp3),
      _MatchCard(matched: data.matched),
      const SizedBox(height: AppTokens.sp8),
      const MSKicker('사건의 진상 · 해설'),
      const SizedBox(height: AppTokens.sp3),
      _RevelationCard(
        culpritName: data.correctCulprit?.name ?? '미상',
        culpritRole: data.correctCulprit?.role,
        feedback: data.feedback,
        fullExplanation: data.fullExplanation,
      ),
      if (data.keyEvidences.isNotEmpty) ...[
        const SizedBox(height: AppTokens.sp8),
        const MSKicker('핵심 증거'),
        const SizedBox(height: AppTokens.sp3),
        Wrap(
          spacing: AppTokens.sp2,
          runSpacing: AppTokens.sp2,
          children: data.keyEvidences
              .map((e) => MSPill(e.title, tone: MSPillTone.primary))
              .toList(),
        ),
      ],
    ];
  }

  // ── 레거시 샘플 섹션 ────────────────────────────────────────────────────────

  List<Widget> _buildSampleSections(BuildContext context) {
    final result = widget.result;
    return [
      const MSKicker('추리 채점 결과'),
      const SizedBox(height: AppTokens.sp3),
      _ScoreCard(items: result.scoreItems),
      const SizedBox(height: AppTokens.sp8),
      const MSKicker('사건의 진상 · 해설'),
      const SizedBox(height: AppTokens.sp3),
      _RevelationCard(
        culpritName: result.culpritName,
        feedback: result.revelation,
        fullExplanation: '',
      ),
    ];
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
  const _GradeHeader({required this.grade, required this.totalScore});

  final String grade;
  final int totalScore;

  bool get _isTopGrade => grade == 'S' || grade == 'A';

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Column(
      children: [
        Text(
          grade,
          style: AppText.display.copyWith(
            fontSize: 96,
            color: _isTopGrade ? c.success : c.text,
            height: 1.0,
          ),
        ),
        const SizedBox(height: AppTokens.sp3),
        Text(
          '$totalScore / 100 PTS',
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

// ── 채점 매칭 카드 (서버) ─────────────────────────────────────────────────────

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.matched});

  final MatchedParts matched;

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
        children: [
          _MatchRow(label: '진범 지목', matched: matched.culprit),
          _MatchRow(label: '범행 동기', matched: matched.motive),
          _MatchRow(label: '범행 방법', matched: matched.method),
          _MatchRow(label: '은폐 방법', matched: matched.coverUp),
          _MatchRow(
            label: '핵심 증거',
            matched: matched.keyEvidences > 0,
            trailing: '${matched.keyEvidences}개 일치',
          ),
        ],
      ),
    );
  }
}

class _MatchRow extends StatelessWidget {
  const _MatchRow({
    required this.label,
    required this.matched,
    this.trailing,
  });

  final String label;
  final bool matched;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            matched ? Icons.check_circle : Icons.cancel_outlined,
            size: 18,
            color: matched ? c.success : c.danger,
          ),
          const SizedBox(width: AppTokens.sp3),
          Expanded(
            child: Text(
              label,
              style: AppText.body.copyWith(color: c.textSub),
            ),
          ),
          Text(
            trailing ?? (matched ? '정답' : '오답'),
            style: AppText.monoLabel.copyWith(
              color: matched ? c.success : c.danger,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 점수 카드 (레거시 샘플) ───────────────────────────────────────────────────

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
  const _RevelationCard({
    required this.culpritName,
    required this.feedback,
    required this.fullExplanation,
    this.culpritRole,
  });

  final String culpritName;
  final String? culpritRole;
  final String feedback;
  final String fullExplanation;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final culpritLabel = culpritRole != null && culpritRole!.isNotEmpty
        ? '진범: $culpritName · $culpritRole'
        : '진범: $culpritName';

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
            culpritLabel,
            style: AppText.titleM.copyWith(color: c.danger),
          ),
          if (feedback.isNotEmpty) ...[
            const SizedBox(height: AppTokens.sp3),
            Text(
              feedback,
              style: AppText.body.copyWith(color: c.text, height: 1.6),
            ),
          ],
          if (fullExplanation.isNotEmpty) ...[
            const SizedBox(height: AppTokens.sp3),
            Text(
              fullExplanation,
              style: AppText.body.copyWith(color: c.textSub, height: 1.6),
            ),
          ],
        ],
      ),
    );
  }
}
