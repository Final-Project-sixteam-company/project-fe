// lib/components/image_viewer.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'states.dart';

/// 네트워크 이미지를 전체화면 확대 모달로 연다.
/// - 핀치 줌(1~4배), 빈 영역 탭 또는 우상단 X로 닫기.
/// - 로딩/실패 시 graceful 폴백(스피너 / 깨진 이미지 아이콘).
/// 증거 상세·용의자 상세 등 여러 화면에서 공용으로 사용한다.
void showImageViewer(BuildContext context, String url) {
  if (url.isEmpty) return;
  showDialog<void>(
    context: context,
    barrierColor: AppColors.ink950.withValues(alpha: .92),
    builder: (_) => _ImageViewerModal(url: url),
  );
}

class _ImageViewerModal extends StatelessWidget {
  const _ImageViewerModal({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (_, _) => const MSSpinner(size: 28),
                  errorWidget: (_, _, _) => const Icon(
                    Icons.broken_image_outlined,
                    size: 48,
                    color: AppColors.ink0,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.sp3),
                child: IconButton(
                  icon: const Icon(Icons.close, color: AppColors.ink0),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
