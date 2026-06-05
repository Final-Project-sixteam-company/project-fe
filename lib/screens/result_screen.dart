import 'package:flutter/material.dart';
import '../components/ms_button.dart';
import '../components/ms_kicker.dart';
import '../components/ms_pill.dart';
import '../components/review_write_sheet.dart';
import '../components/states.dart';
import '../core/api/api_exception.dart';
import '../models/play_models.dart';
import '../models/review_models.dart';
import '../repositories/play_session_repository.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

// ── 화면 ──────────────────────────────────────────────────────────────────────

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    required this.sessionId,
    this.scenarioId,
    super.key,
  });

  /// 서버 플레이 세션 ID. 서버에서 채점 결과를 조회한다.
  /// null이면 정답/해설을 노출하지 않고 오류 상태를 보여준다(스포일러 방지).
  final int? sessionId;

  /// 리뷰 작성 진입을 위한 시나리오 ID(완료 후 진입점). 없으면 리뷰 버튼 숨김.
  final String? scenarioId;

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

  // P0-1: 채점이 아직 끝나지 않았을 때(404/AI015/네트워크 지연) 잠시 후 재조회(폴링).
  static const int _maxResultPollAttempts = 5;
  static const Duration _resultPollInterval = Duration(seconds: 3);

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
      // 세션 ID가 없으면 채점 결과를 알 수 없다. 과거엔 샘플(정답/해설 포함)을
      // 노출했으나 스포일러가 되므로 오류 상태만 보여준다.
      _error = '결과 정보를 불러올 수 없습니다.';
    }
  }

  Future<void> _fetchResult(int sessionId, {int attempt = 0}) async {
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
      // 채점 미완료(404)·채점 진행 중(AI015)·네트워크 지연이면 잠시 후 재시도(폴링).
      final notReady = e.isNetwork || e.status == 404 || e.code == 'AI015';
      if (notReady && attempt < _maxResultPollAttempts) {
        await Future.delayed(_resultPollInterval);
        if (mounted) await _fetchResult(sessionId, attempt: attempt + 1);
        return;
      }
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

  Future<void> _writeReview(BuildContext context, String scenarioId) async {
    final review = await showReviewWriteSheet(context, scenarioId: scenarioId);
    if (review == null || !mounted) return;
    sampleReviews.insert(0, review);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('리뷰가 등록되었습니다. 감사합니다!')),
    );
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
            label: '다시 시도',
            variant: MSButtonVariant.primary,
            onPressed: widget.sessionId != null
                ? () => _fetchResult(widget.sessionId!)
                : null,
          ),
          secondaryAction: MSButton(
            label: '홈으로 돌아가기',
            variant: MSButtonVariant.ghost,
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ),
      );
    }

    final data = _data;
    // 데이터도 오류도 없는 상태(이론상 도달하지 않음) — 정답 노출 대신 안내.
    if (data == null) {
      return Padding(
        padding: const EdgeInsets.all(AppTokens.sp4),
        child: MSEmpty(
          icon: Icons.inbox_outlined,
          title: '결과 정보가 없습니다',
          subtitle: '채점 결과를 확인할 수 없습니다.',
          action: MSButton(
            label: '홈으로 돌아가기',
            variant: MSButtonVariant.primary,
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ),
      );
    }
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
                grade: data.grade,
                totalScore: data.score,
              ),
            ),
          ),
          const SizedBox(height: AppTokens.sp8),
          ..._buildServerSections(context, data),
          const SizedBox(height: AppTokens.sp8),
          // ── 하단 액션 ───────────────────────────────────────────
          // 리뷰 작성 진입점 — 플레이를 마친 지금 시점에 노출(상세에서 이전).
          if (widget.scenarioId != null) ...[
            MSButton(
              label: '이 사건 리뷰 작성하기',
              variant: MSButtonVariant.secondary,
              expanded: true,
              icon: Icons.rate_review_outlined,
              onPressed: () => _writeReview(context, widget.scenarioId!),
            ),
            const SizedBox(height: AppTokens.sp3),
          ],
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
      // 등급/점수 직후 가장 읽고 싶은 '사건의 진상·해설'을 먼저 노출하고,
      // 상세 채점표(매칭/맞춘·놓친 추리)는 그 아래로 배치한다.
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
      const SizedBox(height: AppTokens.sp8),
      const MSKicker('추리 채점 결과'),
      const SizedBox(height: AppTokens.sp3),
      _MatchCard(matched: data.matched),
      if (data.matchedParts.isNotEmpty || data.missedParts.isNotEmpty) ...[
        const SizedBox(height: AppTokens.sp8),
        const MSKicker('맞춘 추리 · 놓친 추리'),
        const SizedBox(height: AppTokens.sp3),
        _PartsCard(matched: data.matchedParts, missed: data.missedParts),
      ],
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
        '사건 종결 · 최종 판정',
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

// ── 맞춘/놓친 추리 카드 (서버) ────────────────────────────────────────────────

class _PartsCard extends StatelessWidget {
  const _PartsCard({required this.matched, required this.missed});

  final List<String> matched;
  final List<String> missed;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final part in matched) _PartRow(text: part, matched: true),
          for (final part in missed) _PartRow(text: part, matched: false),
        ],
      ),
    );
  }
}

class _PartRow extends StatelessWidget {
  const _PartRow({required this.text, required this.matched});

  final String text;
  final bool matched;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            matched ? Icons.check_circle : Icons.cancel_outlined,
            size: 18,
            color: matched ? c.success : c.danger,
          ),
          const SizedBox(width: AppTokens.sp3),
          Expanded(
            child: Text(
              text,
              style: AppText.body.copyWith(
                color: matched ? c.text : c.textSub,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 점수 카드 (레거시 샘플) ───────────────────────────────────────────────────

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
