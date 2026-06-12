// lib/models/play_evidence_models.dart
// 증거 관련 플레이 DTO (play_models.dart 에서 분리)

import 'case.dart';

enum EvidenceImportance { low, normal, high, core, fake }

EvidenceImportance evidenceImportanceFromApi(String? v) => switch (v) {
  'LOW' => EvidenceImportance.low,
  'HIGH' => EvidenceImportance.high,
  'CORE' => EvidenceImportance.core,
  'FAKE' => EvidenceImportance.fake,
  _ => EvidenceImportance.normal,
};

EvidencePhase evidencePhaseFromApi(int? v) => switch (v) {
  1 => EvidencePhase.phase1,
  2 => EvidencePhase.phase2,
  3 => EvidencePhase.phase3,
  4 => EvidencePhase.phase4,
  _ => EvidencePhase.phase0,
};

List<ProofDimension> proofDimensionsFromApi(List<dynamic>? v) {
  if (v == null) return const [];
  return v
      .map((e) => switch (e as String?) {
    'TIME_PROOF' => ProofDimension.timeProof,
    'METHOD_PROOF' => ProofDimension.methodProof,
    'MOTIVE_PROOF' => ProofDimension.motiveProof,
    'COVER_UP_PROOF' => ProofDimension.coverUpProof,
    _ => null,
  })
      .whereType<ProofDimension>()
      .toList();
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

  factory RelatedEvidence.fromJson(Map<String, dynamic> j) => RelatedEvidence(
    evidenceId: (j['evidenceId'] as num).toInt(),
    title: j['title'] as String? ?? '',
  );
}

class PlayEvidence {
  const PlayEvidence({
    required this.evidenceId,
    required this.title,
    required this.importance,
    required this.isUnlocked,
    this.description,
    this.locationName,
    this.unlockHint,
    this.relatedSuspects = const [],
    this.phase = EvidencePhase.phase0,
    this.proofDimensions = const [],
    this.category,
    this.imageUrl,
    this.oneLine,
    this.imageAssetKey,
    this.categoryLabel,
  });

  final int evidenceId;
  final String title;
  final EvidenceImportance importance;
  final bool isUnlocked;
  final String? description;
  final String? locationName;
  final String? unlockHint;
  final List<RelatedSuspect> relatedSuspects;
  final EvidencePhase phase;
  final List<ProofDimension> proofDimensions;
  final String? category;
  final String? imageUrl;
  final String? oneLine;
  final String? imageAssetKey;
  final String? categoryLabel;

  factory PlayEvidence.fromJson(Map<String, dynamic> j) {
    final url = j['imageUrl'] as String?;
    return PlayEvidence(
      evidenceId: (j['evidenceId'] as num).toInt(),
      title: j['title'] as String? ?? '',
      importance: evidenceImportanceFromApi(j['importance'] as String?),
      isUnlocked: j['isUnlocked'] as bool? ?? false,
      description: j['description'] as String?,
      locationName: j['locationName'] as String?,
      unlockHint: j['unlockHint'] as String?,
      relatedSuspects:
      ((j['relatedSuspects'] as List<dynamic>?) ?? const [])
          .map((e) => RelatedSuspect.fromJson(e as Map<String, dynamic>))
          .toList(),
      phase: evidencePhaseFromApi((j['phase'] as num?)?.toInt()),
      proofDimensions:
      proofDimensionsFromApi(j['proofDimensions'] as List<dynamic>?),
      category: j['evidenceType'] as String? ?? j['category'] as String?,
      imageUrl: url,
      oneLine: j['oneLine'] as String?,
      imageAssetKey: (url != null && url.isNotEmpty)
          ? url
          : j['imageAssetKey'] as String?,
      categoryLabel: j['categoryLabel'] as String?,
    );
  }
}

// ── 증거 상세 조회 응답 ──────────────────────────────────────────────────────
// GET …/play-sessions/{sessionId}/evidences/{evidenceId} 전용.
// 목록(PlayEvidence)보다 풍부한 본문(description)과 관련 타임라인 이벤트를 포함.

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

