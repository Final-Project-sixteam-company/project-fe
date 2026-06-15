// lib/screens/interrogation_chat_screen.dart
import 'package:flutter/material.dart';
import '../components/game_modals.dart';
import '../components/ms_button.dart';
import '../components/ms_text_field.dart';
import '../components/states.dart';
import '../controllers/game_session_provider.dart';
import '../core/api/api_exception.dart';
import '../models/case.dart';
import '../models/play_models.dart';
import '../models/session_models.dart';
import '../repositories/play_session_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

enum _Sender { detective, suspect }

class _Message {
  const _Message({
    required this.text,
    required this.sender,
    this.presentedEvidenceId,
  });

  final String text;
  final _Sender sender;
  final String? presentedEvidenceId;
}

const _suggestedQuestions = [
  '그 시간대에 어디에 있었나요?',
  '사건 관계자와 어떤 관계인가요?',
  '마지막으로 관련자를 본 건 언제인가요?',
  '알리바이를 증명할 수 있나요?',
  '확인해야 할 다른 정황이 있나요?',
];

class InterrogationChatScreen extends StatefulWidget {
  const InterrogationChatScreen({
    required this.suspect,
    this.initialQuestion,
    this.presentedEvidenceId,
    this.presentedEvidenceTitle,
    super.key,
  });

  final Suspect suspect;

  /// Guidance 추천 질문 prefill 텍스트. null이면 prefill 없음.
  final String? initialQuestion;

  /// Guidance 추천 질문에 연결된 증거 ID (EVIDENCE_PRESENTED 전송용).
  final String? presentedEvidenceId;

  /// Guidance 추천 질문에 연결된 증거 제목 (입력 바 위 표시용).
  final String? presentedEvidenceTitle;

  @override
  State<InterrogationChatScreen> createState() =>
      _InterrogationChatScreenState();
}

