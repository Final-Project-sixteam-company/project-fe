// lib/screens/scene_map_dot.dart
import 'package:flutter/material.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

// ── 데이터 모델 ───────────────────────────────────────────────────────────────

class SceneMarker {
  const SceneMarker({
    required this.id,
    required this.label,
    required this.x,
    required this.y,
    this.isUnlocked = true,
  });

  /// 증거 ID (onMarkerTap 콜백에 전달)
  final String id;

  /// 마커 아래 표시할 짧은 라벨
  final String label;

  /// 0.0 ~ 1.0 상대 좌표 (좌측 상단 기준)
  final double x;
  final double y;

  /// false 면 잠금 아이콘으로 표시, 탭 비활성
  final bool isUnlocked;
}

// ── 마커 Dot ──────────────────────────────────────────────────────────────────

class SceneMarkerDot extends StatelessWidget {
  const SceneMarkerDot({
    required this.marker,
    this.onTap,
    super.key,
  });

  final SceneMarker           marker;
  final ValueChanged<String>? onTap;

  @override
  Widget build(BuildContext context) {
    final c      = context.c;
    final color  = marker.isUnlocked ? c.primary   : c.textMute;
    final bgCol  = marker.isUnlocked ? c.primarySoft : c.bgHover;

    return GestureDetector(
      onTap: marker.isUnlocked ? () => onTap?.call(marker.id) : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width:  AppTokens.sp6,
            height: AppTokens.sp6,
            decoration: BoxDecoration(
              color: bgCol,
              border: Border.all(color: color, width: AppTokens.r1),
              borderRadius: BorderRadius.circular(AppTokens.rPill),
            ),
            child: Icon(
              marker.isUnlocked ? Icons.location_on : Icons.lock_outline,
              size:  AppTokens.sp3 + AppTokens.sp1,
              color: color,
            ),
          ),
          const SizedBox(height: AppTokens.sp1),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.chipPadH / 2,
              vertical:   AppTokens.chipPadV / 2,
            ),
            decoration: BoxDecoration(
              color:        c.bgElev,
              borderRadius: BorderRadius.circular(AppTokens.r2),
            ),
            child: Text(
              marker.label,
              style: AppText.monoLabel.copyWith(
                fontSize: AppTokens.fsXs,
                color:    color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
