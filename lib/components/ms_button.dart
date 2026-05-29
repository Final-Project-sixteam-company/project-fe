// lib/components/ms_button.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/app_text.dart';

enum MSButtonVariant { primary, secondary, ghost, danger }

class MSButton extends StatefulWidget {
  const MSButton({
    required this.label,
    required this.onPressed,
    this.variant = MSButtonVariant.primary,
    this.icon,
    this.expanded = false,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final MSButtonVariant variant;
  final IconData? icon;
  final bool expanded;
  final bool loading;

  @override
  State<MSButton> createState() => _MSButtonState();
}

class _MSButtonState extends State<MSButton> {
  bool _isPressed = false;

  bool get _disabled => widget.onPressed == null;
  bool get _cannotPress => _disabled || widget.loading;

  // label 이 비어 있으면 아이콘 전용 버튼으로 취급
  bool get _iconOnly => widget.label.isEmpty;

  void _handleTapDown(TapDownDetails _) {
    if (_cannotPress) return;
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    if (_cannotPress) return;
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    if (_cannotPress) return;
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
        fg = AppColors.ink0;
        break;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool shouldExpand =
            widget.expanded && constraints.hasBoundedWidth;

        final Widget content = Container(
          // expanded: true 면 부모 너비를 채우고,
          // 아이콘 전용이면 정사각형에 가까운 최소 너비 36 확보,
          // 나머지는 콘텐츠 크기에 맞춘다.
          width: shouldExpand
              ? double.infinity
              : (_iconOnly ? AppTokens.btnH : null),
          height: AppTokens.btnH,
          padding: EdgeInsets.symmetric(
            // 아이콘 전용 버튼은 가로 패딩을 줄여 정사각형 유지
            horizontal: _iconOnly ? AppTokens.sp2 : AppTokens.sp4,
            vertical: AppTokens.sp2,
          ),
          decoration: BoxDecoration(
            color: bg,
            border: border,
            borderRadius: BorderRadius.circular(AppTokens.r3),
          ),
          child: Row(
            // expanded 버튼: max / 아이콘 전용·텍스트 버튼: min
            // min 을 사용하면 Row 가 children 의 자연 크기만큼만 차지하므로
            // 부모가 좁을 때 overflow 가 발생하지 않는다.
            mainAxisSize:
            shouldExpand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.loading)
                SizedBox(
                  width: AppTokens.btnSpinnerSize,
                  height: AppTokens.btnSpinnerSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: fg,
                  ),
                )
              else ...[
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 16, color: fg),
                  // 아이콘 전용 버튼에서는 스페이서와 텍스트를 렌더링하지 않는다.
                  if (!_iconOnly) const SizedBox(width: AppTokens.btnIconGap),
                ],
                if (!_iconOnly)
                // shouldExpand 일 때는 Flexible 로 감싸서 텍스트가
                // 남은 공간을 차지하되 overflow 없이 ellipsis 처리한다.
                // shouldExpand 가 아닐 때는 wrap 없이 자연 크기를 허용한다.
                  _buildLabel(shouldExpand: shouldExpand, fg: fg),
              ],
            ],
          ),
        );

        return GestureDetector(
          onTapDown: _cannotPress ? null : _handleTapDown,
          onTapUp: _cannotPress ? null : _handleTapUp,
          onTapCancel: _cannotPress ? null : _handleTapCancel,
          onTap: _cannotPress ? null : widget.onPressed,
          behavior: HitTestBehavior.opaque,
          child: AnimatedScale(
            scale: _isPressed ? 0.98 : 1.0,
            duration: AppMotion.dur1,
            curve: AppMotion.easeOut,
            child: Opacity(
              opacity: _disabled ? 0.42 : 1.0,
              child: content,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabel({
    required bool shouldExpand,
    required Color fg,
  }) {
    final text = Text(
      widget.label,
      style: AppText.body.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.05,
        color: fg,
        height: 1.0,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    // expanded 버튼 안에서 텍스트가 Row 의 남은 공간만 차지하도록 Flexible 로 감싼다.
    // min 버튼에서 Flexible 을 쓰면 MainAxisSize.min 의 효과가 사라지므로 쓰지 않는다.
    if (shouldExpand) {
      return Flexible(child: text);
    }
    return text;
  }
}

// ── 사용 예시 ─────────────────────────────────────────────────────────────────

class MSButtonExample extends StatelessWidget {
  const MSButtonExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 일반 버튼 4종
          Row(
            children: [
              MSButton(
                label: '추적 시작',
                onPressed: () {},
                variant: MSButtonVariant.primary,
                icon: Icons.search,
              ),
              const SizedBox(width: AppTokens.sp2),
              MSButton(
                label: '단서 추가',
                onPressed: () {},
                variant: MSButtonVariant.secondary,
              ),
              const SizedBox(width: AppTokens.sp2),
              MSButton(
                label: '취소',
                onPressed: () {},
                variant: MSButtonVariant.ghost,
              ),
              const SizedBox(width: AppTokens.sp2),
              MSButton(
                label: '종결',
                onPressed: () {},
                variant: MSButtonVariant.danger,
              ),
            ],
          ),
          const SizedBox(height: AppTokens.sp4),
          // 아이콘 전용 버튼 (label: '')
          Row(
            children: [
              MSButton(
                label: '',
                variant: MSButtonVariant.primary,
                icon: Icons.send,
                onPressed: () {},
              ),
              const SizedBox(width: AppTokens.sp2),
              MSButton(
                label: '',
                variant: MSButtonVariant.secondary,
                icon: Icons.bookmark_outline,
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: AppTokens.sp4),
          // 로딩 / 비활성화
          Row(
            children: [
              MSButton(
                label: '로딩중',
                onPressed: () {},
                loading: true,
              ),
              const SizedBox(width: AppTokens.sp2),
              MSButton(
                label: '비활성화',
                onPressed: null,
                variant: MSButtonVariant.secondary,
              ),
            ],
          ),
          const SizedBox(height: AppTokens.sp4),
          // expanded 버튼
          MSButton(
            label: '확장 버튼',
            onPressed: () {},
            expanded: true,
          ),
        ],
      ),
    );
  }
}