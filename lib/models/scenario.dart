enum ScenarioType { official, custom }

enum Difficulty { easy, medium, hard }

enum PlayState { inProgress, completed, abandoned }

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