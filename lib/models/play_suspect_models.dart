// lib/models/play_suspect_models.dart
// 용의자·현장(장소) 플레이 DTO

class PlaySuspect {
  const PlaySuspect({
    required this.suspectId,
    required this.name,
    required this.interrogationCount,
    this.role,
    this.relationToVictim,
    this.publicStatement,
    this.alibi,
    this.publicAlibi,
    this.personalityTone,
    this.portraitImageUrl,
    this.isWitness = false,
  });

  final int suspectId;
  final String name;
  final int interrogationCount;
  final String? role;
  final String? relationToVictim;
  final String? publicStatement;
  final String? alibi;

  /// 공개 알리바이 — 누구에게나 말하는 알리바이 요약
  final String? publicAlibi;

  /// 성격 톤 레이블 (예: '방어적', '냉정한', '소심한')
  final String? personalityTone;

  /// 공개 프로필 이미지 URL. 없으면 이니셜 아바타로 폴백한다.
  final String? portraitImageUrl;

  final bool isWitness;

  factory PlaySuspect.fromJson(Map<String, dynamic> j) {
    final isWitness =
        j['isWitness'] as bool? ??
        (j['characterType'] as String?) == 'NEUTRAL_WITNESS';
    final portrait = (j['portraitImageUrl'] as String?)?.trim();
    return PlaySuspect(
      suspectId: (j['suspectId'] as num).toInt(),
      name: j['name'] as String? ?? '',
      interrogationCount: (j['interrogationCount'] as num?)?.toInt() ?? 0,
      role: j['role'] as String?,
      relationToVictim: j['relationToVictim'] as String?,
      publicStatement: j['publicStatement'] as String?,
      alibi: j['alibi'] as String?,
      publicAlibi: j['publicAlibi'] as String?,
      personalityTone: j['personalityTone'] as String?,
      portraitImageUrl: portrait?.isNotEmpty == true ? portrait : null,
      isWitness: isWitness,
    );
  }
}

// ── 현장(장소) ───────────────────────────────────────────────────────────────

class PlayLocations {
  const PlayLocations({this.mapImageUrl, this.locations = const []});

  final String? mapImageUrl;
  final List<PlayLocation> locations;

  factory PlayLocations.fromJson(Map<String, dynamic> j) => PlayLocations(
    mapImageUrl: j['mapImageUrl'] as String?,
    locations: ((j['locations'] as List<dynamic>?) ?? const [])
        .map((e) => PlayLocation.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class PlayLocation {
  const PlayLocation({
    required this.locationId,
    required this.name,
    required this.totalEvidenceCount,
    required this.unlockedEvidenceCount,
    this.floor,
    this.description,
    this.imageUrl,
    this.mapX,
    this.mapY,
  });

  final int locationId;
  final String name;
  final int totalEvidenceCount;
  final int unlockedEvidenceCount;
  final String? floor;
  final String? description;
  final String? imageUrl;
  final double? mapX;
  final double? mapY;

  factory PlayLocation.fromJson(Map<String, dynamic> j) => PlayLocation(
    locationId: (j['locationId'] as num).toInt(),
    name: j['name'] as String? ?? '',
    totalEvidenceCount: (j['totalEvidenceCount'] as num?)?.toInt() ?? 0,
    unlockedEvidenceCount: (j['unlockedEvidenceCount'] as num?)?.toInt() ?? 0,
    floor: j['floor']?.toString(),
    description: j['description'] as String?,
    imageUrl: j['imageUrl'] as String?,
    mapX: (j['mapX'] as num?)?.toDouble(),
    mapY: (j['mapY'] as num?)?.toDouble(),
  );
}
