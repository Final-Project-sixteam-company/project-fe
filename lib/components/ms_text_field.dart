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

  const MSTextField({
    this.controller,
    this.hintText,
    this.onChanged,
    this.suffixIcon,
    this.maxLength,
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

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Glow Background
        Positioned.fill(
          child: AnimatedContainer(
            duration: AppMotion.dur2,
            curve: AppMotion.easeOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.r3),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: c.primary.withOpacity(0.28),
                        blurRadius: 0,
                        spreadRadius: 3,
                      )
                    ]
                  : [],
            ),
          ),
        ),
        // Main TextField
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  onChanged: widget.onChanged,
                  maxLength: widget.maxLength,
                  style: AppText.body.copyWith(color: c.text),
                  cursorColor: c.primary,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: AppText.body.copyWith(color: c.textMute),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    counterText: '', // maxLength가 있어도 하단 카운터 숨김
                    contentPadding: EdgeInsets.only(
                      left: AppTokens.sp3,
                      top: 9,
                      bottom: 9,
                      right: widget.suffixIcon != null ? 8 : AppTokens.sp3,
                    ),
                  ),
                ),
              ),
              if (widget.suffixIcon != null)
                Padding(
                  padding: const EdgeInsets.only(right: AppTokens.sp3),
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
  }
}

// ----------------------------------------------------------------------
// [사용 예시]
// ----------------------------------------------------------------------
class MSTextFieldExample extends StatelessWidget {
  const MSTextFieldExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          MSTextField(
            hintText: '사건 번호를 입력하세요',
          ),
          SizedBox(height: 16),
          MSTextField(
            hintText: '검색어를 입력하세요',
            suffixIcon: Icons.search,
          ),
        ],
      ),
    );
  }
}
