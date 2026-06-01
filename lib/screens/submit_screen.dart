// lib/screens/submit_screen.dart
import 'package:flutter/material.dart';
import '../components/ms_button.dart';
import '../components/ms_kicker.dart';
import '../components/ms_pill.dart';
import '../components/ms_text_field.dart';
import '../controllers/game_session_controller.dart';
import '../controllers/game_session_provider.dart';
import '../core/api/api_exception.dart';
import '../models/case.dart';
import '../repositories/play_session_repository.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import 'result_screen.dart';

class SubmitScreen extends StatefulWidget {
  const SubmitScreen({this.initialSuspect, super.key});

  /// 용의자 상세에서 '범인 지목'으로 진입할 때 미리 선택될 용의자.
  final Suspect? initialSuspect;

  @override
  State<SubmitScreen> createState() => _SubmitScreenState();
}

class _SubmitScreenState extends State<SubmitScreen> {
  Suspect? _selectedSuspect;
  final TextEditingController _motiveCtrl = TextEditingController();
  final TextEditingController _methodCtrl = TextEditingController();
  final TextEditingController _concealCtrl = TextEditingController();
  final TextEditingController _summaryCtrl = TextEditingController();
  final List<Evidence> _selectedEvidences = [];

  static const int _maxEvidenceCount = 3;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedSuspect = widget.initialSuspect;
  }

  @override
  void dispose() {
    _motiveCtrl.dispose();
    _methodCtrl.dispose();
    _concealCtrl.dispose();
    _summaryCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_submitting &&
          _selectedSuspect != null &&
          _motiveCtrl.text.isNotEmpty &&
          _methodCtrl.text.isNotEmpty &&
          _concealCtrl.text.isNotEmpty &&
          _summaryCtrl.text.isNotEmpty &&
          _selectedEvidences.length == _maxEvidenceCount;

  void _toggleEvidence(Evidence e) {
    setState(() {
      if (_selectedEvidences.contains(e)) {
        _selectedEvidences.remove(e);
      } else if (_selectedEvidences.length < _maxEvidenceCount) {
        _selectedEvidences.add(e);
      }
    });
  }

  Future<void> _onSubmit() async {
    final controller = context.sessionRead;
    final sessionId = controller.backendSessionId;
    final culpritId = int.tryParse(_selectedSuspect?.id ?? '');

    if (!_canSubmit || sessionId == null || culpritId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sessionId == null
                ? '세션이 아직 준비되지 않았습니다. 잠시 후 다시 시도해 주세요.'
                : '모든 항목을 입력해주세요.',
          ),
        ),
      );
      return;
    }

    final evidenceIds = _selectedEvidences
        .map((e) => int.tryParse(e.id))
        .whereType<int>()
        .toList();

    setState(() => _submitting = true);
    try {
      await playSessionRepo.submitFinalDeduction(
        sessionId,
        selectedCulpritId: culpritId,
        motiveText: _motiveCtrl.text.trim(),
        methodText: _methodCtrl.text.trim(),
        coverUpText: _concealCtrl.text.trim(),
        selectedEvidenceIds: evidenceIds,
      );

      if (!mounted) return;
      // 타이머 정지 + 세션 완료 표시(점수는 결과 화면에서 서버 값으로 표시).
      controller.completeSession(rawScore: 0);

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResultScreen(sessionId: sessionId),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('제출 실패: ${e.message}')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('제출 중 오류가 발생했습니다.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final controller = context.session;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.sp4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppTokens.sp6),
              // ── 경고 헤더 ───────────────────────────────────────
              Column(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 48,
                    color: c.danger,
                  ),
                  const SizedBox(height: AppTokens.sp4),
                  Text(
                    '사건 종결 및 추리 제출',
                    style: AppText.titleL.copyWith(color: c.text),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTokens.sp2),
                  Text(
                    '범인을 지목하고 사건의 전말을 제출합니다.\n이 결정은 되돌릴 수 없습니다.',
                    style: AppText.bodySm.copyWith(color: c.textSub),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.sp8),
              // ── 1. 진범 지목 ────────────────────────────────────
              const MSKicker('1. FINAL SUSPECT · 진범 지목'),
              const SizedBox(height: AppTokens.sp3),
              _SuspectDropdown(
                suspects: controller.suspects,
                selected: _selectedSuspect,
                onSelect: (s) =>
                    setState(() => _selectedSuspect = s),
              ),
              const SizedBox(height: AppTokens.sp6),
              // ── 2. 범행 동기 및 방법 ────────────────────────────
              const MSKicker('2. 범행 동기 및 방법'),
              const SizedBox(height: AppTokens.sp3),
              MSTextField(
                controller: _motiveCtrl,
                hintText: '범인이 피해자를 해친 동기는 무엇인가요?',
                maxLines: 3,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppTokens.sp3),
              MSTextField(
                controller: _methodCtrl,
                hintText: '어떤 방법으로 범행을 저질렀나요?',
                maxLines: 3,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppTokens.sp3),
              MSTextField(
                controller: _concealCtrl,
                hintText: '범행을 어떻게 은폐하려 했나요?',
                maxLines: 3,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppTokens.sp6),
              // ── 3. 결정적 증거 선택 ─────────────────────────────
              MSKicker(
                '3. 결정적 증거 · ${_selectedEvidences.length}/$_maxEvidenceCount 선택',
              ),
              const SizedBox(height: AppTokens.sp3),
              _EvidenceSelector(
                evidences: _unlockedEvidences(controller),
                selected: _selectedEvidences,
                onToggle: _toggleEvidence,
                maxCount: _maxEvidenceCount,
              ),
              const SizedBox(height: AppTokens.sp6),
              // ── 4. 종합 추리 설명 ───────────────────────────────
              const MSKicker('4. 종합 추리 설명'),
              const SizedBox(height: AppTokens.sp3),
              MSTextField(
                controller: _summaryCtrl,
                hintText: '사건의 전말을 상세히 기록해주세요.',
                maxLines: 5,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppTokens.sp8),
              // ── 5. 제출 버튼 ────────────────────────────────────
              MSButton(
                label: _submitting ? '제출 중...' : '최종 추리 제출',
                variant: MSButtonVariant.danger,
                expanded: true,
                onPressed: _canSubmit ? _onSubmit : null,
              ),
              const SizedBox(height: AppTokens.sp10),
            ],
          ),
        ),
      ),
    );
  }

  /// 제시 가능한(해금된) 증거. 서버 연동 시 백엔드 정수 ID를 가진다.
  List<Evidence> _unlockedEvidences(GameSessionController controller) =>
      controller.evidences.where((e) => !e.isLocked).toList();
}

