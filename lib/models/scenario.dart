// lib/models/scenario.dart
enum ScenarioType { official, custom }

enum Difficulty { easy, medium, hard }

enum PlayState { inProgress, completed, abandoned }

enum ScenarioGenre { murder, theft, arson, espionage, fraud }

extension ScenarioGenreLabel on ScenarioGenre {
  String get label => switch (this) {
    ScenarioGenre.murder => '살인',
    ScenarioGenre.theft => '절도',
    ScenarioGenre.arson => '방화',
    ScenarioGenre.espionage => '스파이',
    ScenarioGenre.fraud => '사기',
  };
}

class Scenario {
  final String id;
  final String code;
  final String title;
  final String subtitle;
  final ScenarioType type;
  final Difficulty difficulty;
  final int estimatedMinutes;
  final int suspectsCount;
  final int evidenceCount;
  final double rating;
  final int plays;
  final List<String> tags;
  final String synopsis;
  final String? author;
  final String? thumbnailUrl;
  final String? coverAssetKey;
  final String? mapAssetKey;
  final ScenarioGenre? genre;
  /// API Spec §6.1, §6.2 — 서버가 내려주는 플레이 가능 여부.
  /// false 이면 플레이 버튼 비활성. 클라이언트 하드코딩 ID 목록으로 판단하지 않는다.
  final bool canPlay;

  const Scenario({
    required this.id,
    required this.code,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.difficulty,
    required this.estimatedMinutes,
    required this.suspectsCount,
    required this.evidenceCount,
    required this.rating,
    required this.plays,
    required this.tags,
    required this.synopsis,
    this.author,
    this.thumbnailUrl,
    this.coverAssetKey,
    this.mapAssetKey,
    this.genre,
    this.canPlay = false,
  });

  String get difficultyLabel => switch (difficulty) {
    Difficulty.easy => '쉬움',
    Difficulty.medium => '보통',
    Difficulty.hard => '어려움',
  };
}

class PlaySession {
  final String id;
  final String scenarioId;
  final String scenarioTitle;
  final String scenarioCode;
  final PlayState state;
  final int progressPercent;
  final String? grade;
  final int? score;
  final DateTime startedAt;
  final DateTime? completedAt;

  const PlaySession({
    required this.id,
    required this.scenarioId,
    required this.scenarioTitle,
    required this.scenarioCode,
    required this.state,
    required this.progressPercent,
    required this.startedAt,
    this.grade,
    this.score,
    this.completedAt,
  });
}