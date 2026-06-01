// lib/models/api_models.dart
//
// API DTO 모델 — CaseLab_AI_API_Spec.md 기준
// 백엔드 응답 JSON ↔ Dart 객체 변환 전담.

// ── 시나리오 ──────────────────────────────────────────────────────────────────

class ScenarioSummaryDto {
  const ScenarioSummaryDto({
    required this.scenarioId,
    required this.title,
    required this.description,
    required this.scenarioType,
    required this.difficulty,
    required this.estimatedPlayTimeMinutes,
    required this.suspectCount,
    required this.evidenceCount,
    required this.playCount,
    required this.averageRating,
    this.thumbnailUrl,
    this.isBookmarked = false,
  });

  final int scenarioId;
  final String title;
  final String description;
  final String scenarioType;
  final String difficulty;
  final int estimatedPlayTimeMinutes;
  final int suspectCount;
  final int evidenceCount;
  final int playCount;
  final double averageRating;
  final String? thumbnailUrl;
  final bool isBookmarked;

  factory ScenarioSummaryDto.fromJson(Map<String, dynamic> j) =>
      ScenarioSummaryDto(
        scenarioId: j['scenarioId'] as int,
        title: j['title'] as String,
        description: j['description'] as String? ?? '',
        scenarioType: j['scenarioType'] as String? ?? 'OFFICIAL',
        difficulty: j['difficulty'] as String? ?? 'NORMAL',
        estimatedPlayTimeMinutes: j['estimatedPlayTimeMinutes'] as int? ?? 30,
        suspectCount: j['suspectCount'] as int? ?? 0,
        evidenceCount: j['evidenceCount'] as int? ?? 0,
        playCount: j['playCount'] as int? ?? 0,
        averageRating: (j['averageRating'] as num?)?.toDouble() ?? 0.0,
        thumbnailUrl: j['thumbnailUrl'] as String?,
        isBookmarked: j['isBookmarked'] as bool? ?? false,
      );
}

class ScenarioDetailDto {
  const ScenarioDetailDto({
    required this.scenarioId,
    required this.title,
    required this.description,
    required this.synopsis,
    required this.scenarioType,
    required this.difficulty,
    required this.estimatedPlayTimeMinutes,
    required this.playCount,
    required this.averageRating,
    required this.ratingCount,
    required this.suspectCount,
    required this.evidenceCount,
    required this.hintCount,
    required this.tags,
    this.isBookmarked = false,
    this.canPlay = false,
  });

  final int scenarioId;
  final String title;
  final String description;
  final String synopsis;
  final String scenarioType;
  final String difficulty;
  final int estimatedPlayTimeMinutes;
  final int playCount;
  final double averageRating;
  final int ratingCount;
  final int suspectCount;
  final int evidenceCount;
  final int hintCount;
  final List<String> tags;
  final bool isBookmarked;
  final bool canPlay;

