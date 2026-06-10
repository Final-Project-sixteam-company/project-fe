# Frontend API Integration Guide

기준일: 2026-06-11

대상 repo: `C:\java\assignment\spring\start-up-fe`

목적:

- 백엔드 최신 계약에 맞춰 프론트 API 연동을 보강할 때 수정할 파일과 순서를 명확히 한다.
- drift를 단순 목록이 아니라 구현 가능한 작업 단위로 쪼갠다.
- 기능 변경 PR을 작게 나눠 리뷰 가능하게 만든다.

범위:

- Auth token wiring
- Active session recovery
- FCM device token registration
- Timeline API
- Scenario `canPlay`
- API client/test 보강

Evidence guidance와 suggested question UX는 별도 `FRONTEND_GUIDANCE_UX_IMPLEMENTATION_PLAN.md`에서 다룬다.

## 구현 순서

권장 순서:

1. Auth token wiring 정책 확정
2. Active session recovery
3. FCM device token registration
4. Timeline API
5. Scenario `canPlay`
6. API/model test 보강
7. lint cleanup

이 순서는 앱이 깨질 수 있는 인증/세션 문제를 먼저 닫고, UX 데이터 API를 뒤에 붙이는 기준이다.

## 공통 원칙

- API endpoint 문자열은 repository 계층에 둔다.
- 화면에서 직접 `ApiClient`를 호출하지 않는다.
- backend 공통 응답 `{success,data,error}` 파싱은 `ApiClient`가 담당한다.
- AI/채점처럼 오래 걸리는 요청은 `ApiConfig.aiTimeout`을 사용한다.
- optional backend field는 null-safe하게 파싱한다.
- 새 API model은 단위 테스트를 같이 추가한다.
- API 실패가 부가 기능이면 앱 진입을 막지 않는 best-effort로 처리한다.

## 1. Auth Token Wiring

### 목표

`AuthService`에 저장된 token을 `ApiClient`가 사용할 수 있게 연결한다.

### 현재 파일

- `lib/services/auth_service.dart`
- `lib/core/api/api_client.dart`
- `lib/main.dart`

### 현재 문제

`ApiClient.authTokenProvider`는 있지만 실제 연결이 없다.

### 구현 방향

`main.dart`에서 `AuthService.instance.init()` 이후 token provider를 연결한다.

```dart
await AuthService.instance.init();
ApiClient.instance.authTokenProvider = () => AuthService.instance.token;
```

필요 import:

```dart
import 'package:clueroom/core/api/api_client.dart';
```

### 정책 확인 필요

현재 `AuthService`는 token이 없으면 `mock_jwt_token`을 넣는다.

백엔드 인증 정책에 따라 둘 중 하나를 선택해야 한다.

| 정책 | 설명 |
|---|---|
| Mock token 유지 | backend가 `mock_jwt_token`을 허용하는 경우 |
| Token 없으면 null | backend가 mock token을 JWT로 검증해서 실패하는 경우 |

추천:

- 인증 강제 전까지는 token provider wiring만 하고, `mock_jwt_token`이 backend에서 유효한지 확인한다.
- 유효하지 않다면 `AuthService.init()`에서 mock token 자동 주입을 제거한다.

### 검증

1. debug proxy/log로 `Authorization` header 확인
2. token 없음 상태에서 공개 API 동작 확인
3. token 있음 상태에서 보호 API 동작 확인

### 테스트 후보

- `AuthService.init()` token fallback 정책 테스트
- `ApiClient`가 token provider 반환값을 header에 넣는지 test client로 검증

## 2. Active Session Recovery

### 목표

서버에 이미 진행 중인 세션이 있을 때 local storage가 없어도 이어갈 수 있게 한다.

### 백엔드 endpoint

```http
GET /api/play-sessions/active?scenarioId={scenarioId}
```

### 수정 파일

- `lib/repositories/play_session_repository.dart`
- `lib/controllers/game_session_controller.dart`
- `lib/screens/case_screen.dart`
- 필요 시 `lib/models/play_session_models.dart`

### Repository 추가

예상 형태:

