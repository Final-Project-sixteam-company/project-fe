// lib/screens/case_screen.dart
import 'package:flutter/material.dart';
import '../components/game_modals.dart';
import '../components/ms_bottom_nav.dart';
import '../components/ms_button.dart';
import '../components/states.dart';
import '../controllers/game_session_controller.dart';
import '../controllers/game_session_provider.dart';
import '../models/play_models.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import 'evidence_screen.dart';
import 'result_screen.dart';
import 'scene_screen.dart';
import 'submit_screen.dart';
import 'suspects_screen.dart';
import 'timeline_screen.dart';

class CaseScreen extends StatefulWidget {
  const CaseScreen({this.scenarioId = 'demoday-eve', super.key});

  final String scenarioId;

  @override
  State<CaseScreen> createState() => _CaseScreenState();
}

class _CaseScreenState extends State<CaseScreen> {
  late final GameSessionController _session;
  int _navIndex = 0;

  /// 상단 HUD에 표시할 사건 코드. 숫자 시나리오 id는 'CL-XXX'로 합성하고,
  /// 샘플(demoday-eve)은 CL-001로 표시한다.
  String get _caseCode {
    final n = int.tryParse(widget.scenarioId);
    if (n != null) return 'CL-${n.toString().padLeft(3, '0')}';
    return 'CL-001';
  }

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
    // 증거 상세 등에서 올린 탭 전환 인텐트를 소비해 바텀 탭을 전환한다.
    _session.addListener(_onSessionChanged);
    // 화면 진입 직후 세션 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _session.startSession();
    });
  }

  /// 컨트롤러가 올린 탭 전환 요청을 처리(소비는 재알림 없이 → 루프 방지).
  void _onSessionChanged() {
    final req = _session.tabRequest;
    if (req == null) return;
    _session.consumeTabRequest();
    if (req != _navIndex && req >= 0 && req < _kScreens.length) {
      setState(() => _navIndex = req);
    }
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    _session.dispose();
    super.dispose();
  }

  /// 뒤로가기 이탈 시: 진행 중인 수사를 중단할지 확인하고, 확정 시 abandon.
  Future<void> _handlePop(bool didPop) async {
    if (didPop) return;
    final navigator = Navigator.of(context);
    // 이미 제출 완료된 경우만 그대로 나간다.
    if (_session.isCompleted) {
      navigator.pop();
      return;
    }
    if (_session.isFinalDeductionSubmitting) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('최종 추리 제출 중입니다. 결과 확인까지 잠시만 기다려 주세요.')),
        );
      return;
    }
    // 서버 세션이 없고 생성 중도 아니면(샘플 시나리오 등) 중단 대상이 아니다.
    // 생성 중(isLoading)이면 다이얼로그를 거쳐 abandonSession 이 생성 완료를 기다린 뒤
    // 정리하도록 한다(생성 직후 이탈 시 PLAYING 세션 잔류 → 409 레이스 방지).
    if (_session.backendSessionId == null && !_session.isLoading) {
      navigator.pop();
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      barrierColor: context.c.scrim,
      builder: (_) => const _AbandonDialog(),
    );
    if (leave != true || !mounted) return;
    final canLeave = await _session.abandonSession();
    if (!mounted) return;
    if (canLeave) {
      navigator.pop();
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('최종 추리 처리 중입니다. 결과 상태를 다시 확인해 주세요.')),
        );
    }
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
              // 정답 누출 런타임 가드: 이미 종료된(PLAYING 아님) 세션이 어떤 경로로든
              // 케이스 화면에 노출되면 증거/용의자/타임라인 탭(정답성 데이터 포함)을
              // 띄우지 않고 종결 상태를 안내한다. (정상 제출은 ResultScreen으로 대체됨)
              final status = _session.dashboard?.status;
              if (!_session.isCompleted &&
                  status != null &&
                  status != PlaySessionStatus.playing) {
                return _buildClosedSession(context);
              }
              return IndexedStack(index: _navIndex, children: _kScreens);
            },
          ),
        ),
      ),
    );
  }

  // ── 세션 로딩 실패 화면(재시도) ──────────────────────────────────────────
  Widget _buildLoadError(BuildContext context) {
    final conflict = _session.sessionConflict;

    // 409 충돌은 단순 '다시 시도'로 해소되지 않는다(이미 진행 중인 세션이 점유 중).
    // 이 경우 '기존 세션 포기 후 새로 시작'을 주 액션으로 올려 복구 경로를 제공한다.
    // (이 기기에서 시작한 세션이면 abandon 으로 정리 후 재시작)
    final retryButton = MSButton(
      label: conflict ? '기존 세션 포기 후 새로 시작' : '다시 시도',
      variant: conflict ? MSButtonVariant.primary : MSButtonVariant.secondary,
      onPressed: () =>
          conflict ? _session.abandonConflictAndRestart() : _session.retry(),
    );
    final exitButton = MSButton(
      label: '나가기',
      variant: MSButtonVariant.ghost,
      onPressed: () => Navigator.of(context).pop(),
    );

    return Padding(
      padding: const EdgeInsets.all(AppTokens.sp6),
      child: MSEmpty(
        icon: conflict ? Icons.lock_clock_outlined : Icons.cloud_off,
        title: conflict ? '진행 중인 세션이 있습니다' : '세션을 시작하지 못했습니다',
        // 서버 메시지가 있으면 우선 사용하고, 없으면 상황별 구체적 안내를 제공한다.
        subtitle:
            _session.loadError ??
            (conflict
                ? '다른 기기나 창에서 이미 이 사건을 수사 중입니다. 나가서 기존 수사를 마치거나 중단한 뒤 다시 시작하세요.'
                : '네트워크 상태를 확인한 뒤 다시 시도해 주세요.'),
        // 충돌(409)이든 일반 오류든 복구 액션('포기 후 재시작'/'다시 시도')을 주 액션으로,
        // '나가기'를 보조 액션으로 둔다.
        action: retryButton,
        secondaryAction: exitButton,
      ),
    );
  }

  // ── 이미 종결된 세션 안내(정답 누출 방지) ────────────────────────────────
  Widget _buildClosedSession(BuildContext context) {
    final status = _session.dashboard?.status;
    // 채점이 끝난(SUBMITTED/COMPLETED) 세션이면 결과 화면으로 보낼 수 있다.
    final scored =
        status == PlaySessionStatus.submitted ||
        status == PlaySessionStatus.completed;
    final sessionId = _session.backendSessionId;

    return Padding(
      padding: const EdgeInsets.all(AppTokens.sp6),
      child: MSEmpty(
        icon: Icons.gavel_outlined,
        title: '이미 종결된 사건입니다',
        subtitle: scored
            ? '이 수사는 이미 제출이 완료되었습니다. 결과를 확인하세요.'
            : '이 수사는 더 이상 진행할 수 없습니다.',
        action: (scored && sessionId != null)
            ? MSButton(
                label: '결과 보기',
                variant: MSButtonVariant.primary,
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => ResultScreen(sessionId: sessionId),
                  ),
                ),
              )
            : MSButton(
                label: '홈으로 돌아가기',
                variant: MSButtonVariant.primary,
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
              ),
        secondaryAction: (scored && sessionId != null)
            ? MSButton(
                label: '홈으로 돌아가기',
                variant: MSButtonVariant.ghost,
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
              )
            : null,
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
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.sp4),
            decoration: BoxDecoration(
              color: c.bg,
              border: Border(bottom: BorderSide(color: c.lineSoft)),
            ),
            child: Row(
              children: [
                // 사건 코드
                Text(
                  _caseCode,
                  style: AppText.monoLabel.copyWith(color: c.textMute),
                ),
                // 사건 브리핑 재확인(개요·피해자·목표). 데이터 로드 후에만 노출.
                // 아이콘 전용(16px·textMute·~32dp)은 발견성·터치가 약해
                // '브리핑' 라벨 + 20px 아이콘 + primary 색 + HUD 풀하이트 터치로 강화.
                if (_session.dashboard != null) ...[
                  const SizedBox(width: AppTokens.sp2),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => showCaseBriefingModal(
                      context,
                      dashboard: _session.dashboard!,
                    ),
                    child: Container(
                      height: AppTokens.sp10, // HUD 높이만큼 세로 터치 영역 확보
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.sp2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 20,
                            color: c.primary,
                          ),
                          const SizedBox(width: AppTokens.sp1),
                          Text(
                            '브리핑',
                            style: AppText.monoLabel.copyWith(
                              color: c.primary,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                // 경과 시간
                Icon(Icons.timer_outlined, size: 14, color: c.textMute),
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
                  color: _session.unlockedCount == 0 ? c.textMute : c.success,
                ),
                const SizedBox(width: AppTokens.sp1),
                Text(
                  '${_session.unlockedCount}/${_session.totalEvidenceCount}',
                  style: AppText.monoNum.copyWith(
                    fontSize: 13,
                    color: _session.unlockedCount == 0 ? c.textMute : c.success,
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
                Text('수사 중단', style: AppText.titleM.copyWith(color: c.text)),
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
