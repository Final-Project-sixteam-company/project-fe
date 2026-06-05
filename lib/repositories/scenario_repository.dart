// lib/repositories/scenario_repository.dart
import '../core/api/api_client.dart';
import '../models/scenario.dart';

enum ScenarioSort { popular, newest, rating }

class ScenarioFilter {
  const ScenarioFilter({
    this.type,
    this.difficulty,
    this.sort = ScenarioSort.popular,
    this.query = '',
  });

  final ScenarioType? type;
  final Difficulty? difficulty;
  final ScenarioSort sort;
  final String query;

  ScenarioFilter copyWith({
    ScenarioType? type,
    Difficulty? difficulty,
    ScenarioSort? sort,
    String? query,
    bool clearType = false,
    bool clearDifficulty = false,
  }) {
    return ScenarioFilter(
      type: clearType ? null : (type ?? this.type),
      difficulty: clearDifficulty ? null : (difficulty ?? this.difficulty),
      sort: sort ?? this.sort,
      query: query ?? this.query,
    );
  }
}

/// 시나리오 데이터 소스.
/// 비동기(API) 기반 — UI는 로딩/에러/빈 상태를 함께 처리해야 한다.
abstract class ScenarioRepository {
  Future<List<Scenario>> query(ScenarioFilter filter);

  /// 페이지 단위 조회(더보기 페이지네이션용). [Page.hasNext] 로 추가 로드 여부 판단.
  Future<Page<Scenario>> queryPage(
    ScenarioFilter filter, {
    int page,
    int size,
  });

  Future<List<Scenario>> popular({int limit = 5});
  Future<Scenario> detail(String scenarioId);
}

/// 백엔드(`/api/scenarios`) 연동 구현체.
class ApiScenarioRepository implements ScenarioRepository {
  const ApiScenarioRepository({this._client});

  final ApiClient? _client;
  ApiClient get _api => _client ?? ApiClient.instance;

  @override
  Future<Page<Scenario>> queryPage(
    ScenarioFilter filter, {
    int page = 0,
    int size = 20,
  }) async {
    final data = await _api.get(
      '/api/scenarios',
      query: {
        if (filter.query.isNotEmpty) 'keyword': filter.query,
        if (filter.type != null) 'type': _typeToApi(filter.type!),
        if (filter.difficulty != null)
          'difficulty': _difficultyToApi(filter.difficulty!),
        'sort': _sortToApi(filter.sort),
        'page': page,
        'size': size,
      },
    );
    return Page<Scenario>.fromJson(
      data as Map<String, dynamic>,
      _fromSummaryJson,
    );
  }

  @override
  Future<List<Scenario>> query(ScenarioFilter filter) async =>
      (await queryPage(filter, page: 0, size: 50)).content;

  @override
  Future<List<Scenario>> popular({int limit = 5}) async {
    final data = await _api.get(
      '/api/scenarios',
      query: {'sort': 'popular', 'page': 0, 'size': limit},
    );
    final page = Page<Scenario>.fromJson(
      data as Map<String, dynamic>,
      _fromSummaryJson,
    );
    return page.content;
  }

  @override
  Future<Scenario> detail(String scenarioId) async {
    final data = await _api.get('/api/scenarios/$scenarioId');
    return _fromDetailJson(data as Map<String, dynamic>);
  }
}

// ── JSON → 앱 모델 매퍼 ──────────────────────────────────────────────────────

Scenario _fromSummaryJson(Map<String, dynamic> json) {
  final id = (json['scenarioId'] as num).toInt();
  final desc = json['description'] as String? ?? '';
  return Scenario(
    id: id.toString(),
    code: _synthCode(id),
    title: json['title'] as String? ?? '제목 없음',
    subtitle: desc,
    type: _typeFromApi(json['scenarioType'] as String?),
    difficulty: _difficultyFromApi(json['difficulty'] as String?),
    estimatedMinutes: (json['estimatedPlayTimeMinutes'] as num?)?.toInt() ?? 0,
    suspectsCount: (json['suspectCount'] as num?)?.toInt() ?? 0,
    evidenceCount: (json['evidenceCount'] as num?)?.toInt() ?? 0,
    rating: (json['averageRating'] as num?)?.toDouble() ?? 0,
    plays: (json['playCount'] as num?)?.toInt() ?? 0,
    tags: const [],
    synopsis: desc,
    thumbnailUrl: json['thumbnailUrl'] as String?,
  );
}

Scenario _fromDetailJson(Map<String, dynamic> json) {
  final id = (json['scenarioId'] as num).toInt();
  final creator = json['creator'] as Map<String, dynamic>?;
  return Scenario(
    id: id.toString(),
    code: _synthCode(id),
    title: json['title'] as String? ?? '제목 없음',
    subtitle: json['description'] as String? ?? '',
    type: _typeFromApi(json['scenarioType'] as String?),
    difficulty: _difficultyFromApi(json['difficulty'] as String?),
    estimatedMinutes: (json['estimatedPlayTimeMinutes'] as num?)?.toInt() ?? 0,
    suspectsCount: (json['suspectCount'] as num?)?.toInt() ?? 0,
    evidenceCount: (json['evidenceCount'] as num?)?.toInt() ?? 0,
    rating: (json['averageRating'] as num?)?.toDouble() ?? 0,
    plays: (json['playCount'] as num?)?.toInt() ?? 0,
    tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
    synopsis: json['synopsis'] as String? ?? json['description'] as String? ?? '',
    author: creator?['nickname'] as String?,
    thumbnailUrl: json['thumbnailUrl'] as String?,
  );
}

// 백엔드에는 표시용 코드(CL-XXX)가 없어 scenarioId로 합성한다.
String _synthCode(int id) => 'CL-${id.toString().padLeft(3, '0')}';

ScenarioType _typeFromApi(String? v) =>
    v == 'CUSTOM' ? ScenarioType.custom : ScenarioType.official;

String _typeToApi(ScenarioType t) =>
    t == ScenarioType.custom ? 'CUSTOM' : 'OFFICIAL';

Difficulty _difficultyFromApi(String? v) => switch (v) {
      'EASY' => Difficulty.easy,
      'HARD' => Difficulty.hard,
      _ => Difficulty.medium, // NORMAL
    };

String _difficultyToApi(Difficulty d) => switch (d) {
      Difficulty.easy => 'EASY',
      Difficulty.medium => 'NORMAL',
      Difficulty.hard => 'HARD',
    };

String _sortToApi(ScenarioSort s) => switch (s) {
      ScenarioSort.popular => 'popular',
      ScenarioSort.newest => 'latest',
      ScenarioSort.rating => 'rating',
    };

/// 전역 싱글턴 — 추후 DI 컨테이너로 교체 가능.
const ScenarioRepository scenarioRepo = ApiScenarioRepository();
