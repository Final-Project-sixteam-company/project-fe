// lib/components/asset_image_widget.dart
//
// 역할: assetKey(URL 또는 로컬 경로)로 이미지를 표시하는 범용 위젯.
//   - 이미지가 없거나 null이면 폴백(initialLabel / icon)을 표시한다.
//   - 로딩 중에는 shimmer 스켈레톤을 보여준다.
//   - 에러 시에도 폴백으로 전환한다.
//
// [사용처]
//   CharacterPortrait  — 용의자·피해자 프로필 사진
//   EvidenceThumb      — 증거 카드 썸네일
//   ScenarioCoverImage — 시나리오 커버
//   SceneMapImage      — 맵 이미지

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

// ── 공통 이미지 위젯 ──────────────────────────────────────────────────────────

class AssetImageWidget extends StatelessWidget {
  const AssetImageWidget({
    required this.assetKey,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallback,
    super.key,
  });

  /// S3/CDN URL 또는 로컬 assets/ 경로. null이면 폴백 표시.
  final String? assetKey;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  /// assetKey가 null이거나 로드 실패 시 보여줄 위젯.
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final key = assetKey;
    Widget child;

    if (key == null || key.isEmpty) {
      child = fallback ?? _DefaultFallback(width: width, height: height);
    } else if (key.startsWith('http')) {
      child = Image.network(
        key,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return _Shimmer(width: width, height: height);
        },
        errorBuilder: (context, error, stackTrace) =>
        fallback ?? _DefaultFallback(width: width, height: height),
      );
    } else {
      // 로컬 assets 경로
      child = Image.asset(
        key,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
        fallback ?? _DefaultFallback(width: width, height: height),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }
}

// ── Shimmer 스켈레톤 ─────────────────────────────────────────────────────────

class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.width, required this.height});
  final double width;
  final double height;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [c.bgElev, c.bgHover, c.bgElev],
            stops: [
              (_anim.value - 0.4).clamp(0.0, 1.0),
              _anim.value.clamp(0.0, 1.0),
              (_anim.value + 0.4).clamp(0.0, 1.0),
            ],
          ),
        ),
      ),
    );
  }
}

class _DefaultFallback extends StatelessWidget {
  const _DefaultFallback({required this.width, required this.height});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: width,
      height: height,
      color: c.bgElev,
      alignment: Alignment.center,
      child: Icon(Icons.image_not_supported_outlined,
          size: 20, color: c.textMute),
    );
  }
}

// ── CharacterPortrait ─────────────────────────────────────────────────────────
// 용의자·피해자 프로필 사진. 이미지 없으면 이니셜 아바타로 폴백.

class CharacterPortrait extends StatelessWidget {
  const CharacterPortrait({
    required this.name,
    required this.size,
    this.assetKey,
    this.borderRadius,
    this.isWitness = false,
    super.key,
  });

  final String name;
  final double size;
  final String? assetKey;
  final double? borderRadius;
  final bool isWitness;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppTokens.r4;
    final initial = name.isNotEmpty ? name.characters.first : '?';

    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isWitness
              ? [AppColors.ink600, AppColors.ink500]
              : [AppColors.tealBase, AppColors.skyBase],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.ink0.withValues(alpha: .14)),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: AppText.titleM.copyWith(
          fontSize: size * 0.38,
          color: AppColors.ink950,
          height: 1.0,
        ),
      ),
    );

    if (assetKey == null || assetKey!.isEmpty) return fallback;

    return AssetImageWidget(
      assetKey: assetKey,
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(radius),
      fallback: fallback,
    );
  }
}

// ── EvidenceThumb ─────────────────────────────────────────────────────────────
// 증거 카드 내 썸네일. 이미지 있으면 사진, 없으면 아이콘 박스.

class EvidenceThumb extends StatelessWidget {
  const EvidenceThumb({
    required this.icon,
    required this.iconColor,
    this.assetKey,
    this.size = 34,
    super.key,
  });

  final IconData icon;
  final Color iconColor;
  final String? assetKey;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (assetKey != null && assetKey!.isNotEmpty) {
      return AssetImageWidget(
        assetKey: assetKey,
        width: size,
        height: size,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(AppTokens.r2),
        fallback: _IconBox(icon: icon, color: iconColor, size: size),
      );
    }

    return _IconBox(icon: icon, color: iconColor, size: size);
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({
    required this.icon,
    required this.color,
    required this.size,
  });
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.bgHover,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppTokens.r2),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: size * 0.5, color: color),
    );
  }
}

// ── ScenarioCoverImage ────────────────────────────────────────────────────────
// 시나리오 커버 이미지. 없으면 그라디언트 배경 + 시나리오 코드.

class ScenarioCoverImage extends StatelessWidget {
  const ScenarioCoverImage({
    required this.scenarioCode,
    required this.aspectRatio,
    this.assetKey,
    super.key,
  });

  final String scenarioCode;
  final double aspectRatio;
  final String? assetKey;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    final gradient = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.ink900, AppColors.tealBase],
          stops: [0.3, 1.0],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        scenarioCode,
        style: AppText.monoNum.copyWith(
          fontSize: 36,
          color: c.primary.withValues(alpha: .3),
          height: 1.0,
        ),
      ),
    );

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: assetKey != null && assetKey!.isNotEmpty
          ? AssetImageWidget(
        assetKey: assetKey,
        width: double.infinity,
        height: double.infinity,
        fallback: gradient,
      )
          : gradient,
    );
  }
}

// ── 사용 예시 ─────────────────────────────────────────────────────────────────

class AssetImageWidgetExample extends StatelessWidget {
  const AssetImageWidgetExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTokens.sp4),
      child: Wrap(
        spacing: AppTokens.sp3,
        runSpacing: AppTokens.sp3,
        children: const [
          CharacterPortrait(name: '박재민', size: 60),
          CharacterPortrait(name: '윤서하', size: 60, isWitness: false),
          CharacterPortrait(name: '문하연', size: 60, isWitness: true),
          EvidenceThumb(
            icon: Icons.local_cafe_outlined,
            iconColor: Colors.blue,
          ),
        ],
      ),
    );
  }
}