class _InterrogationChatScreenState extends State<InterrogationChatScreen> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<_Message> _messages = [];
  bool _isWaiting = false;
  bool _initialized = false;

  /// Guidance prefill로 설정된 증거 ID. 첫 전송에 사용 후 null로 리셋.
  String? _prefillEvidenceId;

  /// Guidance prefill로 설정된 증거 이름 표시용 상태 변수.
  String? _prefillEvidenceTitle;

  /// Chip/guidance prefill로 설정된 질문 타입. 전송 후 기본 FREE로 리셋한다.
  QuestionType _prefillQuestionType = QuestionType.free;

  /// Prefill 원문. 사용자가 내용을 바꾸면 추천 질문 타입을 FREE로 되돌린다.
  String? _prefillQuestionText;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    // 같은 세션 내에서 이전에 이 용의자와 나눈 심문 기록을 복원한다.
    final controller = context.sessionRead;
    final priorLogs = controller.interrogationLogs.where(
      (log) => log.suspectId == widget.suspect.id,
    );
    for (final log in priorLogs) {
      _messages.add(
        _Message(
          text: log.question,
          sender: _Sender.detective,
          presentedEvidenceId: log.presentedEvidenceId,
        ),
      );
      _messages.add(_Message(text: log.answer, sender: _Sender.suspect));
    }

    if (_messages.isEmpty) {
      final raw = controller.rawSuspect(widget.suspect.id);
      final statement = raw?.publicStatement?.trim();
      final opening = (statement != null && statement.isNotEmpty)
          ? statement
          : '무엇이 궁금하신가요? 질문해 주세요.';
      _messages.add(_Message(text: opening, sender: _Sender.suspect));
    }

    // Guidance 추천 질문 prefill — 최초 1회만 설정
    if (widget.initialQuestion?.trim().isNotEmpty == true) {
      final presentedEvidenceId = widget.presentedEvidenceId?.trim();
      final hasPresentedEvidence =
          presentedEvidenceId != null && presentedEvidenceId.isNotEmpty;
      _inputCtrl.text = widget.initialQuestion!.trim();
      _inputCtrl.selection = TextSelection.collapsed(
        offset: _inputCtrl.text.length,
      );
      _prefillEvidenceId = hasPresentedEvidence ? presentedEvidenceId : null;
      _prefillEvidenceTitle = hasPresentedEvidence
          ? (widget.presentedEvidenceTitle?.trim().isNotEmpty == true
                ? widget.presentedEvidenceTitle!.trim()
                : '선택된 증거')
          : null;
      _prefillQuestionType = hasPresentedEvidence
          ? QuestionType.evidencePresented
          : QuestionType.free;
      _prefillQuestionText = _inputCtrl.text;
    }

    _scrollToBottom();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(
    String text, {
    String? evidenceId,
    QuestionType questionType = QuestionType.free,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isWaiting) return;

    final controller = context.sessionRead;
    final sessionId = controller.backendSessionId;
    final suspectIdInt = int.tryParse(widget.suspect.id);

    final evidenceIdInt = evidenceId != null ? int.tryParse(evidenceId) : null;
    if (evidenceId != null && evidenceIdInt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이 증거는 제시할 수 없습니다. 다시 시도해 주세요.')),
      );
      return;
    }

    setState(() {
      _messages.add(
        _Message(
          text: trimmed,
          sender: _Sender.detective,
          presentedEvidenceId: evidenceId,
        ),
      );
      _isWaiting = true;
      _inputCtrl.clear();

      // 💡 리뷰어 피드백 반영: 메시지가 발송 스택에 진입하는 즉시
      // 이전에 머물러 있던 모든 가이드라인 prefill 상태를 안전하게 청소합니다.
      _prefillEvidenceId = null;
      _prefillEvidenceTitle = null;
      _prefillQuestionType = QuestionType.free;
      _prefillQuestionText = null;
    });

    _scrollToBottom();

    if (sessionId == null || suspectIdInt == null) {
      if (mounted) {
        setState(() {
          _messages.add(
            const _Message(
              text: '세션이 아직 준비되지 않았습니다. 잠시 후 다시 시도해 주세요.',
              sender: _Sender.suspect,
            ),
          );
          _isWaiting = false;
        });
        _scrollToBottom();
      }
      return;
    }

    final resolvedType = evidenceIdInt != null
        ? QuestionType.evidencePresented
        : questionType;

    String answer = '...대답을 거부하고 있습니다.';
    String? errorNotice;
    List<RelatedEvidence> unlockedEvidences = const [];
    try {
      final result = await playSessionRepo.interrogate(
        sessionId,
        suspectId: suspectIdInt,
        questionType: resolvedType,
        question: trimmed,
        presentedEvidenceId: evidenceIdInt,
      );
      answer = result.answer;
      unlockedEvidences = result.unlockedEvidences;

      if (!mounted) return;

      controller.addInterrogationLog(
        InterrogationLog(
          suspectId: widget.suspect.id,
          suspectName: widget.suspect.name,
          question: trimmed,
          answer: answer,
          askedAt: controller.elapsed,
          presentedEvidenceId: evidenceId,
        ),
      );
    } on ApiException {
      answer = '...지금은 대답하기 어려운 것 같습니다.';
      errorNotice = '응답을 받지 못했습니다. 잠시 후 다시 시도해 주세요.';
    } catch (_) {
      answer = '...지금은 대답하기 어려운 것 같습니다.';
      errorNotice = '오류가 발생했습니다. 잠시 후 다시 시도해 주세요.';
    } finally {
      if (mounted) {
        setState(() {
          _messages.add(_Message(text: answer, sender: _Sender.suspect));
          _isWaiting = false;
        });
        _scrollToBottom();
      }
    }

    if (errorNotice != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorNotice)));
    }

    if (unlockedEvidences.isNotEmpty && mounted) {
      await controller.refreshEvidences();
      if (mounted) {
        final names = unlockedEvidences.map((e) => e.title).join(', ');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('새로운 증거 확보: $names')));
      }
    }
  }

  Future<void> _presentEvidence() async {
    final evidence = await showEvidencePresentModal(context);
    if (evidence != null && mounted) {
      _prefillQuestion(
        '이 증거를 제시합니다: ${evidence.name}',
        evidenceId: evidence.id,
        evidenceTitle: evidence.name,
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollCtrl.hasClients) return;
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: AppMotion.dur3,
          curve: AppMotion.easeOut,
        );
      });
    });
  }

  void _prefillQuestion(
    String question, {
    String? evidenceId,
    String? evidenceTitle,
    QuestionType questionType = QuestionType.free,
  }) {
    final trimmed = question.trim();
    if (trimmed.isEmpty || _isWaiting) return;
    final normalizedEvidenceId = evidenceId?.trim();
    final hasEvidence =
        normalizedEvidenceId != null && normalizedEvidenceId.isNotEmpty;
    setState(() {
      _inputCtrl.text = trimmed;
      _inputCtrl.selection = TextSelection.collapsed(
        offset: _inputCtrl.text.length,
      );
      _prefillEvidenceId = hasEvidence ? normalizedEvidenceId : null;
      _prefillEvidenceTitle = hasEvidence
          ? (evidenceTitle?.trim().isNotEmpty == true
                ? evidenceTitle!.trim()
                : '선택된 증거')
          : null;
      _prefillQuestionType = hasEvidence
          ? QuestionType.evidencePresented
          : questionType;
      _prefillQuestionText = trimmed;
    });
  }

  void _prefillSuggestedQuestion(String question) {
    _prefillQuestion(question, questionType: QuestionType.recommended);
  }

  QuestionType _questionTypeForCurrentInput() {
    if (_prefillEvidenceId != null) return QuestionType.evidencePresented;
    if (_prefillQuestionType == QuestionType.recommended &&
        _prefillQuestionText == _inputCtrl.text.trim()) {
      return QuestionType.recommended;
    }
    return QuestionType.free;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              controller: _scrollCtrl,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.sp4,
                vertical: AppTokens.sp4,
              ),
              itemCount: _messages.length + (_isWaiting ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: AppTokens.sp2),
              itemBuilder: (_, i) {
                if (i == _messages.length && _isWaiting) {
                  return const _WaitingBubble();
                }
                final msg = _messages[i];
                return msg.sender == _Sender.suspect
                    ? _SuspectBubble(text: msg.text, suspect: widget.suspect)
                    : _DetectiveBubble(
                        text: msg.text,
                        evidenceId: msg.presentedEvidenceId,
                      );
              },
            ),
          ),
          _SuggestedQuestions(
            onSelect: _prefillSuggestedQuestion,
            disabled: _isWaiting,
          ),
          const SizedBox(height: AppTokens.sp3),
          _InputBar(
            controller: _inputCtrl,
            prefillEvidenceTitle: _prefillEvidenceTitle, // 💡 증거 제시 가이드 UI 연동
            onClearPrefill: () {
              setState(() {
                _prefillEvidenceId = null;
                _prefillEvidenceTitle = null;
                _prefillQuestionType = QuestionType.free;
                _prefillQuestionText = null;
              });
            },
            onSend: () {
              _sendMessage(
                _inputCtrl.text,
                evidenceId: _prefillEvidenceId,
                questionType: _questionTypeForCurrentInput(),
              );
            },
            onPresentEvidence: _isWaiting ? null : _presentEvidence,
            disabled: _isWaiting,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final c = context.c;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: c.text),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.suspect.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.titleM.copyWith(color: c.text),
          ),
          Text(
            widget.suspect.role,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.bodySm.copyWith(color: c.textSub),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: '힌트 보기',
          onPressed: () {
            final sessionId = context.sessionRead.backendSessionId;
            if (sessionId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('세션이 아직 준비되지 않았습니다. 잠시 후 다시 시도해 주세요.'),
                ),
              );
              return;
            }
            showHintModal(context, sessionId: sessionId);
          },
          icon: Icon(Icons.lightbulb_outline, color: c.primary),
        ),
        Padding(
          padding: const EdgeInsets.only(right: AppTokens.sp2),
          child: IconButton(
            tooltip: '증거 제시',
            onPressed: _isWaiting ? null : _presentEvidence,
            icon: Icon(Icons.description_outlined, color: c.primary),
          ),
        ),
      ],
    );
  }
}

