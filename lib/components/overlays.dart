import 'package:flutter/material.dart';
import '../components/ms_button.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

// ── Toast ─────────────────────────────────────────────────────────────────────

enum ToastTone { primary, success, danger }

extension _ToastToneColors on ToastTone {
  Color soft(AppColorsScheme c) => switch (this) {
    ToastTone.primary => c.primarySoft,
    ToastTone.success => c.successSoft,
    ToastTone.danger => c.dangerSoft,
  };

  Color base(AppColorsScheme c) => switch (this) {
    ToastTone.primary => c.primary,
    ToastTone.success => c.success,
    ToastTone.danger => c.danger,
  };
}

class MSToast {
  MSToast._();

  static void show(
      BuildContext context,
      String message, {
        ToastTone tone = ToastTone.primary,
      }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _ToastWidget(
        message: message,
        tone: tone,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }
}

class _ToastWidget extends StatefulWidget {
  const _ToastWidget({
    required this.message,
    required this.tone,
    required this.onDismiss,
  });

  final String message;
  final ToastTone tone;
  final VoidCallback onDismiss;

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppMotion.dur2);
    _opacity = CurvedAnimation(parent: _ctrl, curve: AppMotion.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: AppMotion.easeOut));

    _ctrl.forward();

    Future.delayed(const Duration(seconds: 4), _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _ctrl.reverse();
    if (mounted) widget.onDismiss();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final Color soft = widget.tone.soft(c);
    final Color base = widget.tone.base(c);

    return Positioned(
      bottom: AppTokens.sp10,
      left: AppTokens.sp4,
      right: AppTokens.sp4,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) => FadeTransition(
          opacity: _opacity,
          child: Transform.translate(
            offset: _slide.value,
            child: child,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.sp4,
              vertical: AppTokens.sp3,
            ),
            decoration: BoxDecoration(
              color: soft,
              border: Border.all(color: base),
              borderRadius: BorderRadius.circular(AppTokens.r3),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: base,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppTokens.sp3),
                Expanded(
                  child: Text(
                    widget.message,
                    style: AppText.bodySm.copyWith(color: base),
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

// ── Modal ─────────────────────────────────────────────────────────────────────

Future<void> showMSModal(
    BuildContext context, {
      required String title,
      required Widget child,
      required MSButton primaryAction,
      required MSButton secondaryAction,
    }) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Theme.of(context).brightness == Brightness.dark
        ? AppColors.ink950.withValues(alpha: .54)
        : AppColors.ink0.withValues(alpha: .26),
    transitionDuration: AppMotion.dur3,
    pageBuilder: (_, __, ___) => _MSModalContent(
      title: title,
      primaryAction: primaryAction,
      secondaryAction: secondaryAction,
      child: child,
    ),
    transitionBuilder: (_, anim, __, child) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: AppMotion.easeOut,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: .98, end: 1.0).animate(curved),
          child: AnimatedBuilder(
            animation: curved,
            builder: (context, c) => Transform.translate(
              offset: Offset(0, (1 - curved.value) * 8),
              child: c,
            ),
            child: child,
          ),
        ),
      );
    },
  );
}

class _MSModalContent extends StatelessWidget {
  const _MSModalContent({
    required this.title,
    required this.child,
    required this.primaryAction,
    required this.secondaryAction,
  });

  final String title;
  final Widget child;
  final MSButton primaryAction;
  final MSButton secondaryAction;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.sp4),
          child: Container(
            padding: const EdgeInsets.all(AppTokens.sp6),
            decoration: BoxDecoration(
              color: c.bgElev,
              border: Border.all(color: c.line),
              borderRadius: BorderRadius.circular(AppTokens.r6),
              boxShadow: [
                BoxShadow(
                  color: c.shadowCard,
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: c.shadowCard,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: AppText.titleM.copyWith(color: c.text),
                ),
                const SizedBox(height: AppTokens.sp4),
                child,
                const SizedBox(height: AppTokens.sp6),
                Row(
                  children: [
                    Expanded(child: secondaryAction),
                    const SizedBox(width: AppTokens.sp3),
                    Expanded(child: primaryAction),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 사용 예시 ─────────────────────────────────────────────────────────────────

class OverlaysExample extends StatelessWidget {
  const OverlaysExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MSButton(
            label: 'Toast — primary',
            onPressed: () => MSToast.show(context, '단서가 추가됐습니다'),
          ),
          const SizedBox(height: AppTokens.sp3),
          MSButton(
            label: 'Toast — success',
            variant: MSButtonVariant.secondary,
            onPressed: () => MSToast.show(
              context,
              '증거 분석이 완료됐습니다',
              tone: ToastTone.success,
            ),
          ),
          const SizedBox(height: AppTokens.sp3),
          MSButton(
            label: 'Toast — danger',
            variant: MSButtonVariant.danger,
            onPressed: () => MSToast.show(
              context,
              '용의자가 도주했습니다',
              tone: ToastTone.danger,
            ),
          ),
          const SizedBox(height: AppTokens.sp6),
          MSButton(
            label: 'Modal 열기',
            variant: MSButtonVariant.secondary,
            onPressed: () => showMSModal(
              context,
              title: '증거 삭제',
              child: Text(
                '이 증거를 삭제하면 복구할 수 없습니다. 계속하시겠습니까?',
                style: AppText.body.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const AppColorsScheme(
                    bg: Color(0xFF020617),
                    bgElev: Color(0xFF0F172A),
                    bgHover: Color(0xFF1E293B),
                    line: Color(0xFF334155),
                    lineSoft: Color(0xFF1E293B),
                    text: Color(0xFFF8FAFC),
                    textSub: Color(0xFFCBD5E1),
                    textMute: Color(0xFF64748B),
                    primary: Color(0xFF38BDF8),
                    primarySoft: Color(0x2438BDF8),
                    primaryInk: Color(0xFF020617),
                    success: Color(0xFF0D9488),
                    successSoft: Color(0x240D9488),
                    danger: Color(0xFFF43F5E),
                    dangerSoft: Color(0x24F43F5E),
                    scrim: Colors.black54,
                    shadowCard: Colors.black87,
                  ).textSub
                      : const AppColorsScheme(
                    bg: Color(0xFFF8FAFC),
                    bgElev: Color(0xFFFFFFFF),
                    bgHover: Color(0xFFF1F5F9),
                    line: Color(0xFFCBD5E1),
                    lineSoft: Color(0xFFE2E8F0),
                    text: Color(0xFF0F172A),
                    textSub: Color(0xFF475569),
                    textMute: Color(0xFF94A3B8),
                    primary: Color(0xFF0284C7),
                    primarySoft: Color(0x2438BDF8),
                    primaryInk: Color(0xFFFFFFFF),
                    success: Color(0xFF0F766E),
                    successSoft: Color(0x240D9488),
                    danger: Color(0xFFE11D48),
                    dangerSoft: Color(0x24F43F5E),
                    scrim: Colors.black26,
                    shadowCard: Colors.black12,
                  ).textSub,
                ),
              ),
              primaryAction: MSButton(
                label: '삭제',
                variant: MSButtonVariant.danger,
                expanded: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
              secondaryAction: MSButton(
                label: '취소',
                variant: MSButtonVariant.secondary,
                expanded: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}