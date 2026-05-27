import 'package:flutter/material.dart';
import '../components/ms_button.dart';
import '../components/ms_kicker.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import 'case_screen.dart';

class CaseBriefingScreen extends StatefulWidget {
  const CaseBriefingScreen({super.key});

  @override
  State<CaseBriefingScreen> createState() => _CaseBriefingScreenState();
}

class _CaseBriefingScreenState extends State<CaseBriefingScreen>
    with TickerProviderStateMixin {
  final List<AnimationController> _ctrls = [];
  final List<Animation<double>> _opacities = [];
  final List<Animation<Offset>> _slides = [];

  static const int _sectionCount = 5;

  @override
  void initState() {
    super.initState();

    for (int i = 0; i < _sectionCount; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: AppMotion.dur3,
      );
      final opacity = CurvedAnimation(parent: ctrl, curve: AppMotion.easeOut);
      final slide = Tween<Offset>(
        begin: const Offset(0, 10),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: ctrl, curve: AppMotion.easeOut));

      _ctrls.add(ctrl);
      _opacities.add(opacity);
      _slides.add(slide);
    }

    _playSequential();
  }

  Future<void> _playSequential() async {
    for (int i = 0; i < _sectionCount; i++) {
      await Future.delayed(Duration(milliseconds: 80 * i));
      if (mounted) _ctrls[i].forward();
    }
  }

  @override
  void dispose() {
    for (final ctrl in _ctrls) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Widget _animated(int index, Widget child) {
    return FadeTransition(
      opacity: _opacities[index],
      child: AnimatedBuilder(
        animation: _slides[index],
        builder: (_, c) => Transform.translate(
          offset: _slides[index].value,
          child: c,
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.sp4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppTokens.sp4),
                      // ── 0. 사건 제목 ──────────────────────────────
                      _animated(
                        0,
                        Text(
                          '데모데이 전야\n살인사건',
                          style: AppText.display.copyWith(
                            color: c.text,
                            height: 1.15,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTokens.sp6),
                      // ── 1. 사건 개요 ──────────────────────────────
                      _animated(
                        1,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const MSKicker('사건 개요'),
                            const SizedBox(height: AppTokens.sp3),
                            Text(
                              'AI 스타트업 대표 강도현이 데모데이 전날 밤 사망했다. '
                                  '시신은 6층 데모룸에서 발견됐으며, 외부 침입 흔적은 없었다. '
                                  '당일 밤 건물에 남아 있던 관계자는 총 4명. '
                                  '모두 알리바이를 주장하고 있지만, '
                                  '타임라인에는 설명되지 않는 공백이 존재한다.',
                              style: AppText.body.copyWith(
                                color: c.text,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTokens.sp6),
                      // ── 2. 피해자 정보 ────────────────────────────
                      _animated(
                        2,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const MSKicker('피해자 정보'),
                            const SizedBox(height: AppTokens.sp3),
                            _VictimRow(),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTokens.sp6),
                      // ── 3. 탐정 목표 ──────────────────────────────
                      _animated(
                        3,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const MSKicker('탐정 목표'),
                            const SizedBox(height: AppTokens.sp3),
                            Container(
                              padding: const EdgeInsets.all(AppTokens.sp4),
                              decoration: BoxDecoration(
                                color: c.dangerSoft,
                                border: Border.all(color: c.danger),
                                borderRadius:
                                BorderRadius.circular(AppTokens.r4),
                              ),
                              child: Text(
                                '1. 진범을 찾아라\n'
                                    '2. 살해 방법과 동기를 밝혀라\n'
                                    '3. 결정적 증거 3개를 수집하라',
                                style: AppText.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: c.danger,
                                  height: 1.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTokens.sp8),
                    ],
                  ),
                ),
              ),
              // ── 4. 하단 버튼 ──────────────────────────────────────
              _animated(
                4,
                MSButton(
                  label: '수사 시작하기',
                  variant: MSButtonVariant.primary,
                  expanded: true,
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const CaseScreen()),
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.sp6),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final c = context.c;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      titleSpacing: AppTokens.sp4,
      title: Text(
        'CASE BRIEFING',
        style: AppText.monoLabel.copyWith(color: c.textMute),
      ),
    );
  }
}

// ── 피해자 요약 행 ────────────────────────────────────────────────────────────

class _VictimRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.ink700, AppColors.ink500],
            ),
            borderRadius: BorderRadius.circular(AppTokens.r3),
            border: Border.all(color: const Color(0x24FFFFFF)),
          ),
          alignment: Alignment.center,
          child: Text(
            '강',
            style: AppText.titleM.copyWith(
              fontSize: 16,
              color: AppColors.ink50,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(width: AppTokens.sp3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '강도현',
                style: AppText.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: c.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'CEO · AI 스타트업 대표',
                style: AppText.bodySm.copyWith(color: c.textSub),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.sp2,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: c.dangerSoft,
            border: Border.all(color: c.danger),
            borderRadius: BorderRadius.circular(AppTokens.r2),
          ),
          child: Text(
            '데모룸',
            style: AppText.monoLabel.copyWith(
              color: c.danger,
              height: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}