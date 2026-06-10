// lib/components/evidence_tile_helpers.dart
// EvidenceTile 내부 소형 위젯 (evidence_tile.dart 에서 분리)
import 'package:flutter/material.dart';
import '../components/asset_image_widget.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

/// 증거 유형 카테고리 소형 뱃지
class EvidenceCategoryBadge extends StatelessWidget {
  const EvidenceCategoryBadge({required this.category, super.key});

  final String category;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.sp1,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: c.bgHover,
        borderRadius: BorderRadius.circular(AppTokens.r1),
      ),
      child: Text(
        category,
        style: AppText.monoLabel.copyWith(
          fontSize: 8.5,
          color: c.textMute,
          height: 1.0,
        ),
      ),
    );
  }
}

/// 증거 아이콘 썸네일 (34×34)
class EvidenceIconThumb extends StatelessWidget {
  const EvidenceIconThumb({
    required this.icon,
    required this.color,
    this.imageUrl,
    super.key,
  });

  final IconData icon;
  final Color color;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return EvidenceThumb(
      icon: icon,
      iconColor: color,
      assetKey: imageUrl,
      size: 34,
    );
  }
}
