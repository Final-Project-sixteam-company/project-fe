// lib/models/play_models.dart
// 플레이 세션 관련 API 응답 모델 (백엔드 DTO와 1:1 대응)

enum EvidenceImportance { low, normal, high, core, fake }

EvidenceImportance evidenceImportanceFromApi(String? v) => switch (v) {
  'LOW' => EvidenceImportance.low,
  'HIGH' => EvidenceImportance.high,
  'CORE' => EvidenceImportance.core,
  'FAKE' => EvidenceImportance.fake,
  _ => EvidenceImportance.normal,
};

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

enum PlaySessionStatus { playing, submitted, completed, abandoned }

PlaySessionStatus playSessionStatusFromApi(String? v) => switch (v) {
  'SUBMITTED' => PlaySessionStatus.submitted,
  'COMPLETED' => PlaySessionStatus.completed,
  'ABANDONED' => PlaySessionStatus.abandoned,
  _ => PlaySessionStatus.playing,
};

// ── 세션 생성 ────────────────────────────────────────────────────────────────

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
    startedAt: _parseDate(j['startedAt']),
  );
}

// ── 대시보드 ─────────────────────────────────────────────────────────────────

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
    totalEvidenceCount:
    (j['totalEvidenceCount'] as num?)?.toInt() ?? 0,
    hintUsedCount: (j['hintUsedCount'] as num?)?.toInt() ?? 0,
    interrogationCount:
    (j['interrogationCount'] as num?)?.toInt() ?? 0,
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

// ── 증거 ─────────────────────────────────────────────────────────────────────

class PlayEvidence {
  const PlayEvidence({
    required this.evidenceId,
    required this.title,
    required this.importance,
    required this.isUnlocked,
    this.oneLine,
    this.imageUrl,
    this.description,
    this.locationName,
    this.unlockHint,
    this.relatedSuspects = const [],
    // 이미지/카테고리 — 시나리오 YAML의 imageAssetKey / category 필드 대응
    this.imageAssetKey,
    this.categoryLabel,
  });

  final int evidenceId;
  final String title;
  final EvidenceImportance importance;
  final bool isUnlocked;

  /// 한 줄 요약(목록 티저). 잠긴 증거는 보통 null.
  final String? oneLine;

  /// 증거 썸네일/이미지(S3 URL). 해금된 증거에만 존재하며 없으면 null → 아이콘 폴백.
  final String? imageUrl;

  final String? description;
  final String? locationName;
  final String? unlockHint;
  final List<RelatedSuspect> relatedSuspects;

  /// 증거 이미지 URL 또는 로컬 assetKey.
  final String? imageAssetKey;

  /// 증거 카테고리 표시 라벨 (PHYSICAL / DOCUMENT / DIGITAL_LOG / MAP 등).
  final String? categoryLabel;

  factory PlayEvidence.fromJson(Map<String, dynamic> j) => PlayEvidence(
        evidenceId: (j['evidenceId'] as num).toInt(),
        title: j['title'] as String? ?? '',
        importance: evidenceImportanceFromApi(j['importance'] as String?),
        isUnlocked: j['isUnlocked'] as bool? ?? false,
        oneLine: j['oneLine'] as String?,
        imageUrl: j['imageUrl'] as String?,
        description: j['description'] as String?,
        locationName: j['locationName'] as String?,
        unlockHint: j['unlockHint'] as String?,
        relatedSuspects: ((j['relatedSuspects'] as List<dynamic>?) ?? const [])
            .map((e) => RelatedSuspect.fromJson(e as Map<String, dynamic>))
            .toList(),
        // imageUrl(API spec 명칭) 또는 imageAssetKey(로컬/레거시) 우선순위 적용.
        // 백엔드가 어느 키로 내려줘도 thumbnail/viewer UI가 동작한다.
        imageAssetKey: (() {
          final url = j['imageUrl'] as String?;
          if (url != null && url.isNotEmpty) return url;
          return j['imageAssetKey'] as String?;
        })(),
        categoryLabel: j['categoryLabel'] as String?,
      );
}

/// 증거 상세 조회(`GET …/evidences/{evidenceId}`) 응답.
/// 목록(PlayEvidence)보다 풍부한 본문(description)과 관련 타임라인 이벤트를 준다.
/// location 은 목록의 `locationName`(문자열)과 달리 `{locationId,name}` 객체다.
class EvidenceDetail {
  const EvidenceDetail({
    required this.evidenceId,
    required this.title,
    required this.importance,
    this.description,
    this.imageUrl,
    this.locationName,
    this.relatedSuspects = const [],
    this.relatedTimelineEvents = const [],
  });