  factory ScenarioDetailDto.fromJson(Map<String, dynamic> j) =>
      ScenarioDetailDto(
        scenarioId: j['scenarioId'] as int,
        title: j['title'] as String,
        description: j['description'] as String? ?? '',
        synopsis: j['synopsis'] as String? ?? '',
        scenarioType: j['scenarioType'] as String? ?? 'OFFICIAL',
        difficulty: j['difficulty'] as String? ?? 'NORMAL',
        estimatedPlayTimeMinutes: j['estimatedPlayTimeMinutes'] as int? ?? 30,
        playCount: j['playCount'] as int? ?? 0,
        averageRating: (j['averageRating'] as num?)?.toDouble() ?? 0.0,
        ratingCount: j['ratingCount'] as int? ?? 0,
        suspectCount: j['suspectCount'] as int? ?? 0,
        evidenceCount: j['evidenceCount'] as int? ?? 0,
        hintCount: j['hintCount'] as int? ?? 0,
        tags: (j['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
        isBookmarked: j['isBookmarked'] as bool? ?? false,
        canPlay: j['canPlay'] as bool? ?? false,
      );
}

class ScenarioListResponseDto {
  const ScenarioListResponseDto({
    required this.content,
    required this.page,
    required this.totalElements,
    required this.hasNext,
  });

  final List<ScenarioSummaryDto> content;
  final int page;
  final int totalElements;
  final bool hasNext;

  factory ScenarioListResponseDto.fromJson(Map<String, dynamic> j) =>
      ScenarioListResponseDto(
        content: (j['content'] as List<dynamic>)
            .map((e) => ScenarioSummaryDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        page: j['page'] as int? ?? 0,
        totalElements: j['totalElements'] as int? ?? 0,
        hasNext: j['hasNext'] as bool? ?? false,
      );
}

// ── 플레이 세션 ───────────────────────────────────────────────────────────────

class PlaySessionDto {
  const PlaySessionDto({
    required this.sessionId,
    required this.scenarioId,
    required this.status,
    required this.startedAt,
  });

  final int sessionId;
  final int scenarioId;
  final String status;
  final String startedAt;

  factory PlaySessionDto.fromJson(Map<String, dynamic> j) => PlaySessionDto(
    sessionId: j['sessionId'] as int,
    scenarioId: j['scenarioId'] as int,
    status: j['status'] as String? ?? 'PLAYING',
    startedAt: j['startedAt'] as String? ?? '',
  );
}

class DashboardDto {
  const DashboardDto({
    required this.sessionId,
    required this.scenarioId,
    required this.scenarioTitle,
    required this.status,
    required this.elapsedSeconds,
    required this.unlockedEvidenceCount,
    required this.totalEvidenceCount,
    required this.hintUsedCount,
    required this.interrogationCount,
  });

  final int sessionId;
  final int scenarioId;
  final String scenarioTitle;
  final String status;
  final int elapsedSeconds;
  final int unlockedEvidenceCount;
  final int totalEvidenceCount;
  final int hintUsedCount;
  final int interrogationCount;

  factory DashboardDto.fromJson(Map<String, dynamic> j) => DashboardDto(
    sessionId: j['sessionId'] as int,
    scenarioId: j['scenarioId'] as int,
    scenarioTitle: j['scenarioTitle'] as String? ?? '',
    status: j['status'] as String? ?? 'PLAYING',
    elapsedSeconds: j['elapsedSeconds'] as int? ?? 0,
    unlockedEvidenceCount: j['unlockedEvidenceCount'] as int? ?? 0,
    totalEvidenceCount: j['totalEvidenceCount'] as int? ?? 0,
    hintUsedCount: j['hintUsedCount'] as int? ?? 0,
    interrogationCount: j['interrogationCount'] as int? ?? 0,
  );
}

// ── 증거 ──────────────────────────────────────────────────────────────────────

class EvidenceDto {
  const EvidenceDto({
    required this.evidenceId,
    required this.title,
    required this.isUnlocked,
    this.description,
    this.locationName,
    this.importance,
    this.unlockHint,
    this.relatedSuspects = const [],
  });

  final int evidenceId;
  final String title;
  final bool isUnlocked;
  final String? description;
  final String? locationName;
  final String? importance;
  final String? unlockHint;
  final List<SuspectRefDto> relatedSuspects;

  factory EvidenceDto.fromJson(Map<String, dynamic> j) => EvidenceDto(
    evidenceId: j['evidenceId'] as int,
    title: j['title'] as String,
    isUnlocked: j['isUnlocked'] as bool? ?? false,
    description: j['description'] as String?,
    locationName: j['locationName'] as String?,
    importance: j['importance'] as String?,
    unlockHint: j['unlockHint'] as String?,
    relatedSuspects: (j['relatedSuspects'] as List<dynamic>?)
        ?.map((e) => SuspectRefDto.fromJson(e as Map<String, dynamic>))
        .toList() ??
        const [],
  );
}

// ── 용의자 ────────────────────────────────────────────────────────────────────

class SuspectRefDto {
  const SuspectRefDto({required this.suspectId, required this.name});

  final int suspectId;
  final String name;

  factory SuspectRefDto.fromJson(Map<String, dynamic> j) => SuspectRefDto(
    suspectId: j['suspectId'] as int,
    name: j['name'] as String,
  );
}

class SuspectDto {
  const SuspectDto({
    required this.suspectId,
    required this.name,
    required this.role,
    required this.relationToVictim,
    required this.publicStatement,
    required this.alibi,
    required this.suspicionLevel,
    this.interrogationCount = 0,
    this.publicProfile,
    this.relatedEvidences = const [],
  });

  final int suspectId;
  final String name;
  final String role;
  final String relationToVictim;
  final String publicStatement;
  final String alibi;
  final int suspicionLevel;
  final int interrogationCount;
  final String? publicProfile;
  final List<EvidenceDto> relatedEvidences;

  factory SuspectDto.fromJson(Map<String, dynamic> j) => SuspectDto(
    suspectId: j['suspectId'] as int,
    name: j['name'] as String,
    role: j['role'] as String? ?? '',
    relationToVictim: j['relationToVictim'] as String? ?? '',
    publicStatement: j['publicStatement'] as String? ?? '',
    alibi: j['alibi'] as String? ?? '',
    suspicionLevel: j['suspicionLevel'] as int? ?? 0,
    interrogationCount: j['interrogationCount'] as int? ?? 0,
    publicProfile: j['publicProfile'] as String?,
    relatedEvidences: (j['relatedEvidences'] as List<dynamic>?)
        ?.map((e) => EvidenceDto.fromJson(e as Map<String, dynamic>))
        .toList() ??
        const [],
  );
}

// ── 타임라인 ──────────────────────────────────────────────────────────────────

class TimelineEventDto {
  const TimelineEventDto({
    required this.time,
    required this.title,
    this.description,
    this.isTrueEvent = true,
    this.relatedEvidenceId,
  });

  final String time;
  final String title;
  final String? description;
  final bool isTrueEvent;
  final int? relatedEvidenceId;

  factory TimelineEventDto.fromJson(Map<String, dynamic> j) =>
      TimelineEventDto(
        time: j['time'] as String,
        title: j['title'] as String,
        description: j['description'] as String?,
        isTrueEvent: j['isTrueEvent'] as bool? ?? true,
        relatedEvidenceId: j['relatedEvidenceId'] as int?,
      );
}

// ── 힌트 ──────────────────────────────────────────────────────────────────────

class HintDto {
  const HintDto({
    required this.hintId,
    required this.hintLevel,
    required this.isAvailable,
    required this.isUsed,
    required this.penaltyScore,
    this.content,
  });

  final int hintId;
  final int hintLevel;
  final bool isAvailable;
  final bool isUsed;
  final int penaltyScore;
  final String? content;

  factory HintDto.fromJson(Map<String, dynamic> j) => HintDto(
    hintId: j['hintId'] as int,
    hintLevel: j['hintLevel'] as int,
    isAvailable: j['isAvailable'] as bool? ?? false,
    isUsed: j['isUsed'] as bool? ?? false,
    penaltyScore: j['penaltyScore'] as int? ?? 5,
    content: j['content'] as String?,
  );
}

class HintUseResultDto {
  const HintUseResultDto({
    required this.hintId,
    required this.content,
    required this.penaltyScore,
  });

  final int hintId;
  final String content;
  final int penaltyScore;

  factory HintUseResultDto.fromJson(Map<String, dynamic> j) =>
      HintUseResultDto(
        hintId: j['hintId'] as int,
        content: j['content'] as String,
        penaltyScore: j['penaltyScore'] as int? ?? 5,
      );
}

// ── 심문 ──────────────────────────────────────────────────────────────────────

class InterrogationResultDto {
  const InterrogationResultDto({
    required this.interrogationId,
    required this.suspectId,
    required this.suspectName,
    required this.question,
    required this.answer,
    this.unlockedEvidences = const [],
  });

  final int interrogationId;
  final int suspectId;
  final String suspectName;
  final String question;
  final String answer;
  final List<EvidenceDto> unlockedEvidences;

  factory InterrogationResultDto.fromJson(Map<String, dynamic> j) =>
      InterrogationResultDto(
        interrogationId: j['interrogationId'] as int,
        suspectId: j['suspectId'] as int,
        suspectName: j['suspectName'] as String,
        question: j['question'] as String,
        answer: j['answer'] as String,
        unlockedEvidences: (j['unlockedEvidences'] as List<dynamic>?)
            ?.map((e) => EvidenceDto.fromJson(e as Map<String, dynamic>))
            .toList() ??
            const [],
      );
}

// ── 최종 추리 / 결과 ──────────────────────────────────────────────────────────

class FinalDeductionResultDto {
  const FinalDeductionResultDto({
    required this.finalDeductionId,
    required this.score,
    required this.grade,
    required this.feedbackSummary,
    required this.resultAvailable,
  });

  final int finalDeductionId;
  final int score;
  final String grade;
  final String feedbackSummary;
  final bool resultAvailable;

  factory FinalDeductionResultDto.fromJson(Map<String, dynamic> j) =>
      FinalDeductionResultDto(
        finalDeductionId: j['finalDeductionId'] as int,
        score: j['score'] as int,
        grade: j['grade'] as String,
        feedbackSummary: j['feedbackSummary'] as String? ?? '',
        resultAvailable: j['resultAvailable'] as bool? ?? true,
      );
}

class CaseResultDto {
  const CaseResultDto({
    required this.sessionId,
    required this.score,
    required this.grade,
    required this.culpritName,
    required this.fullExplanation,
    required this.feedback,
    required this.matchedParts,
    required this.missedParts,
  });

  final int sessionId;
  final int score;
  final String grade;
  final String culpritName;
  final String fullExplanation;
  final String feedback;
  final List<String> matchedParts;
  final List<String> missedParts;

  factory CaseResultDto.fromJson(Map<String, dynamic> j) {
    final culprit = j['correctCulprit'] as Map<String, dynamic>?;
    return CaseResultDto(
      sessionId: j['sessionId'] as int,
      score: j['score'] as int,
      grade: j['grade'] as String,
      culpritName: culprit?['name'] as String? ?? '미상',
      fullExplanation: j['fullExplanation'] as String? ?? '',
      feedback: j['feedback'] as String? ?? '',
      matchedParts: (j['matchedParts'] as List<dynamic>?)?.cast<String>() ?? const [],
      missedParts: (j['missedParts'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }
}

// ── 리뷰 ──────────────────────────────────────────────────────────────────────

class ReviewDto {
  const ReviewDto({
    required this.reviewId,
    required this.authorName,
    required this.rating,
    required this.content,
    required this.createdAt,
    this.isSpoiler = false,
  });

  final int reviewId;
  final String authorName;
  final double rating;
  final String content;
  final String createdAt;
  final bool isSpoiler;

  factory ReviewDto.fromJson(Map<String, dynamic> j) {
    final user = j['user'] as Map<String, dynamic>?;
    return ReviewDto(
      reviewId: j['reviewId'] as int,
      authorName: user?['nickname'] as String? ?? '익명',
      rating: (j['rating'] as num?)?.toDouble() ?? 0.0,
      content: j['content'] as String? ?? '',
      createdAt: j['createdAt'] as String? ?? '',
      isSpoiler: j['isSpoiler'] as bool? ?? false,
    );
  }
}

class ReviewListDto {
  const ReviewListDto({required this.content, required this.hasNext});

  final List<ReviewDto> content;
  final bool hasNext;

  factory ReviewListDto.fromJson(Map<String, dynamic> j) => ReviewListDto(
    content: (j['content'] as List<dynamic>)
        .map((e) => ReviewDto.fromJson(e as Map<String, dynamic>))
        .toList(),
    hasNext: j['hasNext'] as bool? ?? false,
  );
}

// ── AI 검증 ───────────────────────────────────────────────────────────────────

class ValidationResultDto {
  const ValidationResultDto({
    required this.scenarioId,
    required this.validationStatus,
    required this.validationScore,
    required this.problemSummary,
    required this.suggestion,
    required this.checkItems,
  });

  final int scenarioId;
  final String validationStatus;
  final int validationScore;
  final String problemSummary;
  final String suggestion;
  final List<ValidationCheckItem> checkItems;

  factory ValidationResultDto.fromJson(Map<String, dynamic> j) =>
      ValidationResultDto(
        scenarioId: j['scenarioId'] as int,
        validationStatus: j['validationStatus'] as String,
        validationScore: j['validationScore'] as int? ?? 0,
        problemSummary: j['problemSummary'] as String? ?? '',
        suggestion: j['suggestion'] as String? ?? '',
        checkItems: (j['checkItems'] as List<dynamic>?)
            ?.map((e) =>
            ValidationCheckItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
            const [],
      );
}

class ValidationCheckItem {
  const ValidationCheckItem({required this.name, required this.passed});

  final String name;
  final bool passed;

  factory ValidationCheckItem.fromJson(Map<String, dynamic> j) =>
      ValidationCheckItem(
        name: j['name'] as String,
        passed: j['passed'] as bool? ?? false,
      );
}

// ── 현장 위치 ─────────────────────────────────────────────────────────────────

class LocationDto {
  const LocationDto({
    required this.locationId,
    required this.name,
    required this.description,
    required this.evidenceCount,
    this.mapX,
    this.mapY,
  });

  final int locationId;
  final String name;
  final String description;
  final int evidenceCount;
  final int? mapX;
  final int? mapY;

  factory LocationDto.fromJson(Map<String, dynamic> j) => LocationDto(
    locationId: j['locationId'] as int,
    name: j['name'] as String,
    description: j['description'] as String? ?? '',
    evidenceCount: j['evidenceCount'] as int? ?? 0,
    mapX: j['mapX'] as int?,
    mapY: j['mapY'] as int?,
  );
}