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

  @override
  QuestionType? prefillQuestionType;

  bool _initialized = false;
  String _lastPrefilledText = '';

  @override
  void initState() {
    super.initState();

    // 초기 주입 질문 바인딩 및 타입 추적 초기화
    if (widget.initialQuestion?.trim().isNotEmpty == true) {
      final initialText = widget.initialQuestion!.trim();
      inputCtrl.text = initialText;
      inputCtrl.selection = TextSelection.collapsed(offset: inputCtrl.text.length);
      prefillEvidenceId = widget.presentedEvidenceId;
      prefillEvidenceTitle = widget.presentedEvidenceTitle ?? '선택된 증거';

      prefillQuestionType = QuestionType.recommended;
      _lastPrefilledText = initialText;
    }

    // 유저가 프리필된 추천 가이드를 수정하면 즉시 점수 및 가이드 타입(RECOMMENDED) 무효화 처리
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

  /// 텍스트 리스너: 추천 질문이 수정되었는지 검증 및 상태 동기화
  void _handleInputTextChanged() {
    if (prefillQuestionType != null && inputCtrl.text != _lastPrefilledText) {
      setState(() {
        prefillQuestionType = null;
      });
    }
  }

  @override
  void onChipPrefill(SuggestedQuestionInfo sq) {
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
              onPrefill: onChipPrefill,
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