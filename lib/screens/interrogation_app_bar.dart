// lib/screens/interrogation_app_bar.dart
import 'package:flutter/material.dart';
import '../components/game_modals.dart';
import '../controllers/game_session_provider.dart';
import '../models/case.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

class InterrogationAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const InterrogationAppBar({
    required this.suspect,
    required this.onPresentEvidence,
    required this.disabled,
    super.key,
  });

  final Suspect suspect;
  final VoidCallback? onPresentEvidence;
  final bool disabled;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.transparent,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: c.text),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            suspect.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.titleM.copyWith(color: c.text),
          ),
          Text(
            suspect.role,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.bodySm.copyWith(color: c.textSub),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: '힌트 보기',
          onPressed: () {
            final sessionId = context.sessionRead.backendSessionId;
            if (sessionId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('세션이 아직 준비되지 않았습니다. 잠시 후 다시 시도해 주세요.'),
                ),
              );
              return;
            }
            showHintModal(context, sessionId: sessionId);
          },
          icon: Icon(Icons.lightbulb_outline, color: c.primary),
        ),
        Padding(
          padding: const EdgeInsets.only(right: AppTokens.sp2),
          child: IconButton(
            tooltip: '증거 제시',
            onPressed: disabled ? null : onPresentEvidence,
            icon: Icon(Icons.description_outlined, color: c.primary),
          ),
        ),
      ],
    );
  }
}
