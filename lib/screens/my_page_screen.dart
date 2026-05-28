// lib/screens/my_page_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

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

class _MenuItemData {
  final String label;
  final IconData icon;

  const _MenuItemData(this.label, this.icon);
}

const _menuItems = [
  _MenuItemData('알림 설정', Icons.notifications_outlined),
  _MenuItemData('도움말 / 튜토리얼', Icons.help_outline),
  _MenuItemData('이용약관', Icons.description_outlined),
  _MenuItemData('로그아웃', Icons.logout),
];

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.item});
  final _MenuItemData item;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final bool isDanger = item.label == '로그아웃';

    return Material(
      color: c.bgElev,
      borderRadius: BorderRadius.circular(AppTokens.r3),
      child: InkWell(
        onTap: () {},
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
