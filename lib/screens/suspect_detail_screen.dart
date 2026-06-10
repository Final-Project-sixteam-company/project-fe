// lib/screens/suspect_detail_screen.dart
import 'package:flutter/material.dart';
import '../components/evidence_item.dart';
import '../components/ms_kicker.dart';
import '../components/ms_pill.dart';
import '../controllers/game_session_provider.dart';
import '../core/api/api_exception.dart';
import '../models/case.dart';
import '../models/play_models.dart';
import '../repositories/play_session_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import 'suspect_detail_bottom_bar.dart';
import 'suspect_detail_widgets.dart';
import 'suspect_detail_cards.dart';
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
    _ctrl = AnimationController(vsync: this, duration: AppMotion.dur3);
    _opacity = CurvedAnimation(parent: _ctrl, curve: AppMotion.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 8), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: AppMotion.easeOut));
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
    final ctrl = context.sessionRead;
    final sessionId = ctrl.backendSessionId;
    final suspectId = int.tryParse(widget.suspect.id);
    if (sessionId == null || suspectId == null) return;
    try {
      final logs = await playSessionRepo.interrogationLogs(
          sessionId, suspectId: suspectId);
      if (mounted) setState(() => _logs = logs);
    } on ApiException catch (_) {
    } catch (_) {}
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<Evidence> _relatedEvidences() {
    final ctrl = context.session;
    final suspectId = int.tryParse(widget.suspect.id);
    if (suspectId == null) return const [];
    return ctrl.evidences.where((e) {
      final raw = ctrl.rawEvidence(e.id);
      return raw != null &&
          raw.relatedSuspects.any((rs) => rs.suspectId == suspectId);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final raw = context.session.rawSuspect(widget.suspect.id);
    final related = _relatedEvidences();
    final tone = raw?.personalityTone ?? widget.suspect.personalityTone;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.suspect.isWitness ? 'WITNESS' : 'SUSPECT',
          style: AppText.monoLabel.copyWith(color: c.textMute),
        ),
      ),
      bottomNavigationBar:
      SuspectDetailBottomBar(
        suspect: widget.suspect,
        onInterrogationDone: _loadLogs,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.sp4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppTokens.sp6),
            Center(
              child: Column(
                children: [
                  Hero(
                    tag: widget.suspect.id,
                    child: SuspectLargeAvatar(
                      name: widget.suspect.name,
                      isWitness: widget.suspect.isWitness,
                    ),
                  ),
                  const SizedBox(height: AppTokens.sp3),
                  Text(widget.suspect.name,
                      style: AppText.titleL.copyWith(color: c.text)),
                  const SizedBox(height: AppTokens.sp1),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(raw?.role ?? widget.suspect.role,
                          style:
                          AppText.bodySm.copyWith(color: c.textSub)),
                      if (widget.suspect.isWitness) ...[
                        const SizedBox(width: AppTokens.sp2),
                        const MSPill('증인', tone: MSPillTone.mute),
                      ],
                    ],
                  ),
                  if (tone != null) ...[
                    const SizedBox(height: AppTokens.sp2),
                    PersonalityBadge(tone: tone),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppTokens.sp6),
            if (!widget.suspect.isWitness)
              FadeTransition(
                opacity: _opacity,
                child: AnimatedBuilder(
                  animation: _slide,
                  builder: (_, child) => Transform.translate(
                      offset: _slide.value, child: child),
                  child: SuspicionPanel(
                    suspicion:
                    raw?.suspicionLevel ?? widget.suspect.suspicion,
                  ),
                ),
              ),
            if (raw?.relationToVictim?.isNotEmpty ?? false) ...[
              const SizedBox(height: AppTokens.sp6),
              const MSKicker('피해자와의 관계'),
              const SizedBox(height: AppTokens.sp3),
              SuspectInfoCard(text: raw!.relationToVictim!),
            ],
            // ── 관련 증거 ──────────────────────────────────────────
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
            // ── 진술 ──────────────────────────────────────────────
            const SizedBox(height: AppTokens.sp6),
            const MSKicker('진술'),
            const SizedBox(height: AppTokens.sp3),
            SuspectStatementCard(
              statement: raw?.publicStatement,
              alibi: raw?.alibi,
              publicAlibi:
              raw?.publicAlibi ?? widget.suspect.publicAlibi,
            ),
            // ── 이전 심문 기록 ─────────────────────────────────────
            if (_logs.isNotEmpty) ...[
              const SizedBox(height: AppTokens.sp6),
              MSKicker('이전 심문 · ${_logs.length}건'),
              const SizedBox(height: AppTokens.sp3),
              ..._logs.map((log) => SuspectLogCard(log: log)),
            ],
            const SizedBox(height: AppTokens.sp10),
          ],
        ),
      ),
    );
  }
}