  final int evidenceId;
  final String title;
  final EvidenceImportance importance;
  final String? description;
  final String? imageUrl;
  final String? locationName;
  final List<RelatedSuspect> relatedSuspects;
  final List<RelatedTimelineEvent> relatedTimelineEvents;

  factory EvidenceDetail.fromJson(Map<String, dynamic> j) => EvidenceDetail(
        evidenceId: (j['evidenceId'] as num).toInt(),
        title: j['title'] as String? ?? '',
        importance: evidenceImportanceFromApi(j['importance'] as String?),
        description: j['description'] as String?,
        imageUrl: j['imageUrl'] as String?,
        // location 객체에서 표시용 이름만 추출(없으면 null).
        locationName:
            (j['location'] as Map<String, dynamic>?)?['name'] as String?,
        relatedSuspects: ((j['relatedSuspects'] as List<dynamic>?) ?? const [])
            .map((e) => RelatedSuspect.fromJson(e as Map<String, dynamic>))
            .toList(),
        relatedTimelineEvents:
            ((j['relatedTimelineEvents'] as List<dynamic>?) ?? const [])
                .map((e) =>
                    RelatedTimelineEvent.fromJson(e as Map<String, dynamic>))
                .toList(),
      );
}

/// 증거 상세의 관련 타임라인 이벤트(`{time, title}`).
class RelatedTimelineEvent {
  const RelatedTimelineEvent({required this.time, required this.title});

  final String time;
  final String title;

  factory RelatedTimelineEvent.fromJson(Map<String, dynamic> j) =>
      RelatedTimelineEvent(
        time: j['time'] as String? ?? '',
        title: j['title'] as String? ?? '',
      );
}

class RelatedSuspect {
  const RelatedSuspect({required this.suspectId, required this.name});

  final int suspectId;
  final String name;

  factory RelatedSuspect.fromJson(Map<String, dynamic> j) => RelatedSuspect(
    suspectId: (j['suspectId'] as num).toInt(),
    name: j['name'] as String? ?? '',
  );
}

class RelatedEvidence {
  const RelatedEvidence({required this.evidenceId, required this.title});

  final int evidenceId;
  final String title;

  factory RelatedEvidence.fromJson(Map<String, dynamic> j) =>
      RelatedEvidence(
        evidenceId: (j['evidenceId'] as num).toInt(),
        title: j['title'] as String? ?? '',
      );
}

// ── 용의자 ───────────────────────────────────────────────────────────────────

class PlaySuspect {
  const PlaySuspect({
    required this.suspectId,
    required this.name,
    required this.suspicionLevel,
    required this.interrogationCount,
    this.role,
    this.relationToVictim,
    this.publicStatement,
    this.alibi,
    this.portraitImageUrl,
    // 이미지/캐릭터 타입
    this.portraitAssetKey,
    this.characterType,
    this.isWitness = false,
  });

  final int suspectId;
  final String name;
  final int suspicionLevel;
  final int interrogationCount;
  final String? role;
  final String? relationToVictim;
  final String? publicStatement;
  final String? alibi;

  /// 용의자 공식 초상 이미지(S3 URL). 없으면 null → UI는 이니셜 아바타로 폴백.
  /// portraitAssetKey 와 동일 값으로 채워지는 레거시 별칭(기존 뷰어/소비처 호환).
  final String? portraitImageUrl;

  /// 프로필 사진 URL 또는 로컬 assetKey.
  /// 백엔드가 'portraitImageUrl' 또는 'portraitAssetKey' 중 어느 키로 내려줘도
  /// 동일하게 처리한다. null이면 CharacterPortrait가 이니셜 아바타로 폴백.
  final String? portraitAssetKey;

  /// 백엔드 캐릭터 유형 문자열. 예: 'SUSPECT', 'NEUTRAL_WITNESS'.
  /// isWitness 판정의 보조 수단. 후속에서 isWitness boolean 필드로 교체 예정.
  final String? characterType;

  /// 서버가 isWitness boolean을 직접 내려줄 경우 우선 적용.
  /// 없으면 characterType == 'NEUTRAL_WITNESS' 로 폴백.
  /// 후속 백엔드 DTO 추가 시 characterType 의존을 완전히 제거한다.
  final bool isWitness;

