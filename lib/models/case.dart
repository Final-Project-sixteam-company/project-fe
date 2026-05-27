// lib/models/case.dart
import 'package:flutter/material.dart';

class Suspect {
  final String id;
  final String name;
  final String role;
  final int suspicion;

  const Suspect({
    required this.id,
    required this.name,
    required this.role,
    required this.suspicion,
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

  const Evidence({
    required this.id,
    required this.name,
    required this.location,
    required this.icon,
    this.isNew = false,
    this.isAnalyzed = false,
    this.isLocked = false,
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