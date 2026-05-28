// lib/screens/app_shell.dart
import 'package:flutter/material.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'scenario_library_screen.dart';
import 'my_records_screen.dart';
import 'my_page_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  static const _screens = <Widget>[
    HomeScreen(),
    ScenarioLibraryScreen(),
    MyRecordsScreen(),
    _BuilderPlaceholder(),
    MyPageScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Scaffold(
      backgroundColor: c.bg,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ── 빌더 플레이스홀더 ─────────────────────────────────────────────────────────

class _BuilderPlaceholder extends StatelessWidget {
  const _BuilderPlaceholder();

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.construction_outlined, size: 40, color: c.textMute),
              const SizedBox(height: AppTokens.sp4),
              Text(
                '시나리오 제작',
                style: AppText.titleM.copyWith(color: c.text),
              ),
              const SizedBox(height: AppTokens.sp2),
              Text(
                '준비 중입니다',
                style: AppText.bodySm.copyWith(color: c.textSub),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 앱 하단 네비 ──────────────────────────────────────────────────────────────

const _kAppNavItems = [
  ('홈', Icons.home_outlined),
  ('라이브러리', Icons.library_books_outlined),
  ('기록', Icons.assignment_outlined),
  ('만들기', Icons.add_circle_outline),
  ('내 정보', Icons.person_outline),
];

class _AppBottomNav extends StatelessWidget {
  const _AppBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.sp4,
          vertical: AppTokens.sp2,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: c.bg,
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(AppTokens.r4),
          ),
          child: Row(
            children: [
              for (int i = 0; i < _kAppNavItems.length; i++)
                _NavItem(
                  icon: _kAppNavItems[i].$2,
                  label: _kAppNavItems[i].$1,
                  active: currentIndex == i,
                  onTap: () => onTap(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final Color color = active ? c.primary : c.textMute;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTokens.r2),
        child: InkWell(
          onTap: onTap,
          splashColor: c.primary.withValues(alpha: .06),
          highlightColor: c.primary.withValues(alpha: .04),
          borderRadius: BorderRadius.circular(AppTokens.r2),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: color),
                const SizedBox(height: AppTokens.sp1),
                Text(
                  label,
                  style: AppText.caption.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: color,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
