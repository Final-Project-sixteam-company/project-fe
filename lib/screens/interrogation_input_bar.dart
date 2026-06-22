// lib/screens/interrogation_input_bar.dart
import 'package:flutter/material.dart';
import '../components/ms_button.dart';
import '../components/ms_text_field.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 심문 화면 입력 바
// ─────────────────────────────────────────────────────────────────────────────
class InterrogationInputBar extends StatelessWidget {
  const InterrogationInputBar({
    required this.controller,
    required this.onSend,
    required this.onPresentEvidence,
    required this.disabled,
    this.prefillEvidenceTitle,
    this.onClearPrefill,
    super.key,
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
                    Icon(Icons.link, size: AppTokens.iconSm, color: c.success),
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
                      icon: Icon(
                        Icons.close,
                        size: AppTokens.iconSm,
                        color: c.success,
                      ),
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
