// lib/screens/suspect_detail_bottom_bar.dart
// SuspectDetailScreen 하단 버튼 바 + 범인 지목 확인 다이얼로그

import 'package:flutter/material.dart';
import '../components/ms_button.dart';
import '../controllers/game_session_controller.dart';
import '../controllers/game_session_provider.dart';
import '../models/case.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import 'interrogation_chat_screen.dart';
import 'submit_screen.dart';

class SuspectDetailBottomBar extends StatelessWidget {
  const SuspectDetailBottomBar({required this.suspect, super.key});

  final Suspect suspect;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.sp4,
          vertical: AppTokens.sp3,
        ),
        child: Row(
          children: [
            Expanded(
              child: MSButton(
                label: '뒤로',
                variant: MSButtonVariant.secondary,
                expanded: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: AppTokens.sp3),
            Expanded(
              flex: 2,
              child: MSButton(
                label: '심문하기',
                variant: MSButtonVariant.primary,
                expanded: true,
                onPressed: () {
                  final ctrl = context.sessionRead;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GameSessionProvider(
                        controller: ctrl,
                        child: InterrogationChatScreen(suspect: suspect),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (!suspect.isWitness) ...[
              const SizedBox(width: AppTokens.sp3),
              Expanded(
                child: MSButton(
                  label: '범인 지목',
                  variant: MSButtonVariant.danger,
                  expanded: true,
                  onPressed: () => _showConfirmDialog(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showConfirmDialog(BuildContext context) {
    final ctrl = context.sessionRead;
    final nav = Navigator.of(context);
    showDialog(
      context: context,
      barrierColor: context.c.scrim,
      builder: (_) => SuspectAccuseDialog(
        suspect: suspect,
        controller: ctrl,
        navigator: nav,
      ),
    );
  }
}

class SuspectAccuseDialog extends StatelessWidget {
  const SuspectAccuseDialog({
    required this.suspect,
    required this.controller,
    required this.navigator,
    super.key,
  });

  final Suspect suspect;
  final GameSessionController controller;
  final NavigatorState navigator;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Dialog(
      backgroundColor: c.bgElev,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.r6),
        side: BorderSide(color: c.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.sp6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('범인 지목',
                style: AppText.titleM.copyWith(color: c.text)),
            const SizedBox(height: AppTokens.sp3),
            Text(
              '${suspect.name}을(를) 범인으로 지목하고 최종 추리를 작성합니다.\n'
              '범행 동기·방법·결정적 증거를 입력해야 제출할 수 있습니다.',
              style: AppText.body.copyWith(color: c.textSub, height: 1.6),
            ),
            const SizedBox(height: AppTokens.sp6),
            Row(
              children: [
                Expanded(
                  child: MSButton(
                    label: '취소',
                    variant: MSButtonVariant.secondary,
                    expanded: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: AppTokens.sp3),
                Expanded(
                  child: MSButton(
                    label: '추리 작성',
                    variant: MSButtonVariant.danger,
                    expanded: true,
                    onPressed: () {
                      navigator.pop();
                      navigator.push(
                        MaterialPageRoute(
                          builder: (_) => GameSessionProvider(
                            controller: controller,
                            child: SubmitScreen(initialSuspect: suspect),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
