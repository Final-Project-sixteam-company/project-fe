// lib/screens/my_records_screen.dart
import 'package:flutter/material.dart';
import '../components/ms_kicker.dart';
import '../components/ms_stat_row.dart';
import '../components/states.dart';
import '../models/scenario.dart';
import '../models/sample_scenarios.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

enum _RecordsFilter { all, completed, inProgress, mine }

extension _RecordsFilterLabel on _RecordsFilter {
  String get label => switch (this) {
    _RecordsFilter.all => '전체',
    _RecordsFilter.completed => '완료',
    _RecordsFilter.inProgress => '진행 중',
    _RecordsFilter.mine => '내 시나리오',
  };
}

class MyRecordsScreen extends StatefulWidget {
  const MyRecordsScreen({super.key});

  @override
  State<MyRecordsScreen> createState() => _MyRecordsScreenState();
}

class _MyRecordsScreenState extends State<MyRecordsScreen> {
  _RecordsFilter _filter = _RecordsFilter.all;

  // ── 통계 (세션 데이터에서 직접 파생) ───────────────────────────────────────

  List<PlaySession> get _completedSessions =>
      samplePlaySessions.where((s) => s.state == PlayState.completed).toList();

  int get _solvedCount => _completedSessions.length;

  /// 완료 세션 중 score가 있는 항목의 평균. 없으면 '--'.
  String get _avgAccuracy {
    final scores = _completedSessions
        .map((s) => s.score)
        .whereType<int>()
        .toList();
    if (scores.isEmpty) return '--';
    final avg = scores.reduce((a, b) => a + b) / scores.length;
    return '${avg.round()}%';
  }

  List<PlaySession> get _filtered => switch (_filter) {
    _RecordsFilter.completed => _completedSessions,
    _RecordsFilter.inProgress =>
        samplePlaySessions.where((s) => s.state == PlayState.inProgress).toList(),
  // 현재 유저가 제작한 시나리오 세션이 없으므로 빈 목록 반환.
  // 추후 authored scenario IDs와 교차 필터링으로 교체 예정.
    _RecordsFilter.mine => const [],
    _RecordsFilter.all => samplePlaySessions,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final sessions = _filtered;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.sp4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppTokens.sp4),
              Text(
                '내 기록',
                style: AppText.titleL.copyWith(color: c.text),
              ),
              const SizedBox(height: 2),
              Text(
                'DETECTIVE FILE',
                style: AppText.monoLabel.copyWith(color: c.textMute),
              ),
              const SizedBox(height: AppTokens.sp4),
              // ── 탐정 등급 카드 ───────────────────────────────────
              _DetectiveGradeCard(),
              const SizedBox(height: AppTokens.sp4),
              // ── 통계 ────────────────────────────────────────────
              MSStatRow([
                StatCell('해결 사건', '$_solvedCount건', tone: StatTone.good),
                StatCell('평균 정답률', _avgAccuracy, tone: StatTone.good),
                const StatCell('제작 수', '0개'),
              ]),
              const SizedBox(height: AppTokens.sp6),
              // ── 탭 필터 ─────────────────────────────────────────
              const MSKicker('기록 목록'),
              const SizedBox(height: AppTokens.sp3),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _RecordsFilter.values.map((f) {
                    final bool active = _filter == f;
                    return Padding(
                      padding: EdgeInsets.only(
                        right: f != _RecordsFilter.values.last
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
              const SizedBox(height: AppTokens.sp3),
              // ── 기록 목록 ────────────────────────────────────────
              if (sessions.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: AppTokens.sp8),
                  child: MSEmpty(
                    icon: Icons.assignment_outlined,
                    title: '아직 기록이 없습니다',
                  ),
                )
              else
                ...sessions.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: AppTokens.sp3),
                  child: _SessionCard(session: s),
                )),
              const SizedBox(height: AppTokens.sp10),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 탐정 등급 카드 ────────────────────────────────────────────────────────────

class _DetectiveGradeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Container(
      padding: const EdgeInsets.all(AppTokens.sp4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.ink800, AppColors.tealBase.withValues(alpha: .3)],
          stops: const [0.5, 1.0],
        ),
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppTokens.r6),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: .12),
              border: Border.all(color: c.primary.withValues(alpha: .4)),
              borderRadius: BorderRadius.circular(AppTokens.r4),
            ),
            alignment: Alignment.center,
            child: Text(
              'A',
              style: AppText.monoNum.copyWith(
                fontSize: 28,
                color: c.primary,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(width: AppTokens.sp4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '주임 탐정',
                  style: AppText.titleM.copyWith(color: c.text),
                ),
                const SizedBox(height: 2),
                Text(
                  'ASSOCIATE DETECTIVE',
                  style: AppText.monoLabel.copyWith(color: c.textMute),
                ),
                const SizedBox(height: AppTokens.sp2),
                Text(
                  '다음 등급까지 사건 2건 더 해결 필요',
                  style: AppText.bodySm.copyWith(color: c.textSub),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 세션 카드 ─────────────────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});
  final PlaySession session;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    final IconData stateIcon = switch (session.state) {
      PlayState.completed => Icons.check_circle_outline,
      PlayState.inProgress => Icons.access_time_outlined,
      PlayState.abandoned => Icons.cancel_outlined,
    };

    final Color stateColor = switch (session.state) {
      PlayState.completed => c.success,
      PlayState.inProgress => c.primary,
      PlayState.abandoned => c.textMute,
    };

    return Container(
      padding: const EdgeInsets.all(AppTokens.sp3),
      decoration: BoxDecoration(
        color: c.bgElev,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppTokens.r4),
      ),
      child: Row(
        children: [
          Icon(stateIcon, size: 18, color: stateColor),
          const SizedBox(width: AppTokens.sp3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      session.scenarioCode,
                      style: AppText.monoLabel.copyWith(
                        fontSize: 9.5,
                        color: c.textMute,
                      ),
                    ),
                    const SizedBox(width: AppTokens.sp2),
                    Text(
                      _formatDate(session.startedAt),
                      style: AppText.monoLabel.copyWith(
                        fontSize: 9.5,
                        color: c.textMute,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  session.scenarioTitle,
                  style: AppText.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: c.text,
                    height: 1.3,
                  ),
                ),
                if (session.state == PlayState.inProgress) ...[
                  const SizedBox(height: AppTokens.sp2),
                  _ProgressBar(percent: session.progressPercent),
                ],
              ],
            ),
          ),
          if (session.grade != null) ...[
            const SizedBox(width: AppTokens.sp3),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: c.successSoft,
                border: Border.all(color: c.success),
                borderRadius: BorderRadius.circular(AppTokens.r2),
              ),
              alignment: Alignment.center,
              child: Text(
                session.grade!,
                style: AppText.monoNum.copyWith(
                  fontSize: 16,
                  color: c.success,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.percent});
  final int percent;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final double ratio = (percent / 100).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.r1),
      child: SizedBox(
        height: 4,
        child: LayoutBuilder(
          builder: (_, constraints) => Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: c.bgHover)),
              Positioned(
                left: 0, top: 0, bottom: 0,
                width: constraints.maxWidth * ratio,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.skyBase, AppColors.tealBase],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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