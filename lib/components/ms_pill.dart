import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/app_text.dart';

enum MSPillTone { primary, success, danger, mute }

class MSPill extends StatelessWidget {
  final String label;
  final MSPillTone tone;

  const MSPill(
    this.label, {
    this.tone = MSPillTone.primary,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    Color bg;
    Color borderColor;
    Color textColor;

    switch (tone) {
      case MSPillTone.primary:
        bg = c.primarySoft;
        borderColor = c.primary;
        textColor = c.primary;
        break;
      case MSPillTone.success:
        bg = c.successSoft;
        borderColor = c.success;
        textColor = c.success;
        break;
      case MSPillTone.danger:
        bg = c.dangerSoft;
        borderColor = c.danger;
        textColor = c.danger;
        break;
      case MSPillTone.mute:
        bg = Colors.transparent;
        borderColor = c.line;
        textColor = c.textMute;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(AppTokens.r1),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppText.monoLabel.copyWith(
          color: textColor,
          fontSize: 9.5,
          height: 1.0, // 텍스트 위아래 여백 최소화
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// [사용 예시]
// ----------------------------------------------------------------------
class MSPillExample extends StatelessWidget {
  const MSPillExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        spacing: 8,
        children: const [
          MSPill('suspect', tone: MSPillTone.primary),
          MSPill('alibi', tone: MSPillTone.success),
          MSPill('guilty', tone: MSPillTone.danger),
          MSPill('미상', tone: MSPillTone.mute),
        ],
      ),
    );
  }
}
