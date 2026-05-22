import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/app_text.dart';

class MSKicker extends StatelessWidget {
  const MSKicker(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label.toUpperCase(),
          style: AppText.monoLabel.copyWith(
            color: c.textMute,
            height: 1.0, // 수직 정렬을 위해 높이 조정
          ),
        ),
        const SizedBox(width: AppTokens.sp2),
        Flexible(
          child: Divider(
            color: c.line,
            thickness: 1,
            height: 1, // Row의 crossAxisAlignment.center 와 함께 중앙 정렬
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------------
// [사용 예시]
// ----------------------------------------------------------------------
class MSKickerExample extends StatelessWidget {
  const MSKickerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          MSKicker('suspect timeline'),
          SizedBox(height: 32),
          MSKicker('evidence logs'),
        ],
      ),
    );
  }
}