class _SuspectBubble extends StatelessWidget {
  const _SuspectBubble({required this.text, required this.suspect});

  final String text;
  final Suspect suspect;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final initial = suspect.name.isNotEmpty
        ? suspect.name.characters.first
        : '?';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.tealBase, AppColors.skyBase],
            ),
            borderRadius: BorderRadius.circular(AppTokens.r2),
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: AppText.monoLabel.copyWith(
              fontSize: 10,
              color: AppColors.ink950,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(width: AppTokens.sp2),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.sp3,
              vertical: AppTokens.sp2,
            ),
            decoration: BoxDecoration(
              color: c.bgElev,
              border: Border.all(color: c.line),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTokens.r1),
                topRight: Radius.circular(AppTokens.r4),
                bottomLeft: Radius.circular(AppTokens.r4),
                bottomRight: Radius.circular(AppTokens.r4),
              ),
            ),
            child: Text(
              text,
              style: AppText.body.copyWith(
                fontSize: 13,
                color: c.text,
                height: 1.55,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppTokens.sp10),
      ],
    );
  }
}

class _DetectiveBubble extends StatelessWidget {
  const _DetectiveBubble({required this.text, this.evidenceId});

  final String text;
  final String? evidenceId;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isEvidence = evidenceId != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(width: AppTokens.sp10),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.sp3,
              vertical: AppTokens.sp2,
            ),
            decoration: BoxDecoration(
              color: isEvidence ? c.successSoft : c.primarySoft,
              border: Border.all(color: isEvidence ? c.success : c.primary),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTokens.r4),
                topRight: Radius.circular(AppTokens.r1),
                bottomLeft: Radius.circular(AppTokens.r4),
                bottomRight: Radius.circular(AppTokens.r4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isEvidence) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 12,
                        color: c.success,
                      ),
                      const SizedBox(width: AppTokens.sp1),
                      Text(
                        '증거 제시',
                        style: AppText.monoLabel.copyWith(
                          fontSize: 10,
                          color: c.success,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.sp1),
                ],
                Text(
                  text,
                  style: AppText.body.copyWith(
                    fontSize: 13,
                    color: isEvidence ? c.text : c.primary,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WaitingBubble extends StatelessWidget {
  const _WaitingBubble();

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: c.bgHover,
            borderRadius: BorderRadius.circular(AppTokens.r2),
          ),
          alignment: Alignment.center,
          child: MSSpinner(size: 12, color: c.primary),
        ),
        const SizedBox(width: AppTokens.sp2),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.sp3,
            vertical: AppTokens.sp2,
          ),
          decoration: BoxDecoration(
            color: c.bgElev,
            border: Border.all(color: c.line),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppTokens.r1),
              topRight: Radius.circular(AppTokens.r4),
              bottomLeft: Radius.circular(AppTokens.r4),
              bottomRight: Radius.circular(AppTokens.r4),
            ),
          ),
          child: MSSpinner(size: 16, color: c.textMute),
        ),
      ],
    );
  }
}

