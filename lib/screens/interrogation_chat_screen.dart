// lib/screens/interrogation_chat_screen.dart
import 'package:flutter/material.dart';
import '../components/game_modals.dart';
import '../components/ms_button.dart';
import '../components/ms_text_field.dart';
import '../components/states.dart';
import '../controllers/game_session_provider.dart';
import '../models/case.dart';
import '../models/session_models.dart';
import '../repositories/interrogation_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

// ── 메시지 모델 ───────────────────────────────────────────────────────────────

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

// ── 화면 ──────────────────────────────────────────────────────────────────────

class InterrogationChatScreen extends StatefulWidget {
  const InterrogationChatScreen({required this.suspect, super.key});

  final Suspect suspect;

  @override
  State<InterrogationChatScreen> createState() =>
      _InterrogationChatScreenState();
}

class _InterrogationChatScreenState
    extends State<InterrogationChatScreen> {
  final InterrogationRepository _repo = buildInterrogationRepository();
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<_Message> _messages = [
    const _Message(
      text: '저는 할 말이 없습니다. 변호사를 불러주세요.',
      sender: _Sender.suspect,
    ),
  ];
  bool _isWaiting = false;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(
      String text, {
        String? evidenceId,
      }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isWaiting) return;

    final session = context.sessionRead;
    final unlockedIds = session.unlockedEvidenceIds.toList();

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

    final answer = await _repo.ask(
      InterrogationRequest(
        sessionId: session.sessionId,
        scenarioId: session.scenarioId,
        suspectId: widget.suspect.id,
        question: trimmed,
        unlockedEvidenceIds: unlockedIds,
        conversationHistory: _buildConversationHistory(),
        presentedEvidenceId: evidenceId,
      ),
    );

    if (!mounted) return;

    // 심문 로그 세션에 저장
    session.addInterrogationLog(
      InterrogationLog(
        suspectId: widget.suspect.id,
        suspectName: widget.suspect.name,
        question: trimmed,
        answer: answer,
        askedAt: session.elapsed,
        presentedEvidenceId: evidenceId,
      ),
    );

    setState(() {
      _messages.add(_Message(text: answer, sender: _Sender.suspect));
      _isWaiting = false;
    });

    _scrollToBottom();
  }

  /// 최근 12개 메시지를 백엔드 전달용 history 형식으로 변환
  List<Map<String, String>> _buildConversationHistory() {
    final recent = _messages.length > 12
        ? _messages.sublist(_messages.length - 12)
        : _messages;
    return recent
        .map(
          (msg) => {
        'role':
        msg.sender == _Sender.detective ? 'user' : 'assistant',
        'content': msg.text,
      },
    )
        .toList();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: AppMotion.dur3,
        curve: AppMotion.easeOut,
      );
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
              separatorBuilder: (_, __) =>
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
            onSelect: _sendMessage,
            disabled: _isWaiting,
          ),
          _InputBar(
            controller: _inputCtrl,
            onSend: () => _sendMessage(_inputCtrl.text),
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
            style: AppText.titleM.copyWith(color: c.text),
          ),
          Text(
            widget.suspect.role,
            style: AppText.bodySm.copyWith(color: c.textSub),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppTokens.sp4),
          child: MSButton(
            label: '증거',
            variant: MSButtonVariant.ghost,
            icon: Icons.description_outlined,
            onPressed: () async {
              final evidence =
              await showEvidencePresentModal(context);
              if (evidence != null && mounted) {
                await _sendMessage(
                  '이 증거를 제시합니다: ${evidence.name}',
                  evidenceId: evidence.id,
                );
              }
            },
          ),
        ),
      ],
    );
  }
}

// ── 말풍선 위젯들 ─────────────────────────────────────────────────────────────

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
              color: c.primarySoft,
              border: Border.all(
                color: evidenceId != null ? c.success : c.primary,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTokens.r4),
                topRight: Radius.circular(AppTokens.r1),
                bottomLeft: Radius.circular(AppTokens.r4),
                bottomRight: Radius.circular(AppTokens.r4),
              ),
            ),
            child: Text(
              text,
              style: AppText.body.copyWith(
                fontSize: 13,
                color: c.primary,
                height: 1.55,
              ),
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

// ── 추천 질문 칩 ──────────────────────────────────────────────────────────────

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
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.sp4),
        itemCount: _suggestedQuestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppTokens.sp2),
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

// ── 입력창 ────────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.disabled,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
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
        child: Row(
          children: [
            Expanded(
              child: MSTextField(
                controller: controller,
                hintText: '질문을 입력하세요...',
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
      ),
    );
  }
}