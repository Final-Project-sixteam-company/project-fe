// lib/components/game_modals.dart
import 'package:flutter/material.dart';
import '../components/ms_button.dart';
import '../components/ms_text_field.dart';
import '../controllers/game_session_provider.dart';
import '../models/case.dart';
import '../models/sample_case.dart';
import '../models/session_models.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

// ── 힌트 모달 ─────────────────────────────────────────────────────────────────

Future<void> showHintModal(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _HintSheet(
      // 세션 컨트롤러를 미리 읽어서 넘김 (sheet는 새 context)
      onUseHint: (level) {
        GameSessionProvider.read(context).useHint(level);
      },
      usedHints: GameSessionProvider.read(context).usedHints,
    ),
  );
}

class _HintSheet extends StatelessWidget {
  const _HintSheet({
    required this.onUseHint,
    required this.usedHints,
  });

  final void Function(HintLevel) onUseHint;
  final List<HintRecord> usedHints;

  bool _isUsed(HintLevel level) =>
      usedHints.any((h) => h.level == level);

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Container(
      decoration: BoxDecoration(
        color: c.bgElev,
        borderRadius: const BorderRadius.only(
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
              // ── 제목 ─────────────────────────────────────────────
              Text(
                '힌트 요청',
                style: AppText.titleL.copyWith(color: c.text),
              ),
              const SizedBox(height: AppTokens.sp2),
              Text(
                '힌트 사용 시 최종 점수가 감점됩니다.',
                style: AppText.bodySm.copyWith(color: c.danger),
              ),
              // ── 현재까지 사용한 감점 표시 ─────────────────────────
              if (usedHints.isNotEmpty) ...[
                const SizedBox(height: AppTokens.sp3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.sp3,
                    vertical: AppTokens.sp2,
                  ),
                  decoration: BoxDecoration(
                    color: c.dangerSoft,
                    border: Border.all(color: c.danger),
                    borderRadius: BorderRadius.circular(AppTokens.r3),
                  ),
                  child: Text(
                    '누적 감점: -${usedHints.fold(0, (s, h) => s + h.penalty)}점',
                    style: AppText.monoLabel.copyWith(color: c.danger),
                  ),
                ),
              ],
              const SizedBox(height: AppTokens.sp6),
              // ── 힌트 버튼들 ──────────────────────────────────────
              ...HintLevel.values.map(
                    (level) => Padding(
                  padding: const EdgeInsets.only(bottom: AppTokens.sp3),
                  child: _HintButton(
                    level: level,
                    used: _isUsed(level),
                    onPressed: _isUsed(level)
                        ? null
                        : () {
                      onUseHint(level);
                      Navigator.of(context).pop();
                    },
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

class _HintButton extends StatelessWidget {
  const _HintButton({
    required this.level,
    required this.used,
    required this.onPressed,
  });

  final HintLevel level;
  final bool used;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (used) {
      return MSButton(
        label: '${level.label} (사용됨)',
        variant: MSButtonVariant.ghost,
        expanded: true,
        onPressed: null,
      );
    }
    return MSButton(
      label: '${level.label} (${level.penaltyLabel})',
      variant: level == HintLevel.decisive
          ? MSButtonVariant.danger
          : MSButtonVariant.secondary,
      expanded: true,
      onPressed: onPressed,
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
  State<_EvidencePresentSheet> createState() =>
      _EvidencePresentSheetState();
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
    final unlocked = sampleCase.evidences.where((e) => !e.isLocked).toList();
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
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppTokens.r6),
              topRight: Radius.circular(AppTokens.r6),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: AppTokens.sp4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  MSTextField(
                    controller: _searchCtrl,
                    hintText: '보유한 증거 검색...',
                    suffixIcon: Icons.search,
                    onChanged: (v) => setState(() => _query = v.trim()),
                  ),
                  const SizedBox(height: AppTokens.sp4),
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
                      itemBuilder: (_, i) => _EvidencePickItem(
                        evidence: results[i],
                        onTap: () =>
                            Navigator.of(context).pop(results[i]),
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

// ── 증거 선택 아이템 ──────────────────────────────────────────────────────────

class _EvidencePickItem extends StatelessWidget {
  const _EvidencePickItem({
    required this.evidence,
    required this.onTap,
  });

  final Evidence evidence;
  final VoidCallback onTap;

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
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            color: c.bg,
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(AppTokens.r4),
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
                child: Icon(evidence.icon, size: 17, color: c.primary),
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