// lib/models/review_models.dart
import 'package:flutter/foundation.dart';

/// 시나리오 리뷰 단일 모델.
@immutable
class ScenarioReview {
  const ScenarioReview({
    required this.id,
    required this.scenarioId,
    required this.authorName,
    required this.rating,
    required this.body,
    required this.createdAt,
    this.isSpoiler = false,
  });

  final String   id;
  final String   scenarioId;
  final String   authorName;
  final double   rating;     // 1.0 ~ 5.0
  final String   body;
  final DateTime createdAt;
  final bool     isSpoiler;

  /// JSON → ScenarioReview
  factory ScenarioReview.fromJson(Map<String, dynamic> json) {
    return ScenarioReview(
      id:         json['reviewId']?.toString() ?? '',
      scenarioId: json['scenarioId']?.toString() ?? '',
      authorName: (json['user'] as Map<String, dynamic>?)?['nickname'] as String? ?? '익명',
      rating:     (json['rating'] as num?)?.toDouble() ?? 0.0,
      body:       json['content'] as String? ?? '',
      createdAt:  json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      isSpoiler:  json['isSpoiler'] as bool? ?? false,
    );
  }

  ScenarioReview copyWith({
    String?   id,
    String?   scenarioId,
    String?   authorName,
    double?   rating,
    String?   body,
    DateTime? createdAt,
    bool?     isSpoiler,
  }) {
    return ScenarioReview(
      id:         id         ?? this.id,
      scenarioId: scenarioId ?? this.scenarioId,
      authorName: authorName ?? this.authorName,
      rating:     rating     ?? this.rating,
      body:       body       ?? this.body,
      createdAt:  createdAt  ?? this.createdAt,
      isSpoiler:  isSpoiler  ?? this.isSpoiler,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ScenarioReview &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ScenarioReview(id: $id, scenarioId: $scenarioId, '
          'author: $authorName, rating: $rating, spoiler: $isSpoiler)';
}

/// 샘플 리뷰 데이터 — 실 API 연결 전 UI 미리보기용.
/// API 연결 후 제거한다.
final List<ScenarioReview> sampleReviews = [
  ScenarioReview(
    id:         'r_demo_1',
    scenarioId: '10',
    authorName: '탐정순구',
    rating:     5.0,
    body:       '증거 조합이 정말 재밌었어요. 마지막 반전이 납득됐습니다.',
    createdAt:  DateTime(2026, 5, 15),
    isSpoiler:  false,
  ),
  ScenarioReview(
    id:         'r_demo_2',
    scenarioId: '10',
    authorName: '야간탐정',
    rating:     4.0,
    body:       '범인이 박재민인 이유가 명확합니다.',
    createdAt:  DateTime(2026, 5, 14),
    isSpoiler:  true,
  ),
  ScenarioReview(
    id:         'r_demo_3',
    scenarioId: '11',
    authorName: '추리러버',
    rating:     4.5,
    body:       '스튜디오9 시나리오 최고입니다. 디지털 증거 구성이 탄탄해요.',
    createdAt:  DateTime(2026, 5, 20),
    isSpoiler:  false,
  ),
];