// lib/screens/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppMotion.dur3);
    _opacity = CurvedAnimation(parent: _ctrl, curve: AppMotion.easeOut);
    _ctrl.forward();

    _timer = Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          // ── 방사형 배경 ───────────────────────────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.2),
                  radius: 0.9,
                  colors: [
                    AppColors.tealBase.withValues(alpha: .06),
                    AppColors.roseBase.withValues(alpha: .04),
                    AppColors.ink950,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          // ── 콘텐츠 ───────────────────────────────────────────────
          FadeTransition(
            opacity: _opacity,
            child: SafeArea(
              child: Column(
                children: [
                  const Spacer(),
                  // 로고
                  _LogoBadge(),
                  const SizedBox(height: AppTokens.sp6),
                  // 앱 이름
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'ClueRoom',
                        style: AppText.titleL.copyWith(
                          fontSize: 28,
                          color: c.text,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: c.primarySoft,
                          border: Border.all(color: c.primary),
                          borderRadius: BorderRadius.circular(AppTokens.r1),
                        ),
                        child: Text(
                          'AI',
                          style: AppText.monoLabel.copyWith(
                            fontSize: 10,
                            color: c.primary,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.sp3),
                  // 상태 텍스트
                  _PulsingLabel(),
                  const Spacer(),
                  // 하단 버전
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppTokens.sp8),
                    child: Text(
                      'A DETECTIVE GAME · v0.9.2',
                      style: AppText.monoLabel.copyWith(
                        color: c.textMute,
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 로고 배지 ────────────────────────────────────────────────────────────────

class _LogoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.bgElev,
        border: Border.all(color: c.primary.withValues(alpha: .6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: c.primary.withValues(alpha: .18),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 십자선
          Positioned.fill(
            child: CustomPaint(painter: _CrosshairPainter(color: c.line)),
          ),
          Text(
            'CR',
            style: AppText.titleM.copyWith(
              color: c.primary,
              letterSpacing: 2,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  const _CrosshairPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawLine(Offset(cx, 8), Offset(cx, cy - 14), paint);
    canvas.drawLine(Offset(cx, cy + 14), Offset(cx, size.height - 8), paint);
    canvas.drawLine(Offset(8, cy), Offset(cx - 14, cy), paint);
    canvas.drawLine(Offset(cx + 14, cy), Offset(size.width - 8, cy), paint);
  }

  @override
  bool shouldRepaint(_CrosshairPainter old) => old.color != color;
}

// ── 펄스 라벨 ────────────────────────────────────────────────────────────────

class _PulsingLabel extends StatefulWidget {
  @override
  State<_PulsingLabel> createState() => _PulsingLabelState();
}

class _PulsingLabelState extends State<_PulsingLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
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

    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_anim),
      child: Text(
        'INVESTIGATING · 조사 준비 중',
        style: AppText.monoLabel.copyWith(color: c.textMute),
      ),
    );
  }
}
