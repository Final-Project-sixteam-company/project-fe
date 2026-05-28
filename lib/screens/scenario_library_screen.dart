// lib/screens/scenario_library_screen.dart
import 'package:flutter/material.dart';
import '../components/ms_kicker.dart';
import '../components/ms_pill.dart';
import '../components/ms_text_field.dart';
import '../components/states.dart';
import '../models/scenario.dart';
import '../models/sample_scenarios.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import 'scenario_detail_screen.dart';

enum _LibraryFilter {
  all, official, custom, popular, newest, easy, medium, hard
}

extension _LibraryFilterLabel on _LibraryFilter {
  String get label => switch (this) {
    _LibraryFilter.all => '전체',
    _LibraryFilter.official => '공식',
    _LibraryFilter.custom => '커스텀',
    _LibraryFilter.popular => '인기',
    _LibraryFilter.newest => '최신',
    _LibraryFilter.easy => '쉬움',
    _LibraryFilter.medium => '보통',
    _LibraryFilter.hard => '어려움',
  };
}

class ScenarioLibraryScreen extends StatefulWidget {
  const ScenarioLibraryScreen({super.key});

  @override
  State<ScenarioLibraryScreen> createState() => _ScenarioLibraryScreenState();
}

class _ScenarioLibraryScreenState extends State<ScenarioLibraryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  _LibraryFilter _filter = _LibraryFilter.all;
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Scenario> get _filtered {
    var list = List<Scenario>.from(sampleScenarios);

    if (_query.isNotEmpty) {
      list = list.where((s) =>
      s.title.contains(_query) ||
          s.tags.any((t) => t.contains(_query)) ||
          (s.author?.contains(_query) ?? false)
      ).toList();
    }

    list = switch (_filter) {
      _LibraryFilter.official => list.where((s) => s.type == ScenarioType.official).toList(),
      _LibraryFilter.custom => list.where((s) => s.type == ScenarioType.custom).toList(),
      _LibraryFilter.popular => list..sort((a, b) => b.plays.compareTo(a.plays)),
    // code 내림차순(예: CL-006 → CL-001)으로 최신 등록 순 정렬.
    // 추후 createdAt 필드 추가 시 해당 필드로 교체 예정.
      _LibraryFilter.newest => list..sort((a, b) => b.code.compareTo(a.code)),
      _LibraryFilter.easy => list.where((s) => s.difficulty == Difficulty.easy).toList(),
      _LibraryFilter.medium => list.where((s) => s.difficulty == Difficulty.medium).toList(),
      _LibraryFilter.hard => list.where((s) => s.difficulty == Difficulty.hard).toList(),
      _LibraryFilter.all => list,
    };

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final results = _filtered;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppTokens.sp4, AppTokens.sp4, AppTokens.sp4, 0),
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
                    onChanged: (v) => setState(() => _query = v.trim()),
                  ),
                  const SizedBox(height: AppTokens.sp3),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _LibraryFilter.values.map((f) {
                        final bool active = _filter == f;
                        return Padding(
                          padding: EdgeInsets.only(
                            right: f != _LibraryFilter.values.last
                                ? AppTokens.sp2
                                : 0,
                          ),
                          child: _FilterChip(
                            label: f.label,
                            active: active,
                            onTap: () => setState(() => _filter = f),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppTokens.sp4),
                  const MSKicker('사건 목록'),
                  const SizedBox(height: AppTokens.sp3),
                ],
              ),
            ),
            Expanded(
              child: results.isEmpty
                  ? const MSEmpty(
                icon: Icons.search_off,
                title: '일치하는 사건이 없습니다',
              )
                  : ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                    AppTokens.sp4, 0, AppTokens.sp4, AppTokens.sp10),
                itemCount: results.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: AppTokens.sp3),
                itemBuilder: (_, i) => _ScenarioRow(
                  scenario: results[i],
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ScenarioDetailScreen(scenario: results[i]),
                    ),
                  ),
                ),
              ),
            ),
          ],
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
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '★ ${scenario.rating}',
          style: AppText.monoLabel.copyWith(
            color: c.primary,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
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

  String _formatPlays(int p) {
    if (p >= 1000) return '${(p / 1000).toStringAsFixed(1)}k';
    return p.toString();
  }
}

// ── 필터 칩 ───────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.dur2,
        curve: AppMotion.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? c.primarySoft : Colors.transparent,
          border: Border.all(color: active ? c.primary : c.line),
          borderRadius: BorderRadius.circular(AppTokens.rPill),
        ),
        child: Text(
          label,
          style: AppText.monoLabel.copyWith(
            color: active ? c.primary : c.textSub,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}