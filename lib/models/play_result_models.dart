// lib/models/play_result_models.dart
// 최종 추리 제출·결과 DTO (play_models.dart 에서 분리)

// ── 최종 추리 제출 응답 ──────────────────────────────────────────────────────

class FinalDeductionResult {
  const FinalDeductionResult({
    required this.finalDeductionId,
    required this.score,
    required this.grade,
    required this.feedbackSummary,
    required this.resultAvailable,
    this.submittedAt,
  });

  final int finalDeductionId;
  final int score;
  final String grade;
  final String feedbackSummary;
  final bool resultAvailable;
  final DateTime? submittedAt;

  factory FinalDeductionResult.fromJson(Map<String, dynamic> j) =>
      FinalDeductionResult(
        finalDeductionId: (j['finalDeductionId'] as num).toInt(),
        score: (j['score'] as num?)?.toInt() ?? 0,
        grade: j['grade'] as String? ?? '-',
        feedbackSummary: j['feedbackSummary'] as String? ?? '',
        resultAvailable: j['resultAvailable'] as bool? ?? false,
        submittedAt: _parse(j['submittedAt']),
      );
}

// ── 결과/해설 조회 ────────────────────────────────────────────────────────────

class DeductionResult {
  const DeductionResult({
    required this.sessionId,
    required this.score,
    required this.grade,
    required this.matched,
    this.correctCulprit,
    this.matchedParts = const [],
    this.missedParts = const [],
    this.feedback = '',
    this.fullExplanation = '',
    this.keyEvidences = const [],
    this.nextRecommendedScenarios = const [],
  });

  final int sessionId;
  final int score;
  final String grade;
  final MatchedParts matched;
  final CorrectCulprit? correctCulprit;
  final List<String> matchedParts;
  final List<String> missedParts;
  final String feedback;
  final String fullExplanation;
  final List<KeyEvidence> keyEvidences;
  final List<RecommendedScenario> nextRecommendedScenarios;

  factory DeductionResult.fromJson(Map<String, dynamic> j) => DeductionResult(
        sessionId: (j['sessionId'] as num).toInt(),
        score: (j['score'] as num?)?.toInt() ?? 0,
        grade: j['grade'] as String? ?? '-',
        matched: MatchedParts.fromJson(
            (j['matched'] as Map<String, dynamic>?) ?? const {}),
        correctCulprit: j['correctCulprit'] == null
            ? null
            : CorrectCulprit.fromJson(
                j['correctCulprit'] as Map<String, dynamic>),
        matchedParts:
            ((j['matchedParts'] as List<dynamic>?) ?? const []).cast<String>(),
        missedParts:
            ((j['missedParts'] as List<dynamic>?) ?? const []).cast<String>(),
        feedback: j['feedback'] as String? ?? '',
        fullExplanation: j['fullExplanation'] as String? ?? '',
        keyEvidences: ((j['keyEvidences'] as List<dynamic>?) ?? const [])
            .map((e) => KeyEvidence.fromJson(e as Map<String, dynamic>))
            .toList(),
        nextRecommendedScenarios: ((j['nextRecommendedScenarios']
                    as List<dynamic>?) ??
                const [])
            .map((e) =>
                RecommendedScenario.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class MatchedParts {
  const MatchedParts({
    required this.culprit,
    required this.motive,
    required this.method,
    required this.coverUp,
    required this.keyEvidences,
  });

  final bool culprit;
  final bool motive;
  final bool method;
  final bool coverUp;
  final int keyEvidences;

  factory MatchedParts.fromJson(Map<String, dynamic> j) => MatchedParts(
        culprit: j['culprit'] as bool? ?? false,
        motive: j['motive'] as bool? ?? false,
        method: j['method'] as bool? ?? false,
        coverUp: j['coverUp'] as bool? ?? false,
        keyEvidences: (j['keyEvidences'] as num?)?.toInt() ?? 0,
      );
}

class CorrectCulprit {
  const CorrectCulprit(
      {required this.suspectId, required this.name, this.role});

  final int suspectId;
  final String name;
  final String? role;

  factory CorrectCulprit.fromJson(Map<String, dynamic> j) => CorrectCulprit(
        suspectId: (j['suspectId'] as num).toInt(),
        name: j['name'] as String? ?? '',
        role: j['role'] as String?,
      );
}

class KeyEvidence {
  const KeyEvidence({required this.evidenceId, required this.title});

  final int evidenceId;
  final String title;

  factory KeyEvidence.fromJson(Map<String, dynamic> j) => KeyEvidence(
        evidenceId: (j['evidenceId'] as num).toInt(),
        title: j['title'] as String? ?? '',
      );
}

class RecommendedScenario {
  const RecommendedScenario({required this.scenarioId, required this.title});

  final int scenarioId;
  final String title;

  factory RecommendedScenario.fromJson(Map<String, dynamic> j) =>
      RecommendedScenario(
        scenarioId: (j['scenarioId'] as num).toInt(),
        title: j['title'] as String? ?? '',
      );
}

DateTime? _parse(dynamic v) {
  if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
  return null;
}