class CompareEvidenceInfo {
  const CompareEvidenceInfo({
    this.evidenceId,
    this.evidenceCode,
    required this.title,
    required this.isUnlocked,
    this.unlockHint,
  });

  final int? evidenceId;
  final String? evidenceCode;
  final String title;
  final bool isUnlocked;
  final String? unlockHint;

  factory CompareEvidenceInfo.fromJson(Map<String, dynamic> j) =>
      CompareEvidenceInfo(
        evidenceId: (j['evidenceId'] as num?)?.toInt(),
        evidenceCode: j['evidenceCode'] as String?,
        title: j['title'] as String? ?? '',
        isUnlocked: j['isUnlocked'] as bool? ?? false,
        unlockHint: j['unlockHint'] as String?,
      );
}

class SuggestedQuestionInfo {
  const SuggestedQuestionInfo({
    this.targetCharacterCode,
    this.targetSuspectId,
    this.targetName,
    required this.question,
    this.presentedEvidenceId,
    this.questionType,
  });

  final String? targetCharacterCode;
  final int? targetSuspectId;
  final String? targetName;
  final String question;
  final int? presentedEvidenceId;
  final String? questionType;

  factory SuggestedQuestionInfo.fromJson(Map<String, dynamic> j) =>
      SuggestedQuestionInfo(
        targetCharacterCode: j['targetCharacterCode'] as String?,
        targetSuspectId: (j['targetSuspectId'] as num?)?.toInt(),
        targetName: j['targetName'] as String?,
        question: j['question'] as String? ?? '',
        presentedEvidenceId: (j['presentedEvidenceId'] as num?)?.toInt(),
        questionType: j['questionType'] as String?,
      );
}

class EvidenceGuidance {
  const EvidenceGuidance({
    this.readingPoints = const [],
    this.compareEvidences = const [],
    this.suggestedQuestions = const [],
  });

  final List<String> readingPoints;
  final List<CompareEvidenceInfo> compareEvidences;
  final List<SuggestedQuestionInfo> suggestedQuestions;

  factory EvidenceGuidance.fromJson(Map<String, dynamic> j) => EvidenceGuidance(
        readingPoints: (j['readingPoints'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        compareEvidences: (j['compareEvidences'] as List<dynamic>?)
                ?.map((e) => CompareEvidenceInfo.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        suggestedQuestions: (j['suggestedQuestions'] as List<dynamic>?)
                ?.map((e) => SuggestedQuestionInfo.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

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
    this.guidance,
  });

  final int evidenceId;
  final String title;
  final EvidenceImportance importance;
  final String? description;
  final String? imageUrl;
  final String? locationName;
  final List<RelatedSuspect> relatedSuspects;
  final List<RelatedTimelineEvent> relatedTimelineEvents;
  final EvidenceGuidance? guidance;

  factory EvidenceDetail.fromJson(Map<String, dynamic> j) => EvidenceDetail(
    evidenceId: (j['evidenceId'] as num).toInt(),
    title: j['title'] as String? ?? '',
    importance: evidenceImportanceFromApi(j['importance'] as String?),
    description: j['description'] as String?,
    imageUrl: j['imageUrl'] as String?,
    locationName:
    (j['location'] as Map<String, dynamic>?)?['name'] as String?,
    relatedSuspects:
    ((j['relatedSuspects'] as List<dynamic>?) ?? const [])
        .map((e) => RelatedSuspect.fromJson(e as Map<String, dynamic>))
        .toList(),
    relatedTimelineEvents:
    ((j['relatedTimelineEvents'] as List<dynamic>?) ?? const [])
        .map((e) =>
        RelatedTimelineEvent.fromJson(e as Map<String, dynamic>))
        .toList(),
    guidance: j['guidance'] != null
        ? EvidenceGuidance.fromJson(j['guidance'] as Map<String, dynamic>)
        : null,
  );
}