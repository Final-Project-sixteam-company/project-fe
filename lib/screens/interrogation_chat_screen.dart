// lib/screens/interrogation_chat_screen.dart
import 'package:flutter/material.dart';
import '../controllers/game_session_provider.dart';
import '../models/case.dart';
import '../models/play_models.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import 'interrogation_actions_mixin.dart';
import 'interrogation_app_bar.dart';
import 'interrogation_bubbles.dart';
import 'interrogation_input_bar.dart';
import 'interrogation_suggested_questions.dart';
import 'interrogation_waiting_bubble.dart';

class InterrogationChatScreen extends StatefulWidget {
  const InterrogationChatScreen({
    required this.suspect,
    this.suggestedQuestions = const [],
    this.initialQuestion,
    this.presentedEvidenceId,
    this.presentedEvidenceTitle,
    super.key,
  });

  final Suspect suspect;
  final List<SuggestedQuestionInfo> suggestedQuestions;
  final String? initialQuestion;
  final String? presentedEvidenceId;
  final String? presentedEvidenceTitle;

  @override
  State<InterrogationChatScreen> createState() =>
      _InterrogationChatScreenState();
}

class _InterrogationChatScreenState extends State<InterrogationChatScreen>
    with InterrogationActionsMixin {

  @override
  String get suspectId => widget.suspect.id;
  @override
  String get suspectName => widget.suspect.name;
  @override
  String get backendSessionId_ => '';

  @override
  final TextEditingController inputCtrl = TextEditingController();
  @override
  final ScrollController scrollCtrl = ScrollController();
  @override
  final List<InterrogationMessage> messages = [];

  @override
  bool isWaiting = false;
  @override
  String? prefillEvidenceId;
  @override
  String? prefillEvidenceTitle;

  QuestionType? prefillQuestionType;

  bool _initialized = false;
  String _lastPrefilledText = '';

  @override
  void initState() {
    super.initState();

    // 초기 주입 질문이 있을 경우 세팅
    if (widget.initialQuestion?.trim().isNotEmpty == true) {
      final initialText = widget.initialQuestion!.trim();
      inputCtrl.text = initialText;
      inputCtrl.selection = TextSelection.collapsed(offset: inputCtrl.text.length);
      prefillEvidenceId = widget.presentedEvidenceId;
      prefillEvidenceTitle = widget.presentedEvidenceTitle ?? '선택된 증거';

      // 초기 질문 역시 추천 질문 경로에서 왔다면 해당 타입 매핑 (기본값 RECOMMENDED 설정 가능)
      prefillQuestionType = QuestionType.recommended;
      _lastPrefilledText = initialText;
    }

    // 💡 안전장치 추가: 유저가 칩을 누른 뒤 텍스트를 임의로 수정하면 Free 타입으로 변경
    inputCtrl.addListener(_handleInputTextChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final ctrl = context.sessionRead;
    final logs = ctrl.interrogationLogs.where((l) => l.suspectId == widget.suspect.id);

    for (final log in logs) {
      messages
        ..add(InterrogationMessage(
            text: log.question,
            sender: InterrogationSender.detective,
            presentedEvidenceId: log.presentedEvidenceId))
        ..add(InterrogationMessage(text: log.answer, sender: InterrogationSender.suspect));
    }

    if (messages.isEmpty) {
      final stmt = ctrl.rawSuspect(widget.suspect.id)?.publicStatement?.trim();
      messages.add(InterrogationMessage(
        text: (stmt?.isNotEmpty == true) ? stmt! : '무엇이 궁금하신가요? 질문해 주세요.',
        sender: InterrogationSender.suspect,
      ));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());
  }

  @override
  void dispose() {
    inputCtrl.removeListener(_handleInputTextChanged);
    inputCtrl.dispose();
    scrollCtrl.dispose();
    super.dispose();
  }

  /// 입력창 텍스트 변경 리스너: 유저가 프리필된 추천 질문을 수정했는지 감지
  void _handleInputTextChanged() {
    if (prefillQuestionType != null && inputCtrl.text != _lastPrefilledText) {
      setState(() {
        // 유저가 한 글자라도 수정했다면 더 이상 추천 질문이 아니므로 일반 질문(free) 처리
        prefillQuestionType = null;
      });
    }
  }

  @override
  void onChipPrefill(SuggestedQuestionInfo sq) {
    // 부모 mixin의 기능을 실행하면서 스크린 단의 텍스트 변조 비교용 백업 데이터 갱신
    super.onChipPrefill(sq);
    _lastPrefilledText = sq.question;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.bg,
      appBar: InterrogationAppBar(
        suspect: widget.suspect,
        onPresentEvidence: presentEvidence,
        disabled: isWaiting,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              controller: scrollCtrl,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.sp4,
                vertical: AppTokens.sp4,
              ),
              itemCount: messages.length + (isWaiting ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: AppTokens.sp2),
              itemBuilder: (_, i) {
                if (i == messages.length && isWaiting) {
                  return const WaitingBubble();
                }
                final msg = messages[i];
                return msg.sender == InterrogationSender.suspect
                    ? SuspectBubble(text: msg.text, suspect: widget.suspect)
                    : DetectiveBubble(
                  text: msg.text,
                  evidenceId: msg.presentedEvidenceId,
                );
              },
            ),
          ),
          if (widget.suggestedQuestions.isNotEmpty)
            SuggestedQuestionsBar(
              questions: widget.suggestedQuestions,
              onPrefill: onChipPrefill, // 재정의된 온칩 프리필 호출
              disabled: isWaiting,
            ),
          InterrogationInputBar(
            controller: inputCtrl,
            prefillEvidenceTitle: prefillEvidenceTitle,
            onClearPrefill: () => setState(() {
              prefillEvidenceId = null;
              prefillEvidenceTitle = null;
              prefillQuestionType = null;
              _lastPrefilledText = '';
            }),
            onSend: () {
              final finalType = prefillEvidenceId != null
                  ? QuestionType.evidencePresented
                  : (prefillQuestionType ?? QuestionType.free);

              sendMessage(
                inputCtrl.text,
                evidenceId: prefillEvidenceId,
                questionType: finalType,
              );
            },
            onPresentEvidence: isWaiting ? null : presentEvidence,
            disabled: isWaiting,
          ),
        ],
      ),
    );
  }
}