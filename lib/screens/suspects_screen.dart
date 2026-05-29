import 'package:flutter/material.dart';
import '../components/ms_bottom_nav.dart';
import '../components/ms_kicker.dart';
import '../components/ms_stat_row.dart';
import '../components/ms_text_field.dart';
import '../components/states.dart';
import '../components/suspect_card.dart';
import '../controllers/game_session_provider.dart';
import '../models/case.dart';
import '../models/sample_case.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import 'suspect_detail_screen.dart';

class SuspectsScreen extends StatefulWidget {
  const SuspectsScreen({super.key});

  @override
  State<SuspectsScreen> createState() => _SuspectsScreenState();
}

class _SuspectsScreenState extends State<SuspectsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Suspect> get _filtered {
    final sorted = List<Suspect>.from(sampleCase.suspects)
      ..sort((a, b) => b.suspicion.compareTo(a.suspicion));

    if (_query.isEmpty) return sorted;
    return sorted
        .where(
          (s) => s.name.contains(_query) || s.role.contains(_query),
    )
        .toList();
  }

  int get _maxSuspicion => sampleCase.suspects
      .map((s) => s.suspicion)
      .reduce((a, b) => a > b ? a : b);

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final results = _filtered;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.sp4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppTokens.sp4),
              // ── 1. 검색창 ─────────────────────────────────────────────
              MSTextField(
                controller: _searchCtrl,
                hintText: '용의자 이름 · 직책 검색…',
                suffixIcon: Icons.search,
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
              const SizedBox(height: AppTokens.sp4),
              // ── 2. 통계 ───────────────────────────────────────────────
              MSStatRow([
                StatCell('전체 용의자', '${sampleCase.suspects.length}명'),
                const StatCell('확인된 알리바이', '2건'),
                StatCell(
                  '최고 의심도',
                  '$_maxSuspicion%',
                  tone: StatTone.warn,
                ),
              ]),
              const SizedBox(height: AppTokens.sp4),
              // ── 3. 섹션 타이틀 ────────────────────────────────────────
              const MSKicker('모든 용의자'),
              const SizedBox(height: AppTokens.sp3),
              // ── 4. 리스트 ─────────────────────────────────────────────
              Expanded(
                child: results.isEmpty
                    ? const MSEmpty(
                  icon: Icons.person_off,
                  title: '용의자가 없습니다',
                )
                    : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: results.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: AppTokens.sp3),
                  itemBuilder: (_, i) => SuspectCard(
                    results[i],
                    onTap: () {
                      final ctrl = context.sessionRead;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => GameSessionProvider(
                            controller: ctrl,
                            child: SuspectDetailScreen(
                              suspect: results[i],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  padding: const EdgeInsets.only(
                    bottom: AppTokens.sp10,
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