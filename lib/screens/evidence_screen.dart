// lib/screens/evidence_screen.dart
import 'package:flutter/material.dart';
import '../components/evidence_tile.dart';
import '../components/filter_chip_widget.dart';
import '../components/ms_kicker.dart';
import '../components/ms_text_field.dart';
import '../components/states.dart';
import '../controllers/game_session_provider.dart';
import '../models/case.dart';
import '../models/sample_case.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

enum _Filter { all, acquired, locked, key }

extension _FilterLabel on _Filter {
  String get label => switch (this) {
        _Filter.all => '전체',
        _Filter.acquired => '확보됨',
        _Filter.locked => '잠긴 증거',
        _Filter.key => '핵심 증거',
      };
}

class EvidenceScreen extends StatefulWidget {
  const EvidenceScreen({super.key});

  @override
  State<EvidenceScreen> createState() => _EvidenceScreenState();
}

class _EvidenceScreenState extends State<EvidenceScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  _Filter _filter = _Filter.all;
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Evidence> _filtered(Set<String> unlockedIds) {
    final sorted = List<Evidence>.from(sampleCase.evidences)
      ..sort((a, b) {
        final aU = unlockedIds.contains(a.id);
        final bU = unlockedIds.contains(b.id);
        if (aU != bU) return aU ? -1 : 1;
        if (a.isLocked != b.isLocked) return a.isLocked ? 1 : -1;
        if (a.isNew != b.isNew) return a.isNew ? -1 : 1;
        return 0;
      });

    return sorted.where((e) {
      final matchesQuery = _query.isEmpty ||
          e.name.contains(_query) ||
          e.location.contains(_query);
      final isTimeLocked = e.isLocked && !unlockedIds.contains(e.id);
      final matchesFilter = switch (_filter) {
        _Filter.all => true,
        _Filter.acquired => !isTimeLocked,
        _Filter.locked => isTimeLocked,
        _Filter.key => e.isAnalyzed,
      };
      return matchesQuery && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return AnimatedBuilder(
      animation: context.session,
      builder: (context, _) {
        final unlockedIds = context.sessionRead.unlockedEvidenceIds;
        final results = _filtered(unlockedIds);

        return Scaffold(
          backgroundColor: c.bg,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.sp4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppTokens.sp4),
                  MSTextField(
                    controller: _searchCtrl,
                    hintText: '증거 이름 · 장소 검색…',
                    suffixIcon: Icons.search,
                    onChanged: (v) => setState(() => _query = v.trim()),
                  ),
                  const SizedBox(height: AppTokens.sp3),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _Filter.values.map((f) {
                        return Padding(
                          padding: EdgeInsets.only(
                            right: f != _Filter.values.last
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
                  ),
                  const SizedBox(height: AppTokens.sp4),
                  const MSKicker('사건 증거 보드'),
                  const SizedBox(height: AppTokens.sp3),
                  Expanded(
                    child: results.isEmpty
                        ? const MSEmpty(
                            icon: Icons.search_off,
                            title: '일치하는 증거가 없습니다',
                          )
                        : ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            itemCount: results.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppTokens.sp2),
                            itemBuilder: (_, i) {
                              final e = results[i];
                              final isTimeLocked =
                                  e.isLocked && !unlockedIds.contains(e.id);
                              return EvidenceTile(
                                evidence: e,
                                isTimeLocked: isTimeLocked,
                                isNewlyUnlocked:
                                    unlockedIds.contains(e.id) && e.isLocked,
                              );
                            },
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
      },
    );
  }
}