// ── 용의자 드롭다운 ───────────────────────────────────────────────────────────

class _SuspectDropdown extends StatelessWidget {
  const _SuspectDropdown({
    required this.suspects,
    required this.selected,
    required this.onSelect,
  });

  final List<Suspect> suspects;
  final Suspect? selected;
  final ValueChanged<Suspect?> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.sp3,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppTokens.r3),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Suspect>(
          value: selected,
          isExpanded: true,
          dropdownColor: c.bgElev,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: c.textSub,
            size: 20,
          ),
          hint: Text(
            '범인 선택',
            style: AppText.body.copyWith(color: c.textMute),
          ),
          style: AppText.body.copyWith(color: c.text),
          items: suspects.map((s) {
            return DropdownMenuItem<Suspect>(
              value: s,
              child: Text('${s.name} · ${s.role}'),
            );
          }).toList(),
          onChanged: onSelect,
        ),
      ),
    );
  }
}

// ── 증거 선택 영역 ────────────────────────────────────────────────────────────

class _EvidenceSelector extends StatelessWidget {
  const _EvidenceSelector({
    required this.evidences,
    required this.selected,
    required this.onToggle,
    required this.maxCount,
  });

  final List<Evidence> evidences;
  final List<Evidence> selected;
  final ValueChanged<Evidence> onToggle;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    if (evidences.isEmpty) {
      return Text(
        '제출할 수 있는 증거가 아직 없습니다.',
        style: AppText.bodySm.copyWith(color: c.textSub),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (selected.isNotEmpty) ...[
          Wrap(
            spacing: AppTokens.sp2,
            runSpacing: AppTokens.sp2,
            children: selected
                .map(
                  (e) => GestureDetector(
                onTap: () => onToggle(e),
                child: MSPill(e.name, tone: MSPillTone.primary),
              ),
            )
                .toList(),
          ),
          const SizedBox(height: AppTokens.sp3),
        ],
        ...evidences.map(
              (e) {
            final bool isSelected = selected.contains(e);
            final bool isDisabled =
                !isSelected && selected.length >= maxCount;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppTokens.sp2),
              child: GestureDetector(
                onTap: isDisabled ? null : () => onToggle(e),
                child: AnimatedContainer(
                  duration: AppMotion.dur2,
                  curve: AppMotion.easeOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.sp3,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color:
                    isSelected ? c.primarySoft : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? c.primary : c.line,
                    ),
                    borderRadius: BorderRadius.circular(AppTokens.r3),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle_outline
                            : Icons.radio_button_unchecked,
                        size: 16,
                        color: isSelected
                            ? c.primary
                            : isDisabled
                            ? c.textMute
                            : c.textSub,
                      ),
                      const SizedBox(width: AppTokens.sp3),
                      Expanded(
                        child: Text(
                          e.name,
                          style: AppText.body.copyWith(
                            fontSize: 13,
                            color: isDisabled ? c.textMute : c.text,
                          ),
                        ),
                      ),
                      Text(
                        e.location,
                        style: AppText.monoLabel.copyWith(
                          fontSize: 9.5,
                          color: c.textMute,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
