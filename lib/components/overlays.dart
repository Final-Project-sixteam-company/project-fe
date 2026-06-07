import 'package:flutter/material.dart';
import '../components/ms_button.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

// ── Toast ─────────────────────────────────────────────────────────────────────

enum ToastTone { primary, success, danger }

extension _ToastToneColors on ToastTone {
  Color soft(AppColorScheme c) => switch (this) {
    ToastTone.primary => c.primarySoft,
    ToastTone.success => c.successSoft,
    ToastTone.danger => c.dangerSoft,
  };

  Color base(AppColorScheme c) => switch (this) {
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
        onDismiss: () {
          entry.remove();
        },
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

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  bool _isDismissing = false;

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

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && !_isDismissing) {
        _dismiss();
      }
    });
  }

  Future<void> _dismiss() async {
    if (!mounted || _isDismissing) return;
    setState(() => _isDismissing = true);
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
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _slide,
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
    barrierColor: context.c.scrim,
    transitionDuration: AppMotion.dur3,
    pageBuilder: (_, _, _) => _MSModalContent(
      title: title,
      primaryAction: primaryAction,
      secondaryAction: secondaryAction,
      child: child,
    ),
    transitionBuilder: (_, anim, _, child) {
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
      // showGeneralDialog 경로엔 Material 조상이 없어 텍스트가 기본(밑줄) 스타일로
      // 새므로, 투명 Material 로 감싸 정상 텍스트 스타일을 제공한다.
      child: Material(
        type: MaterialType.transparency,
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
                  color: context.c.textSub,
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