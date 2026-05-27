import 'package:flutter/material.dart';
import '../components/ms_kicker.dart';
import '../components/ms_text_field.dart';
import '../components/states.dart';
import '../models/case.dart';
import '../models/sample_case.dart';
import '../theme/app_text.dart';
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

  List<Evidence> get _filtered {
    final sorted = List<Evidence>.from(sampleCase.evidences)
      ..sort((a, b) {
        if (a.isLocked != b.isLocked) return a.isLocked ? 1 : -1;
        if (a.isNew != b.isNew) return a.isNew ? -1 : 1;
        return 0;
      });

    return sorted.where((e) {
      final matchesQuery = _query.isEmpty ||
          e.name.contains(_query) ||
          e.location.contains(_query);

      final matchesFilter = switch (_filter) {
        _Filter.all => true,
        _Filter.acquired => e.isNew && !e.isLocked,
        _Filter.locked => e.isLocked,
        _Filter.key => e.isAnalyzed,
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
                        right: f != _Filter.values.last
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
              // ── 3. 섹션 타이틀 ──────────────────────────────────────
              const MSKicker('사건 증거 보드'),
              const SizedBox(height: AppTokens.sp3),
              // ── 4. 리스트 ───────────────────────────────────────────
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
                  itemBuilder: (_, i) => _EvidenceRow(
                    evidence: results[i],
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

// ── 증거 행 (잠금 처리 포함) ──────────────────────────────────────────────────

class _EvidenceRow extends StatelessWidget {
  const _EvidenceRow({required this.evidence});

  final Evidence evidence;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    if (evidence.isLocked) {
      return Opacity(
        opacity: 0.5,
        child: Stack(
          alignment: Alignment.centerRight,
          children: [
            _EvidenceTile(evidence: evidence),
            Padding(
              padding: const EdgeInsets.only(right: AppTokens.sp4),
              child: Icon(
                Icons.lock_outline,
                size: 16,
                color: c.textMute,
              ),
            ),
          ],
        ),
      );
    }

    return _EvidenceTile(evidence: evidence, onTap: () {});
  }
}

// ── 증거 타일 (EvidenceItem 인라인 구현) ──────────────────────────────────────

class _EvidenceTile extends StatelessWidget {
  const _EvidenceTile({required this.evidence, this.onTap});

  final Evidence evidence;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Material(
      color: c.bg,
      borderRadius: BorderRadius.circular(AppTokens.r4),
      child: InkWell(
        onTap: onTap,
        splashColor: c.primary.withValues(alpha: .08),
        highlightColor: c.primary.withValues(alpha: .04),
        borderRadius: BorderRadius.circular(AppTokens.r4),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: c.bg,
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(AppTokens.r4),
            boxShadow: evidence.isNew
                ? [
              BoxShadow(
                color: c.primarySoft,
                spreadRadius: 2,
                blurRadius: 0,
              ),
            ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: c.bgHover,
                  border: Border.all(color: c.line),
                  borderRadius: BorderRadius.circular(AppTokens.r2),
                ),
                alignment: Alignment.center,
                child: Icon(
                  evidence.icon,
                  size: 17,
                  color: evidence.isAnalyzed ? c.success : c.primary,
                ),
              ),
              const SizedBox(width: AppTokens.sp3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      evidence.name,
                      style: AppText.body.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                        color: c.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      evidence.location,
                      style: AppText.monoLabel.copyWith(
                        fontSize: 9.5,
                        letterSpacing: 9.5 * 0.06,
                        color: c.textMute,
                        height: 1.0,
                      ),
                    ),
                  ],
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