// lib/repositories/play_session_repository.dart
//
// 게임 플레이 관련 API — PRD Section 9, 10, 11

import '../models/api_models.dart';
import '../services/api_client.dart';

abstract class PlaySessionRepository {
  Future<PlaySessionDto?> startSession(int scenarioId);
  Future<DashboardDto?> getDashboard(int sessionId);
  Future<List<LocationDto>> getLocations(int sessionId);
  Future<List<EvidenceDto>> getEvidences(int sessionId);
  Future<EvidenceDto?> getEvidenceDetail(int sessionId, int evidenceId);
  Future<bool> unlockEvidence(int sessionId, int evidenceId, String reason);
  Future<List<SuspectDto>> getSuspects(int sessionId);
  Future<SuspectDto?> getSuspectDetail(int sessionId, int suspectId);
  Future<List<TimelineEventDto>> getTimeline(int sessionId);
  Future<List<HintDto>> getHints(int sessionId);
  Future<HintUseResultDto?> useHint(int sessionId, int hintId);
  Future<FinalDeductionResultDto?> submitDeduction({
    required int sessionId,
    required int selectedCulpritId,
    required String motiveText,
    required String methodText,
    required String coverUpText,
    required List<int> selectedEvidenceIds,
  });
  Future<CaseResultDto?> getResult(int sessionId);
}

class ApiPlaySessionRepository implements PlaySessionRepository {
  const ApiPlaySessionRepository();

  @override
  Future<PlaySessionDto?> startSession(int scenarioId) async {
    final res = await ApiClient.instance.post(
      '/api/play-sessions',
      body: {'scenarioId': scenarioId},
      fromJson: (d) => PlaySessionDto.fromJson(d as Map<String, dynamic>),
    );
    return res.isSuccess ? res.data : null;
  }

  @override
  Future<DashboardDto?> getDashboard(int sessionId) async {
    final res = await ApiClient.instance.get(
      '/api/play-sessions/$sessionId/dashboard',
      fromJson: (d) => DashboardDto.fromJson(d as Map<String, dynamic>),
    );
    return res.isSuccess ? res.data : null;
  }

  @override
  Future<List<LocationDto>> getLocations(int sessionId) async {
    final res = await ApiClient.instance.get(
      '/api/play-sessions/$sessionId/locations',
      fromJson: (d) => (d as List<dynamic>)
          .map((e) => LocationDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return res.isSuccess ? res.data! : const [];
  }

  @override
  Future<List<EvidenceDto>> getEvidences(int sessionId) async {
    final res = await ApiClient.instance.get(
      '/api/play-sessions/$sessionId/evidences',
      fromJson: (d) => (d as List<dynamic>)
          .map((e) => EvidenceDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return res.isSuccess ? res.data! : const [];
  }

  @override
  Future<EvidenceDto?> getEvidenceDetail(
      int sessionId, int evidenceId) async {
    final res = await ApiClient.instance.get(
      '/api/play-sessions/$sessionId/evidences/$evidenceId',
      fromJson: (d) => EvidenceDto.fromJson(d as Map<String, dynamic>),
    );
    return res.isSuccess ? res.data : null;
  }

  @override
  Future<bool> unlockEvidence(
      int sessionId, int evidenceId, String reason) async {
    final res = await ApiClient.instance.post(
      '/api/play-sessions/$sessionId/evidences/$evidenceId/unlock',
      body: {'reason': reason},
      fromJson: (d) => d as Map<String, dynamic>,
    );
    return res.isSuccess;
  }

  @override
  Future<List<SuspectDto>> getSuspects(int sessionId) async {
    final res = await ApiClient.instance.get(
      '/api/play-sessions/$sessionId/suspects',
      fromJson: (d) => (d as List<dynamic>)
          .map((e) => SuspectDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return res.isSuccess ? res.data! : const [];
  }

  @override
  Future<SuspectDto?> getSuspectDetail(int sessionId, int suspectId) async {
    final res = await ApiClient.instance.get(
      '/api/play-sessions/$sessionId/suspects/$suspectId',
      fromJson: (d) => SuspectDto.fromJson(d as Map<String, dynamic>),
    );
    return res.isSuccess ? res.data : null;
  }

  @override
  Future<List<TimelineEventDto>> getTimeline(int sessionId) async {
    final res = await ApiClient.instance.get(
      '/api/play-sessions/$sessionId/timeline',
      fromJson: (d) => (d as List<dynamic>)
          .map((e) => TimelineEventDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return res.isSuccess ? res.data! : const [];
  }

  @override
  Future<List<HintDto>> getHints(int sessionId) async {
    final res = await ApiClient.instance.get(
      '/api/play-sessions/$sessionId/hints',
      fromJson: (d) => (d as List<dynamic>)
          .map((e) => HintDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return res.isSuccess ? res.data! : const [];
  }

  @override
  Future<HintUseResultDto?> useHint(int sessionId, int hintId) async {
    final res = await ApiClient.instance.post(
      '/api/play-sessions/$sessionId/hints/$hintId/use',
      fromJson: (d) => HintUseResultDto.fromJson(d as Map<String, dynamic>),
    );
    return res.isSuccess ? res.data : null;
  }

  @override
  Future<FinalDeductionResultDto?> submitDeduction({
    required int sessionId,
    required int selectedCulpritId,
    required String motiveText,
    required String methodText,
    required String coverUpText,
    required List<int> selectedEvidenceIds,
  }) async {
    final res = await ApiClient.instance.post(
      '/api/play-sessions/$sessionId/final-deduction',
      body: {
        'selectedCulpritId': selectedCulpritId,
        'motiveText': motiveText,
        'methodText': methodText,
        'coverUpText': coverUpText,
        'selectedEvidenceIds': selectedEvidenceIds,
      },
      fromJson: (d) =>
          FinalDeductionResultDto.fromJson(d as Map<String, dynamic>),
    );
    return res.isSuccess ? res.data : null;
  }

  @override
  Future<CaseResultDto?> getResult(int sessionId) async {
    final res = await ApiClient.instance.get(
      '/api/play-sessions/$sessionId/result',
      fromJson: (d) => CaseResultDto.fromJson(d as Map<String, dynamic>),
    );
    return res.isSuccess ? res.data : null;
  }
}

const PlaySessionRepository playSessionRepo = ApiPlaySessionRepository();