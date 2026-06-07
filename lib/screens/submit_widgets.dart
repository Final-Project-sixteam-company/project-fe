// lib/screens/submit_widgets.dart
import 'package:flutter/material.dart';
import '../components/ms_button.dart';
import '../models/case.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
export 'submit_evidence_selector.dart';

// ── 모델 ──────────────────────────────────────────────────────────────────────

class SubmitRequirement {
  const SubmitRequirement(this.label, this.met);
  final String label;
  final bool   met;
}

// ── 헤더 ──────────────────────────────────────────────────────────────────────

class SubmitHeader extends StatelessWidget {
  const SubmitHeader({
    required this.dangerColor,
    required this.subColor,
    required this.textColor,
    super.key,
  });
  final Color dangerColor;
  final Color subColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) => Column(children: [
    Icon(Icons.warning_amber_rounded, size: AppTokens.sp12, color: dangerColor),
    const SizedBox(height: AppTokens.sp4),
    Text('사건 종결 및 추리 제출',
        style: AppText.titleL.copyWith(color: textColor),
        textAlign: TextAlign.center),
    const SizedBox(height: AppTokens.sp2),
    Text('범인을 지목하고 사건의 전말을 제출합니다.\n이 결정은 되돌릴 수 없습니다.',
        style: AppText.bodySm.copyWith(color: subColor),
        textAlign: TextAlign.center),
  ]);
}

// ── 체크리스트 ────────────────────────────────────────────────────────────────

class SubmitChecklist extends StatelessWidget {
  const SubmitChecklist({required this.requirements, super.key});
  final List<SubmitRequirement> requirements;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(AppTokens.sp4),
      decoration: BoxDecoration(color: c.bgElev,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(AppTokens.r4)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('제출하려면 아래 항목을 완료해 주세요',
            style: AppText.monoLabel.copyWith(color: c.textSub)),
        const SizedBox(height: AppTokens.sp3),
        ...requirements.map((r) => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTokens.rowGap),
          child: Row(children: [
            Icon(r.met ? Icons.check_circle : Icons.radio_button_unchecked,
                size: AppTokens.sp4,
                color: r.met ? c.success : c.textMute),
            const SizedBox(width: AppTokens.sp3),
            Expanded(child: Text(r.label,
                style: AppText.bodySm.copyWith(
                    color: r.met ? c.textMute : c.text))),
          ]),
        )),
      ]),
    );
  }
}

// ── 제출 확인 다이얼로그 ──────────────────────────────────────────────────────

class SubmitConfirmDialog extends StatelessWidget {
  const SubmitConfirmDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Dialog(
      backgroundColor: c.bgElev,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.r6),
          side: BorderSide(color: c.line)),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.sp6),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Icon(Icons.warning_amber_rounded,
                size: AppTokens.sp6, color: c.danger),
            const SizedBox(width: AppTokens.sp2),
            Text('최종 추리 제출',
                style: AppText.titleM.copyWith(color: c.text)),
          ]),
          const SizedBox(height: AppTokens.sp3),
          Text('제출하면 사건이 종결됩니다.\n정말 제출하시겠습니까?',
              style: AppText.body.copyWith(color: c.textSub, height: 1.6)),
          const SizedBox(height: AppTokens.sp6),
          Row(children: [
            Expanded(child: MSButton(label: '취소',
                variant: MSButtonVariant.secondary, expanded: true,
                onPressed: () => Navigator.of(context).pop(false))),
            const SizedBox(width: AppTokens.sp3),
            Expanded(child: MSButton(label: '제출',
                variant: MSButtonVariant.danger, expanded: true,
                onPressed: () => Navigator.of(context).pop(true))),
          ]),
        ]),
      ),
    );
  }
}

// ── 용의자 드롭다운 ───────────────────────────────────────────────────────────

class SuspectDropdown extends StatelessWidget {
  const SuspectDropdown({
    required this.suspects,
    required this.selected,
    required this.onSelect,
    super.key,
  });
  final List<Suspect>          suspects;
  final Suspect?               selected;
  final ValueChanged<Suspect?> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.sp3, vertical: AppTokens.sp2),
      decoration: BoxDecoration(color: c.bg,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(AppTokens.r3)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Suspect>(
          value: selected, isExpanded: true, dropdownColor: c.bgElev,
          icon: Icon(Icons.keyboard_arrow_down,
              color: c.textSub, size: AppTokens.sp5),
          hint: Text('범인 선택',
              style: AppText.body.copyWith(color: c.textMute)),
          style: AppText.body.copyWith(color: c.text),
          items: suspects.map((s) => DropdownMenuItem(
              value: s, child: Text('${s.name} · ${s.role}'))).toList(),
          onChanged: onSelect,
        ),
      ),
    );
  }
}
