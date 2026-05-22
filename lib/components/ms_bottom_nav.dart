import 'package:flutter/material.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

const _kItems = [
  ('현장', Icons.home_outlined),
  ('증거', Icons.description_outlined),
  ('용의자', Icons.people_outline),
  ('타임라인', Icons.schedule_outlined),
  ('제출', Icons.star_outline),
];

class MSBottomNav extends StatelessWidget {
  const MSBottomNav({
    required this.currentIndex,
    required this.onTap,
    super.key,
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
              for (int i = 0; i < _kItems.length; i++)
                _NavItem(
                  icon: _kItems[i].$2,
                  label: _kItems[i].$1,
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

// ── 탭 아이템 ─────────────────────────────────────────────────────────────────

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
                    fontSize: 11,
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

// ── 사용 예시 ─────────────────────────────────────────────────────────────────

class MSBottomNavExample extends StatefulWidget {
  const MSBottomNavExample({super.key});

  @override
  State<MSBottomNavExample> createState() => _MSBottomNavExampleState();
}

class _MSBottomNavExampleState extends State<MSBottomNavExample> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const SizedBox.shrink(),
      bottomNavigationBar: MSBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}