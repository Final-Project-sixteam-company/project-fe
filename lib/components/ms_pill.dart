// lib/components/ms_pill.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

enum MSPillTone { primary, success, danger, mute }

class MSPill extends StatelessWidget {
  const MSPill(
      this.label, {
        this.tone = MSPillTone.primary,
        super.key,
      });

  final String label;
  final MSPillTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final Color bg;
    final Color borderColor;
    final Color textColor;

    switch (tone) {
      case MSPillTone.primary:
        bg = c.primarySoft;
        borderColor = c.primary;
        textColor = c.primary;
      case MSPillTone.success:
        bg = c.successSoft;
        borderColor = c.success;
        textColor = c.success;
      case MSPillTone.danger:
        bg = c.dangerSoft;
        borderColor = c.danger;
        textColor = c.danger;
      case MSPillTone.mute:
        bg = AppColors.transparent;
        borderColor = c.line;
        textColor = c.textMute;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.pillPadH,
        vertical: AppTokens.pillPadV,
      ),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(AppTokens.r1),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppText.monoLabel.copyWith(
          color: textColor,
          fontSize: AppTokens.fsSm,
          height: AppTokens.lhLabel,
        ),
      ),
    );
  }
}

// ── 사용 예시 ─────────────────────────────────────────────────────────────────

class MSPillExample extends StatelessWidget {
  const MSPillExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppTokens.sp4),
      child: Wrap(
        spacing: AppTokens.sp2,
        children: [
          MSPill('suspect', tone: MSPillTone.primary),
          MSPill('alibi',   tone: MSPillTone.success),
          MSPill('guilty',  tone: MSPillTone.danger),
          MSPill('미상',    tone: MSPillTone.mute),
        ],
      ),
    );
  }
}