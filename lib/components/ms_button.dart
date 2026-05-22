import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/app_text.dart';

enum MSButtonVariant { primary, secondary, ghost, danger }

class MSButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final MSButtonVariant variant;
  final IconData? icon;
  final bool expanded;
  final bool loading;

  const MSButton({
    required this.label,
    required this.onPressed,
    this.variant = MSButtonVariant.primary,
    this.icon,
    this.expanded = false,
    this.loading = false,
    super.key,
  });

  @override
  State<MSButton> createState() => _MSButtonState();
}

class _MSButtonState extends State<MSButton> {
  bool _isPressed = false;

  bool get disabled => widget.onPressed == null;
  bool get cannotPress => disabled || widget.loading;

  void _handleTapDown(TapDownDetails details) {
    if (cannotPress) return;
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    if (cannotPress) return;
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    if (cannotPress) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    Color bg;
    Color fg;
    Border? border;

    switch (widget.variant) {
      case MSButtonVariant.primary:
        bg = c.primary;
        fg = c.primaryInk;
        break;
      case MSButtonVariant.secondary:
        bg = Colors.transparent;
        fg = c.text;
        border = Border.all(color: c.line, width: 1);
        break;
      case MSButtonVariant.ghost:
        bg = Colors.transparent;
        fg = c.textSub;
        break;
      case MSButtonVariant.danger:
        bg = c.danger;
        fg = Colors.white;
        break;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool shouldExpand = widget.expanded && constraints.hasBoundedWidth;

        final Widget content = Container(
          width: shouldExpand ? double.infinity : null,
          height: 36,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.sp4,
            vertical: AppTokens.sp2,
          ),
          decoration: BoxDecoration(
            color: bg,
            border: border,
            borderRadius: BorderRadius.circular(AppTokens.r3),
          ),
          child: Row(
            mainAxisSize: shouldExpand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.loading)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: fg,
                  ),
                )
              else ...[
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 16, color: fg),
                  const SizedBox(width: 6),
                ],
                Text(
                  widget.label,
                  style: AppText.body.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.05,
                    color: fg,
                    height: 1.0, // Avoid vertical overflow in 36px height
                  ),
                ),
              ],
            ],
          ),
        );

        return GestureDetector(
          onTapDown: cannotPress ? null : _handleTapDown,
          onTapUp: cannotPress ? null : _handleTapUp,
          onTapCancel: cannotPress ? null : _handleTapCancel,
          onTap: cannotPress ? null : widget.onPressed,
          behavior: HitTestBehavior.opaque,
          child: AnimatedScale(
            scale: _isPressed ? 0.98 : 1.0,
            duration: AppMotion.dur1,
            curve: AppMotion.easeOut,
            child: Opacity(
              opacity: disabled ? 0.42 : 1.0,
              child: content,
            ),
          ),
        );
      },
    );
  }
}

// ----------------------------------------------------------------------
// 아래는 MSButton 4가지 variant를 테스트해볼 수 있는 Example 위젯입니다.
// ----------------------------------------------------------------------
class MSButtonExample extends StatelessWidget {
  const MSButtonExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MSButton(
                label: '추적 시작',
                onPressed: () {},
                variant: MSButtonVariant.primary,
                icon: Icons.search,
              ),
              const SizedBox(width: 8),
              MSButton(
                label: '단서 추가',
                onPressed: () {},
                variant: MSButtonVariant.secondary,
              ),
              const SizedBox(width: 8),
              MSButton(
                label: '취소',
                onPressed: () {},
                variant: MSButtonVariant.ghost,
              ),
              const SizedBox(width: 8),
              MSButton(
                label: '사건 종결',
                onPressed: () {},
                variant: MSButtonVariant.danger,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              MSButton(
                label: '로딩중',
                onPressed: () {},
                loading: true,
              ),
              const SizedBox(width: 8),
              MSButton(
                label: '비활성화',
                onPressed: null,
                variant: MSButtonVariant.secondary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MSButton(
                  label: '확장 버튼',
                  onPressed: () {},
                  expanded: true,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
