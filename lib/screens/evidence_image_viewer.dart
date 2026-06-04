// lib/screens/evidence_image_viewer.dart
//
// 증거 이미지 풀스크린 뷰어.
// - Hero 애니메이션으로 EvidenceDetailScreen의 썸네일에서 전환.
// - 핀치줌 + 드래그 지원 (InteractiveViewer).
// - 상단 바: 증거명·카테고리 라벨. 하단: 발견 위치.
// - 이미지 없으면 표시하지 않는다(호출 측에서 guard).

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import '../components/asset_image_widget.dart';

class EvidenceImageViewer extends StatefulWidget {
  const EvidenceImageViewer({
    required this.heroTag,
    required this.assetKey,
    required this.title,
    required this.location,
    this.categoryLabel,
    super.key,
  });

  final String heroTag;
  final String assetKey;
  final String title;
  final String location;
  final String? categoryLabel;

  @override
  State<EvidenceImageViewer> createState() => _EvidenceImageViewerState();
}

class _EvidenceImageViewerState extends State<EvidenceImageViewer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  bool _overlayVisible = true;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: AppMotion.dur2);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: AppMotion.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _toggleOverlay() {
    setState(() => _overlayVisible = !_overlayVisible);
    if (_overlayVisible) {
      _fadeCtrl.forward();
    } else {
      _fadeCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Scaffold(
      backgroundColor: AppColors.ink950,
      body: GestureDetector(
        onTap: _toggleOverlay,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── 이미지 (핀치줌) ─────────────────────────────────
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Hero(
                  tag: widget.heroTag,
                  child: AssetImageWidget(
                    assetKey: widget.assetKey,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    fit: BoxFit.contain,
                    fallback: Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: 48,
                        color: c.textMute,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // ── 상단 오버레이 ────────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: !_overlayVisible,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.ink950, Colors.transparent],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.sp4,
                          vertical: AppTokens.sp3,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: AppColors.ink50,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            const SizedBox(width: AppTokens.sp2),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.title,
                                    style: AppText.titleM.copyWith(
                                      color: AppColors.ink50,
                                      fontSize: 15,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (widget.categoryLabel != null)
                                    Text(
                                      widget.categoryLabel!.toUpperCase(),
                                      style: AppText.monoLabel.copyWith(
                                        color: AppColors.skyBase,
                                        height: 1.2,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // ── 하단 오버레이 ─────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: !_overlayVisible,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [AppColors.ink950, Colors.transparent],
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.all(AppTokens.sp4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: AppColors.ink400,
                            ),
                            const SizedBox(width: AppTokens.sp1),
                            Text(
                              widget.location,
                              style: AppText.monoLabel.copyWith(
                                color: AppColors.ink400,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
