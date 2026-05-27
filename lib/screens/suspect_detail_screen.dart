// lib/screens/suspect_detail_screen.dart
import 'package:flutter/material.dart';
import '../components/evidence_item.dart';
import '../components/ms_button.dart';
import '../components/ms_kicker.dart';
import '../models/case.dart';
import '../models/sample_case.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import 'interrogation_chat_screen.dart';

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
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

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
                    widget.suspect.role,
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
                child: _SuspicionPanel(suspicion: widget.suspect.suspicion),
              ),
            ),
            const SizedBox(height: AppTokens.sp6),
            // ── 관련 증거 ────────────────────────────────────────────
            const MSKicker('관련 증거'),
            const SizedBox(height: AppTokens.sp3),
            ...sampleCase.evidences.take(2).map(
                  (e) => Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.sp3),
                child: EvidenceItem(e, onTap: () {}),
              ),
            ),
            const SizedBox(height: AppTokens.sp3),
            // ── 진술 ────────────────────────────────────────────────
            const MSKicker('진술'),
            const SizedBox(height: AppTokens.sp3),
            _StatementCard(suspect: widget.suspect),
            const SizedBox(height: AppTokens.sp10),
          ],
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

// ── 진술 카드 ─────────────────────────────────────────────────────────────────

class _StatementCard extends StatelessWidget {
  const _StatementCard({required this.suspect});

  final Suspect suspect;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"그날 밤 저는 22시 이전에 이미 퇴근했습니다. '
                'CCTV 기록을 확인하시면 알 수 있을 겁니다."',
            style: AppText.body.copyWith(color: c.text, height: 1.6),
          ),
          const SizedBox(height: AppTokens.sp3),
          Text(
            '22:35 · 1차 조사실',
            style: AppText.monoLabel.copyWith(color: c.textMute),
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
    final c = context.c;

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
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => InterrogationChatScreen(suspect: suspect),
                  ),
                ),
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

    showDialog(
      context: context,
      barrierColor: c.scrim,
      builder: (context) => _ConfirmDialog(suspect: suspect),
    );
  }
}

// ── 범인 지목 확인 다이얼로그 ─────────────────────────────────────────────────

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({required this.suspect});

  final Suspect suspect;

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
              '${suspect.name}을(를) 범인으로 지목합니다.\n'
                  '이 결정은 되돌릴 수 없습니다. 계속하시겠습니까?',
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
                    label: '지목 확정',
                    variant: MSButtonVariant.danger,
                    expanded: true,
                    onPressed: () {
                      Navigator.of(context).pop();
                      // TODO: 결과 화면으로 이동
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