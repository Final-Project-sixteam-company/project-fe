// lib/models/review_models.dart

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

  final String id;
  final String scenarioId;
  final String authorName;
  final double rating;
  final String body;
  final DateTime createdAt;
  final bool isSpoiler;
}

// 샘플 리뷰 데이터
final sampleReviews = <ScenarioReview>[
  ScenarioReview(
    id: 'r1',
    scenarioId: 'demoday-eve',
    authorName: '탐정견습생',
    rating: 5.0,
    body: '타임라인 모순을 발견하는 순간 소름이 돋았습니다. 증거 배치가 정말 치밀해요.',
    createdAt: DateTime(2026, 5, 20),
  ),
  ScenarioReview(
    id: 'r2',
    scenarioId: 'demoday-eve',
    authorName: '추리왕',
    rating: 4.5,
    body: 'AI 용의자 답변이 생각보다 자연스럽습니다. 심문이 재미있었어요.',
    createdAt: DateTime(2026, 5, 18),
  ),
  ScenarioReview(
    id: 'r3',
    scenarioId: 'demoday-eve',
    authorName: '스포주의',
    rating: 4.8,
    body: '범인은 생각지도 못한 인물이었습니다. 힌트 없이 풀었어요.',
    createdAt: DateTime(2026, 5, 15),
    isSpoiler: true,
  ),
];
