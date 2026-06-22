// lib/components/ms_text_field.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/app_text.dart';

class MSTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final IconData? suffixIcon;
  final int? maxLength;
  final int maxLines;

  const MSTextField({
    this.controller,
    this.hintText,
    this.onChanged,
    this.suffixIcon,
    this.maxLength,
    this.maxLines = 1,
    super.key,
  });

  @override
  State<MSTextField> createState() => _MSTextFieldState();
}

class _MSTextFieldState extends State<MSTextField> {
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final bool isMultiLine = widget.maxLines > 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool bounded = constraints.hasBoundedWidth;

        Widget textField = TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          onChanged: widget.onChanged,
          maxLength: widget.maxLength,
          maxLines: widget.maxLines,
          style: AppText.body.copyWith(color: c.text),
          cursorColor: c.primary,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: AppText.body.copyWith(color: c.textMute),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            isDense: true,
            counterText: '',
            contentPadding: EdgeInsets.only(
              left: AppTokens.sp3,
              top: isMultiLine ? AppTokens.sp3 : 9,
              bottom: isMultiLine ? AppTokens.sp3 : 9,
              right: widget.suffixIcon != null ? 8 : AppTokens.sp3,
            ),
          ),
        );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: AnimatedContainer(
                duration: AppMotion.dur2,
                curve: AppMotion.easeOut,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTokens.r3),
                  boxShadow: _isFocused
                      ? [
                    BoxShadow(
                      color: c.primary.withValues(alpha: .28),
                      blurRadius: 0,
                      spreadRadius: 3,
                    ),
                  ]
                      : [],
                ),
              ),
            ),
            AnimatedContainer(
              duration: AppMotion.dur2,
              curve: AppMotion.easeOut,
              decoration: BoxDecoration(
                color: c.bg,
                borderRadius: BorderRadius.circular(AppTokens.r3),
                border: Border.all(
                  color: _isFocused ? c.primary : c.line,
                  width: _isFocused ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
                crossAxisAlignment: isMultiLine
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  bounded
                      ? Expanded(child: textField)
                      : Flexible(child: IntrinsicWidth(child: textField)),
                  if (widget.suffixIcon != null)
                    Padding(
                      padding: EdgeInsets.only(
                        right: AppTokens.sp3,
                        top: isMultiLine ? AppTokens.sp3 : 0,
                      ),
                      child: Icon(
                        widget.suffixIcon,
                        color: c.textSub,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}