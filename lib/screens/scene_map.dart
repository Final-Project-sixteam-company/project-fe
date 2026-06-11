// lib/screens/scene_map.dart
import 'package:flutter/material.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import 'scene_map_dot.dart';

export 'scene_map_dot.dart' show SceneMarker;

// ── SceneMap ──────────────────────────────────────────────────────────────────

/// 현장 단면도 이미지 위에 증거 마커를 오버레이하는 위젯.
///
/// ```dart
/// SceneMap(
///   imageUrl: 'https://example.com/scene.jpg',
///   markers: [
///     const SceneMarker(id: 'e1', label: '컵 라벨', x: 0.42, y: 0.61),
///     const SceneMarker(id: 'e2', label: '에피펜',  x: 0.75, y: 0.38,
///                       isUnlocked: false),
///   ],
///   onMarkerTap: (id) => _handleTap(id),
/// )
/// ```
class SceneMap extends StatelessWidget {
  const SceneMap({
    required this.markers,
    this.imageUrl,
    this.onMarkerTap,
    super.key,
  });

  final String?              imageUrl;
  final List<SceneMarker>    markers;
  final ValueChanged<String>? onMarkerTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: LayoutBuilder(
        builder: (_, box) => Stack(
          fit: StackFit.expand,
          children: [
            SceneMapBackground(imageUrl: imageUrl),
            ...markers.map((m) => Positioned(
              left: m.x * box.maxWidth  - AppTokens.sp3,
              top:  m.y * box.maxHeight - AppTokens.sp3,
              child: SceneMarkerDot(marker: m, onTap: onMarkerTap),
            )),
          ],
        ),
      ),
    );
  }
}

// ── 배경 이미지 ───────────────────────────────────────────────────────────────
// cached_network_image 금지(규칙 8) → Image.network + loadingBuilder 사용.

class SceneMapBackground extends StatelessWidget {
  const SceneMapBackground({this.imageUrl, super.key});
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final c   = context.c;
    final url = imageUrl;
    if (url == null || url.isEmpty) return SceneMapFallback(c: c);
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, prog) =>
      prog == null ? child : SceneMapFallback(c: c, loading: true),
      errorBuilder: (context, error, stackTrace) => SceneMapFallback(c: c),
    );
  }
}

class SceneMapFallback extends StatelessWidget {
  const SceneMapFallback({required this.c, this.loading = false, super.key});
  final AppColorScheme c;
  final bool           loading;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: c.bgElev,
      child: Center(
        child: loading
            ? CircularProgressIndicator(
            strokeWidth: AppTokens.sp1, color: c.primary)
            : Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.map_outlined,
              size: AppTokens.sp12, color: c.textMute),
          const SizedBox(height: AppTokens.sp2),
          Text('현장 지도 없음',
              style: AppText.monoLabel.copyWith(color: c.textMute)),
        ]),
      ),
    );
  }
}