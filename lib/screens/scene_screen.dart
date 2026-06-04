import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../components/game_modals.dart';
import '../components/ms_kicker.dart';
import '../components/ms_pill.dart';
import '../components/states.dart';
import '../controllers/game_session_provider.dart';
import '../models/play_models.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

// ── 화면 ──────────────────────────────────────────────────────────────────────

class SceneScreen extends StatefulWidget {
  const SceneScreen({super.key});

  @override
  State<SceneScreen> createState() => _SceneScreenState();
}

class _SceneScreenState extends State<SceneScreen> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    // 컨트롤러 변경(현장 로딩 완료 등)에 반응해 리빌드한다.
    final session = context.session;
    final locations = session.locations;
    final items = locations?.locations ?? const <PlayLocation>[];

    return Scaffold(
      backgroundColor: c.bg,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.sp4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppTokens.sp4),
            // ── 1. 현장 맵 ────────────────────────────────────────
            // 경과 시간/해금 증거 수는 상단 HUD(CaseScreen)가 라이브로
            // 표시하므로 여기서 중복 통계 헤더를 두지 않는다.
            _SceneMap(mapImageUrl: locations?.mapImageUrl),
            const SizedBox(height: AppTokens.sp6),
            // ── 2. 주요 현장 정보 ─────────────────────────────────
            if (items.isNotEmpty) ...[
              const MSKicker('주요 현장 정보'),
              const SizedBox(height: AppTokens.sp3),
              _LocationList(
                locations: items,
                selectedIndex: _selectedIndex,
                onTap: (i) => setState(
                  () => _selectedIndex = _selectedIndex == i ? null : i,
                ),
              ),
            ] else if (session.isLoading) ...[
              const Padding(
                padding: EdgeInsets.only(top: AppTokens.sp6),
                child: MSListSkeleton(itemCount: 4),
              ),
            ] else ...[
              const Padding(
                padding: EdgeInsets.only(top: AppTokens.sp8),
                child: MSEmpty(
                  icon: Icons.map_outlined,
                  title: '현장 정보 없음',
                  subtitle: '이 시나리오에는 표시할 현장 정보가 없습니다.',
                ),
              ),
            ],
            const SizedBox(height: AppTokens.sp10),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final c = context.c;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      titleSpacing: AppTokens.sp4,
      automaticallyImplyLeading: false,
      title: Text(
        'CRIME SCENE',
        style: AppText.monoLabel.copyWith(color: c.textMute),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppTokens.sp2),
          child: IconButton(
            // 48dp 최소 탭 타깃 유지(기본 IconButton 제약 사용).
            tooltip: '힌트 보기',
            onPressed: () {
              // 힌트는 서버 세션 기반. 세션 미생성 시 안내.
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
        ),
      ],
    );
  }
}

// ── 현장 맵 ───────────────────────────────────────────────────────────────────

class _SceneMap extends StatelessWidget {
  const _SceneMap({this.mapImageUrl});

  /// 현장 지도 이미지 URL. null이면 플레이스홀더를 표시한다(S3 키 조합 금지).
  final String? mapImageUrl;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final url = mapImageUrl;

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        decoration: BoxDecoration(
          color: c.bgElev,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(AppTokens.r4),
        ),
        clipBehavior: Clip.hardEdge,
        child: (url != null && url.isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, _) => _mapPlaceholder(context),
                errorWidget: (_, _, _) => _mapPlaceholder(context),
              )
            : _mapPlaceholder(context),
      ),
    );
  }

  Widget _mapPlaceholder(BuildContext context) {
    final c = context.c;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.map_outlined, size: 48, color: c.textMute),
          const SizedBox(height: AppTokens.sp3),
          Text(
            '현장 지도',
            style: AppText.bodySm.copyWith(color: c.textMute),
          ),
        ],
      ),
    );
  }
}

// ── 장소 리스트 ───────────────────────────────────────────────────────────────

class _LocationList extends StatelessWidget {
  const _LocationList({
    required this.locations,
    required this.selectedIndex,
    required this.onTap,
  });

  final List<PlayLocation> locations;
  final int? selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < locations.length; i++) ...[
          _LocationCard(
            location: locations[i],
            selected: selectedIndex == i,
            onTap: () => onTap(i),
          ),
          if (i < locations.length - 1) const SizedBox(height: AppTokens.sp2),
        ],
      ],
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.location,
    required this.selected,
    required this.onTap,
  });

  final PlayLocation location;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final floor = location.floor;

    return AnimatedContainer(
      duration: AppMotion.dur2,
      curve: AppMotion.easeOut,
      decoration: BoxDecoration(
        color: selected ? c.primarySoft : c.bg,
        border: Border.all(color: selected ? c.primary : c.line),
        borderRadius: BorderRadius.circular(AppTokens.r3),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTokens.r3),
        child: InkWell(
          onTap: onTap,
          splashColor: c.primary.withValues(alpha: .06),
          highlightColor: c.primary.withValues(alpha: .03),
          borderRadius: BorderRadius.circular(AppTokens.r3),
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.sp3),
            child: Row(
              children: [
                Icon(
                  Icons.place_outlined,
                  size: 18,
                  color: c.primary,
                ),
                const SizedBox(width: AppTokens.sp3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        location.name,
                        style: AppText.body.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: c.text,
                        ),
                      ),
                      if (floor != null && floor.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          floor,
                          style: AppText.bodySm.copyWith(color: c.textMute),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppTokens.sp2),
                MSPill(
                  '해금 ${location.unlockedEvidenceCount}/${location.totalEvidenceCount}',
                  tone: MSPillTone.mute,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
