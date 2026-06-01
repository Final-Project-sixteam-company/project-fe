// lib/screens/scenario_library_screen.dart
import 'package:flutter/material.dart';
import '../components/filter_chip_widget.dart';
import '../components/ms_button.dart';
import '../components/ms_kicker.dart';
import '../components/ms_pill.dart';
import '../components/ms_text_field.dart';
import '../components/states.dart';
import '../models/scenario.dart';
import '../repositories/scenario_repository.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import 'scenario_detail_screen.dart';

enum _LibraryTab {
  all,
  official,
  custom,
  popular,
  newest,
  easy,
  medium,
  hard,
}

extension _LibraryTabX on _LibraryTab {
  String get label => switch (this) {
    _LibraryTab.all => '전체',
    _LibraryTab.official => '공식',
    _LibraryTab.custom => '커스텀',
    _LibraryTab.popular => '인기',
    _LibraryTab.newest => '최신',
    _LibraryTab.easy => '쉬움',
    _LibraryTab.medium => '보통',
    _LibraryTab.hard => '어려움',
  };

  ScenarioFilter toFilter(String query) => switch (this) {
    _LibraryTab.all => ScenarioFilter(query: query),
    _LibraryTab.official =>
        ScenarioFilter(type: ScenarioType.official, query: query),
    _LibraryTab.custom =>
        ScenarioFilter(type: ScenarioType.custom, query: query),
    _LibraryTab.popular =>
        ScenarioFilter(sort: ScenarioSort.popular, query: query),
    _LibraryTab.newest =>
        ScenarioFilter(sort: ScenarioSort.newest, query: query),
    _LibraryTab.easy =>
        ScenarioFilter(difficulty: Difficulty.easy, query: query),
    _LibraryTab.medium =>
        ScenarioFilter(difficulty: Difficulty.medium, query: query),
    _LibraryTab.hard =>
        ScenarioFilter(difficulty: Difficulty.hard, query: query),
  };
}

class ScenarioLibraryScreen extends StatefulWidget {
  const ScenarioLibraryScreen({super.key});

  @override
  State<ScenarioLibraryScreen> createState() => _ScenarioLibraryScreenState();
}

class _ScenarioLibraryScreenState extends State<ScenarioLibraryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  _LibraryTab _tab = _LibraryTab.all;
  String _query = '';

  // ── 비동기 상태 ──────────────────────────────────────────────────────────
  List<Scenario> _results = const [];
  bool _isLoading = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final capturedTab = _tab;
    final capturedQuery = _query;
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final data = await scenarioRepo.query(capturedTab.toFilter(capturedQuery));
      if (!mounted || _tab != capturedTab || _query != capturedQuery) return;
      setState(() => _results = data);
    } catch (e) {
      if (!mounted || _tab != capturedTab || _query != capturedQuery) return;
      setState(() => _errorMsg = '목록을 불러오지 못했습니다.');
    } finally {
      if (mounted && _tab == capturedTab && _query == capturedQuery) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onTabChanged(_LibraryTab tab) {
    setState(() => _tab = tab);
    _load();
  }

  void _onQueryChanged(String v) {
    setState(() => _query = v.trim());
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 헤더 + 검색 + 필터 ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.sp4,
                AppTokens.sp4,
                AppTokens.sp4,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '시나리오 라이브러리',
                    style: AppText.titleL.copyWith(color: c.text),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'MYSTERY LIBRARY',
                    style: AppText.monoLabel.copyWith(color: c.textMute),
                  ),
                  const SizedBox(height: AppTokens.sp4),
                  MSTextField(
                    controller: _searchCtrl,
                    hintText: '사건명, 태그, 제작자 검색…',
                    suffixIcon: Icons.search,
                    onChanged: _onQueryChanged,
                  ),
                  const SizedBox(height: AppTokens.sp3),
                  // ── 필터 칩 ────────────────────────────────────────────
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _LibraryTab.values.map((tab) {
                        return Padding(
                          padding: EdgeInsets.only(
                            right: tab != _LibraryTab.values.last
                                ? AppTokens.sp2
                                : 0,
                          ),
                          child: MSFilterChip(
                            label: tab.label,
                            active: _tab == tab,
                            onTap: () => _onTabChanged(tab),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppTokens.sp4),
                  // ── 카운트 행 ──────────────────────────────────────────
                  Row(
                    children: [
                      const MSKicker('사건 목록'),
                      const SizedBox(width: AppTokens.sp2),
                      if (!_isLoading)
                        Text(
                          '${_results.length}건',
                          style: AppText.monoLabel.copyWith(
                            color: c.textMute,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.sp3),
                ],
              ),
            ),
            // ── 본문 ─────────────────────────────────────────────────────
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    // 로딩 중
    if (_isLoading) {
      return const Center(child: MSSpinner(size: 24));
    }

    // 에러
    if (_errorMsg != null) {
      return MSEmpty(
        icon: Icons.wifi_off_outlined,
        title: _errorMsg!,
        action: MSButton(
          label: '다시 시도',
          variant: MSButtonVariant.secondary,
          onPressed: _load,
        ),
      );
    }

    // 결과 없음
    if (_results.isEmpty) {
      return const MSEmpty(
        icon: Icons.search_off,
        title: '일치하는 사건이 없습니다',
      );
    }

    // 목록
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppTokens.sp4,
        0,
        AppTokens.sp4,
        AppTokens.sp10,
      ),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppTokens.sp3),
      itemBuilder: (_, i) => _ScenarioRow(
        scenario: _results[i],
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ScenarioDetailScreen(scenario: _results[i]),
          ),
        ),
      ),
    );
  }
}

