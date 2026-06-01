// lib/repositories/interrogation_repository.dart
//
// [보안 설계 원칙]
// Anthropic API는 앱에서 직접 호출하지 않는다.
// Flutter → POST /api/play-sessions/{id}/interrogations
//         → 백엔드가 프롬프트 조립 + Anthropic 호출 → 응답 반환

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/api_models.dart';
import '../services/api_client.dart';

class InterrogationRequest {
  const InterrogationRequest({
    required this.sessionId,
    required this.scenarioId,
    required this.suspectId,
    required this.question,
    required this.unlockedEvidenceIds,
    required this.conversationHistory,
    this.presentedEvidenceId,
  });

  final String sessionId;
  final String scenarioId;
  final String suspectId;
  final String question;
  final List<String> unlockedEvidenceIds;
  final List<Map<String, String>> conversationHistory;
  final String? presentedEvidenceId;

  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
    'scenario_id': scenarioId,
    'suspect_id': suspectId,
    'question': question,
    'unlocked_evidence_ids': unlockedEvidenceIds,
    'conversation_history': conversationHistory,
    if (presentedEvidenceId != null)
      'presented_evidence_id': presentedEvidenceId,
  };
}

abstract class InterrogationRepository {
  Future<String> ask(InterrogationRequest request);
}

// ── API 연동 구현체 ───────────────────────────────────────────────────────────

class ApiInterrogationRepository implements InterrogationRepository {
  const ApiInterrogationRepository();

  @override
  Future<String> ask(InterrogationRequest request) async {
    final sessionId = int.tryParse(request.sessionId);
    final suspectId = int.tryParse(request.suspectId);

    if (sessionId != null && suspectId != null) {
      return await _callStandardApi(
        sessionId: sessionId,
        suspectId: suspectId,
        request: request,
      );
    }
    // 로컬 샘플 시나리오용 레거시 엔드포인트
    return await _callLegacyEndpoint(request);
  }

  Future<String> _callStandardApi({
    required int sessionId,
    required int suspectId,
    required InterrogationRequest request,
  }) async {
    final evidenceId = int.tryParse(request.presentedEvidenceId ?? '');
    final res = await ApiClient.instance.post(
      '/api/play-sessions/$sessionId/interrogations',
      body: {
        'suspectId': suspectId,
        'questionType': evidenceId != null ? 'EVIDENCE_PRESENTED' : 'FREE',
        'question': request.question,
        if (evidenceId != null) 'presentedEvidenceId': evidenceId,
      },
      fromJson: (d) =>
          InterrogationResultDto.fromJson(d as Map<String, dynamic>),
    );
    if (res.isSuccess) return res.data!.answer;
    debugPrint('[Interrogation] API 실패: ${res.error}');
    return _fallback();
  }

  Future<String> _callLegacyEndpoint(InterrogationRequest request) async {
    try {
      final res = await ApiClient.instance.dio.post<Map<String, dynamic>>(
        '/v1/interrogate',
        data: request.toJson(),
      );
      if (res.statusCode == 200 && res.data != null) {
        return res.data!['answer'] as String? ?? _fallback();
      }
      return _fallback();
    } on DioException catch (e) {
      debugPrint('[Interrogation] legacy 오류: ${e.message}');
      return _fallback();
    }
  }

  String _fallback() => '지금은 답변하기 어렵습니다.';
}

// ── Mock 구현체 ───────────────────────────────────────────────────────────────

class MockInterrogationRepository implements InterrogationRepository {
  const MockInterrogationRepository();

  @override
  Future<String> ask(InterrogationRequest request) async {
    await Future.delayed(const Duration(milliseconds: 900));

    final q = request.question;
    if (request.presentedEvidenceId != null) {
      return '그 증거가 저와 무슨 관계가 있는지 모르겠습니다.';
    }
    if (q.contains('10시') || q.contains('어디')) {
      return '그 시간엔 이미 퇴근한 상태였습니다. CCTV를 확인해보시면 됩니다.';
    }
    if (q.contains('관계') || q.contains('피해자')) {
      return '업무적인 관계입니다. 개인적인 감정은 없었어요.';
    }
    if (q.contains('알리바이')) {
      return 'CCTV와 퇴근 기록이 있습니다. 확인하시면 될 겁니다.';
    }
    return '그 부분에 대해서는 드릴 말씀이 없습니다.';
  }
}

// ── 팩토리 ────────────────────────────────────────────────────────────────────

InterrogationRepository buildInterrogationRepository() {
  if (kDebugMode) return const MockInterrogationRepository();
  return const ApiInterrogationRepository();
}