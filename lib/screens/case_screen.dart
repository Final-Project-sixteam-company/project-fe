import 'package:flutter/material.dart';
import '../components/evidence_item.dart';
import '../components/ms_bottom_nav.dart';
import '../components/ms_button.dart';
import '../components/ms_kicker.dart';
import '../components/ms_stat_row.dart';
import '../components/suspect_card.dart';
import '../components/timeline_list.dart';
import '../models/sample_case.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import 'evidence_screen.dart';
import 'suspect_detail_screen.dart';

class CaseScreen extends StatefulWidget {
  const CaseScreen({super.key});

  @override
  State<CaseScreen> createState() => _CaseScreenState();
}

class _CaseScreenState extends State<CaseScreen> {
  int _navIndex = 0;

  static const _kScreens = <Widget>[
    _CaseBody(),
    EvidenceScreen(),
    _PlaceholderScreen(label: '용의자'),
    _PlaceholderScreen(label: '타임라인'),
    _PlaceholderScreen(label: '제출'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: _buildAppBar(context),
      bottomNavigationBar: MSBottomNav(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
      body: IndexedStack(
        index: _navIndex,
        children: _kScreens,
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
      title: Row(
        children: [
          Text(
            'CASE LAB',
            style: AppText.monoLabel.copyWith(color: c.primary),
          ),
          const SizedBox(width: AppTokens.sp2),
          Text(
            'CL-001',
            style: AppText.monoLabel.copyWith(color: c.textMute),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppTokens.sp4),
          child: _HintButton(),
        ),
      ],
    );
  }
}

// ── 현장 탭 본문 ──────────────────────────────────────────────────────────────

class _CaseBody extends StatelessWidget {
  const _CaseBody();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppTokens.sp3),
          MSStatRow(const [
            StatCell('진행 시간', '14:22'),
            StatCell('해금 증거', '8/12', tone: StatTone.good),
            StatCell('다음 해금', '3분', tone: StatTone.warn),
          ]),
          const SizedBox(height: AppTokens.sp6),
          const MSKicker('용의자 · TOP SUSPECT'),
          const SizedBox(height: AppTokens.sp3),
          Builder(
            builder: (context) => SuspectCard(
              sampleCase.suspects.first,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SuspectDetailScreen(
                    suspect: sampleCase.suspects.first,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.sp6),
          const MSKicker('새로운 증거'),
          const SizedBox(height: AppTokens.sp3),
          const _EvidenceSection(),
          const SizedBox(height: AppTokens.sp6),
          const MSKicker('타임라인 · 모순'),
          const SizedBox(height: AppTokens.sp3),
          TimelineList(sampleCase.timeline),
          const SizedBox(height: AppTokens.sp10),
        ],
      ),
    );
  }
}

// ── 힌트 버튼 ─────────────────────────────────────────────────────────────────

class _HintButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: c.primarySoft,
          border: Border.all(color: c.primary),
          borderRadius: BorderRadius.circular(AppTokens.rPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lightbulb_outline, size: 14, color: c.primary),
            const SizedBox(width: 5),
            Text(
              '힌트',
              style: AppText.monoLabel.copyWith(color: c.primary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 증거 섹션 ─────────────────────────────────────────────────────────────────

class _EvidenceSection extends StatefulWidget {
  const _EvidenceSection();

  @override
  State<_EvidenceSection> createState() => _EvidenceSectionState();
}

class _EvidenceSectionState extends State<_EvidenceSection> {
  static const int _previewCount = 3;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final evidences = sampleCase.evidences;
    final bool hasMore = evidences.length > _previewCount;
    final displayed =
    _expanded ? evidences : evidences.take(_previewCount).toList();
    final remaining = evidences.length - _previewCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < displayed.length; i++) ...[
          EvidenceItem(displayed[i], onTap: () {}),
          if (i < displayed.length - 1) const SizedBox(height: AppTokens.sp3),
        ],
        if (hasMore && !_expanded) ...[
          const SizedBox(height: AppTokens.sp3),
          MSButton(
            label: '$remaining개 더 보기',
            variant: MSButtonVariant.ghost,
            onPressed: () => setState(() => _expanded = true),
          ),
        ],
      ],
    );
  }
}

// ── 플레이스홀더 ──────────────────────────────────────────────────────────────

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Center(
      child: Text(
        '$label 준비 중',
        style: AppText.bodySm.copyWith(color: c.textMute),
      ),
    );
  }
}