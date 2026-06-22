// lib/components/ms_button_example.dart
import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';
import 'ms_button.dart';

/// MSButton 사용 예시 — 개발·스타일가이드 전용
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