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

  /// 뒤로가기 이탈 시: 진행 중인 수사를 중단할지 확인하고, 확정 시 abandon.
  Future<void> _handlePop(bool didPop) async {
    if (didPop) return;
    final navigator = Navigator.of(context);
    // 이미 제출 완료됐거나 서버 세션이 없으면 그대로 나간다(중단 대상 아님).
    if (_session.isCompleted || _session.backendSessionId == null) {
      navigator.pop();
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      barrierColor: context.c.scrim,
      builder: (_) => const _AbandonDialog(),
    );
    if (leave != true || !mounted) return;
    await _session.abandonSession();
    if (mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _handlePop(didPop),
      child: GameSessionProvider(
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

// ── 수사 중단 확인 다이얼로그 ─────────────────────────────────────────────────

class _AbandonDialog extends StatelessWidget {
  const _AbandonDialog();

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Dialog(
      backgroundColor: c.bgElev,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.r6),
        side: BorderSide(color: c.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.sp6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.logout, size: 22, color: c.danger),
                const SizedBox(width: AppTokens.sp2),
                Text(
                  '수사 중단',
                  style: AppText.titleM.copyWith(color: c.text),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.sp3),
            Text(
              '지금 나가면 진행 중인 수사가 중단됩니다.\n'
              '진행 상황은 저장되지 않으며 다음에 새로 시작해야 합니다.',
              style: AppText.body.copyWith(color: c.textSub, height: 1.6),
            ),
            const SizedBox(height: AppTokens.sp6),
            Row(
              children: [
                Expanded(
                  child: MSButton(
                    label: '계속 수사',
                    variant: MSButtonVariant.secondary,
                    expanded: true,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: AppTokens.sp3),
                Expanded(
                  child: MSButton(
                    label: '나가기',
                    variant: MSButtonVariant.danger,
                    expanded: true,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
