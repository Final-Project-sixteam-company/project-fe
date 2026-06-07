// lib/screens/scene_screen.dart
import 'package:flutter/material.dart';
import '../components/asset_image_widget.dart';
import '../components/game_modals.dart';
import '../components/ms_kicker.dart';
import '../components/states.dart';
import '../components/ms_pill.dart';
import '../controllers/game_session_provider.dart';
import '../models/play_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

// ── 로컬 데이터 ───────────────────────────────────────────────────────────────

class _Location {
  final String name;
  final IconData icon;
  final int clueCount;
  final bool isIncident;
  final String? imageAssetKey;

  const _Location({
    required this.name,
    required this.icon,
    required this.clueCount,
    this.isIncident = false,
    this.imageAssetKey,
  });
}

const _locations = [
  _Location(
    name: '데모룸 (사건 발생지)',
    icon: Icons.meeting_room_outlined,
    clueCount: 3,
    isIncident: true,
  ),
  _Location(
    name: '재무팀 사무실',
    icon: Icons.business_outlined,
    clueCount: 2,
  ),
  _Location(
    name: '서버실',
    icon: Icons.storage_outlined,
    clueCount: 2,
  ),
  _Location(
    name: '카페',
    icon: Icons.local_cafe_outlined,
    clueCount: 1,
  ),
  _Location(
    name: '비상계단',
    icon: Icons.stairs_outlined,
    clueCount: 1,
  ),
  _Location(
    name: '보안실',
    icon: Icons.security_outlined,
    clueCount: 1,
  ),
];

const _victimPinOffset = Offset(0.58, 0.42);

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
            // mapImageUrl이 있으면 네트워크 지도를, 없으면 평면도 플레이스홀더+
            // 피해자 핀을 렌더링한다.
            _SceneMap(
              mapImageUrl: locations?.mapImageUrl,
              selectedIndex: _selectedIndex,
            ),
            const SizedBox(height: AppTokens.sp6),
            // ── 2. 주요 현장 정보 ─────────────────────────────────
            // 서버 locations 데이터가 있으면 우선 사용하고, 없으면 CL-001
            // 샘플 데이터(usesCl001SampleCaseData)로 폴백한다. 백엔드 locations
            // 엔드포인트 구현 후 항상 서버 데이터로 교체한다.
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
              // ── 3. 선택된 장소 이미지 ──────────────────────────
              if (_selectedIndex != null &&
                  _selectedIndex! < items.length &&
                  items[_selectedIndex!].imageUrl != null) ...[
                const SizedBox(height: AppTokens.sp4),
                _LocationImageCard(
                  imageUrl: items[_selectedIndex!].imageUrl,
                  name: items[_selectedIndex!].name,
                  icon: Icons.place_outlined,
                ),
              ],
            ] else if (context.sessionRead.usesCl001SampleCaseData) ...[
              // CL-001 외 시나리오에서는 하드코딩 장소 목록이 스포일러가 되므로
              // usesCl001SampleCaseData 게이트로 숨긴다.
              const MSKicker('주요 현장 정보'),
              const SizedBox(height: AppTokens.sp3),
              _SampleLocationList(
                selectedIndex: _selectedIndex,
                onTap: (i) => setState(
                  () => _selectedIndex = _selectedIndex == i ? null : i,
                ),
              ),
              // ── 3. 선택된 장소 이미지 ──────────────────────────
              if (_selectedIndex != null &&
                  _selectedIndex! < _locations.length &&
                  _locations[_selectedIndex!].imageAssetKey != null) ...[
                const SizedBox(height: AppTokens.sp4),
                _LocationImageCard(
                  imageUrl: _locations[_selectedIndex!].imageAssetKey,
                  name: _locations[_selectedIndex!].name,
                  icon: _locations[_selectedIndex!].icon,
                ),
              ],
            ] else if (session.isLoading) ...[
              const Padding(
                padding: EdgeInsets.only(top: AppTokens.sp6),
                child: MSListSkeleton(itemCount: 4),
              ),
            ] else ...[
              const MSKicker('현장 정보'),
              const SizedBox(height: AppTokens.sp3),
              const MSEmpty(
                icon: Icons.map_outlined,
                title: '현장 정보 준비 중',
                subtitle: '이 시나리오의 현장 데이터는 곧 제공될 예정입니다.',
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
            tooltip: '힌트 보기',
            onPressed: () {
              final sessionId = context.sessionRead.backendSessionId;
              if (sessionId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('세션이 아직 준비되지 않았습니다.')),
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
// mapAssetKey가 연결되면 실제 이미지를, 아니면 플레이스홀더를 보여준다.

class _SceneMap extends StatelessWidget {
  const _SceneMap({this.mapImageUrl, this.selectedIndex});

  final String? mapImageUrl;
  final int? selectedIndex;

  static const String? _mapAssetKey = null;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final url = mapImageUrl;
    final hasLiveMap = url != null && url.isNotEmpty;
    final showVictimPin =
        context.sessionRead.usesCl001SampleCaseData && !hasLiveMap;

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        decoration: BoxDecoration(
          color: c.bgElev,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(AppTokens.r4),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 💡 CachedNetworkImage를 Image.network로 대체
            if (hasLiveMap)
              Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox.expand(
                    child: MSSkeleton(radius: AppTokens.r4),
                  );
                },
                errorBuilder: (_, __, ___) => _MapPlaceholder(),
              )
            else if (_mapAssetKey != null)
              AssetImageWidget(
                assetKey: _mapAssetKey,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                fallback: _MapPlaceholder(),
              )
            else
              _MapPlaceholder(),

            // 피해자 위치 핀 오버레이
            if (showVictimPin)
              LayoutBuilder(
                builder: (_, constraints) {
                  final dx = constraints.maxWidth * _victimPinOffset.dx;
                  final dy = constraints.maxHeight * _victimPinOffset.dy;
                  return Stack(
                    children: [
                      Positioned(
                        left: dx - 12,
                        top: dy - 28,
                        child: _VictimPin(),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.map_outlined, size: 48, color: c.textMute),
          const SizedBox(height: AppTokens.sp3),
          Text(
            '건물 평면도 영역',
            style: AppText.bodySm.copyWith(color: c.textMute),
          ),
        ],
      ),
    );
  }
}

class _VictimPin extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: c.danger,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.ink0, width: 2),
            boxShadow: [
              BoxShadow(
                color: c.danger.withValues(alpha: .4),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(Icons.person, size: 12, color: AppColors.ink0),
        ),
        CustomPaint(
          size: const Size(8, 6),
          painter: _PinTailPainter(color: context.c.danger),
        ),
      ],
    );
  }
}

