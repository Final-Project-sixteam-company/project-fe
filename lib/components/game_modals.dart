// lib/components/game_modals.dart
import 'package:flutter/material.dart';
import '../components/evidence_item.dart';
import '../components/ms_button.dart';
import '../components/ms_text_field.dart';
import '../models/case.dart';
import '../models/sample_case.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

// ── 힌트 모달 ─────────────────────────────────────────────────────────────────

Future<void> showHintModal(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _HintSheet(),
  );
}

class _HintSheet extends StatelessWidget {
  const _HintSheet();

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Container(
      decoration: BoxDecoration(
        color: c.bgElev,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTokens.r6),
          topRight: Radius.circular(AppTokens.r6),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.sp4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 드래그 핸들 ──────────────────────────────────────
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppTokens.sp4),
                  decoration: BoxDecoration(
                    color: c.line,
                    borderRadius: BorderRadius.circular(AppTokens.rPill),
                  ),
                ),
              ),
              // ── 제목 + 경고 ──────────────────────────────────────
              Text(
                '힌트 요청',
                style: AppText.titleL.copyWith(color: c.text),
              ),
              const SizedBox(height: AppTokens.sp2),
              Text(
                '힌트 사용 시 최종 점수가 감점됩니다.',
                style: AppText.bodySm.copyWith(color: c.danger),
              ),
              const SizedBox(height: AppTokens.sp6),
              // ── 힌트 버튼들 ──────────────────────────────────────
              MSButton(
                label: '방향 힌트 (-5점)',
                variant: MSButtonVariant.secondary,
                expanded: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: AppTokens.sp3),
              MSButton(
                label: '증거 연결 힌트 (-10점)',
                variant: MSButtonVariant.secondary,
                expanded: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: AppTokens.sp3),
              MSButton(
                label: '결정적 힌트 (-20점)',
                variant: MSButtonVariant.danger,
                expanded: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 증거 제시 모달 ────────────────────────────────────────────────────────────

Future<Evidence?> showEvidencePresentModal(BuildContext context) {
  return showModalBottomSheet<Evidence>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _EvidencePresentSheet(),
  );
}

class _EvidencePresentSheet extends StatefulWidget {
  const _EvidencePresentSheet();

  @override
  State<_EvidencePresentSheet> createState() => _EvidencePresentSheetState();
}

class _EvidencePresentSheetState extends State<_EvidencePresentSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Evidence> get _filtered {
    final unlocked =
    sampleCase.evidences.where((e) => !e.isLocked).toList();
    if (_query.isEmpty) return unlocked;
    return unlocked
        .where(
          (e) =>
      e.name.contains(_query) || e.location.contains(_query),
    )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final results = _filtered;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: c.bgElev,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppTokens.r6),
              topRight: Radius.circular(AppTokens.r6),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.sp4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── 드래그 핸들 ────────────────────────────────
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.symmetric(
                        vertical: AppTokens.sp3,
                      ),
                      decoration: BoxDecoration(
                        color: c.line,
                        borderRadius:
                        BorderRadius.circular(AppTokens.rPill),
                      ),
                    ),
                  ),
                  // ── 헤더 ──────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '제시할 증거 선택',
                          style: AppText.titleM.copyWith(color: c.text),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: c.textSub, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.sp4),
                  // ── 검색바 ────────────────────────────────────
                  MSTextField(
                    controller: _searchCtrl,
                    hintText: '보유한 증거 검색...',
                    suffixIcon: Icons.search,
                    onChanged: (v) => setState(() => _query = v.trim()),
                  ),
                  const SizedBox(height: AppTokens.sp4),
                  // ── 증거 리스트 ───────────────────────────────
                  Expanded(
                    child: results.isEmpty
                        ? Center(
                      child: Text(
                        '일치하는 증거가 없습니다',
                        style: AppText.bodySm
                            .copyWith(color: c.textSub),
                      ),
                    )
                        : ListView.separated(
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      itemCount: results.length,
                      separatorBuilder: (_, __) =>
                      const SizedBox(height: AppTokens.sp2),
                      itemBuilder: (_, i) => EvidenceItem(
                        results[i],
                        onTap: () => Navigator.of(context)
                            .pop(results[i]),
                      ),
                      padding: const EdgeInsets.only(
                        bottom: AppTokens.sp6,
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

// ── 사용 예시 ─────────────────────────────────────────────────────────────────

class GameModalsExample extends StatelessWidget {
  const GameModalsExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MSButton(
            label: '힌트 모달 열기',
            variant: MSButtonVariant.secondary,
            onPressed: () => showHintModal(context),
          ),
          const SizedBox(height: AppTokens.sp3),
          MSButton(
            label: '증거 제시 모달 열기',
            variant: MSButtonVariant.secondary,
            onPressed: () async {
              final evidence = await showEvidencePresentModal(context);
              if (evidence != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('선택된 증거: ${evidence.name}')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}