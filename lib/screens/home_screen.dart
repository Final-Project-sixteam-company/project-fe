import 'package:flutter/material.dart';
import '../components/ms_button.dart';
import '../components/ms_kicker.dart';
import '../components/ms_pill.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import 'case_briefing_screen.dart';
import 'case_screen.dart';

// ── 로컬 데이터 모델 ──────────────────────────────────────────────────────────

class _ActiveCase {
  final String title;
  final int progress;

  const _ActiveCase({required this.title, required this.progress});
}

class _ScenarioCard {
  final String title;
  final String author;
  final double rating;

  const _ScenarioCard({
    required this.title,
    required this.author,
    required this.rating,
  });
}

const _featuredTitle = '자정의 신호';
const _featuredSubtitle = '스타트업 CTO 실종 사건';

const _activeCase = _ActiveCase(
  title: 'CL-001 · 자정의 신호',
  progress: 68,
);

const _scenarios = [
  _ScenarioCard(title: '밀실의 유산', author: '김탐정', rating: 4.8),
  _ScenarioCard(title: '붉은 수요일', author: '이추리', rating: 4.6),
  _ScenarioCard(title: '폐역의 목격자', author: '박단서', rating: 4.9),
  _ScenarioCard(title: '사라진 화가', author: '최미궁', rating: 4.5),
];

// ── 화면 ──────────────────────────────────────────────────────────────────────

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
              // ── 2. 추천 사건 배너 ─────────────────────────────
              _FeaturedBanner(),
              const SizedBox(height: AppTokens.sp6),
              // ── 3. 진행 중인 수사 ──────────────────────────────
              const MSKicker('진행 중인 수사'),
              const SizedBox(height: AppTokens.sp3),
              _ActiveCaseCard(data: _activeCase),
              const SizedBox(height: AppTokens.sp6),
              // ── 4. 인기 커스텀 시나리오 ────────────────────────
              const MSKicker('인기 커스텀 시나리오'),
              const SizedBox(height: AppTokens.sp3),
              _ScenarioList(),
              const SizedBox(height: AppTokens.sp8),
              // ── 5. 나만의 사건 만들기 ──────────────────────────
              MSButton(
                label: '나만의 사건 만들기',
                variant: MSButtonVariant.secondary,
                expanded: true,
                onPressed: () {},
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
          onPressed: () {},
          icon: Icon(Icons.notifications_outlined, color: c.textSub),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: AppTokens.sp3),
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.account_circle_outlined, color: c.textSub),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}

// ── 추천 사건 배너 ────────────────────────────────────────────────────────────

class _FeaturedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.c;

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
              _featuredSubtitle,
              style: AppText.monoLabel.copyWith(
                color: AppColors.tealBase.withValues(alpha: .8),
              ),
            ),
            const Spacer(),
            const MSPill('추천', tone: MSPillTone.primary),
            const SizedBox(height: AppTokens.sp2),
            Text(
              _featuredTitle,
              style: AppText.titleM.copyWith(color: AppColors.ink50),
            ),
            const SizedBox(height: AppTokens.sp3),
            MSButton(
              label: '바로 시작하기',
              variant: MSButtonVariant.ghost,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CaseBriefingScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 진행 중인 수사 카드 ───────────────────────────────────────────────────────

class _ActiveCaseCard extends StatelessWidget {
  const _ActiveCaseCard({required this.data});

  final _ActiveCase data;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final double ratio = (data.progress / 100).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CaseScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppTokens.sp4),
        decoration: BoxDecoration(
          color: c.bgElev,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(AppTokens.r4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    data.title,
                    style: AppText.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: c.text,
                    ),
                  ),
                ),
                Text(
                  '${data.progress}%',
                  style: AppText.monoNum.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: c.primary,
                    height: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.sp3),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTokens.r1),
              child: SizedBox(
                height: 5,
                child: LayoutBuilder(
                  builder: (context, constraints) => Stack(
                    children: [
                      Positioned.fill(
                        child: ColoredBox(color: c.bgHover),
                      ),
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: constraints.maxWidth * ratio,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.skyBase,
                                AppColors.tealBase,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 시나리오 가로 스크롤 ──────────────────────────────────────────────────────

class _ScenarioList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _scenarios.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppTokens.sp3),
        itemBuilder: (_, i) => _ScenarioMiniCard(data: _scenarios[i]),
      ),
    );
  }
}

class _ScenarioMiniCard extends StatelessWidget {
  const _ScenarioMiniCard({required this.data});

  final _ScenarioCard data;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(AppTokens.sp3),
        decoration: BoxDecoration(
          color: c.bg,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(AppTokens.r4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              data.title,
              style: AppText.body.copyWith(
                fontWeight: FontWeight.w600,
                color: c.text,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              data.author,
              style: AppText.caption.copyWith(color: c.textSub),
            ),
            const SizedBox(height: AppTokens.sp1),
            Text(
              '★ ${data.rating}',
              style: AppText.monoLabel.copyWith(color: c.primary),
            ),
          ],
        ),
      ),
    );
  }
}