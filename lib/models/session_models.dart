// lib/models/session_models.dart

enum HintLevel { direction, connection, decisive }

extension HintLevelX on HintLevel {
  String get label => switch (this) {
    HintLevel.direction => '방향 힌트',
    HintLevel.connection => '증거 연결 힌트',
    HintLevel.decisive => '결정적 힌트',
  };

  int get penalty => switch (this) {
    HintLevel.direction => 5,
    HintLevel.connection => 10,
    HintLevel.decisive => 20,
  };

  String get penaltyLabel => '-${penalty}점';
}

class HintRecord {
  const HintRecord({
    required this.level,
    required this.usedAt,
  });

  final HintLevel level;
  final Duration usedAt;

  int get penalty => level.penalty;
}

class InterrogationLog {
  const InterrogationLog({
    required this.suspectId,
    required this.suspectName,
    required this.question,
    required this.answer,
    required this.askedAt,
    this.presentedEvidenceId,
  });

  final String suspectId;
  final String suspectName;
  final String question;
  final String answer;
  final Duration askedAt;
  final String? presentedEvidenceId;
}