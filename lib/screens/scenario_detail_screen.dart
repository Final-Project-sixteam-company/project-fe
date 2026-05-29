// lib/screens/scenario_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/ms_button.dart';
import '../components/ms_kicker.dart';
import '../components/ms_pill.dart';
import '../models/review_models.dart';
import '../models/scenario.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import 'case_briefing_screen.dart';

const _kPlayableIds = {'demoday-eve'};
const _kBookmarkPrefix = 'bookmark_';

class ScenarioDetailScreen extends StatefulWidget {
  const ScenarioDetailScreen({required this.scenario, super.key});

  final Scenario scenario;

  @override
  State<ScenarioDetailScreen> createState() =>
      _ScenarioDetailScreenState();
}

class _ScenarioDetailScreenState
    extends State<ScenarioDetailScreen> {
  bool _bookmarked = false;
  bool get _isPlayable => _kPlayableIds.contains(widget.scenario.id);

  @override
  void initState() {
    super.initState();
    _loadBookmark();
  }

  Future<void> _loadBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    final saved =
        prefs.getBool('$_kBookmarkPrefix${widget.scenario.id}') ?? false;
    if (mounted) setState(() => _bookmarked = saved);
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
    final s = widget.scenario;
    final reviews = sampleReviews
        .where((r) => r.scenarioId == s.id)
        .toList();

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
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
      bottomNavigationBar: _BottomCta(
        bookmarked: _bookmarked,
        scenario: s,
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
            _HeroArt(scenario: s),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.sp4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppTokens.sp4),
                  Row(
                    children: [
                      if (s.type == ScenarioType.official)
                        const MSPill('공식', tone: MSPillTone.danger),
                      const SizedBox(width: AppTokens.sp2),
                      MSPill(
                        s.difficultyLabel,
                        tone: switch (s.difficulty) {
                          Difficulty.easy => MSPillTone.success,
                          Difficulty.medium => MSPillTone.primary,
                          Difficulty.hard => MSPillTone.danger,
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.sp3),
                  Text(
                    s.title,
                    style: AppText.titleL.copyWith(color: c.text),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${s.subtitle} · ${s.code}',
                    style: AppText.monoLabel.copyWith(
                        color: c.textMute),
                  ),
                  const SizedBox(height: AppTokens.sp6),
                  _MetaGrid(scenario: s),
                  const SizedBox(height: AppTokens.sp6),
                  const MSKicker('시놉시스 · SYNOPSIS'),
                  const SizedBox(height: AppTokens.sp3),
                  Text(
                    s.synopsis,
                    style: AppText.body
                        .copyWith(color: c.textSub, height: 1.7),
                  ),
                  const SizedBox(height: AppTokens.sp6),
                  const MSKicker('태그'),
                  const SizedBox(height: AppTokens.sp3),
                  Wrap(
                    spacing: AppTokens.sp2,
                    runSpacing: AppTokens.sp2,
                    children: s.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          border: Border.all(color: c.line),
                          borderRadius:
                              BorderRadius.circular(AppTokens.rPill),
                        ),
                        child: Text(
                          '#$tag',
                          style: AppText.monoLabel.copyWith(
                            color: c.textSub,
                            height: 1.0,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppTokens.sp6),
                  const MSKicker('평점 · REVIEWS'),
                  const SizedBox(height: AppTokens.sp3),
                  _RatingSection(scenario: s),
                  const SizedBox(height: AppTokens.sp4),
                  // ── 리뷰 목록 ──────────────────────────────────
                  if (reviews.isNotEmpty) ...[
                    ...reviews.map(
                      (r) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppTokens.sp3),
                        child: _ReviewCard(review: r),
                      ),
                    ),
                  ],
                  // ── 리뷰 작성 버튼 ──────────────────────────────
                  MSButton(
                    label: '리뷰 작성하기',
                    variant: MSButtonVariant.secondary,
                    expanded: true,
                    icon: Icons.rate_review_outlined,
                    onPressed: () => _showReviewSheet(context),
                  ),
                  const SizedBox(height: AppTokens.sp10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReviewWriteSheet(scenarioId: widget.scenario.id),
    );
  }
}

// ── 리뷰 카드 ─────────────────────────────────────────────────────────────────

class _ReviewCard extends StatefulWidget {
  const _ReviewCard({required this.review});

  final ScenarioReview review;

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  bool _spoilerRevealed = false;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final r = widget.review;

    return Container(
      padding: const EdgeInsets.all(AppTokens.sp3),
      decoration: BoxDecoration(
        color: c.bgElev,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppTokens.r4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                r.authorName,
                style: AppText.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: c.text,
                ),
              ),
              const Spacer(),
              Text(
                '★ ${r.rating.toStringAsFixed(1)}',
                style: AppText.monoLabel.copyWith(color: c.primary),
              ),
              const SizedBox(width: AppTokens.sp3),
              Text(
                '${r.createdAt.month}.${r.createdAt.day}',
                style: AppText.monoLabel.copyWith(
                  fontSize: 9.5,
                  color: c.textMute,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.sp2),
          if (r.isSpoiler && !_spoilerRevealed)
            GestureDetector(
              onTap: () => setState(() => _spoilerRevealed = true),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.sp3,
                  vertical: AppTokens.sp2,
                ),
                decoration: BoxDecoration(
                  color: c.dangerSoft,
                  border: Border.all(color: c.danger),
                  borderRadius: BorderRadius.circular(AppTokens.r2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_outlined,
                        size: 14, color: c.danger),
                    const SizedBox(width: AppTokens.sp2),
                    Text(
                      '스포일러 포함 — 탭하면 공개',
                      style: AppText.bodySm
                          .copyWith(color: c.danger),
                    ),
                  ],
                ),
              ),
            )
          else
            Text(
              r.body,
              style: AppText.body
                  .copyWith(color: c.textSub, height: 1.6),
            ),
        ],
      ),
    );
  }
}

