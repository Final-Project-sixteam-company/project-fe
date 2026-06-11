// lib/components/image_viewer_modal.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

/// 전체화면 이미지 뷰어 모달.
///
/// 사용 예시:
/// ```dart
/// ImageViewerModal.show(
///   context,
///   imageUrl: 'https://example.com/evidence.jpg',
///   label: '찢긴 컵 라벨',
/// );
/// ```
class ImageViewerModal extends StatelessWidget {
  const ImageViewerModal({
    required this.imageUrl,
    this.label,
    super.key,
  });

  final String  imageUrl;
  final String? label;

  /// 모달을 띄우는 헬퍼.
  static Future<void> show(
    BuildContext context, {
    required String imageUrl,
    String? label,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: AppColors.darkScrim,
      builder: (_) => ImageViewerModal(imageUrl: imageUrl, label: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Dialog(
      backgroundColor: AppColors.transparent,
      insetPadding: const EdgeInsets.all(AppTokens.sp4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 닫기 버튼 ──────────────────────────────────────────────────
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: Icon(Icons.close, color: c.text),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          // ── 이미지 ────────────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.r6),
            child: _NetworkImage(url: imageUrl),
          ),
          // ── 라벨 ──────────────────────────────────────────────────────
          if (label != null) ...[
            const SizedBox(height: AppTokens.sp3),
            Text(
              label!,
              style: AppText.monoLabel.copyWith(color: c.textSub),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// ── 네트워크 이미지 (CachedNetworkImage 대체) ─────────────────────────────────
// 규칙 8: google_fonts / flutter/material 외 추가 금지.
// cached_network_image 패키지를 사용하지 않고 Image.network로 대체한다.

class _NetworkImage extends StatelessWidget {
  const _NetworkImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (!url.startsWith('http')) {
      return Image.asset(
        url,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _Placeholder(color: c.bgElev),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.contain,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return _Placeholder(color: c.bgElev, loading: true);
      },
      errorBuilder: (context, error, stackTrace) => _Placeholder(color: c.bgElev),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.color, this.loading = false});

  final Color color;
  final bool  loading;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: double.infinity,
      height: AppTokens.sp16 * 3,
      color: color,
      alignment: Alignment.center,
      child: loading
          ? CircularProgressIndicator(
              strokeWidth: AppTokens.sp1,
              color: c.primary,
            )
          : Icon(
              Icons.broken_image_outlined,
              size: AppTokens.sp12,
              color: c.textMute,
            ),
    );
  }
}
