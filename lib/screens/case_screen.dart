// lib/screens/case_screen.dart
import 'package:flutter/material.dart';
import '../components/ms_bottom_nav.dart';
import '../components/ms_button.dart';
import '../components/states.dart';
import '../controllers/game_session_controller.dart';
import '../controllers/game_session_provider.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import 'evidence_screen.dart';
import 'scene_screen.dart';
import 'submit_screen.dart';
import 'suspects_screen.dart';
import 'timeline_screen.dart';

class CaseScreen extends StatefulWidget {
  const CaseScreen({
    this.scenarioId = 'demoday-eve',
    super.key,
  });

  final String scenarioId;

  @override
  State<CaseScreen> createState() => _CaseScreenState();
}

class _CaseScreenState extends State<CaseScreen> {
  late final GameSessionController _session;
  int _navIndex = 0;

  static const _kScreens = <Widget>[
    SceneScreen(),
    EvidenceScreen(),
    SuspectsScreen(),
    TimelineScreen(),
    SubmitScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _session = GameSessionController(scenarioId: widget.scenarioId);
    // 화면 진입 직후 세션 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _session.startSession();
    });
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return GameSessionProvider(
      controller: _session,
      child: Scaffold(
        backgroundColor: c.bg,
        appBar: _buildHud(context),
        bottomNavigationBar: MSBottomNav(
          currentIndex: _navIndex,
          onTap: (i) {
            setState(() => _navIndex = i);
            // 증거 탭(1) 진입 시 서버에서 증거/대시보드 재조회.
            // 시간 기반 해금(unlock_type=TIME)은 심문 응답에 실리지 않아
            // 탭 진입 시점에 다시 불러와야 새로 풀린 증거가 노출된다.
            if (i == 1) _session.refreshEvidences();
          },
        ),
        body: AnimatedBuilder(
          animation: _session,
          builder: (context, _) {
            // 세션 초기 로딩/실패 시에는 탭(가짜/빈 데이터) 대신 전역 상태를 노출.
            // dashboard가 채워지면 정상 로딩 완료로 본다.
            if (_session.dashboard == null) {
              if (_session.isLoading) {
                return const Center(child: MSSpinner(size: 28));
              }
              if (_session.loadError != null) {
                return _buildLoadError(context);
              }
            }
            return IndexedStack(
              index: _navIndex,
              children: _kScreens,
            );
          },
        ),
      ),
    );
  }

  // ── 세션 로딩 실패 화면(재시도) ──────────────────────────────────────────
  Widget _buildLoadError(BuildContext context) {
    final conflict = _session.sessionConflict;
    return Padding(
      padding: const EdgeInsets.all(AppTokens.sp6),
      child: MSEmpty(
        icon: conflict ? Icons.lock_clock_outlined : Icons.cloud_off,
        title: conflict ? '진행 중인 세션이 있습니다' : '세션을 시작하지 못했습니다',
        subtitle: _session.loadError,
        action: MSButton(
          label: '다시 시도',
          variant: MSButtonVariant.secondary,
          onPressed: () => _session.retry(),
        ),
      ),
    );
  }

  // ── 상단 HUD: 타이머 + 해금 증거 수 ──────────────────────────────────────
  PreferredSizeWidget _buildHud(BuildContext context) {
    final c = context.c;

    return PreferredSize(
      preferredSize: const Size.fromHeight(AppTokens.sp10),
      child: SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: _session,
          builder: (context, _) => Container(
            height: AppTokens.sp10,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.sp4,
            ),
            decoration: BoxDecoration(
              color: c.bg,
              border: Border(
                bottom: BorderSide(color: c.lineSoft),
              ),
            ),
            child: Row(
              children: [
                // 사건 코드
                Text(
                  'CL-001',
                  style: AppText.monoLabel.copyWith(color: c.textMute),
                ),
                const Spacer(),
                // 경과 시간
                Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: c.textMute,
                ),
                const SizedBox(width: AppTokens.sp1),
                Text(
                  _session.elapsedLabel,
                  style: AppText.monoNum.copyWith(
                    fontSize: 13,
                    color: c.text,
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: AppTokens.sp4),
                // 해금 증거 수 (서버 기준)
                Icon(
                  Icons.description_outlined,
                  size: 14,
                  color: _session.unlockedCount == 0
                      ? c.textMute
                      : c.success,
                ),
                const SizedBox(width: AppTokens.sp1),
                Text(
                  '${_session.unlockedCount}/${_session.totalEvidenceCount}',
                  style: AppText.monoNum.copyWith(
                    fontSize: 13,
                    color: _session.unlockedCount == 0
                        ? c.textMute
                        : c.success,
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