// ── 시나리오 카드 ─────────────────────────────────────────────────────────────

class _ScenarioRow extends StatelessWidget {
  const _ScenarioRow({required this.scenario, required this.onTap});

  final Scenario scenario;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Material(
      color: c.bgElev,
      borderRadius: BorderRadius.circular(AppTokens.r4),
      child: InkWell(
        onTap: onTap,
        splashColor: c.primary.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(AppTokens.r4),
        child: Container(
          padding: const EdgeInsets.all(AppTokens.sp3),
          decoration: BoxDecoration(
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(AppTokens.r4),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CodeThumb(scenario: scenario),
              const SizedBox(width: AppTokens.sp3),
              Expanded(child: _ScenarioMeta(scenario: scenario)),
              const SizedBox(width: AppTokens.sp3),
              _ScenarioStats(scenario: scenario),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeThumb extends StatelessWidget {
  const _CodeThumb({required this.scenario});

  final Scenario scenario;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Container(
      width: 48,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: scenario.type == ScenarioType.official
              ? [c.bgHover, c.primarySoft]
              : [c.bgHover, c.successSoft],
        ),
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppTokens.r3),
      ),
      alignment: Alignment.center,
      child: Text(
        scenario.code,
        style: AppText.monoLabel.copyWith(
          fontSize: 8,
          color: c.primary,
          height: 1.2,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ScenarioMeta extends StatelessWidget {
  const _ScenarioMeta({required this.scenario});

  final Scenario scenario;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            MSPill(
              scenario.difficultyLabel,
              tone: switch (scenario.difficulty) {
                Difficulty.easy => MSPillTone.success,
                Difficulty.medium => MSPillTone.primary,
                Difficulty.hard => MSPillTone.danger,
              },
            ),
            const SizedBox(width: AppTokens.sp2),
            Text(
              '${scenario.estimatedMinutes}분 · 용의자 ${scenario.suspectsCount}명',
              style: AppText.monoLabel.copyWith(
                fontSize: 9.5,
                color: c.textMute,
                height: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          scenario.title,
          style: AppText.body.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: c.text,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 5),
        Wrap(
          spacing: AppTokens.sp1,
          runSpacing: AppTokens.sp1,
          children: scenario.tags.take(3).map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: c.bgHover,
                borderRadius: BorderRadius.circular(AppTokens.r1),
              ),
              child: Text(
                '#$tag',
                style: AppText.monoLabel.copyWith(
                  fontSize: 9,
                  color: c.textMute,
                  height: 1.0,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ScenarioStats extends StatelessWidget {
  const _ScenarioStats({required this.scenario});

  final Scenario scenario;

  String _formatPlays(int p) {
    if (p >= 1000) return '${(p / 1000).toStringAsFixed(1)}k';
    return p.toString();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '★ ${scenario.rating}',
          style: AppText.monoLabel.copyWith(color: c.primary, height: 1.0),
        ),
        const SizedBox(height: AppTokens.sp1),
        Text(
          _formatPlays(scenario.plays),
          style: AppText.monoLabel.copyWith(
            fontSize: 9.5,
            color: c.textMute,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}