```dart
Future<PlaySessionInfo?> activeSession(int scenarioId) async {
  try {
    final data = await _api.get(
      '/api/play-sessions/active',
      query: {'scenarioId': scenarioId},
    );
    if (data == null) return null;
    return PlaySessionInfo.fromJson(data as Map<String, dynamic>);
  } on ApiException catch (e) {
    if (e.isNotFound) return null;
    rethrow;
  }
}
```

백엔드가 active session 없음에 대해 `204`, `404`, `{data:null}` 중 무엇을 주는지에 따라 parsing을 맞춘다.

### Controller 흐름

권장 흐름:

```text
loadFromServer()
-> local saved session 있으면 _tryResume(saved)
-> 실패 또는 없음
-> _repo.activeSession(scenarioId)
-> active 있으면 resume + local save
-> active 없으면 createSession
-> createSession 409면 activeSession 재조회
```

### UI 흐름

409 conflict 화면은 두 액션으로 나눈다.

```text
기존 수사 이어하기
기존 수사 포기 후 새로 시작
```

주의:

- 자동 abandon은 금지한다.
- 사용자가 “포기 후 새로 시작”을 명시 선택한 경우에만 `POST /abandon` 호출한다.
- active session이 이미 `COMPLETED/ABANDONED`면 새 세션 생성으로 넘어간다.

### 완료 기준

- local storage가 비어 있어도 서버 active session을 이어간다.
- 409에서 dead-end가 되지 않는다.
- abandon 실패 시 local key를 무리하게 삭제하지 않는다.
- `flutter test`에 active session model parsing test 추가.

## 3. FCM Device Token Registration

### 목표

Firebase Messaging token을 백엔드에 등록한다.

### 백엔드 endpoint

```http
POST /api/device-tokens
```

### 수정 파일

- `lib/main.dart`
- 신규 후보: `lib/repositories/device_token_repository.dart`
- 또는 신규 후보: `lib/services/device_token_service.dart`

### 현재 문제

`_registerFcmTokenWithBackend()`가 debug print만 한다. TODO도 오래된 `PATCH /api/users/me`를 가리킨다.

### 구현 방향

Repository 후보:

```dart
class DeviceTokenRepository {
  const DeviceTokenRepository({ApiClient? client}) : _client = client;

  final ApiClient? _client;
  ApiClient get _api => _client ?? ApiClient.instance;

  Future<void> register({
    required String token,
    required String platform,
  }) async {
    await _api.post(
      '/api/device-tokens',
      body: {
        'token': token,
        'platform': platform,
      },
    );
  }
}
```

정확한 request field는 backend API spec을 기준으로 맞춘다.

### Best-effort 처리

FCM token 등록 실패가 앱 시작을 막으면 안 된다.

권장:

```dart
try {
  await deviceTokenRepo.register(...);
} catch (e) {
  debugPrint('FCM token registration failed: $e');
}
```

### 호출 시점

1. 앱 시작 후 token 획득 시
2. token refresh 시
3. 로그인/사용자 식별 상태가 바뀐 후 필요 시 재등록

### 완료 기준

- `_registerFcmTokenWithBackend`가 실제 backend endpoint 호출
- 실패해도 앱 진입은 계속
- `PATCH /api/users/me` TODO 제거
- backend DB/log에서 token 등록 확인

## 4. Timeline API

### 목표

sample timeline 대신 백엔드 timeline API를 사용한다.

### 백엔드 endpoint

```http
GET /api/play-sessions/{sessionId}/timeline
```

### 수정 파일

- `lib/repositories/play_session_repository.dart`
- `lib/controllers/game_session_controller.dart`
- `lib/screens/timeline_screen.dart`
- 신규/수정 모델: `lib/models/play_timeline_models.dart` 또는 `play_session_models.dart`

### 모델 후보

백엔드 응답 필드에 맞춰 조정해야 한다. 최소 UI 모델 후보:

```dart
class PlayTimelineEvent {
  const PlayTimelineEvent({
    required this.time,
    required this.title,
    this.description,
    this.eventType,
    this.conflict,
  });

  final String time;
  final String title;
  final String? description;
  final String? eventType;
  final String? conflict;
}
```

### Repository 추가

