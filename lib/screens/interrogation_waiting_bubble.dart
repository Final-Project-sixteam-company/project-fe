// lib/screens/interrogation_waiting_bubble.dart
import 'package:flutter/material.dart';
import '../components/states.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

/// AI 응답 대기 중 표시되는 말풍선
class WaitingBubble extends StatelessWidget {
  const WaitingBubble({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Row(
      children: [
        Container(
          width: AppTokens.sp6,
          height: AppTokens.sp6,
          decoration: BoxDecoration(
            color: c.bgHover,
            borderRadius: BorderRadius.circular(AppTokens.r2),
          ),
          alignment: Alignment.center,
          child: MSSpinner(size: AppTokens.iconXs, color: c.primary),
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
          child: MSSpinner(size: AppTokens.sp4, color: c.textMute),
        ),
      ],
    );
  }
}