  factory PlaySuspect.fromJson(Map<String, dynamic> j) {
    // portraitImageUrl(서버 명칭) 또는 portraitAssetKey(레거시) 중 존재하는 값 사용.
    final portrait = (j['portraitImageUrl'] as String?)?.isNotEmpty == true
        ? j['portraitImageUrl'] as String
        : j['portraitAssetKey'] as String?;

    final characterType = j['characterType'] as String?;
    // isWitness: 서버가 boolean으로 내려주면 우선, 없으면 characterType 문자열로 판단.
    final isWitness = j['isWitness'] as bool? ??
        (characterType == 'NEUTRAL_WITNESS');

    return PlaySuspect(
      suspectId: (j['suspectId'] as num).toInt(),
      name: j['name'] as String? ?? '',
      suspicionLevel: (j['suspicionLevel'] as num?)?.toInt() ?? 0,
      interrogationCount: (j['interrogationCount'] as num?)?.toInt() ?? 0,
      role: j['role'] as String?,
      relationToVictim: j['relationToVictim'] as String?,
      publicStatement: j['publicStatement'] as String?,
      alibi: j['alibi'] as String?,
      // 동일 값으로 두 필드를 모두 채워 asset-key/URL 양쪽 소비처 호환.
      portraitImageUrl: portrait,
      portraitAssetKey: portrait,
      characterType: characterType,
      isWitness: isWitness,
    );
  }
}

// ── 현장(장소) ───────────────────────────────────────────────────────────────

class PlayLocations {
  const PlayLocations({
    this.mapImageUrl,
    this.locations = const [],
  });

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
    this.locationCode,
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
  final String? locationCode;
  final String? floor;
  final String? description;
  final String? imageUrl;
  final double? mapX;
  final double? mapY;

  factory PlayLocation.fromJson(Map<String, dynamic> j) => PlayLocation(
        locationId: (j['locationId'] as num).toInt(),
        name: j['name'] as String? ?? '',
        totalEvidenceCount: (j['totalEvidenceCount'] as num?)?.toInt() ?? 0,
        unlockedEvidenceCount:
            (j['unlockedEvidenceCount'] as num?)?.toInt() ?? 0,
        locationCode: j['locationCode'] as String?,
        floor: j['floor']?.toString(),
        description: j['description'] as String?,
        imageUrl: j['imageUrl'] as String?,
        mapX: (j['mapX'] as num?)?.toDouble(),
        mapY: (j['mapY'] as num?)?.toDouble(),
      );
}

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
    usedAt: _parseDate(j['usedAt']),
  );
}

// ── 심문 ─────────────────────────────────────────────────────────────────────

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

  /// 질문 유형(FREE/RECOMMENDED/EVIDENCE_PRESENTED). 심문 로그 조회 응답에만 존재하며
  /// POST 응답에는 없어 기본 FREE로 처리한다.
  final QuestionType questionType;

  /// 증거 제시 심문일 때 제시된 증거(`{evidenceId, title}`). 그 외에는 null.
  /// 로그 복원 시 증거 제시 마커를 되살리는 데 쓴다.
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
        unlockedEvidences: ((j['unlockedEvidences'] as List<dynamic>?) ?? const [])
            .map((e) => RelatedEvidence.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: _parseDate(j['createdAt']),
      );
}

// ── 최종 추리 / 결과 ─────────────────────────────────────────────────────────

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
        submittedAt: _parseDate(j['submittedAt']),
      );
}

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

  factory DeductionResult.fromJson(Map<String, dynamic> j) =>
      DeductionResult(
        sessionId: (j['sessionId'] as num).toInt(),
        score: (j['score'] as num?)?.toInt() ?? 0,
        grade: j['grade'] as String? ?? '-',
        matched: MatchedParts.fromJson(
            (j['matched'] as Map<String, dynamic>?) ?? const {}),
        correctCulprit: j['correctCulprit'] == null
            ? null
            : CorrectCulprit.fromJson(
            j['correctCulprit'] as Map<String, dynamic>),
        matchedParts: ((j['matchedParts'] as List<dynamic>?) ?? const [])
            .cast<String>(),
        missedParts:
        ((j['missedParts'] as List<dynamic>?) ?? const []).cast<String>(),
        feedback: j['feedback'] as String? ?? '',
        fullExplanation: j['fullExplanation'] as String? ?? '',
        keyEvidences:
        ((j['keyEvidences'] as List<dynamic>?) ?? const [])
            .map((e) =>
            KeyEvidence.fromJson(e as Map<String, dynamic>))
            .toList(),
        nextRecommendedScenarios:
        ((j['nextRecommendedScenarios'] as List<dynamic>?) ?? const [])
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

  factory CorrectCulprit.fromJson(Map<String, dynamic> j) =>
      CorrectCulprit(
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

// ── 공통 ─────────────────────────────────────────────────────────────────────

DateTime? _parseDate(dynamic v) {
  if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
  return null;
}