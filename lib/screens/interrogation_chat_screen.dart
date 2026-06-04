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
  '어젯밤 10시에 어디 있었나요?',
  '피해자와의 관계는?',
  '마지막으로 피해자를 본 건 언제인가요?',
  '알리바이를 증명할 수 있나요?',
  '그날 밤 데모룸에 다시 들어간 적 있나요?',
];

class InterrogationChatScreen extends StatefulWidget {
  const InterrogationChatScreen({required this.suspect, super.key});

  final Suspect suspect;

  @override
  State<InterrogationChatScreen> createState() =>
      _InterrogationChatScreenState();
}

class _InterrogationChatScreenState
    extends State<InterrogationChatScreen> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<_Message> _messages = [];
  bool _isWaiting = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    // 같은 세션 내에서 이전에 이 용의자와 나눈 심문 기록을 복원한다.
    final controller = context.sessionRead;
    final priorLogs = controller.interrogationLogs
        .where((log) => log.suspectId == widget.suspect.id);
    for (final log in priorLogs) {
      _messages.add(_Message(
        text: log.question,
        sender: _Sender.detective,
        presentedEvidenceId: log.presentedEvidenceId,
      ));
      _messages.add(_Message(text: log.answer, sender: _Sender.suspect));
    }

    if (_messages.isEmpty) {
      // 첫 진입 기본 버블: 임의의 거부 대사(하드코딩)를 띄우면 모든 용의자가
      // 동일하게 비협조적으로 보이고, 심문 전인데 진술을 거부한 것처럼 오인된다.
      // 서버가 제공하는 용의자 공개 진술(publicStatement)을 출처로 쓰고,
      // 없으면 특정 알리바이/태도를 단정하지 않는 중립 안내로 연다.
      final raw = controller.rawSuspect(widget.suspect.id);
      final statement = raw?.publicStatement?.trim();
      final opening = (statement != null && statement.isNotEmpty)
          ? statement
          : '무엇이 궁금하신가요? 질문해 주세요.';
      _messages.add(_Message(text: opening, sender: _Sender.suspect));
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
        // 발신 질문 유형 힌트. 증거가 제시되면 EVIDENCE_PRESENTED가 항상 우선한다.
        // 추천 질문 칩은 RECOMMENDED를, 자유 입력은 기본 FREE를 넘긴다.
        QuestionType questionType = QuestionType.free,
      }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isWaiting) return;

    final controller = context.sessionRead;
    final sessionId = controller.backendSessionId;
    final suspectIdInt = int.tryParse(widget.suspect.id);

    setState(() {
      _messages.add(_Message(
        text: trimmed,
        sender: _Sender.detective,
        presentedEvidenceId: evidenceId,
      ));
      _isWaiting = true;
      _inputCtrl.clear();
    });

    _scrollToBottom();

    // 서버 세션이 아직 준비되지 않았거나 용의자 ID가 정수가 아니면(샘플 시나리오)
    // 심문을 진행할 수 없다.
    if (sessionId == null || suspectIdInt == null) {
      if (mounted) {
        setState(() {
          _messages.add(const _Message(
            text: '세션이 아직 준비되지 않았습니다. 잠시 후 다시 시도해 주세요.',
            sender: _Sender.suspect,
          ));
          _isWaiting = false;
        });
        _scrollToBottom();
      }
      return;
    }

    final evidenceIdInt = evidenceId != null ? int.tryParse(evidenceId) : null;
    // 증거 제시는 항상 EVIDENCE_PRESENTED로 강제하고, 그 외에는 호출자가 넘긴
    // 유형(추천 칩=RECOMMENDED, 자유 입력=FREE)을 그대로 사용한다.
    final resolvedType = evidenceIdInt != null
        ? QuestionType.evidencePresented
        : questionType;

    String answer = '...대답을 거부하고 있습니다.';
    // 서버/네트워크 오류 메시지(영문일 수 있음)를 용의자 대사처럼 노출하지 않고,
    // 별도 시스템 안내(SnackBar)로 전달한다.
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorNotice)),
      );
    }

    // 심문으로 새 증거가 해금되면 증거/대시보드를 다시 로드하고 안내한다.
    if (unlockedEvidences.isNotEmpty && mounted) {
      await controller.refreshEvidences();
      if (mounted) {
        final names = unlockedEvidences.map((e) => e.title).join(', ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('새로운 증거 확보: $names')),
        );
      }
    }
  }

  // 증거 제시 진입점(AppBar·입력창 양쪽에서 재사용).
  Future<void> _presentEvidence() async {
    final evidence = await showEvidencePresentModal(context);
    if (evidence != null && mounted) {
      await _sendMessage(
        '이 증거를 제시합니다: ${evidence.name}',
        evidenceId: evidence.id,
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
              separatorBuilder: (_, _) =>
              const SizedBox(height: AppTokens.sp2),
              itemBuilder: (_, i) {
                if (i == _messages.length && _isWaiting) {
                  return const _WaitingBubble();
                }
                final msg = _messages[i];
                return msg.sender == _Sender.suspect
                    ? _SuspectBubble(
                  text: msg.text,
                  suspect: widget.suspect,
                )
                    : _DetectiveBubble(
                  text: msg.text,
                  evidenceId: msg.presentedEvidenceId,
                );
              },
            ),
          ),
          _SuggestedQuestions(
            // 추천 질문 칩은 RECOMMENDED 유형으로 전송(자유 입력 FREE와 구분).
            onSelect: (q) =>
                _sendMessage(q, questionType: QuestionType.recommended),
            disabled: _isWaiting,
          ),
          // 추천 질문 배지와 입력창 사이 간격 — 오탭 방지.
          const SizedBox(height: AppTokens.sp3),
          _InputBar(
            controller: _inputCtrl,
            onSend: () => _sendMessage(_inputCtrl.text),
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
        // 힌트 진입점(현장 화면과 동일하게 서버 세션 기반).
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
        // 증거 제시 보조 진입점(주 진입점은 입력창 위 강조 버튼).
        // AI 응답 대기 중 중복 전송(동시 요청) 방지.
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
  const _SuspectBubble({
    required this.text,
    required this.suspect,
  });

  final String text;
  final Suspect suspect;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final initial =
    suspect.name.isNotEmpty ? suspect.name.characters.first : '?';

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
  const _DetectiveBubble({
    required this.text,
    this.evidenceId,
  });

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
              // 증거 제시는 배경까지 success 계열로 강조해 일반 질문과 구분.
              color: isEvidence ? c.successSoft : c.primarySoft,
              border: Border.all(
                color: isEvidence ? c.success : c.primary,
              ),
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
  const _SuggestedQuestions({
    required this.onSelect,
    required this.disabled,
  });

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
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
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
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  // null 이면 비활성(응답 대기 중).
  final VoidCallback? onPresentEvidence;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

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
            // 핵심 메커닉 — 증거 제시 강조 액션(입력창 바로 위, 발견성 확보).
            MSButton(
              label: '증거 제시',
              variant: MSButtonVariant.secondary,
              icon: Icons.description_outlined,
              onPressed: onPresentEvidence,
            ),
            const SizedBox(height: AppTokens.sp2),
            Row(
              children: [
                Expanded(
                  child: MSTextField(
                    controller: controller,
                    hintText: '질문을 입력하세요...',
                    // 백엔드 question 계약(maxLength 500)을 입력 단계에서 하드캡.
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