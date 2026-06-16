// lib/screens/submit_screen.dart
import 'package:flutter/material.dart';
import '../components/ms_button.dart';
import '../components/ms_kicker.dart';
import '../components/ms_text_field.dart';
import '../controllers/game_session_provider.dart';
import '../core/api/api_exception.dart';
import '../models/case.dart';
import '../repositories/play_session_repository.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import 'result_screen.dart';
import 'submit_widgets.dart';

class SubmitScreen extends StatefulWidget {
  const SubmitScreen({this.initialSuspect, super.key});
  final Suspect? initialSuspect;
  @override
  State<SubmitScreen> createState() => _SubmitScreenState();
}

class _SubmitScreenState extends State<SubmitScreen> {
  Suspect? _selectedSuspect;
  final _motiveCtrl = TextEditingController();
  final _methodCtrl = TextEditingController();
  final _concealCtrl = TextEditingController();
  final _summaryCtrl = TextEditingController();
  final _evidence = <Evidence>[];
  bool _submitting = false;

  static const _minEvidence = 1;
  static const _maxEvidence = 15;
  static const _minText = 5;

  // 제출 가능 상태 변경 여부를 추적하여 불필요한 리빌드를 방지하는 변수
  bool _wasAllMet = false;

  @override
  void initState() {
    super.initState();
    final s = widget.initialSuspect;
    _selectedSuspect = (s != null && !s.isWitness) ? s : null;
    _wasAllMet = _allMet;

    _motiveCtrl.addListener(_onTextChanged);
    _methodCtrl.addListener(_onTextChanged);
    _concealCtrl.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _motiveCtrl.removeListener(_onTextChanged);
    _methodCtrl.removeListener(_onTextChanged);
    _concealCtrl.removeListener(_onTextChanged);

    _motiveCtrl.dispose();
    _methodCtrl.dispose();
    _concealCtrl.dispose();
    _summaryCtrl.dispose();
    super.dispose();
  }

  // 필수 조건 만족 여부가 바뀔 때만 setState를 호출해 리빌드를 최소화합니다.
  void _onTextChanged() {
    final currentAllMet = _allMet;
    if (_wasAllMet != currentAllMet || !currentAllMet) {
      if (mounted) {
        setState(() {
          _wasAllMet = currentAllMet;
        });
      }
    }
  }

  List<SubmitRequirement> get _reqs => [
    SubmitRequirement('진범을 지목했습니다', _selectedSuspect != null),
    SubmitRequirement(
      '범행 동기 $_minText자 이상',
      _motiveCtrl.text.trim().length >= _minText,
    ),
    SubmitRequirement(
      '범행 방법 $_minText자 이상',
      _methodCtrl.text.trim().length >= _minText,
    ),
    SubmitRequirement(
      '은폐 방법 $_minText자 이상',
      _concealCtrl.text.trim().length >= _minText,
    ),
    SubmitRequirement(
      '제출 증거 $_minEvidence~$_maxEvidence개',
      _evidence.length >= _minEvidence && _evidence.length <= _maxEvidence,
    ),
  ];

  bool get _allMet => _reqs.every((r) => r.met);
  bool get _canSubmit => !_submitting && _allMet;

  void _toggle(Evidence e) => setState(() {
    _evidence.contains(e)
        ? _evidence.remove(e)
        : (_evidence.length < _maxEvidence ? _evidence.add(e) : null);
  });

