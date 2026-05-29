// lib/screens/case_screen.dart
import 'package:flutter/material.dart';
import '../components/ms_bottom_nav.dart';
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
          onTap: (i) => setState(() => _navIndex = i),
        ),
        body: IndexedStack(
          index: _navIndex,
          children: _kScreens,
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
                // 해금 증거 수
                Icon(
                  Icons.description_outlined,
                  size: 14,
                  color: _session.unlockedEvidenceIds.isEmpty
                      ? c.textMute
                      : c.success,
                ),
                const SizedBox(width: AppTokens.sp1),
                Text(
                  '${_session.unlockedEvidenceIds.length}/5',
                  style: AppText.monoNum.copyWith(
                    fontSize: 13,
                    color: _session.unlockedEvidenceIds.isEmpty
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
