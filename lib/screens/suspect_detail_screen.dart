// lib/screens/suspect_detail_screen.dart
import 'package:flutter/material.dart';
import '../components/evidence_item.dart';
import '../components/ms_button.dart';
import '../components/ms_kicker.dart';
import '../controllers/game_session_controller.dart';
import '../controllers/game_session_provider.dart';
import '../core/api/api_exception.dart';
import '../models/case.dart';
import '../models/play_models.dart';
import '../repositories/play_session_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import 'interrogation_chat_screen.dart';
import 'submit_screen.dart';

class SuspectDetailScreen extends StatefulWidget {
  const SuspectDetailScreen({required this.suspect, super.key});

  final Suspect suspect;

  @override
  State<SuspectDetailScreen> createState() => _SuspectDetailScreenState();
}

class _SuspectDetailScreenState extends State<SuspectDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  bool _logsLoaded = false;
  List<InterrogationResult> _logs = const [];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AppMotion.dur3,
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: AppMotion.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 8),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: AppMotion.easeOut));
    _ctrl.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_logsLoaded) return;
    _logsLoaded = true;
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final controller = context.sessionRead;
    final sessionId = controller.backendSessionId;
    final suspectId = int.tryParse(widget.suspect.id);
    if (sessionId == null || suspectId == null) return;
    try {
      final logs = await playSessionRepo.interrogationLogs(
        sessionId,
        suspectId: suspectId,
      );
      if (mounted) setState(() => _logs = logs);
    } on ApiException catch (_) {
      // 로그 조회 실패는 조용히 무시(프로필은 계속 표시)
    } catch (_) {}
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final raw = context.session.rawSuspect(widget.suspect.id);
    final related = _relatedEvidences(context);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: _buildAppBar(context),
      bottomNavigationBar: _BottomBar(suspect: widget.suspect),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.sp4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppTokens.sp6),
            // ── 아바타 + 이름 ─────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Hero(
                    tag: widget.suspect.id,
                    child: _LargeAvatar(name: widget.suspect.name),
                  ),
                  const SizedBox(height: AppTokens.sp3),
                  Text(
                    widget.suspect.name,
                    style: AppText.titleL.copyWith(color: c.text),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    raw?.role ?? widget.suspect.role,
                    style: AppText.bodySm.copyWith(color: c.textSub),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.sp6),
            // ── 의심도 패널 (애니메이션) ──────────────────────────────
            FadeTransition(
              opacity: _opacity,
              child: AnimatedBuilder(
                animation: _slide,
                builder: (context, child) => Transform.translate(
                  offset: _slide.value,
                  child: child,
                ),
                child: _SuspicionPanel(
                  suspicion: raw?.suspicionLevel ?? widget.suspect.suspicion,
                ),
              ),
            ),
            // ── 피해자와의 관계 ──────────────────────────────────────
            if (raw?.relationToVictim != null &&
                raw!.relationToVictim!.isNotEmpty) ...[
              const SizedBox(height: AppTokens.sp6),
              const MSKicker('피해자와의 관계'),
              const SizedBox(height: AppTokens.sp3),
              _InfoCard(text: raw.relationToVictim!),
            ],
            // ── 관련 증거 ────────────────────────────────────────────
            if (related.isNotEmpty) ...[
              const SizedBox(height: AppTokens.sp6),
              const MSKicker('관련 증거'),
              const SizedBox(height: AppTokens.sp3),
              ...related.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: AppTokens.sp3),
                  child: EvidenceItem(e, onTap: () {}),
                ),
              ),
            ],
            const SizedBox(height: AppTokens.sp6),
            // ── 진술 ────────────────────────────────────────────────
            const MSKicker('진술'),
            const SizedBox(height: AppTokens.sp3),
            _StatementCard(
              statement: raw?.publicStatement,
              alibi: raw?.alibi,
            ),
            // ── 이전 심문 기록 ───────────────────────────────────────
            if (_logs.isNotEmpty) ...[
              const SizedBox(height: AppTokens.sp6),
              MSKicker('이전 심문 · ${_logs.length}건'),
              const SizedBox(height: AppTokens.sp3),
              ..._logs.map((log) => _LogCard(log: log)),
            ],
            const SizedBox(height: AppTokens.sp10),
          ],
        ),
      ),
    );
  }

  /// 이 용의자와 연관된(관련 용의자에 포함된) 증거 목록.
  List<Evidence> _relatedEvidences(BuildContext context) {
    final controller = context.session;
    final suspectId = int.tryParse(widget.suspect.id);
    if (suspectId == null) return const [];
    return controller.evidences.where((e) {
      final raw = controller.rawEvidence(e.id);
      return raw != null &&
          raw.relatedSuspects.any((rs) => rs.suspectId == suspectId);
    }).toList();
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final c = context.c;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: c.text),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'SUSPECT',
        style: AppText.monoLabel.copyWith(color: c.textMute),
      ),
    );
  }
}

// ── 큰 아바타 ─────────────────────────────────────────────────────────────────

class _LargeAvatar extends StatelessWidget {
  const _LargeAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.characters.first : '?';

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.tealBase, AppColors.skyBase],
        ),
        borderRadius: BorderRadius.circular(AppTokens.r5),
        border: Border.all(color: const Color(0x24FFFFFF)),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: AppText.titleL.copyWith(
          fontSize: 32,
          color: AppColors.ink950,
          height: 1.0,
        ),
      ),
    );
  }
}

// ── 의심도 패널 ───────────────────────────────────────────────────────────────

