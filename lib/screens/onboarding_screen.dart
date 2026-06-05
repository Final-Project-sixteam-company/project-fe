// lib/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/ms_button.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import 'app_shell.dart';
import 'splash_screen.dart' show OnboardingFlag;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageCtrl = PageController();
  int _page = 0;
  bool _navigating = false;

  static const _slides = [
    _Slide(
      icon: Icons.search,
      title: '사건을 선택하세요',
      body: '공식 시나리오 또는 유저가 만든 커스텀 사건 중 원하는 사건을 골라 조사를 시작하세요.',
    ),
    _Slide(
      icon: Icons.description_outlined,
      title: '증거를 수집하세요',
      body: '현장에 흩어진 증거 카드를 수집하고, 시간이 지날수록 새 단서가 해금됩니다.',
    ),
    _Slide(
      icon: Icons.people_outline,
      title: 'AI 용의자를 심문하세요',
      body: '각 용의자는 AI로 구동됩니다. 날카로운 질문과 증거 제시로 모순을 찾아내세요.',
    ),
    _Slide(
      icon: Icons.lightbulb_outline,
      title: '힌트를 활용하세요',
      body: '막히면 단계별 힌트를 사용할 수 있습니다. 단, 점수가 감점됩니다.',
    ),
    _Slide(
      icon: Icons.star_outline,
      title: '최종 추리를 제출하세요',
      body: '범인, 동기, 범행 방법, 결정적 증거를 조합해 사건의 진상을 밝혀내세요.',
    ),
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _goHome() async {
    if (_navigating) return; // 이중 탭 방지
    setState(() => _navigating = true);
    HapticFeedback.selectionClick();
    await OnboardingFlag.markComplete();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppShell()),
    );
  }

  void _next() {
    if (_page < _slides.length - 1) {
      _pageCtrl.nextPage(
        duration: AppMotion.dur3,
        curve: AppMotion.easeOut,
      );
    } else {
      _goHome(); // unawaited intentionally — navigation is fire-and-forget
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final bool isLast = _page == _slides.length - 1;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── 건너뛰기 ────────────────────────────────────────
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: AppTokens.sp2,
                  right: AppTokens.sp2,
                ),
                // MSButton(ghost): fg=textSub 로 대비 상향 + 높이 48dp 터치 타깃 확보.
                child: MSButton(
                  label: '건너뛰기',
                  variant: MSButtonVariant.ghost,
                  onPressed: _navigating ? null : _goHome,
                ),
              ),
            ),
            // ── 슬라이드 ─────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _slides.length,
                itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
              ),
            ),
            // ── 인디케이터 + 버튼 ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppTokens.sp6),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      return AnimatedContainer(
                        duration: AppMotion.dur2,
                        width: _page == i ? 20 : 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _page == i ? c.primary : c.line,
                          borderRadius:
                          BorderRadius.circular(AppTokens.rPill),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppTokens.sp6),
                  MSButton(
                    label: isLast ? '시작하기' : '다음',
                    variant: MSButtonVariant.primary,
                    expanded: true,
                    // 시작하기 비동기 동안 잠금(스피너) → 이중 탭 방지
                    loading: isLast && _navigating,
                    onPressed: _navigating ? null : _next,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  final IconData icon;
  final String title;
  final String body;

  const _Slide({
    required this.icon,
    required this.title,
    required this.body,
  });
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.sp8),
      child: Column(
        // flex Spacer 로 상하 여백을 비율 고정 → 작은 폰~태블릿에서 동일 위치 유지(부유 방지)
        children: [
          const Spacer(flex: 2),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.tealBase, AppColors.skyBase],
              ),
              borderRadius: BorderRadius.circular(AppTokens.r6),
            ),
            alignment: Alignment.center,
            child: Icon(slide.icon, size: 36, color: AppColors.ink950),
          ),
          const SizedBox(height: AppTokens.sp6),
          Text(
            slide.title,
            style: AppText.titleL.copyWith(color: c.text),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTokens.sp3),
          Text(
            slide.body,
            style: AppText.body.copyWith(color: c.textSub, height: 1.65),
            textAlign: TextAlign.center,
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}