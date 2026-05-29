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

Future<HintLevel?> showHintModal(BuildContext context) {
  return showModalBottomSheet<HintLevel>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _HintSheet(
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
                      onUseHint(level); // 1. 컨트롤러에 감점 기록
                      Navigator.of(context).pop(level); // 2. 선택한 레벨을 들고 모달 닫기
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
  // 세션 해금 상태를 미리 읽어서 Sheet에 전달한다.
  // showModalBottomSheet는 새 루트 컨텍스트를 만들기 때문에
  // Sheet 내부에서 GameSessionProvider를 찾을 수 없다.
  Set<String> unlockedIds;
  try {
    unlockedIds = GameSessionProvider.read(context).unlockedEvidenceIds;
  } catch (_) {
    // GameSessionProvider가 없는 컨텍스트(미리보기 등)에서는 빈 세트로 폴백
    unlockedIds = const {};
  }

  return showModalBottomSheet<Evidence>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _EvidencePresentSheet(unlockedIds: unlockedIds),
  );
}

class _EvidencePresentSheet extends StatefulWidget {
  const _EvidencePresentSheet({required this.unlockedIds});

  /// 세션에서 시간 해금된 evidence ID 집합.
  /// isLocked == true 라도 이 집합에 포함되면 제시 가능하다.
  final Set<String> unlockedIds;

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

  /// 접근 가능한 증거:
  ///   - 원래부터 잠기지 않은 증거 (isLocked == false)
  ///   - isLocked == true 지만 세션에서 해금된 증거 (id ∈ unlockedIds)
  List<Evidence> get _filtered {
    final accessible = sampleCase.evidences
        .where((e) => !e.isLocked || widget.unlockedIds.contains(e.id))
        .toList();
    if (_query.isEmpty) return accessible;
    return accessible
        .where(
          (e) => e.name.contains(_query) || e.location.contains(_query),
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.cardPadH,
            vertical: AppTokens.cardPadV,
          ),
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