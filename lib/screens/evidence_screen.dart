import 'package:flutter/material.dart';
import '../components/evidence_item.dart';
import '../components/ms_text_field.dart';
import '../models/case.dart';
import '../models/sample_case.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

enum _Filter { all, newOnly, analyzed, pending }

extension _FilterLabel on _Filter {
  String get label => switch (this) {
    _Filter.all => '전체',
    _Filter.newOnly => 'NEW',
    _Filter.analyzed => '분석완료',
    _Filter.pending => '미확인',
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

  List<Evidence> get _filtered {
    final all = List<Evidence>.from(sampleCase.evidences)
      ..sort((a, b) {
        if (a.isNew != b.isNew) return a.isNew ? -1 : 1;
        return 0;
      });

    return all.where((e) {
      final matchesQuery = _query.isEmpty ||
          e.name.contains(_query) ||
          e.location.contains(_query);

      final matchesFilter = switch (_filter) {
        _Filter.all => true,
        _Filter.newOnly => e.isNew,
        _Filter.analyzed => e.isAnalyzed,
        _Filter.pending => !e.isAnalyzed,
      };

      return matchesQuery && matchesFilter;
    }).toList();
  }

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
              // ── 1. 검색창 ───────────────────────────────────────────
              MSTextField(
                controller: _searchCtrl,
                hintText: '증거 이름 · 장소 검색…',
                suffixIcon: Icons.search,
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
              const SizedBox(height: AppTokens.sp3),
              // ── 2. 필터 칩 ──────────────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _Filter.values.map((f) {
                    final bool active = _filter == f;
                    return Padding(
                      padding: EdgeInsets.only(
                        right: f != _Filter.values.last ? AppTokens.sp2 : 0,
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
              // ── 3. 결과 카운트 ──────────────────────────────────────
              Text(
                '결과 ${results.length}개',
                style: AppText.monoLabel.copyWith(color: c.textMute),
              ),
              const SizedBox(height: AppTokens.sp3),
              // ── 4. 리스트 ───────────────────────────────────────────
              Expanded(
                child: results.isEmpty
                    ? _EmptyState()
                    : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: results.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: AppTokens.sp2),
                  itemBuilder: (_, i) => EvidenceItem(
                    results[i],
                    onTap: () {},
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

// ── 빈 상태 ───────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 32, color: c.textMute),
          const SizedBox(height: AppTokens.sp3),
          Text(
            '일치하는 증거가 없습니다',
            style: AppText.bodySm.copyWith(color: c.textSub),
          ),
        ],
      ),
    );
  }
}