class _PinTailPainter extends CustomPainter {
  const _PinTailPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PinTailPainter old) => old.color != color;
}

// ── 장소 이미지 카드 ──────────────────────────────────────────────────────────

class _LocationImageCard extends StatelessWidget {
  const _LocationImageCard({
    required this.imageUrl,
    required this.name,
    required this.icon,
  });

  /// 이미지 URL 또는 로컬 assetKey. AssetImageWidget이 양쪽을 모두 처리한다.
  final String? imageUrl;
  final String name;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.r4),
      child: Stack(
        children: [
          AssetImageWidget(
            assetKey: imageUrl,
            width: double.infinity,
            height: 160,
            fit: BoxFit.cover,
            fallback: Container(
              height: 160,
              color: c.bgElev,
              alignment: Alignment.center,
              child: Icon(icon, size: 32, color: c.textMute),
            ),
          ),
          // 장소명 오버레이
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(AppTokens.sp3),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [AppColors.ink950, Colors.transparent],
                ),
              ),
              child: Text(
                name,
                style: AppText.bodySm.copyWith(
                  color: AppColors.ink50,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
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

// ── 샘플 장소 리스트 (CL-001 하드코딩) ────────────────────────────────────────
// 백엔드 locations 엔드포인트 미구현 시나리오에서 사용한다.

class _SampleLocationList extends StatelessWidget {
  const _SampleLocationList({
    required this.selectedIndex,
    required this.onTap,
  });

  final int? selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < _locations.length; i++) ...[
          _SampleLocationCard(
            location: _locations[i],
            selected: selectedIndex == i,
            onTap: () => onTap(i),
          ),
          if (i < _locations.length - 1) const SizedBox(height: AppTokens.sp2),
        ],
      ],
    );
  }
}

class _SampleLocationCard extends StatelessWidget {
  const _SampleLocationCard({
    required this.location,
    required this.selected,
    required this.onTap,
  });

  final _Location location;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final bool hasImage = location.imageAssetKey != null;

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
                  location.icon,
                  size: 18,
                  color: location.isIncident ? c.danger : c.primary,
                ),
                const SizedBox(width: AppTokens.sp3),
                Expanded(
                  child: Text(
                    location.name,
                    style: AppText.body.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: c.text,
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.sp2),
                MSPill(
                  '단서 ${location.clueCount}',
                  tone: location.isIncident ? MSPillTone.danger : MSPillTone.mute,
                ),
                // 이미지 있음 표시
                if (hasImage) ...[
                  const SizedBox(width: AppTokens.sp2),
                  Icon(
                    Icons.photo_outlined,
                    size: 14,
                    color: c.textMute,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
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
    final bool hasImage = location.imageUrl != null;

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
                // 이미지 있음 표시
                if (hasImage) ...[
                  const SizedBox(width: AppTokens.sp2),
                  Icon(
                    Icons.photo_outlined,
                    size: 14,
                    color: c.textMute,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
