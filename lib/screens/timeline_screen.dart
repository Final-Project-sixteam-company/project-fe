// lib/screens/timeline_screen.dart
import 'package:flutter/material.dart';
import '../components/ms_kicker.dart';
import '../components/states.dart';
import '../components/timeline_list.dart';
import '../controllers/game_session_provider.dart';
import '../models/case.dart';
import '../models/sample_case.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

enum _TimelineFilter { all, conflict, suspect }

extension _TimelineFilterLabel on _TimelineFilter {
  String get label => switch (this) {
    _TimelineFilter.all => '전체 시간대',
    _TimelineFilter.conflict => '⚠ 모순 발견',
    _TimelineFilter.suspect => '용의자 주장',
  };

  /// 필터별 빈 상태 제목 — 범용 문구 대신 문맥을 반영한다.
  String get emptyTitle => switch (this) {
    _TimelineFilter.all => '아직 기록된 타임라인이 없습니다',
    _TimelineFilter.conflict => '발견된 모순이 없습니다',
    _TimelineFilter.suspect => '용의자 주장 기록이 없습니다',
  };

  /// 필터별 빈 상태 보조 안내(없으면 null).
  String? get emptySubtitle => switch (this) {
    _TimelineFilter.all => null,
    _TimelineFilter.conflict => '진술을 교차 검토하면 모순이 드러납니다.',
    _TimelineFilter.suspect => '용의자를 심문하면 주장이 여기에 정리됩니다.',
  };
}

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  _TimelineFilter _filter = _TimelineFilter.all;

  List<TimelineEntry> _getFiltered(List<TimelineEntry> source) => switch (_filter) {
    _TimelineFilter.all => source,
    _TimelineFilter.conflict =>
        source.where((e) => e.conflict != null).toList(),
    _TimelineFilter.suspect =>
        source.where((e) => e.eventType == 'CLAIM' || (e.eventType == null && e.conflict == null)).toList(),
  };

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final session = context.session;

    List<TimelineEntry> rawTimeline = session.timeline;
    if (rawTimeline.isEmpty && session.usesCl001SampleCaseData) {
      rawTimeline = sampleCase.timeline;
    }

    final entries = _getFiltered(rawTimeline);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.sp4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppTokens.sp4),
            // ── 필터 칩 ────────────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _TimelineFilter.values.map((f) {
                  final bool active = _filter == f;
                  return Padding(
                    padding: EdgeInsets.only(
                      right: f != _TimelineFilter.values.last
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
            // ── 섹션 타이틀 ────────────────────────────────────────
            const MSKicker('사건 타임라인'),
            const SizedBox(height: AppTokens.sp3),
            // ── 타임라인 ───────────────────────────────────────────
            entries.isEmpty
                ? Padding(
              padding: const EdgeInsets.only(top: AppTokens.sp8),
              child: MSEmpty(
                icon: _filter == _TimelineFilter.conflict
                    ? Icons.report_gmailerrorred_outlined
                    : Icons.schedule,
                title: _filter.emptyTitle,
                subtitle: _filter.emptySubtitle,
              ),
            )
                : TimelineList(entries),
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
      titleSpacing: AppTokens.sp4,
      automaticallyImplyLeading: false,
      title: Text(
        'TIMELINE',
        style: AppText.monoLabel.copyWith(color: c.textMute),
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.chipPadH,
          vertical: AppTokens.chipPadV,
        ),
        decoration: BoxDecoration(
          color: active ? c.primarySoft : c.bg.withValues(alpha: 0),
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