class _SuspicionPanel extends StatelessWidget {
  const _SuspicionPanel({required this.suspicion});

  final int suspicion;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final double ratio = (suspicion / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(AppTokens.sp4),
      decoration: BoxDecoration(
        color: c.bgElev,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppTokens.r6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SUSPICION',
            style: AppText.monoLabel.copyWith(color: c.textMute),
          ),
          const SizedBox(height: AppTokens.sp1),
          Text(
            '$suspicion',
            style: AppText.monoNum.copyWith(
              fontSize: 48,
              fontWeight: FontWeight.w700,
              color: c.danger,
              height: 1.0,
            ),
          ),
          const SizedBox(height: AppTokens.sp3),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.r1),
            child: SizedBox(
              height: 8,
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  children: [
                    Positioned.fill(child: ColoredBox(color: c.bgHover)),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: constraints.maxWidth * ratio,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.skyBase, AppColors.roseBase],
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
    );
  }
}

// ── 단순 정보 카드 ────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Container(
      padding: const EdgeInsets.all(AppTokens.sp4),
      decoration: BoxDecoration(
        color: c.bgElev,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppTokens.r6),
      ),
      child: Text(
        text,
        style: AppText.body.copyWith(color: c.text, height: 1.6),
      ),
    );
  }
}

// ── 진술 카드 ─────────────────────────────────────────────────────────────────

class _StatementCard extends StatelessWidget {
  const _StatementCard({this.statement, this.alibi});

  final String? statement;
  final String? alibi;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final text = (statement != null && statement!.isNotEmpty)
        ? '"$statement"'
        : '아직 확보된 진술이 없습니다.';

    return Container(
      padding: const EdgeInsets.all(AppTokens.sp4),
      decoration: BoxDecoration(
        color: c.bgElev,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppTokens.r6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: AppText.body.copyWith(color: c.text, height: 1.6),
          ),
          if (alibi != null && alibi!.isNotEmpty) ...[
            const SizedBox(height: AppTokens.sp3),
            Text(
              '알리바이',
              style: AppText.monoLabel.copyWith(color: c.textMute),
            ),
            const SizedBox(height: AppTokens.sp1),
            Text(
              alibi!,
              style: AppText.bodySm.copyWith(color: c.textSub, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}

// ── 심문 기록 카드 ────────────────────────────────────────────────────────────

class _LogCard extends StatelessWidget {
  const _LogCard({required this.log});

  final InterrogationResult log;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.sp2),
      padding: const EdgeInsets.all(AppTokens.sp3),
      decoration: BoxDecoration(
        color: c.bgElev,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppTokens.r4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Q. ${log.question}',
            style: AppText.bodySm.copyWith(
              color: c.primary,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppTokens.sp1),
          Text(
            'A. ${log.answer}',
            style: AppText.bodySm.copyWith(color: c.textSub, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ── 하단 고정 버튼 바 ─────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.suspect});

  final Suspect suspect;

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.sp4,
          vertical: AppTokens.sp3,
        ),
        child: Row(
          children: [
            Expanded(
              child: MSButton(
                label: '뒤로',
                variant: MSButtonVariant.secondary,
                expanded: true,
                onPressed: () => Navigator.of(context).pop(),
              ),

            ),
            Expanded(
              flex: 2,
              child: MSButton(
                label: '심문하기',
                variant: MSButtonVariant.primary,
                expanded: true,
                onPressed: () {
                  final ctrl = context.sessionRead;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GameSessionProvider(
                        controller: ctrl,
                        child: InterrogationChatScreen(suspect: suspect),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: AppTokens.sp3),
            Expanded(
              child: MSButton(
                label: '범인 지목',
                variant: MSButtonVariant.danger,
                expanded: true,
                onPressed: () => _showConfirmDialog(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmDialog(BuildContext context) {
    final c = context.c;
    // showDialog의 context는 GameSessionProvider 하위가 아니므로
    // 컨트롤러를 여기서(provider 하위에서) 미리 읽어 전달한다.
    final controller = context.sessionRead;
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      barrierColor: c.scrim,
      builder: (_) => _ConfirmDialog(
        suspect: suspect,
        controller: controller,
        navigator: navigator,
      ),
    );
  }
}

// ── 범인 지목 확인 다이얼로그 ─────────────────────────────────────────────────

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.suspect,
    required this.controller,
    required this.navigator,
  });

  final Suspect suspect;
  final GameSessionController controller;
  final NavigatorState navigator;

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
            Text(
              '범인 지목',
              style: AppText.titleM.copyWith(color: c.text),
            ),
            const SizedBox(height: AppTokens.sp3),
            Text(
              '${suspect.name}을(를) 범인으로 지목하고 최종 추리를 작성합니다.\n'
                  '범행 동기·방법·결정적 증거를 입력해야 제출할 수 있습니다.',
              style: AppText.body.copyWith(color: c.textSub, height: 1.6),
            ),
            const SizedBox(height: AppTokens.sp6),
            Row(
              children: [
                Expanded(
                  child: MSButton(
                    label: '취소',
                    variant: MSButtonVariant.secondary,
                    expanded: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: AppTokens.sp3),
                Expanded(
                  child: MSButton(
                    label: '추리 작성',
                    variant: MSButtonVariant.danger,
                    expanded: true,
                    onPressed: () {
                      navigator.pop();
                      navigator.push(
                        MaterialPageRoute(
                          builder: (_) => GameSessionProvider(
                            controller: controller,
                            child: SubmitScreen(initialSuspect: suspect),
                          ),
                        ),
                      );
                    },
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
