// lib/models/play_interrogation_models.dart
// 힌트·심문 DTO (play_suspect_models.dart 에서 분리)

import 'play_evidence_models.dart';

// ── 힌트 ─────────────────────────────────────────────────────────────────────

class PlayHint {
  const PlayHint({
    required this.hintId,
    required this.hintLevel,
    required this.isAvailable,
    required this.isUsed,
    required this.penaltyScore,
    this.content,
    this.remainingMinutes,
  });

  final int hintId;
  final int hintLevel;
  final bool isAvailable;
  final bool isUsed;
  final int penaltyScore;
  final String? content;
  final int? remainingMinutes;

  factory PlayHint.fromJson(Map<String, dynamic> j) => PlayHint(
        hintId: (j['hintId'] as num).toInt(),
        hintLevel: (j['hintLevel'] as num?)?.toInt() ?? 0,
        isAvailable: j['isAvailable'] as bool? ?? false,
        isUsed: j['isUsed'] as bool? ?? false,
        penaltyScore: (j['penaltyScore'] as num?)?.toInt() ?? 0,
        content: j['content'] as String?,
        remainingMinutes: (j['remainingMinutes'] as num?)?.toInt(),
      );
}

class HintUseResult {
  const HintUseResult({
    required this.hintId,
    required this.content,
    required this.penaltyScore,
    this.usedAt,
  });

  final int hintId;
  final String content;
  final int penaltyScore;
  final DateTime? usedAt;

  factory HintUseResult.fromJson(Map<String, dynamic> j) => HintUseResult(
        hintId: (j['hintId'] as num).toInt(),
        content: j['content'] as String? ?? '',
        penaltyScore: (j['penaltyScore'] as num?)?.toInt() ?? 0,
        usedAt: _parse(j['usedAt']),
      );
}

// ── 심문 ─────────────────────────────────────────────────────────────────────

enum QuestionType { free, recommended, evidencePresented }

String questionTypeToApi(QuestionType t) => switch (t) {
      QuestionType.free => 'FREE',
      QuestionType.recommended => 'RECOMMENDED',
      QuestionType.evidencePresented => 'EVIDENCE_PRESENTED',
    };

QuestionType questionTypeFromApi(String? v) => switch (v) {
      'RECOMMENDED' => QuestionType.recommended,
      'EVIDENCE_PRESENTED' => QuestionType.evidencePresented,
      _ => QuestionType.free,
    };

class InterrogationResult {
  const InterrogationResult({
    required this.interrogationId,
    required this.suspectId,
    required this.suspectName,
    required this.question,
    required this.answer,
    this.questionType = QuestionType.free,
    this.presentedEvidence,
    this.unlockedEvidences = const [],
    this.createdAt,
  });

  final int interrogationId;
  final int suspectId;
  final String suspectName;
  final String question;
  final String answer;
  final QuestionType questionType;
  final RelatedEvidence? presentedEvidence;
  final List<RelatedEvidence> unlockedEvidences;
  final DateTime? createdAt;

  factory InterrogationResult.fromJson(Map<String, dynamic> j) =>
      InterrogationResult(
        interrogationId: (j['interrogationId'] as num).toInt(),
        suspectId: (j['suspectId'] as num).toInt(),
        suspectName: j['suspectName'] as String? ?? '',
        question: j['question'] as String? ?? '',
        answer: j['answer'] as String? ?? '',
        questionType: questionTypeFromApi(j['questionType'] as String?),
        presentedEvidence: j['presentedEvidence'] == null
            ? null
            : RelatedEvidence.fromJson(
                j['presentedEvidence'] as Map<String, dynamic>),
        unlockedEvidences:
            ((j['unlockedEvidences'] as List<dynamic>?) ?? const [])
                .map((e) => RelatedEvidence.fromJson(e as Map<String, dynamic>))
                .toList(),
        createdAt: _parse(j['createdAt']),
      );
}

DateTime? _parse(dynamic v) {
  if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
  return null;
}
