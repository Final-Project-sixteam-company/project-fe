// lib/components/image_viewer_modal.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

// ── ImageViewerModal ──────────────────────────────────────────────────────────

/// 전체화면 이미지 뷰어 모달.
///
/// ```dart
/// ImageViewerModal.show(context,
///   imageUrl: 'https://example.com/evidence.jpg',
///   label: '찢긴 컵 라벨');
/// ```
class ImageViewerModal extends StatelessWidget {
  const ImageViewerModal({
    required this.imageUrl,
    this.label,
    super.key,
  });

  final String  imageUrl;
  final String? label;

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
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: Icon(Icons.close, color: c.text),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.r6),
            child: _NetImage(url: imageUrl, fit: BoxFit.contain),
          ),
          if (label != null) ...[
            const SizedBox(height: AppTokens.sp3),
            Text(label!,
                style: AppText.monoLabel.copyWith(color: c.textSub),
                textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}

// ── IconThumb ─────────────────────────────────────────────────────────────────

/// 카드/리스트 안에서 쓰는 소형 이미지 썸네일.
/// CachedNetworkImage 대체 — Image.network 사용 (규칙 8).
///
/// ```dart
/// IconThumb(imageUrl: evidence.imageUrl, size: AppTokens.sp12)
/// ```
class IconThumb extends StatelessWidget {
  const IconThumb({
    required this.imageUrl,
    this.size = AppTokens.sp12,
    this.radius = AppTokens.r3,
    super.key,
  });

  final String imageUrl;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size, height: size,
        child: _NetImage(url: imageUrl, fit: BoxFit.cover),
      ),
    );
  }
}

// ── _NetImage — CachedNetworkImage 대체 ──────────────────────────────────────

class _NetImage extends StatelessWidget {
  const _NetImage({required this.url, required this.fit});

  final String  url;
  final BoxFit  fit;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (!url.startsWith('http')) {
      return Image.asset(
        url,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _ImgPlaceholder(bg: c.bgElev),
      );
    }
    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (_, child, prog) {
        if (prog == null) return child;
        return _ImgPlaceholder(bg: c.bgElev, loading: true);
      },
      errorBuilder: (context, error, stackTrace) => _ImgPlaceholder(bg: c.bgElev),
    );
  }
}

class _ImgPlaceholder extends StatelessWidget {
  const _ImgPlaceholder({required this.bg, this.loading = false});

  final Color bg;
  final bool  loading;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ColoredBox(
      color: bg,
      child: Center(
        child: loading
            ? CircularProgressIndicator(strokeWidth: AppTokens.sp1, color: c.primary)
            : Icon(Icons.broken_image_outlined,
            size: AppTokens.sp8, color: c.textMute),
      ),
    );
  }
}