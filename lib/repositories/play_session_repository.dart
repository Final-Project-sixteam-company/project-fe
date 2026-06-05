// lib/repositories/play_session_repository.dart
import '../core/api/api_client.dart';
import '../models/play_models.dart';

/// 플레이 세션 전체 API(`/api/play-sessions/...`) 연동.
class PlaySessionRepository {
  const PlaySessionRepository({this._client});

  final ApiClient? _client;
  ApiClient get _api => _client ?? ApiClient.instance;

  /// 게임 세션 시작. 이미 진행 중이면 `SESSION_ALREADY_EXISTS`(409) ApiException.
  Future<PlaySessionInfo> createSession(int scenarioId) async {
    final data = await _api.post(
      '/api/play-sessions',
      body: {'scenarioId': scenarioId},
    );
    return PlaySessionInfo.fromJson(data as Map<String, dynamic>);
  }

  Future<DashboardInfo> dashboard(int sessionId) async {
    final data = await _api.get('/api/play-sessions/$sessionId/dashboard');
    return DashboardInfo.fromJson(data as Map<String, dynamic>);
  }

  /// 증거 목록. [includeLocked]=true 면 잠긴 증거도 마스킹된 형태로 포함.
  Future<List<PlayEvidence>> evidences(
    int sessionId, {
    bool includeLocked = false,
  }) async {
    final data = await _api.get(
      '/api/play-sessions/$sessionId/evidences',
      query: {'includeLocked': includeLocked},
    );
    return (data as List<dynamic>)
        .map((e) => PlayEvidence.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 증거 상세 조회. 목록보다 풍부한 본문(description)·관련 타임라인을 준다.
  /// 해금된 증거에 한해 호출한다(잠긴 증거 본문 누출 방지).
  Future<EvidenceDetail> evidenceDetail(int sessionId, int evidenceId) async {
    final data =
        await _api.get('/api/play-sessions/$sessionId/evidences/$evidenceId');
    return EvidenceDetail.fromJson(data as Map<String, dynamic>);
  }

  Future<List<PlaySuspect>> suspects(int sessionId) async {
    final data = await _api.get('/api/play-sessions/$sessionId/suspects');
    return (data as List<dynamic>)
        .map((e) => PlaySuspect.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PlayLocations> locations(int sessionId) async {
    final data = await _api.get('/api/play-sessions/$sessionId/locations');
    return PlayLocations.fromJson(data as Map<String, dynamic>);
  }

  Future<List<PlayHint>> hints(int sessionId) async {
    final data = await _api.get('/api/play-sessions/$sessionId/hints');
    return (data as List<dynamic>)
        .map((e) => PlayHint.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<HintUseResult> useHint(int sessionId, int hintId) async {
    final data =
        await _api.post('/api/play-sessions/$sessionId/hints/$hintId/use');
    return HintUseResult.fromJson(data as Map<String, dynamic>);
  }

  Future<void> abandon(int sessionId) async {
    await _api.post('/api/play-sessions/$sessionId/abandon');
  }

  // ── 심문 ───────────────────────────────────────────────────────────────────

  Future<InterrogationResult> interrogate(
    int sessionId, {
    required int suspectId,
    required QuestionType questionType,
    required String question,
    int? presentedEvidenceId,
  }) async {
    final data = await _api.post(
      '/api/play-sessions/$sessionId/interrogations',
      body: {
        'suspectId': suspectId,
        'questionType': questionTypeToApi(questionType),
        'question': question,
        'presentedEvidenceId': ?presentedEvidenceId,
      },
    );
    return InterrogationResult.fromJson(data as Map<String, dynamic>);
  }

  /// 심문 로그 조회. [suspectId] 지정 시 해당 용의자만.
  Future<List<InterrogationResult>> interrogationLogs(
    int sessionId, {
    int? suspectId,
  }) async {
    final data = await _api.get(
      '/api/play-sessions/$sessionId/interrogations',
      query: {'suspectId': ?suspectId},
    );
    return (data as List<dynamic>)
        .map((e) => InterrogationResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── 최종 추리 / 결과 ───────────────────────────────────────────────────────

  Future<FinalDeductionResult> submitFinalDeduction(
    int sessionId, {
    required int selectedCulpritId,
    required String motiveText,
    required String methodText,
    String? coverUpText,
    required List<int> selectedEvidenceIds,
  }) async {
    final data = await _api.post(
      '/api/play-sessions/$sessionId/final-deduction',
      body: {
        'selectedCulpritId': selectedCulpritId,
        'motiveText': motiveText,
        'methodText': methodText,
        'coverUpText': ?coverUpText,
        'selectedEvidenceIds': selectedEvidenceIds,
      },
    );
    return FinalDeductionResult.fromJson(data as Map<String, dynamic>);
  }

  Future<DeductionResult> result(int sessionId) async {
    final data = await _api.get('/api/play-sessions/$sessionId/result');
    return DeductionResult.fromJson(data as Map<String, dynamic>);
  }
}

/// 전역 싱글턴.
const PlaySessionRepository playSessionRepo = PlaySessionRepository();
