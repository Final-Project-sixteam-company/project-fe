import 'package:flutter/material.dart';
import '../components/ms_button.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

// ── 1. 스켈레톤 ───────────────────────────────────────────────────────────────

class MSSkeleton extends StatefulWidget {
  const MSSkeleton({
    this.width,
    this.height,
    this.radius = AppTokens.r2,
    super.key,
  });

  final double? width;
  final double? height;
  final double radius;

  @override
  State<MSSkeleton> createState() => _MSSkeletonState();
}

class _MSSkeletonState extends State<MSSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              colors: [c.bgElev, c.bgHover, c.bgElev],
              stops: [
                (_anim.value - 0.4).clamp(0.0, 1.0),
                _anim.value.clamp(0.0, 1.0),
                (_anim.value + 0.4).clamp(0.0, 1.0),
              ],
              tileMode: TileMode.clamp,
              transform: const GradientRotation(0),
            ),
          ),
        );
      },
    );
  }
}

/// 리스트 로딩 자리표시자 — 카드 모양 스켈레톤을 n개 쌓는다.
class MSListSkeleton extends StatelessWidget {
  const MSListSkeleton({
    this.itemCount = 5,
    this.itemHeight = 76,
    super.key,
  });

  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppTokens.sp3),
      itemBuilder: (_, _) =>
          MSSkeleton(height: itemHeight, radius: AppTokens.r4),
      padding: const EdgeInsets.only(bottom: AppTokens.sp10),
    );
  }
}

// ── 2. 스피너 ─────────────────────────────────────────────────────────────────

class MSSpinner extends StatelessWidget {
  const MSSpinner({
    this.size = 14,
    this.color,
    super.key,
  });

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: color ?? c.primary,
      ),
    );
  }
}

// ── 3. 빈 상태 ────────────────────────────────────────────────────────────────

class MSEmpty extends StatelessWidget {
  const MSEmpty({
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.secondaryAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final MSButton? action;

  /// 주 액션 아래에 표시되는 보조 액션(예: '나가기').
  final MSButton? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: c.textMute),
          const SizedBox(height: AppTokens.sp4),
          Text(
            title,
            style: AppText.titleM.copyWith(color: c.text),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppTokens.sp2),
            Text(
              subtitle!,
              style: AppText.bodySm.copyWith(color: c.textSub),
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: AppTokens.sp4),
            action!,
          ],
          if (secondaryAction != null) ...[
            const SizedBox(height: AppTokens.sp2),
            secondaryAction!,
          ],
        ],
      ),
    );
  }
}

// ── 사용 예시 ─────────────────────────────────────────────────────────────────

class StatesExample extends StatelessWidget {
  const StatesExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 스켈레톤
          MSSkeleton(width: double.infinity, height: 72),
          const SizedBox(height: AppTokens.sp3),
          MSSkeleton(width: 120, height: 16),
          const SizedBox(height: AppTokens.sp3),
          MSSkeleton(width: 80, height: 16),
          const SizedBox(height: AppTokens.sp6),
          // 스피너
          Row(
            children: const [
              MSSpinner(),
              SizedBox(width: AppTokens.sp3),
              MSSpinner(size: 24),
            ],
          ),
          const SizedBox(height: AppTokens.sp6),
          // 빈 상태
          MSEmpty(
            icon: Icons.search_off,
            title: '단서가 없습니다',
            subtitle: '새로운 증거를 수집하거나 조건을 변경해보세요',
            action: MSButton(
              label: '단서 다시 찾기',
              variant: MSButtonVariant.secondary,
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}