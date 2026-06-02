// lib/models/case.dart
import 'package:flutter/material.dart';

class Suspect {
  final String id;
  final String name;
  final String role;
  final int suspicion;
  final int interrogationCount;

  /// 용의자 프로필 사진 assetKey (S3 URL 또는 로컬 경로).
  /// null이면 이니셜 아바타로 폴백.
  final String? portraitAssetKey;

  /// NEUTRAL_WITNESS 등 용의자가 아닌 증인 여부.
  final bool isWitness;

  const Suspect({
    required this.id,
    required this.name,
    required this.role,
    required this.suspicion,
    this.interrogationCount = 0,
    this.portraitAssetKey,
    this.isWitness = false,
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

  /// 증거 이미지 assetKey. null이면 icon 폴백.
  final String? imageAssetKey;

  /// 증거 카테고리 표시용 라벨.
  /// 예: 'PHYSICAL', 'DOCUMENT', 'DIGITAL_LOG', 'MAP', 'TESTIMONY', 'SCENE'
  final String? categoryLabel;

  const Evidence({
    required this.id,
    required this.name,
    required this.location,
    required this.icon,
    this.isNew = false,
    this.isAnalyzed = false,
    this.isLocked = false,
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