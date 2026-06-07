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
  final _motiveCtrl  = TextEditingController();
  final _methodCtrl  = TextEditingController();
  final _concealCtrl = TextEditingController();
  final _summaryCtrl = TextEditingController();
  final _evidence    = <Evidence>[];
  bool  _submitting  = false;

  static const _maxEvidence  = 3;
  static const _minText      = 5;
  static const _minSummary   = 10;

  @override
  void initState() {
    super.initState();
    final s = widget.initialSuspect;
    _selectedSuspect = (s != null && !s.isWitness) ? s : null;
  }

  @override
  void dispose() {
    _motiveCtrl.dispose(); _methodCtrl.dispose();
    _concealCtrl.dispose(); _summaryCtrl.dispose();
    super.dispose();
  }

  List<SubmitRequirement> get _reqs => [
    SubmitRequirement('진범을 지목했습니다',           _selectedSuspect != null),
    SubmitRequirement('범행 동기 $_minText자 이상',    _motiveCtrl.text.trim().length  >= _minText),
    SubmitRequirement('범행 방법 $_minText자 이상',    _methodCtrl.text.trim().length  >= _minText),
    SubmitRequirement('은폐 방법 $_minText자 이상',    _concealCtrl.text.trim().length >= _minText),
    SubmitRequirement('종합 추리 $_minSummary자 이상', _summaryCtrl.text.trim().length >= _minSummary),
    SubmitRequirement('결정적 증거 $_maxEvidence개',   _evidence.length == _maxEvidence),
  ];

  bool get _allMet    => _reqs.every((r) => r.met);
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
        MaterialPageRoute(builder: (_) => ResultScreen(sessionId: sessionId)));
  }

  Future<void> _onSubmit() async {
    final ctrl      = context.sessionRead;
    final sessionId = ctrl.backendSessionId;
    final culpritId = int.tryParse(_selectedSuspect?.id ?? '');
    if (!_canSubmit || sessionId == null || culpritId == null) {
      _snack(sessionId == null ? '세션 준비 중입니다. 잠시 후 다시 시도해 주세요.' : '모든 항목을 입력해주세요.');
      return;
    }
    final ok = await showDialog<bool>(
      context: context, barrierColor: context.c.scrim,
      builder: (_) => const SubmitConfirmDialog(),
    );
    if (ok != true || !mounted) return;

    setState(() => _submitting = true);
    try {
      await playSessionRepo.submitFinalDeduction(sessionId,
        selectedCulpritId:   culpritId,
        motiveText:           _motiveCtrl.text.trim(),
        methodText:           _methodCtrl.text.trim(),
        coverUpText:          _concealCtrl.text.trim(),
        selectedEvidenceIds: _evidence.map((e) => int.tryParse(e.id)).whereType<int>().toList(),
      );
      if (mounted) _navigateToResult(sessionId);
    } on ApiException catch (e) {
      if (!mounted) return;

      // 케이스 1: 이미 제출이 완료되어 중복 제출 에러가 난 경우 -> 결과 화면으로 이동 가능
      if (e.code == 'FINAL_DEDUCTION_ALREADY_SUBMITTED') {
        _snack('이미 제출됐습니다. 결과 화면으로 이동합니다.', dur: const Duration(seconds: 2));
        await Future.delayed(const Duration(milliseconds: 1800));
        _navigateToResult(sessionId);
      }
      // 케이스 2: 5xx 서버 에러 혹은 기타 API 에러 -> 폼을 유지하고 다시 시도할 수 있게 함
      else {
        setState(() => _submitting = false); // 다시 버튼 활성화 및 로딩 해제
        final s = e.status ?? 0;
        if (s >= 500) {
          _snack('채점 서버에 일시적인 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.');
        } else {
          _snack('제출 실패: ${e.message}');
        }
      }
    } catch (_) {
      if (!mounted) return;
      // 케이스 3: 네트워크 단절, 타임아웃 등 일반 예외 -> 유저가 다시 제출할 수 있도록 폼 유지
      setState(() => _submitting = false);
      _snack('네트워크 연결이 불안정합니다. 연결 상태를 확인하고 다시 시도해 주세요.');
    }
  }

  void _snack(String msg, {Duration dur = const Duration(seconds: 5)}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), duration: dur,
          behavior: SnackBarBehavior.floating, backgroundColor: context.c.danger));
  }

  @override
  Widget build(BuildContext context) {
    final c        = context.c;
    final suspects = context.session.suspects.where((s) => !s.isWitness).toList();
    final selected = suspects.where((s) => s.id == _selectedSuspect?.id).firstOrNull;
    final unlocked = context.session.evidences.where((e) => !e.isLocked).toList();

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.sp4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: AppTokens.sp6),
            SubmitHeader(dangerColor: c.danger, subColor: c.textSub, textColor: c.text),
            const SizedBox(height: AppTokens.sp8),
            const MSKicker('1. FINAL SUSPECT · 진범 지목'),
            const SizedBox(height: AppTokens.sp3),
            SuspectDropdown(suspects: suspects, selected: selected,
                onSelect: (s) => setState(() => _selectedSuspect = s)),
            const SizedBox(height: AppTokens.sp6),
            const MSKicker('2. 범행 동기 및 방법'),
            const SizedBox(height: AppTokens.sp3),
            MSTextField(controller: _motiveCtrl, hintText: '범인이 피해자를 해친 동기는 무엇인가요?',
                maxLines: 3, onChanged: (_) => setState(() {})),
            const SizedBox(height: AppTokens.sp3),
            MSTextField(controller: _methodCtrl, hintText: '어떤 방법으로 범행을 저질렀나요?',
                maxLines: 3, onChanged: (_) => setState(() {})),
            const SizedBox(height: AppTokens.sp3),
            MSTextField(controller: _concealCtrl, hintText: '범행을 어떻게 은폐하려 했나요?',
                maxLines: 3, onChanged: (_) => setState(() {})),
            const SizedBox(height: AppTokens.sp6),
            MSKicker('3. 결정적 증거 · ${_evidence.length}/$_maxEvidence 선택'),
            const SizedBox(height: AppTokens.sp3),
            EvidenceSelector(evidences: unlocked, selected: _evidence,
                onToggle: _toggle, maxCount: _maxEvidence),
            const SizedBox(height: AppTokens.sp6),
            const MSKicker('4. 종합 추리 설명'),
            const SizedBox(height: AppTokens.sp3),
            MSTextField(controller: _summaryCtrl, hintText: '사건의 전말을 상세히 기록해주세요.',
                maxLines: 5, onChanged: (_) => setState(() {})),
            const SizedBox(height: AppTokens.sp8),
            if (!_allMet) ...[
              SubmitChecklist(requirements: _reqs),
              const SizedBox(height: AppTokens.sp4),
            ],
            MSButton(label: _submitting ? '제출 중...' : '최종 추리 제출',
                variant: MSButtonVariant.danger, expanded: true,
                onPressed: _canSubmit ? _onSubmit : null),
            const SizedBox(height: AppTokens.sp10),
          ]),
        ),
      ),
    );
  }
}