import 'package:flutter/material.dart';
import '../components/ms_button.dart';
import '../components/ms_pill.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

// ── 화면 ──────────────────────────────────────────────────────────────────────

class HomeScreen extends StatelessWidget {
  const HomeScreen({this.onBrowse, this.onCreate, super.key});

  /// 라이브러리 탭으로 이동(앱 셸이 주입).
  final VoidCallback? onBrowse;

  /// 만들기 탭으로 이동(앱 셸이 주입).
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.sp4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppTokens.sp4),
              // ── 1. 헤더 ─────────────────────────────────────────
              _Header(),
              const SizedBox(height: AppTokens.sp6),
              // ── 2. 수사 시작 배너 ─────────────────────────────
              _WelcomeBanner(onBrowse: onBrowse),
              const SizedBox(height: AppTokens.sp8),
              // ── 3. 나만의 사건 만들기 ──────────────────────────
              MSButton(
                label: '나만의 사건 만들기',
                variant: MSButtonVariant.secondary,
                expanded: true,
                onPressed: onCreate,
              ),
              const SizedBox(height: AppTokens.sp10),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 헤더 ──────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Row(
      children: [
        Expanded(
          child: Text(
            'ClueRoom',
            style: AppText.titleL.copyWith(
              fontWeight: FontWeight.w700,
              color: c.text,
            ),
          ),
        ),
        IconButton(
          tooltip: '알림',
          onPressed: () {},
          icon: Icon(Icons.notifications_outlined, color: c.textSub),
        ),
        IconButton(
          tooltip: '내 정보',
          onPressed: () {},
          icon: Icon(Icons.account_circle_outlined, color: c.textSub),
        ),
      ],
    );
  }
}

// ── 수사 시작 배너 ────────────────────────────────────────────────────────────

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({this.onBrowse});

  final VoidCallback? onBrowse;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.ink900, AppColors.tealBase],
            stops: [0.4, 1.0],
          ),
          borderRadius: BorderRadius.circular(AppTokens.r6),
        ),
        padding: const EdgeInsets.all(AppTokens.sp4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MYSTERY LIBRARY',
              style: AppText.monoLabel.copyWith(
                color: AppColors.tealBase.withValues(alpha: .8),
              ),
            ),
            const Spacer(),
            const MSPill('탐정 사무소', tone: MSPillTone.primary),
            const SizedBox(height: AppTokens.sp2),
            Text(
              '사건을 수사할 시간',
              style: AppText.titleM.copyWith(color: AppColors.ink50),
            ),
            const SizedBox(height: AppTokens.sp1),
            Text(
              '라이브러리에서 사건을 골라 수사를 시작하세요.',
              style: AppText.bodySm.copyWith(
                color: AppColors.ink50.withValues(alpha: .8),
              ),
            ),
            const SizedBox(height: AppTokens.sp3),
            MSButton(
              label: '사건 보러 가기',
              variant: MSButtonVariant.ghost,
              onPressed: onBrowse,
            ),
          ],
        ),
      ),
    );
  }
}
