// lib/repositories/interrogation_repository.dart
//
// [보안 설계 원칙]
// Anthropic API를 앱에서 직접 호출하지 않는다.
//
// 이유:
//   1. x-api-key를 앱 바이너리에 포함하면 리버스 엔지니어링으로 노출된다.
//   2. 범인 정보(secret)는 백엔드 DB에만 존재해야 한다.
//      프롬프트 조립(어떤 정보를 AI에게 줄 것인가)은 백엔드 책임이다.
//   3. 호출 횟수 제한, 어뷰징 방지, 심문 로그 저장은 백엔드에서만 가능하다.
//
// 호출 흐름:
//   Flutter → POST api.clueroom.xyz/v1/interrogate
//           → 백엔드가 x-api-key 포함 후 Anthropic 호출
//           → 백엔드가 응답 반환

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ── 요청/응답 모델 ─────────────────────────────────────────────────────────────

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

class InterrogationResponse {
  const InterrogationResponse({
    required this.answer,
    required this.suspectId,
  });

  final String answer;
  final String suspectId;

  factory InterrogationResponse.fromJson(Map<String, dynamic> json) {
    return InterrogationResponse(
      answer: json['answer'] as String,
      suspectId: json['suspect_id'] as String,
    );
  }
}

// ── Repository 인터페이스 ──────────────────────────────────────────────────────

abstract class InterrogationRepository {
  Future<String> ask(InterrogationRequest request);
}

// ── 운영 구현체 ───────────────────────────────────────────────────────────────

class ApiInterrogationRepository implements InterrogationRepository {
  const ApiInterrogationRepository({
    required this.baseUrl,
    required this.getAuthToken,
  });

  /// 백엔드 베이스 URL. 환경별로 주입.
  final String baseUrl;

  /// JWT 토큰을 반환하는 콜백. AuthService 등에서 주입.
  final Future<String?> Function() getAuthToken;

  @override
  Future<String> ask(InterrogationRequest request) async {
    try {
      final token = await getAuthToken();

      final response = await http
          .post(
        Uri.parse('$baseUrl/v1/interrogate'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final parsed = InterrogationResponse.fromJson(data);
        return parsed.answer;
      }

      debugPrint(
        '[InterrogationRepository] error ${response.statusCode}: '
            '${response.body}',
      );
      return _fallback();
    } catch (e) {
      debugPrint('[InterrogationRepository] exception: $e');
      return _fallback();
    }
  }

  String _fallback() => '지금은 답변하기 어렵습니다.';
}

// ── 개발용 Mock 구현체 ────────────────────────────────────────────────────────
// 백엔드 없이 UI 개발·테스트할 때 사용한다.
// kDebugMode에서만 활성화하고, 릴리즈 빌드에서는 ApiInterrogationRepository 사용.

class MockInterrogationRepository implements InterrogationRepository {
  const MockInterrogationRepository();

  @override
  Future<String> ask(InterrogationRequest request) async {
    // 실제 네트워크 지연을 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 900));

    final q = request.question;
    final evidenceId = request.presentedEvidenceId;

    // 증거 제시 분기
    if (evidenceId != null) {
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

// ── 환경별 인스턴스 팩토리 ────────────────────────────────────────────────────

InterrogationRepository buildInterrogationRepository() {
  if (kDebugMode) {
    // 개발 환경: Mock 사용
    // 백엔드 연동 준비되면 아래 주석 해제 후 Mock 라인 제거
    return const MockInterrogationRepository();

    // return ApiInterrogationRepository(
    //   baseUrl: 'https://dev-api.clueroom.xyz',
    //   getAuthToken: () async => null, // AuthService.instance.token
    // );
  }

  // 운영 환경
  return ApiInterrogationRepository(
    baseUrl: 'https://api.clueroom.xyz',
    getAuthToken: () async {
      // TODO: AuthService.instance.token 연결
      return null;
    },
  );
}