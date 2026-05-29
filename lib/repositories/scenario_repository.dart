// lib/repositories/scenario_repository.dart
import '../models/scenario.dart';
import '../models/sample_scenarios.dart';

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
      difficulty:
          clearDifficulty ? null : (difficulty ?? this.difficulty),
      sort: sort ?? this.sort,
      query: query ?? this.query,
    );
  }
}

/// 현재는 로컬 샘플 데이터 기반.
/// 추후 API 연동 시 이 클래스만 교체하면 UI 변경 불필요.
abstract class ScenarioRepository {
  List<Scenario> query(ScenarioFilter filter);
  List<Scenario> popular({int limit = 5});
}

class LocalScenarioRepository implements ScenarioRepository {
  const LocalScenarioRepository();

  @override
  List<Scenario> query(ScenarioFilter filter) {
    var list = List<Scenario>.from(sampleScenarios);

    // 텍스트 검색
    if (filter.query.isNotEmpty) {
      list = list
          .where(
            (s) =>
                s.title.contains(filter.query) ||
                s.tags.any((t) => t.contains(filter.query)) ||
                (s.author?.contains(filter.query) ?? false),
          )
          .toList();
    }

    // 타입 필터
    if (filter.type != null) {
      list = list.where((s) => s.type == filter.type).toList();
    }

    // 난이도 필터
    if (filter.difficulty != null) {
      list =
          list.where((s) => s.difficulty == filter.difficulty).toList();
    }

    // 정렬
    list = switch (filter.sort) {
      ScenarioSort.popular =>
        list..sort((a, b) => b.plays.compareTo(a.plays)),
      ScenarioSort.newest =>
        list..sort((a, b) => b.code.compareTo(a.code)),
      ScenarioSort.rating =>
        list..sort((a, b) => b.rating.compareTo(a.rating)),
    };

    return list;
  }

  @override
  List<Scenario> popular({int limit = 5}) {
    final sorted = List<Scenario>.from(sampleScenarios)
      ..sort((a, b) => b.plays.compareTo(a.plays));
    return sorted.take(limit).toList();
  }
}

/// 전역 싱글턴 — 추후 DI 컨테이너로 교체 가능
const ScenarioRepository scenarioRepo = LocalScenarioRepository();