// ── 리뷰 작성 시트 ────────────────────────────────────────────────────────────

class _ReviewWriteSheet extends StatefulWidget {
  const _ReviewWriteSheet({required this.scenarioId});

  final String scenarioId;

  @override
  State<_ReviewWriteSheet> createState() => _ReviewWriteSheetState();
}

class _ReviewWriteSheetState extends State<_ReviewWriteSheet> {
  double _rating = 5.0;
  final TextEditingController _bodyCtrl = TextEditingController();
  bool _isSpoiler = false;

  @override
  void dispose() {
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: c.bgElev,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppTokens.r6),
            topRight: Radius.circular(AppTokens.r6),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.sp4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin:
                        const EdgeInsets.only(bottom: AppTokens.sp4),
                    decoration: BoxDecoration(
                      color: c.line,
                      borderRadius:
                          BorderRadius.circular(AppTokens.rPill),
                    ),
                  ),
                ),
                Text(
                  '리뷰 작성',
                  style: AppText.titleM.copyWith(color: c.text),
                ),
                const SizedBox(height: AppTokens.sp4),
                // 별점 슬라이더
                Row(
                  children: [
                    Text(
                      '평점',
                      style: AppText.body.copyWith(color: c.textSub),
                    ),
                    const Spacer(),
                    Text(
                      '★ ${_rating.toStringAsFixed(1)}',
                      style: AppText.monoNum.copyWith(
                        fontSize: 16,
                        color: c.primary,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _rating,
                  min: 1.0,
                  max: 5.0,
                  divisions: 8,
                  activeColor: c.primary,
                  inactiveColor: c.bgHover,
                  onChanged: (v) => setState(() => _rating = v),
                ),
                const SizedBox(height: AppTokens.sp3),
                // 리뷰 본문
                Container(
                  decoration: BoxDecoration(
                    color: c.bg,
                    border: Border.all(color: c.line),
                    borderRadius: BorderRadius.circular(AppTokens.r3),
                  ),
                  child: TextField(
                    controller: _bodyCtrl,
                    maxLines: 4,
                    style: AppText.body.copyWith(color: c.text),
                    cursorColor: c.primary,
                    decoration: InputDecoration(
                      hintText: '이 사건은 어떠셨나요?',
                      hintStyle: AppText.body.copyWith(color: c.textMute),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.all(AppTokens.sp3),
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.sp3),
                // 스포일러 토글
                Row(
                  children: [
                    Switch(
                      value: _isSpoiler,
                      activeThumbColor: c.danger,
                      onChanged: (v) =>
                          setState(() => _isSpoiler = v),
                    ),
                    const SizedBox(width: AppTokens.sp2),
                    Text(
                      '스포일러 포함',
                      style: AppText.body.copyWith(
                        color: _isSpoiler ? c.danger : c.textSub,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.sp4),
                MSButton(
                  label: '리뷰 등록',
                  variant: MSButtonVariant.primary,
                  expanded: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 히어로 영역 ───────────────────────────────────────────────────────────────

class _HeroArt extends StatelessWidget {
  const _HeroArt({required this.scenario});

  final Scenario scenario;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.ink900,
              AppColors.tealBase.withValues(alpha: .6)
            ],
            stops: const [0.3, 1.0],
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          scenario.code,
          style: AppText.monoNum.copyWith(
            fontSize: 36,
            color: c.primary.withValues(alpha: .3),
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

// ── 메타 그리드 ───────────────────────────────────────────────────────────────

class _MetaGrid extends StatelessWidget {
  const _MetaGrid({required this.scenario});

  final Scenario scenario;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    final cells = [
      ('난이도', scenario.difficultyLabel),
      ('플레이시간', '${scenario.estimatedMinutes}분'),
      ('용의자', '${scenario.suspectsCount}명'),
      ('증거', '${scenario.evidenceCount}개'),
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppTokens.r4),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: cells.asMap().entries.map((e) {
            final isLast = e.key == cells.length - 1;
            return Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: AppTokens.sp3,
                  horizontal: AppTokens.sp2,
                ),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(right: BorderSide(color: c.line)),
                ),
                child: Column(
                  children: [
                    Text(
                      e.value.$1.toUpperCase(),
                      style: AppText.monoLabel.copyWith(
                        fontSize: 9,
                        color: c.textMute,
                        height: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTokens.sp1),
                    Text(
                      e.value.$2,
                      style: AppText.monoNum.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.text,
                        height: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── 평점 섹션 ─────────────────────────────────────────────────────────────────

class _RatingSection extends StatelessWidget {
  const _RatingSection({required this.scenario});

  final Scenario scenario;

  String _formatPlays(int p) {
    if (p >= 1000) return '${(p / 1000).toStringAsFixed(1)}k ';
    return '$p ';
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            children: [
              Text(
                scenario.rating.toStringAsFixed(1),
                style: AppText.monoNum.copyWith(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: c.primary,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: AppTokens.sp1),
              Text(
                '${_formatPlays(scenario.plays)}플레이',
                style: AppText.monoLabel.copyWith(
                  fontSize: 9.5,
                  color: c.textMute,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppTokens.sp6),
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final ratio = star == 5
                    ? 0.68
                    : star == 4
                        ? 0.22
                        : star == 3
                            ? 0.07
                            : 0.02;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTokens.sp1,
                  ),
                  child: Row(
                    children: [
                      Text(
                        '$star',
                        style: AppText.monoLabel.copyWith(
                          fontSize: 9.5,
                          color: c.textMute,
                        ),
                      ),
                      const SizedBox(width: AppTokens.sp2),
                      Expanded(
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppTokens.r1),
                          child: SizedBox(
                            height: 6,
                            child: LayoutBuilder(
                              builder: (ctx, constraints) => Stack(
                                children: [
                                  Positioned.fill(
                                    child:
                                        ColoredBox(color: c.bgHover),
                                  ),
                                  Positioned(
                                    left: 0,
                                    top: 0,
                                    bottom: 0,
                                    width:
                                        constraints.maxWidth * ratio,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: c.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 하단 CTA ─────────────────────────────────────────────────────────────────

class _BottomCta extends StatelessWidget {
  const _BottomCta({
    required this.scenario,
    required this.bookmarked,
    required this.isPlayable,
    required this.onBookmark,
    required this.onStart,
  });

  final Scenario scenario;
  final bool bookmarked;
  final bool isPlayable;
  final VoidCallback onBookmark;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.sp4,
          vertical: AppTokens.sp3,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isPlayable) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: AppTokens.sp2,
                  horizontal: AppTokens.sp3,
                ),
                decoration: BoxDecoration(
                  color: c.bgHover,
                  border: Border.all(color: c.line),
                  borderRadius: BorderRadius.circular(AppTokens.r3),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.construction_outlined,
                      size: 14,
                      color: c.textMute,
                    ),
                    const SizedBox(width: AppTokens.sp2),
                    Expanded(
                      child: Text(
                        '${scenario.code} 시나리오 데이터가 준비 중입니다. '
                        'CL-001만 현재 플레이 가능합니다.',
                        style: AppText.bodySm.copyWith(
                          fontSize: 12,
                          color: c.textMute,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.sp2),
            ],
            Row(
              children: [
                MSButton(
                  label: '',
                  variant: bookmarked
                      ? MSButtonVariant.primary
                      : MSButtonVariant.secondary,
                  icon: bookmarked
                      ? Icons.bookmark
                      : Icons.bookmark_outline,
                  onPressed: onBookmark,
                ),
                const SizedBox(width: AppTokens.sp3),
                Expanded(
                  child: MSButton(
                    label: isPlayable ? '조사 시작' : '준비 중',
                    variant: MSButtonVariant.primary,
                    expanded: true,
                    icon: isPlayable
                        ? Icons.play_arrow
                        : Icons.lock_clock_outlined,
                    onPressed: onStart,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