  void _navigateToResult(int sessionId) {
    if (!mounted) return;
    context.sessionRead.completeSession();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ResultScreen(sessionId: sessionId)),
    );
  }

  Future<void> _onSubmit() async {
    final ctrl = context.sessionRead;
    final sessionId = ctrl.backendSessionId;
    final culpritId = int.tryParse(_selectedSuspect?.id ?? '');
    if (!_canSubmit || sessionId == null || culpritId == null) {
      _snack(
        sessionId == null ? '세션 준비 중입니다. 잠시 후 다시 시도해 주세요.' : '모든 항목을 입력해주세요.',
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: context.c.scrim,
      builder: (_) => const SubmitConfirmDialog(),
    );
    if (ok != true || !mounted) return;

    ctrl.setFinalDeductionSubmitting(true);
    setState(() => _submitting = true);
    var navigatingToResult = false;
    try {
      await playSessionRepo.submitFinalDeduction(
        sessionId,
        selectedCulpritId: culpritId,
        motiveText: _motiveCtrl.text.trim(),
        methodText: _methodCtrl.text.trim(),
        coverUpText: _concealCtrl.text.trim(),
        selectedEvidenceIds: _evidence
            .map((e) => int.tryParse(e.id))
            .whereType<int>()
            .toList(),
      );
      if (mounted) {
        navigatingToResult = true;
        _navigateToResult(sessionId);
      }
    } on ApiException catch (e) {
      if (!mounted) return;

      if (e.code == 'AI010' || e.code == 'FINAL_DEDUCTION_ALREADY_SUBMITTED') {
        _snack('이미 제출됐습니다. 결과 화면으로 이동합니다.', dur: const Duration(seconds: 2));
        await Future.delayed(const Duration(milliseconds: 1800));
        navigatingToResult = true;
        _navigateToResult(sessionId);
      } else {
        ctrl.setFinalDeductionSubmitting(false);
        setState(() => _submitting = false);
        final s = e.status ?? 0;
        if (s >= 500) {
          _snack('채점 서버에 일시적인 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.');
        } else {
          _snack('제출 실패: ${e.message}');
        }
      }
    } catch (_) {
      if (!mounted) return;
      ctrl.setFinalDeductionSubmitting(false);
      setState(() => _submitting = false);
      _snack('네트워크 연결이 불안정합니다. 연결 상태를 확인하고 다시 시도해 주세요.');
    } finally {
      if (!navigatingToResult) {
        ctrl.setFinalDeductionSubmitting(false);
      }
    }
  }

  void _snack(String msg, {Duration dur = const Duration(seconds: 5)}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          duration: dur,
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.c.danger,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    final suspects = context.session.accusableSuspects;

    final selected = suspects
        .where((s) => s.id == _selectedSuspect?.id)
        .firstOrNull;
    final unlocked = context.session.evidences
        .where((e) => !e.isLocked)
        .toList();

    return PopScope(
      canPop: !_submitting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _submitting) {
          _snack('최종 추리 제출 중입니다. 결과 확인까지 잠시만 기다려 주세요.');
        }
      },
      child: Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.sp4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppTokens.sp6),
                SubmitHeader(
                  dangerColor: c.danger,
                  subColor: c.textSub,
                  textColor: c.text,
                ),
                const SizedBox(height: AppTokens.sp8),
                const MSKicker('1. FINAL SUSPECT · 진범 지목'),
                const SizedBox(height: AppTokens.sp3),
                SuspectDropdown(
                  suspects: suspects,
                  selected: selected,
                  onSelect: (s) => setState(() => _selectedSuspect = s),
                ),
                const SizedBox(height: AppTokens.sp6),
                const MSKicker('2. 범행 동기 및 방법'),
                const SizedBox(height: AppTokens.sp3),
                MSTextField(
                  controller: _motiveCtrl,
                  hintText: '범인이 피해자를 해친 동기는 무엇인가요?',
                  maxLines: 3,
                ),
                const SizedBox(height: AppTokens.sp3),
                MSTextField(
                  controller: _methodCtrl,
                  hintText: '어떤 방법으로 범행을 저질렀나요?',
                  maxLines: 3,
                ),
                const SizedBox(height: AppTokens.sp3),
                MSTextField(
                  controller: _concealCtrl,
                  hintText: '범행을 어떻게 은폐하려 했나요?',
                  maxLines: 3,
                ),
                const SizedBox(height: AppTokens.sp6),
                MSKicker('3. 제출 증거 · ${_evidence.length}/$_maxEvidence 선택'),
                const SizedBox(height: AppTokens.sp3),
                EvidenceSelector(
                  evidences: unlocked,
                  selected: _evidence,
                  onToggle: _toggle,
                  maxCount: _maxEvidence,
                ),
                const SizedBox(height: AppTokens.sp6),
                const MSKicker('4. 종합 추리 설명 (선택 사항)'),
                const SizedBox(height: AppTokens.sp3),
                MSTextField(
                  controller: _summaryCtrl,
                  hintText: '사건의 전말을 자유롭게 메모해 보세요. (제출 시 저장되지 않습니다.)',
                  maxLines: 5,
                ),
                const SizedBox(height: AppTokens.sp8),
                if (!_allMet) ...[
                  SubmitChecklist(requirements: _reqs),
                  const SizedBox(height: AppTokens.sp4),
                ],
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
      ),
    );
  }
}