class _SuggestedQuestions extends StatelessWidget {
  const _SuggestedQuestions({required this.onSelect, required this.disabled});

  final ValueChanged<String> onSelect;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.sp4),
        itemCount: _suggestedQuestions.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppTokens.sp2),
        itemBuilder: (_, i) {
          return GestureDetector(
            onTap: disabled ? null : () => onSelect(_suggestedQuestions[i]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: c.line),
                borderRadius: BorderRadius.circular(AppTokens.rPill),
              ),
              alignment: Alignment.center,
              child: Text(
                _suggestedQuestions[i],
                style: AppText.bodySm.copyWith(
                  fontSize: 12,
                  color: disabled ? c.textMute : c.textSub,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.onPresentEvidence,
    required this.disabled,
    this.prefillEvidenceTitle,
    this.onClearPrefill,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onPresentEvidence;
  final bool disabled;
  final String? prefillEvidenceTitle;
  final VoidCallback? onClearPrefill;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final hasPrefill = prefillEvidenceTitle != null;

    return Container(
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(top: BorderSide(color: c.line)),
      ),
      padding: const EdgeInsets.all(AppTokens.sp3),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 💡 UX 피드백 반영: 가이드라인 추천 질문 연동 시 하단 패널에 명확한 연동 배너 제공
            if (hasPrefill) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.sp3,
                  vertical: AppTokens.sp2,
                ),
                margin: const EdgeInsets.only(bottom: AppTokens.sp2),
                decoration: BoxDecoration(
                  color: c.successSoft,
                  border: Border.all(color: c.success.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(AppTokens.r3),
                ),
                child: Row(
                  children: [
                    Icon(Icons.link, size: 14, color: c.success),
                    const SizedBox(width: AppTokens.sp2),
                    Expanded(
                      child: Text(
                        '증거 연동됨: $prefillEvidenceTitle',
                        style: AppText.bodySm.copyWith(
                          color: c.success,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 14, color: c.success),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onClearPrefill,
                    ),
                  ],
                ),
              ),
            ] else ...[
              MSButton(
                label: '증거 제시',
                variant: MSButtonVariant.secondary,
                icon: Icons.description_outlined,
                onPressed: onPresentEvidence,
              ),
              const SizedBox(height: AppTokens.sp2),
            ],
            Row(
              children: [
                Expanded(
                  child: MSTextField(
                    controller: controller,
                    hintText: '질문을 입력하세요...',
                    maxLength: 500,
                    onChanged: (_) {},
                  ),
                ),
                const SizedBox(width: AppTokens.sp2),
                MSButton(
                  label: '',
                  variant: MSButtonVariant.primary,
                  icon: Icons.send,
                  onPressed: disabled ? null : onSend,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
