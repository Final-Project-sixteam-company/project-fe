// lib/screens/suspects_screen.dart
import 'package:flutter/material.dart';
import '../components/filter_chip_row.dart';
import '../components/ms_kicker.dart';
import '../components/ms_button.dart';
import '../components/ms_stat_row.dart';
import '../components/ms_text_field.dart';
import '../components/states.dart';
import '../components/suspect_card.dart';
import '../controllers/game_session_controller.dart';
import '../controllers/game_session_provider.dart';
import '../models/case.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import 'suspect_detail_screen.dart';

enum _SuspectFilter { all, suspect, witness }

extension _SuspectFilterLabel on _SuspectFilter {
  String get label => switch (this) {
    _SuspectFilter.all => '전체',
    _SuspectFilter.suspect => '용의자',
    _SuspectFilter.witness => '증인',
  };
}

class SuspectsScreen extends StatefulWidget {
  const SuspectsScreen({super.key});

  @override
  State<SuspectsScreen> createState() => _SuspectsScreenState();
}

class _SuspectsScreenState extends State<SuspectsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  _SuspectFilter _filter = _SuspectFilter.all;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Suspect> _filtered(List<Suspect> source) {
    final sorted = List<Suspect>.from(source)
      ..sort((a, b) {
        if (a.isWitness != b.isWitness) return a.isWitness ? 1 : -1;
        return a.name.compareTo(b.name);
      });

    return sorted.where((s) {
      final matchesQuery =
          _query.isEmpty || s.name.contains(_query) || s.role.contains(_query);
      final matchesFilter = switch (_filter) {
        _SuspectFilter.all => true,
        _SuspectFilter.suspect => !s.isWitness,
        _SuspectFilter.witness => s.isWitness,
      };
      return matchesQuery && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: context.session,
          builder: (context, _) {
            final ctrl = context.session;
            final all = ctrl.suspects;
            final results = _filtered(all);
            final suspectCount = all.where((s) => !s.isWitness).length;
            final witnessCount = all.where((s) => s.isWitness).length;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.sp4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppTokens.sp4),
                  MSTextField(
                    controller: _searchCtrl,
                    hintText: '용의자 이름 · 직책 검색…',
                    suffixIcon: Icons.search,
                    onChanged: (v) => setState(() => _query = v.trim()),
                  ),
                  const SizedBox(height: AppTokens.sp3),
                  Row(
                    children: _SuspectFilter.values.map((f) {
                      return Padding(
                        padding: EdgeInsets.only(
                          right: f != _SuspectFilter.values.last
                              ? AppTokens.sp2
                              : 0,
                        ),
                        child: MSFilterChip(
                          label: f.label,
                          active: _filter == f,
                          onTap: () => setState(() => _filter = f),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppTokens.sp4),
                  MSStatRow([
                    StatCell('용의자', '$suspectCount명'),
                    if (witnessCount > 0) StatCell('증인', '$witnessCount명'),
                    StatCell(
                      '심문 횟수',
                      '${ctrl.dashboard?.interrogationCount ?? 0}회',
                    ),
                  ]),
                  const SizedBox(height: AppTokens.sp4),
                  const MSKicker('모든 인물'),
                  const SizedBox(height: AppTokens.sp3),
                  Expanded(child: _buildBody(context, ctrl, results)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    GameSessionController ctrl,
    List<Suspect> results,
  ) {
    if (ctrl.isLoading && results.isEmpty) {
      return const MSListSkeleton(itemHeight: 84);
    }
    if (ctrl.loadError != null && results.isEmpty) {
      return MSEmpty(
        icon: Icons.cloud_off,
        title: '불러오지 못했습니다',
        subtitle: ctrl.loadError,
        action: MSButton(
          label: '다시 시도',
          variant: MSButtonVariant.secondary,
          onPressed: () => ctrl.retry(),
        ),
      );
    }
    if (results.isEmpty) {
      return const MSEmpty(icon: Icons.person_off, title: '인물이 없습니다');
    }
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppTokens.sp3),
      itemBuilder: (_, i) => SuspectCard(
        results[i],
        onTap: () {
          final c = context.sessionRead;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GameSessionProvider(
                controller: c,
                child: SuspectDetailScreen(suspect: results[i]),
              ),
            ),
          );
        },
      ),
      padding: const EdgeInsets.only(bottom: AppTokens.sp10),
    );
  }
}
