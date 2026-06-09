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
}

enum CharacterType { suspect, witness }

// ─────────────────────────────────────────────────────────────────────────────
// 1. Suspect 모델 수정
// ─────────────────────────────────────────────────────────────────────────────
class Suspect {
  final String id;
  final String name;
  final String role;
  final int suspicion;
  final int interrogationCount;
  final CharacterType characterType;
  final String? publicAlibi;
  final String? personalityTone;
  final String? portraitAssetKey;
  final String? portraitUrl;
  final bool isWitness;
  final bool culpritEligible;

  const Suspect({
    required this.id,
    required this.name,
    required this.role,
    required this.suspicion,
    this.interrogationCount = 0,
    this.characterType = CharacterType.suspect,
    this.publicAlibi,
    this.personalityTone,
    this.portraitAssetKey,
    this.portraitUrl,
    this.isWitness = false,
    this.culpritEligible = true,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Evidence 모델 수정
// ─────────────────────────────────────────────────────────────────────────────
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

  const TimelineEntry({
    required this.time,
    required this.label,
    this.conflict,
  });
}