import 'package:flutter/material.dart';
import '../components/ms_kicker.dart';
import '../components/states.dart';
import '../components/timeline_list.dart';
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
}

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  _TimelineFilter _filter = _TimelineFilter.all;

  List<TimelineEntry> get _filtered => switch (_filter) {
    _TimelineFilter.all => sampleCase.timeline,
    _TimelineFilter.conflict =>
        sampleCase.timeline.where((e) => e.conflict != null).toList(),
    _TimelineFilter.suspect =>
        sampleCase.timeline.where((e) => e.conflict == null).toList(),
  };

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final entries = _filtered;

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
            // ── 1. 필터 칩 ─────────────────────────────────────────
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
            // ── 2. 섹션 타이틀 ─────────────────────────────────────
            const MSKicker('사건 타임라인'),
            const SizedBox(height: AppTokens.sp3),
            // ── 3. 타임라인 ────────────────────────────────────────
            entries.isEmpty
                ? const Padding(
              padding: EdgeInsets.only(top: AppTokens.sp8),
              child: MSEmpty(
                icon: Icons.schedule,
                title: '아직 기록된 타임라인이 없습니다',
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