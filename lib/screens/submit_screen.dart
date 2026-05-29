// lib/screens/submit_screen.dart
import 'package:flutter/material.dart';
import '../components/ms_button.dart';
import '../components/ms_kicker.dart';
import '../components/ms_pill.dart';
import '../components/ms_text_field.dart';
import '../controllers/game_session_provider.dart';
import '../models/case.dart';
import '../models/sample_case.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import 'result_screen.dart';

class SubmitScreen extends StatefulWidget {
  const SubmitScreen({super.key});

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

  // 정답 데이터 (백엔드에서 내려올 값 — 현재는 하드코딩)
  static const String _correctSuspectId = 's1';
  static const List<String> _correctEvidenceIds = ['e3', 'e1', 'e5'];

  @override
  void dispose() {
    _motiveCtrl.dispose();
    _methodCtrl.dispose();
    _concealCtrl.dispose();
    _summaryCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
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

  // ── 점수 계산 (PRD Section 13) ────────────────────────────────────────────
  //
  // [설계 원칙]
  // _ScoreBreakdown 이 per-section 점수를 모두 보유한다.
  // _calculateRawScore() 와 _buildResult() 는 둘 다 이 객체를 사용하기 때문에
  // 표시된 항목 점수 합계 = totalScore 가 항상 보장된다.

  _ScoreBreakdown _evaluate() {
    // 범인 (30점)
    final suspectScore =
    _selectedSuspect?.id == _correctSuspectId ? 30 : 0;

    // 범행 동기 키워드 (20점 / 부분 8점)
    final motive = _motiveCtrl.text.toLowerCase();
    final motiveScore =
    (motive.contains('자금') ||
        motive.contains('횡령') ||
        motive.contains('유용'))
        ? 20
        : (motive.length > 10 ? 8 : 0);

    // 범행 방법 키워드 (25점 / 부분 10점)
    final method = _methodCtrl.text.toLowerCase();
    final methodScore =
    (method.contains('알레르기') || method.contains('에피펜'))
        ? 25
        : (method.length > 10 ? 10 : 0);

    // 은폐 방법 (10점)
    final concealScore = _concealCtrl.text.length > 10 ? 10 : 0;

    // 결정적 증거 (각 5점, 최대 15점)
    final evidenceScore = _selectedEvidences
        .where((e) => _correctEvidenceIds.contains(e.id))
        .length
        .clamp(0, 3) *
        5;

    return _ScoreBreakdown(
      suspectScore: suspectScore,
      motiveScore: motiveScore,
      methodScore: methodScore,
      concealScore: concealScore,
      evidenceScore: evidenceScore,
    );
  }

  void _onSubmit() {
    if (!_canSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 항목을 입력해주세요.')),
      );
      return;
    }

    final breakdown = _evaluate();
    // 세션 종료 + 힌트 감점 적용
    context.sessionRead.completeSession(rawScore: breakdown.total);
    final finalScore = context.sessionRead.finalScore ?? 0;
    final hintPenalty = context.sessionRead.hintPenalty;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          result: _buildResult(
            breakdown: breakdown,
            finalScore: finalScore,
            hintPenalty: hintPenalty,
          ),
        ),
      ),
    );
  }

  CaseResult _buildResult({
    required _ScoreBreakdown breakdown,
    required int finalScore,
    required int hintPenalty,
  }) {
    // breakdown 의 per-section 값을 그대로 ScoreItem 에 사용하기 때문에
    // scoreItems 합계 == finalScore 가 항상 보장된다.
    final grade = _gradeFromScore(finalScore);

    return CaseResult(
      grade: grade,
      totalScore: finalScore,
      maxScore: 100,
      scoreItems: [
        ScoreItem(
          label: '진범 지목',
          score: breakdown.suspectScore,
          maxScore: 30,
        ),
        ScoreItem(
          label: '범행 방법',
          score: breakdown.methodScore,
          maxScore: 25,
        ),
        ScoreItem(
          label: '범행 동기',
          score: breakdown.motiveScore,
          maxScore: 20,
        ),
        ScoreItem(
          label: '은폐 방법',
          score: breakdown.concealScore,
          maxScore: 10,
        ),
        ScoreItem(
          label: '결정적 증거',
          score: breakdown.evidenceScore,
          maxScore: 15,
        ),
        if (hintPenalty > 0)
          ScoreItem(
            label: '힌트 감점',
            score: -hintPenalty,
            maxScore: 0,
          ),
      ],
      culpritName: '박재민',
      revelation: '박재민 CFO는 회사 자금 유용 사실이 데모데이에서 공개될 위기에 놓이자, '
          '피해자의 견과류 알레르기를 이용해 아몬드라떼를 마시게 하고 에피펜을 숨겼다. '
          '이후 피해자의 휴대폰으로 메시지를 보내 사망 시간을 조작했다.',
    );
  }

  String _gradeFromScore(int score) {
    if (score >= 90) return 'S';
    if (score >= 80) return 'A';
    if (score >= 70) return 'B';
    if (score >= 60) return 'C';
    return 'D';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

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
                label: '최종 추리 제출',
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
}

// ── 용의자 드롭다운 ───────────────────────────────────────────────────────────

class _SuspectDropdown extends StatelessWidget {
  const _SuspectDropdown({
    required this.selected,
    required this.onSelect,
  });

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
          items: sampleCase.suspects.map((s) {
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
    required this.selected,
    required this.onToggle,
    required this.maxCount,
  });

  final List<Evidence> selected;
  final ValueChanged<Evidence> onToggle;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final unlocked =
    sampleCase.evidences.where((e) => !e.isLocked).toList();

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
        ...unlocked.map(
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

// ── 채점 분해 값 객체 ─────────────────────────────────────────────────────────
//
// _evaluate() 의 반환값.
// _calculateRawScore() 와 _buildResult() 가 동일한 출처에서 파생되므로
// 결과 화면에 표시되는 항목 점수 합계가 최종 점수와 항상 일치한다.

class _ScoreBreakdown {
  const _ScoreBreakdown({
    required this.suspectScore,
    required this.motiveScore,
    required this.methodScore,
    required this.concealScore,
    required this.evidenceScore,
  });

  final int suspectScore;
  final int motiveScore;
  final int methodScore;
  final int concealScore;
  final int evidenceScore;

  int get total =>
      (suspectScore + motiveScore + methodScore + concealScore + evidenceScore)
          .clamp(0, 100);
}