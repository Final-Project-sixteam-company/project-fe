// lib/screens/scenario_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/review_write_sheet.dart';
import '../models/review_models.dart';
import '../models/scenario.dart';
import '../repositories/scenario_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import 'case_briefing_screen.dart';
import 'scenario_detail_widgets.dart';

const _kBookmarkPrefix = 'bookmark_';

class ScenarioDetailScreen extends StatefulWidget {
  const ScenarioDetailScreen({required this.scenario, super.key});
  final Scenario scenario;

  @override
  State<ScenarioDetailScreen> createState() => _ScenarioDetailScreenState();
}

class _ScenarioDetailScreenState extends State<ScenarioDetailScreen> {
  bool _bookmarked = false;
  bool _isLoading = false;
  late Scenario _detailedScenario; // 전체 상세 데이터를 담을 변수

  /// API Spec §6.1, §6.2 — 서버 canPlay 값 사용. 상세 로딩 완료 전에는 false.
  bool get _isPlayable => _detailedScenario.canPlay;

  @override
  void initState() {
    super.initState();
    _detailedScenario = widget.scenario;
    _loadBookmark();
    _loadFullDetail();
  }

  Future<void> _loadBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    final saved =
        prefs.getBool('$_kBookmarkPrefix${widget.scenario.id}') ?? false;
    if (mounted) setState(() => _bookmarked = saved);
  }

  Future<void> _loadFullDetail() async {
    setState(() => _isLoading = true);
    try {
      final fullScenario = await scenarioRepo.detail(widget.scenario.id);

      if (mounted) {
        setState(() {
          _detailedScenario = fullScenario; // 풀 데이터로 교체
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      // 에러 발생 시 로그를 남기고, UI는 initState에서 세팅한 요약본으로 유지합니다.
      debugPrint('시나리오 상세 로딩 실패: $e');
    }
  }

  Future<void> _toggleBookmark() async {
    final next = !_bookmarked;
    setState(() => _bookmarked = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_kBookmarkPrefix${widget.scenario.id}', next);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    final s = _detailedScenario;
    final reviews = sampleReviews.where((r) => r.scenarioId == s.id).toList();

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _bookmarked ? Icons.bookmark : Icons.bookmark_outline,
              color: _bookmarked ? c.primary : c.textSub,
            ),
            onPressed: _toggleBookmark,
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: c.textSub),
            onPressed: () {},
          ),
        ],
      ),
      bottomNavigationBar: ScenarioBottomCta(
        scenario: s,
        bookmarked: _bookmarked,
        isPlayable: _isPlayable,
        onBookmark: _toggleBookmark,
        onStart: _isPlayable
            ? () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CaseBriefingScreen(scenario: s),
                ),
              )
            : null,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScenarioHeroArt(scenario: s),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.sp4),
              child: _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppTokens.sp10),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _DetailBody(
                      scenario: s,
                      reviews: reviews,
                      bookmarked: _bookmarked,
                      onToggleBookmark: _toggleBookmark,
                      onShowReview: () => _showReviewSheet(context),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReviewSheet(BuildContext context) async {
    final review = await showModalBottomSheet<ScenarioReview>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (_) => ReviewWriteSheet(scenarioId: widget.scenario.id),
    );
    if (review != null && mounted) {
      setState(() => sampleReviews.insert(0, review));
    }
  }
}

// ── 상세 본문 (분리 위젯) ─────────────────────────────────────────────────────

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.scenario,
    required this.reviews,
    required this.bookmarked,
    required this.onToggleBookmark,
    required this.onShowReview,
  });
  final Scenario scenario;
  final List<ScenarioReview> reviews;
  final bool bookmarked;
  final VoidCallback onToggleBookmark;
  final VoidCallback onShowReview;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = scenario;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppTokens.sp4),
        ScenarioTypeBadgeRow(scenario: s),
        const SizedBox(height: AppTokens.sp3),
        Text(s.title, style: AppText.titleL.copyWith(color: c.text)),
        const SizedBox(height: AppTokens.sp1),
        Text(
          '${s.subtitle} · ${s.code}',
          style: AppText.monoLabel.copyWith(color: c.textMute),
        ),
        const SizedBox(height: AppTokens.sp6),
        ScenarioMetaGrid(scenario: s),
        const SizedBox(height: AppTokens.sp6),
        ScenarioSynopsisSection(scenario: s),
        const SizedBox(height: AppTokens.sp6),
        ScenarioTagsSection(scenario: s),
        const SizedBox(height: AppTokens.sp6),
        ScenarioReviewsSection(
          scenario: s,
          reviews: reviews,
          onShowReview: onShowReview,
        ),
        const SizedBox(height: AppTokens.sp10),
      ],
    );
  }
}