```dart
Future<List<PlayTimelineEvent>> timeline(int sessionId) async {
  final data = await _api.get('/api/play-sessions/$sessionId/timeline');
  return (data as List<dynamic>)
      .map((e) => PlayTimelineEvent.fromJson(e as Map<String, dynamic>))
      .toList();
}
```

### Controller 추가

- `_timeline` state 추가
- `_refreshAll()`에서 timeline도 best-effort 또는 core로 로딩할지 결정
- timeline 실패 시 플레이 전체를 깨지 않으려면 best-effort 권장

### Screen 변경

`TimelineScreen`은 `sampleCase.timeline` 대신 controller timeline을 사용한다.

필터 기준:

```text
전체
모순 발견
용의자 주장
```

서버 event type이 없다면 일단 전체 표시만 하고, 필터는 empty state로 처리한다.

### 완료 기준

- CL-001 외 시나리오도 서버 timeline 표시
- timeline 없음은 empty state
- API 실패는 error/empty state로 분리
- sample timeline은 fallback/history로만 남김

## 5. Scenario `canPlay`

### 목표

플레이 가능 여부를 local allowlist가 아니라 backend `canPlay`로 판단한다.

### 수정 파일

- `lib/models/scenario.dart`
- `lib/repositories/scenario_repository.dart`
- `lib/screens/scenario_detail_screen.dart`

### 모델 변경

```dart
class Scenario {
  ...
  final bool? canPlay;
}
```

### mapper 변경

```dart
canPlay: json['canPlay'] as bool?,
```

summary/detail 모두에서 파싱한다.

### 화면 변경

현재:

```dart
bool get _isPlayable => _kLocalPlayableIds.contains(widget.scenario.id);
```

변경 후보:

```dart
bool get _isPlayable =>
    _detailedScenario.canPlay ?? _kLocalPlayableIds.contains(widget.scenario.id);
```

후속으로 backend field가 안정화되면 `_kLocalPlayableIds`는 제거한다.

### 완료 기준

- backend `canPlay=false`면 시작 버튼 disabled
- backend `canPlay=true`면 local allowlist 없이 시작 가능
- scenario 추가 시 프론트 코드 수정 불필요

## 6. API Client / Model Test 보강

### 현재 테스트

파일: `test/models/play_models_test.dart`

현재는 모델 파싱 중심이다.

### 추가 권장 테스트

| 테스트 | 목적 |
|---|---|
| `PlaySessionInfo.fromJson` active session parsing | active endpoint 응답 안전성 |
| `Scenario.fromJson` 또는 mapper test | `canPlay` 파싱 |
| `PlayTimelineEvent.fromJson` | timeline API 응답 안전성 |
| `EvidenceGuidance.fromJson` | guidance 계약 안전성 |
| `question prefill policy` widget/unit | suggested question 자동 전송 방지 |

Repository test는 현재 DI/mock HTTP 구조가 약하므로, 먼저 model parsing test를 늘리는 것이 현실적이다.

## 7. PR 분리 제안

한 PR에 모두 넣지 않는다.

권장 PR:

1. `fix: wire auth token provider`
2. `feat: recover active play sessions`
3. `feat: register device tokens`
4. `feat: render timeline from backend`
5. `feat: use scenario canPlay`
6. `feat: add evidence guidance UX`
7. `chore: clean flutter analyze warnings`

Guidance UX는 화면/모델/navigation 변경이 크므로 별도 PR로 분리한다.

## 구현 전 확인 체크리스트

```text
[ ] backend API spec에서 request/response 필드 확인
[ ] endpoint가 prod에 배포되어 있는지 확인
[ ] optional/null 응답 정책 확인
[ ] 401/403/404/409 에러 UX 확인
[ ] 기존 sample/fallback 제거 범위 확인
[ ] flutter test 추가 범위 결정
```

## 구현 후 검증 체크리스트

```bash
flutter test
flutter analyze
```

수동 QA:

```text
[ ] 운영 API로 시나리오 목록/상세 조회
[ ] canPlay=false 시 시작 버튼 disabled
[ ] 새 세션 시작
[ ] local storage 삭제 후 active session 이어가기
[ ] 409 conflict에서 dead-end 없음
[ ] FCM token 등록 실패해도 앱 진입 가능
[ ] timeline 표시
[ ] 최종 추리 제출/결과 조회 정상
```
