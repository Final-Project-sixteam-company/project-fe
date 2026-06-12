// lib/models/case.dart
import 'package:flutter/material.dart';

enum ProofDimension { timeProof, methodProof, motiveProof, coverUpProof }

extension ProofDimensionLabel on ProofDimension {
  String get label => switch (this) {
    ProofDimension.timeProof => '시간 증명',
    ProofDimension.methodProof => '방법 증명',
    ProofDimension.motiveProof => '동기 증명',
    ProofDimension.coverUpProof => '은폐 증명',
  };
}

enum EvidencePhase { phase0, phase1, phase2, phase3, phase4 }

extension EvidencePhaseLabelX on EvidencePhase {
  String get label => switch (this) {
    EvidencePhase.phase0 => 'Phase 0',
    EvidencePhase.phase1 => 'Phase 1',
    EvidencePhase.phase2 => 'Phase 2',
    EvidencePhase.phase3 => 'Phase 3',
    EvidencePhase.phase4 => 'Phase 4',
  };

  int get index => switch (this) {
    EvidencePhase.phase0 => 0,
    EvidencePhase.phase1 => 1,
    EvidencePhase.phase2 => 2,
    EvidencePhase.phase3 => 3,
    EvidencePhase.phase4 => 4,
  };
}

class Suspect {
  final String id;
  final String name;
  final String role;
  final int suspicion;
  final int interrogationCount;

  /// 공식 초상 이미지 URL — game_session_controller.dart 호환용 레거시 별칭.
  /// null/빈값이면 이니셜 아바타로 폴백.
  final String? portraitUrl;

  /// 프로필 이미지 에셋 키 (S3 URL 또는 로컬 경로).
  final String? portraitAssetKey;

  /// 증인 여부. true면 용의자가 아닌 참고인.
  /// game_session_controller.dart 에서 named 파라미터로 전달된다.
  final bool isWitness;

  /// 최종 범인 지목 가능 여부.
  final bool culpritEligible;

  final String? publicAlibi;
  final String? personalityTone;

  const Suspect({
    required this.id,
    required this.name,
    required this.role,
    required this.suspicion,
    this.interrogationCount = 0,
    this.portraitUrl,
    this.portraitAssetKey,
    this.isWitness = false,
    this.culpritEligible = true,
    this.publicAlibi,
    this.personalityTone,
  });
}

class Evidence {
  final String id;
  final String name;
  final String location;
  final IconData icon;
  final bool isNew;
  final bool isAnalyzed;
  final bool isLocked;
  final EvidencePhase phase;
  final List<ProofDimension> proofDimensions;
  final String? category;
  final String? oneLine;
  final String? imageUrl;
  final String? imageAssetKey;
  final String? categoryLabel;

  const Evidence({
    required this.id,
    required this.name,
    required this.location,
    required this.icon,
    this.isNew = false,
    this.isAnalyzed = false,
    this.isLocked = false,
    this.phase = EvidencePhase.phase0,
    this.proofDimensions = const [],
    this.category,
    this.oneLine,
    this.imageUrl,
    this.imageAssetKey,
    this.categoryLabel,
  });
}

class TimelineEntry {
  final String time;
  final String label;
  final String? conflict;
  final String? eventType;
  final String? description;

  const TimelineEntry({
    required this.time,
    required this.label,
    this.conflict,
    this.eventType,
    this.description,
  });
}
