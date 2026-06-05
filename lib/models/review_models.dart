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

/// CL-001은 백엔드 시나리오 id('1')와 샘플 id('demoday-eve')가 같은 사건을 가리킨다.
/// (controller.usesCl001SampleCaseData 와 동일한 이중-id 사실)
/// 리뷰는 작성 경로(결과 화면 = controller.scenarioId)와 열람 경로(상세 = scenario.id)가
/// 서로 다른 id를 쓸 수 있어, 같은 사건의 리뷰가 갈라지지 않도록 키를 정규화한다.
const _cl001ScenarioAliases = {'demoday-eve', '1'};

String canonicalScenarioId(String id) =>
    _cl001ScenarioAliases.contains(id) ? 'demoday-eve' : id;

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
