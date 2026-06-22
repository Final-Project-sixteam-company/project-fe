// lib/screens/my_page_screen.dart
import 'package:flutter/material.dart';
import '../components/ms_button.dart';
import '../components/overlays.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import 'splash_screen.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

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
              Text(
                '마이페이지',
                style: AppText.titleL.copyWith(color: c.text),
              ),
              const SizedBox(height: 2),
              Text(
                'PROFILE',
                style: AppText.monoLabel.copyWith(color: c.textMute),
              ),
              const SizedBox(height: AppTokens.sp6),
              // ── 프로필 카드 ──────────────────────────────────────
              _ProfileCard(),
              const SizedBox(height: AppTokens.sp6),
              // ── 메뉴 목록 ────────────────────────────────────────
              ..._menuItems.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppTokens.sp2),
                    child: _MenuItem(item: item),
                  )),
              const SizedBox(height: AppTokens.sp10),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 프로필 카드 ───────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Container(
      padding: const EdgeInsets.all(AppTokens.sp4),
      decoration: BoxDecoration(
        color: c.bgElev,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppTokens.r6),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.tealBase, AppColors.skyBase],
              ),
              borderRadius: BorderRadius.circular(AppTokens.rPill),
              border: Border.all(
                color: const Color(0x24FFFFFF),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '탐',
              style: AppText.titleM.copyWith(
                fontSize: 20,
                color: AppColors.ink950,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(width: AppTokens.sp4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '탐정견습생',
                style: AppText.titleM.copyWith(color: c.text),
              ),
              const SizedBox(height: 3),
              Text(
                'detective@clueroom.xyz',
                style: AppText.monoLabel.copyWith(
                  fontSize: 10,
                  color: c.textMute,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 메뉴 아이템 ───────────────────────────────────────────────────────────────

// 메뉴 탭 동작 — 미구현 항목은 '준비 중' 안내, 로그아웃은 확인 다이얼로그.
enum _MenuAction { comingSoon, logout }

class _MenuItemData {
  final String label;
  final IconData icon;
  final _MenuAction action;

  const _MenuItemData(this.label, this.icon, this.action);
}

const _menuItems = [
  _MenuItemData('알림 설정', Icons.notifications_outlined, _MenuAction.comingSoon),
  _MenuItemData('도움말 / 튜토리얼', Icons.help_outline, _MenuAction.comingSoon),
  _MenuItemData('이용약관', Icons.description_outlined, _MenuAction.comingSoon),
  _MenuItemData('로그아웃', Icons.logout, _MenuAction.logout),
];

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.item});
  final _MenuItemData item;

  void _handleTap(BuildContext context) {
    switch (item.action) {
      case _MenuAction.comingSoon:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.label} · 준비 중입니다')),
        );
      case _MenuAction.logout:
        _confirmLogout(context);
    }
  }

  // 복구 불가한 파괴적 액션 — 반드시 2단계 확인 후에만 토큰을 비운다.
  Future<void> _confirmLogout(BuildContext context) {
    return showMSModal(
      context,
      title: '로그아웃',
      child: Text(
        '정말 로그아웃하시겠어요?\n다시 로그인할 때까지 진행 중인 정보에 접근할 수 없어요.',
        style: AppText.body.copyWith(color: context.c.textSub, height: 1.5),
      ),
      secondaryAction: MSButton(
        label: '취소',
        variant: MSButtonVariant.secondary,
        onPressed: () => Navigator.of(context).pop(),
      ),
      primaryAction: MSButton(
        label: '로그아웃',
        variant: MSButtonVariant.danger,
        onPressed: () async {
          Navigator.of(context).pop();
          await AuthService.instance.logout();
          if (!context.mounted) return;
          // 로그인 화면 도입 전까지는 진입 플로(Splash)로 스택을 리셋한다.
          // 추후 로그인 게이팅은 SplashScreen 한 곳에서 처리.
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SplashScreen()),
            (route) => false,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final bool isDanger = item.action == _MenuAction.logout;

    return Material(
      color: c.bgElev,
      borderRadius: BorderRadius.circular(AppTokens.r3),
      child: InkWell(
        onTap: () => _handleTap(context),
        splashColor: c.primary.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(AppTokens.r3),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.sp4,
            vertical: AppTokens.sp3,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(AppTokens.r3),
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 18,
                color: isDanger ? c.danger : c.textSub,
              ),
              const SizedBox(width: AppTokens.sp3),
              Expanded(
                child: Text(
                  item.label,
                  style: AppText.body.copyWith(
                    color: isDanger ? c.danger : c.text,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: c.textMute,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
