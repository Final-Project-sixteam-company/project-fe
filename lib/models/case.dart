// lib/models/case.dart
import 'package:flutter/material.dart';

class Suspect {
  final String id;
  final String name;
  final String role;
  final int interrogationCount;

  /// 공식 초상 이미지 URL.
  /// null/빈값이면 이니셜 아바타로 폴백.
  final String? portraitUrl;

  /// 증인 여부. true면 용의자가 아닌 참고인.
  /// game_session_controller.dart 에서 named 파라미터로 전달된다.
  final bool isWitness;

  final String? publicAlibi;
  final String? personalityTone;

  const Suspect({
    required this.id,
    required this.name,
    required this.role,
    this.interrogationCount = 0,
    this.portraitUrl,
    this.isWitness = false,
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
  final bool isLocked;
  final String? category;
  final String? oneLine;
  final String? imageUrl;
  final String? categoryLabel;

  const Evidence({
    required this.id,
    required this.name,
    required this.location,
    required this.icon,
    this.isNew = false,
    this.isLocked = false,
    this.category,
    this.oneLine,
    this.imageUrl,
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
