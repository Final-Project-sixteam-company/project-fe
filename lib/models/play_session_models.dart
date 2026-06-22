// lib/models/play_session_models.dart
// 세션 생성, 대시보드, Briefing DTO
// (play_models.dart 에서 분리)

enum PlaySessionStatus { playing, submitted, completed, abandoned }

PlaySessionStatus playSessionStatusFromApi(String? v) => switch (v) {
      'SUBMITTED' => PlaySessionStatus.submitted,
      'COMPLETED' => PlaySessionStatus.completed,
      'ABANDONED' => PlaySessionStatus.abandoned,
      _ => PlaySessionStatus.playing,
    };

class PlaySessionInfo {
  const PlaySessionInfo({
    required this.sessionId,
    required this.scenarioId,
    required this.status,
    this.startedAt,
  });

  final int sessionId;
  final int scenarioId;
  final PlaySessionStatus status;
  final DateTime? startedAt;

  factory PlaySessionInfo.fromJson(Map<String, dynamic> j) => PlaySessionInfo(
        sessionId: (j['sessionId'] as num).toInt(),
        scenarioId: (j['scenarioId'] as num).toInt(),
        status: playSessionStatusFromApi(j['status'] as String?),
        startedAt: _parse(j['startedAt']),
      );
}

class DashboardInfo {
  const DashboardInfo({
    required this.sessionId,
    required this.scenarioId,
    required this.scenarioTitle,
    required this.status,
    required this.elapsedSeconds,
    required this.unlockedEvidenceCount,
    required this.totalEvidenceCount,
    required this.hintUsedCount,
    required this.interrogationCount,
    required this.briefing,
  });

  final int sessionId;
  final int scenarioId;
  final String scenarioTitle;
  final PlaySessionStatus status;
  final int elapsedSeconds;
  final int unlockedEvidenceCount;
  final int totalEvidenceCount;
  final int hintUsedCount;
  final int interrogationCount;
  final Briefing briefing;

  factory DashboardInfo.fromJson(Map<String, dynamic> j) => DashboardInfo(
        sessionId: (j['sessionId'] as num).toInt(),
        scenarioId: (j['scenarioId'] as num).toInt(),
        scenarioTitle: j['scenarioTitle'] as String? ?? '',
        status: playSessionStatusFromApi(j['status'] as String?),
        elapsedSeconds: (j['elapsedSeconds'] as num?)?.toInt() ?? 0,
        unlockedEvidenceCount:
            (j['unlockedEvidenceCount'] as num?)?.toInt() ?? 0,
        totalEvidenceCount: (j['totalEvidenceCount'] as num?)?.toInt() ?? 0,
        hintUsedCount: (j['hintUsedCount'] as num?)?.toInt() ?? 0,
        interrogationCount: (j['interrogationCount'] as num?)?.toInt() ?? 0,
        briefing: Briefing.fromJson(
            (j['briefing'] as Map<String, dynamic>?) ?? const {}),
      );
}

class Briefing {
  const Briefing({
    required this.victimName,
    required this.foundLocation,
    required this.summary,
  });

  final String victimName;
  final String foundLocation;
  final String summary;

  factory Briefing.fromJson(Map<String, dynamic> j) => Briefing(
        victimName: j['victimName'] as String? ?? '알 수 없음',
        foundLocation: j['foundLocation'] as String? ?? '알 수 없음',
        summary: j['summary'] as String? ?? '',
      );
}

class ActivePlaySession {
  const ActivePlaySession({
    required this.hasActiveSession,
    this.activeSessionId,
    required this.scenarioId,
    this.status,
    this.startedAt,
  });

  final bool hasActiveSession;
  final int? activeSessionId;
  final int scenarioId;
  final PlaySessionStatus? status;
  final DateTime? startedAt;

  factory ActivePlaySession.fromJson(Map<String, dynamic> j) =>
      ActivePlaySession(
        hasActiveSession: j['hasActiveSession'] == true,
        activeSessionId: (j['activeSessionId'] as num?)?.toInt(),
        scenarioId: (j['scenarioId'] as num).toInt(),
        status: playSessionStatusFromApi(j['status'] as String?),
        startedAt: _parse(j['startedAt']),
      );
}

DateTime? _parse(dynamic v) {
  if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
  return null;
}
