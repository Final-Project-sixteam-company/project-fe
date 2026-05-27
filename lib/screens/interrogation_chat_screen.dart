import 'package:flutter/material.dart';
import '../components/game_modals.dart';
import '../components/ms_button.dart';
import '../components/ms_text_field.dart';
import '../components/states.dart';
import '../models/case.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

// ── 메시지 모델 ───────────────────────────────────────────────────────────────

enum _Sender { detective, suspect }

class _Message {
  final String text;
  final _Sender sender;

  const _Message({required this.text, required this.sender});
}

const _suggestedQuestions = [
  '어젯밤 10시에 어디 있었나요?',
  '피해자와의 관계는?',
  '마지막으로 피해자를 본 건 언제인가요?',
  'USB 드라이브에 대해 알고 있나요?',
  '알리바이를 증명할 수 있나요?',
];

// ── 화면 ──────────────────────────────────────────────────────────────────────

class InterrogationChatScreen extends StatefulWidget {
  const InterrogationChatScreen({required this.suspect, super.key});

  final Suspect suspect;

  @override
  State<InterrogationChatScreen> createState() =>
      _InterrogationChatScreenState();
}

class _InterrogationChatScreenState extends State<InterrogationChatScreen> {
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

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isWaiting) return;

    setState(() {
      _messages.add(_Message(text: trimmed, sender: _Sender.detective));
      _isWaiting = true;
      _inputCtrl.clear();
    });

    _scrollToBottom();

    // AI 응답 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 1400));

    if (!mounted) return;
    setState(() {
      _messages.add(
        _Message(
          text: _mockReply(trimmed),
          sender: _Sender.suspect,
        ),
      );
      _isWaiting = false;
    });

    _scrollToBottom();
  }

  String _mockReply(String question) {
    if (question.contains('10시') || question.contains('어디')) {
      return '그 시간에 저는 이미 퇴근한 상태였습니다. CCTV를 확인해보시면 알 수 있을 겁니다.';
    }
    if (question.contains('관계') || question.contains('피해자')) {
      return '강도현 대표와는 업무적인 관계입니다. 개인적인 감정은 없었어요.';
    }
    if (question.contains('USB')) {
      return '무슨 USB 말씀하시는 건지 모르겠습니다.';
    }
    return '그 부분에 대해서는 드릴 말씀이 없습니다.';
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
          // ── 1. 채팅 리스트 ───────────────────────────────────────
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
                    : _DetectiveBubble(text: msg.text);
              },
            ),
          ),
          // ── 2. 추천 질문 ─────────────────────────────────────────
          _SuggestedQuestions(
            onSelect: _sendMessage,
            disabled: _isWaiting,
          ),
          // ── 3. 입력창 ────────────────────────────────────────────
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
              final evidence = await showEvidencePresentModal(context);
              if (evidence != null && mounted) {
                _sendMessage('이 증거를 제시합니다: ${evidence.name}');
              }
            },
          ),
        ),
      ],
    );
  }
}

// ── 용의자 말풍선 ─────────────────────────────────────────────────────────────

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

// ── 탐정 말풍선 ───────────────────────────────────────────────────────────────

class _DetectiveBubble extends StatelessWidget {
  const _DetectiveBubble({required this.text});

  final String text;

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
              border: Border.all(color: c.primary),
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

// ── AI 대기 말풍선 ────────────────────────────────────────────────────────────

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

    return Container(
      height: 40,
      padding: const EdgeInsets.only(
        left: AppTokens.sp4,
        right: AppTokens.sp4,
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
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