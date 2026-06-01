// lib/repositories/scenario_repository.dart
import '../models/scenario.dart';
import '../models/api_models.dart';
import '../models/sample_scenarios.dart';
import '../services/api_client.dart';

enum ScenarioSort { popular, newest, rating }

class ScenarioFilter {
  const ScenarioFilter({
    this.type,
    this.difficulty,
    this.sort = ScenarioSort.popular,
    this.query = '',
    this.page = 0,
    this.size = 20,
  });

  final ScenarioType? type;
  final Difficulty? difficulty;
  final ScenarioSort sort;
  final String query;
  final int page;
  final int size;

  ScenarioFilter copyWith({
    ScenarioType? type,
    Difficulty? difficulty,
    ScenarioSort? sort,
    String? query,
    int? page,
    bool clearType = false,
    bool clearDifficulty = false,
  }) {
    return ScenarioFilter(
      type: clearType ? null : (type ?? this.type),
      difficulty: clearDifficulty ? null : (difficulty ?? this.difficulty),
      sort: sort ?? this.sort,
      query: query ?? this.query,
      page: page ?? this.page,
      size: size,
    );
  }

  Map<String, String> toQueryParams() {
    final params = <String, String>{
      'sort': sort == ScenarioSort.popular
          ? 'popular'
          : sort == ScenarioSort.newest
          ? 'latest'
          : 'rating',
      'page': '$page',
      'size': '$size',
    };
    if (query.isNotEmpty) params['keyword'] = query;
    if (type != null) {
      params['type'] =
      type == ScenarioType.official ? 'OFFICIAL' : 'CUSTOM';
    }
    if (difficulty != null) {
      params['difficulty'] = difficulty == Difficulty.easy
          ? 'EASY'
          : difficulty == Difficulty.hard
          ? 'HARD'
          : 'NORMAL';
    }
    return params;
  }
}

abstract class ScenarioRepository {
  Future<List<Scenario>> query(ScenarioFilter filter);
  Future<List<Scenario>> popular({int limit = 5});
  Future<Scenario?> getDetail(String scenarioId);
}

/// API 연동 구현체.
/// 서버 오류 시 로컬 샘플 데이터로 폴백한다.
class ApiScenarioRepository implements ScenarioRepository {
  const ApiScenarioRepository();

  static const _fallback = LocalScenarioRepository();

  @override
  Future<List<Scenario>> query(ScenarioFilter filter) async {
    final result = await ApiClient.instance.get(
      '/api/scenarios',
      query: filter.toQueryParams(),
      auth: false,
      fromJson: (data) =>
          ScenarioListResponseDto.fromJson(data as Map<String, dynamic>),
    );
    if (result.isSuccess) {
      return result.data!.content.map(_dtoToScenario).toList();
    }
    return _fallback.query(filter);
  }

  @override
  Future<List<Scenario>> popular({int limit = 5}) async {
    final result = await ApiClient.instance.get(
      '/api/scenarios',
      query: {'sort': 'popular', 'size': '$limit'},
      auth: false,
      fromJson: (data) =>
          ScenarioListResponseDto.fromJson(data as Map<String, dynamic>),
    );
    if (result.isSuccess) {
      return result.data!.content.map(_dtoToScenario).toList();
    }
    return _fallback.popular(limit: limit);
  }

  @override
  Future<Scenario?> getDetail(String scenarioId) async {
    final result = await ApiClient.instance.get(
      '/api/scenarios/$scenarioId',
      auth: false,
      fromJson: (data) =>
          ScenarioDetailDto.fromJson(data as Map<String, dynamic>),
    );
    if (result.isSuccess) return _detailDtoToScenario(result.data!);
    // 폴백: 로컬 샘플에서 검색
    try {
      return sampleScenarios.firstWhere((s) => s.id == scenarioId);
    } catch (_) {
      return null;
    }
  }

  static Scenario _dtoToScenario(ScenarioSummaryDto d) => Scenario(
    id: '${d.scenarioId}',
    code: 'CL-${d.scenarioId.toString().padLeft(3, '0')}',
    title: d.title,
    subtitle: d.description,
    type: d.scenarioType == 'OFFICIAL'
        ? ScenarioType.official
        : ScenarioType.custom,
    difficulty: _parseDifficulty(d.difficulty),
    estimatedMinutes: d.estimatedPlayTimeMinutes,
    suspectsCount: d.suspectCount,
    evidenceCount: d.evidenceCount,
    rating: d.averageRating,
    plays: d.playCount,
    tags: const [],
    synopsis: d.description,
  );

  static Scenario _detailDtoToScenario(ScenarioDetailDto d) => Scenario(
    id: '${d.scenarioId}',
    code: 'CL-${d.scenarioId.toString().padLeft(3, '0')}',
    title: d.title,
    subtitle: d.synopsis,
    type: d.scenarioType == 'OFFICIAL'
        ? ScenarioType.official
        : ScenarioType.custom,
    difficulty: _parseDifficulty(d.difficulty),
    estimatedMinutes: d.estimatedPlayTimeMinutes,
    suspectsCount: d.suspectCount,
    evidenceCount: d.evidenceCount,
    rating: d.averageRating,
    plays: d.playCount,
    tags: d.tags,
    synopsis: d.synopsis,
  );

  static Difficulty _parseDifficulty(String s) => switch (s) {
    'EASY' => Difficulty.easy,
    'HARD' => Difficulty.hard,
    _ => Difficulty.medium,
  };
}

/// 로컬 샘플 구현체 — 폴백 전용
class LocalScenarioRepository implements ScenarioRepository {
  const LocalScenarioRepository();

  @override
  Future<List<Scenario>> query(ScenarioFilter filter) async {
    var list = List<Scenario>.from(sampleScenarios);

    if (filter.query.isNotEmpty) {
      list = list
          .where((s) =>
      s.title.contains(filter.query) ||
          s.tags.any((t) => t.contains(filter.query)) ||
          (s.author?.contains(filter.query) ?? false))
          .toList();
    }
    if (filter.type != null) {
      list = list.where((s) => s.type == filter.type).toList();
    }
    if (filter.difficulty != null) {
      list = list.where((s) => s.difficulty == filter.difficulty).toList();
    }
    list = switch (filter.sort) {
      ScenarioSort.popular => list..sort((a, b) => b.plays.compareTo(a.plays)),
      ScenarioSort.newest => list..sort((a, b) => b.code.compareTo(a.code)),
      ScenarioSort.rating => list..sort((a, b) => b.rating.compareTo(a.rating)),
    };
    return list;
  }

  @override
  Future<List<Scenario>> popular({int limit = 5}) async {
    final sorted = List<Scenario>.from(sampleScenarios)
      ..sort((a, b) => b.plays.compareTo(a.plays));
    return sorted.take(limit).toList();
  }

  @override
  Future<Scenario?> getDetail(String scenarioId) async {
    try {
      return sampleScenarios.firstWhere((s) => s.id == scenarioId);
    } catch (_) {
      return null;
    }
  }
}

const ScenarioRepository scenarioRepo = ApiScenarioRepository();