# Frontend / Backend Drift

기준일: 2026-06-11

대상 repo: `C:\java\assignment\spring\start-up-fe`

백엔드 기준 repo: `C:\java\assignment\spring\start-up`

이 문서는 현재 Flutter 프론트 구현과 Spring Boot 백엔드 최신 계약 사이의 차이를 정리한다. 목표는 blame이 아니라 수정 순서를 명확히 하는 것이다.

## 우선순위 기준

| 우선순위 | 의미 |
|---|---|
| P0 | 백엔드 설정/운영 전환 시 앱이 깨질 수 있는 항목 |
| P1 | MVP UX 또는 최신 백엔드 계약과 직접 충돌하는 항목 |
| P2 | 기능은 돌아가지만 유지보수/문서/품질상 정리해야 하는 항목 |
| P3 | 이후 개선 또는 polish |

## 요약

| 우선순위 | Drift | 현재 영향 | 수정 대상 |
|---|---|---|---|
| P0 | 인증 강제 모드 대비 부족 | backend auth enforcement 시 API 요청 실패 가능 | `AuthService`, `ApiClient`, app bootstrap |
| P0/P1 | active session 복구 미사용 | 409 세션 충돌 시 다른 기기/브라우저 세션 복구 불가 | `PlaySessionRepository`, `GameSessionController`, `CaseScreen` |
| P1 | FCM device token 등록 미구현 | 알림 token이 backend에 저장되지 않음 | `main.dart`, `AuthService`, 신규 repository/service |
| P1 | evidence guidance 미구현 | 백엔드 #57 guidance 계약이 UI에 반영되지 않음 | evidence model/detail screen/interrogation navigation |
| P1 | suggested question UX 계약 불일치 | hardcoded chip 자동 전송. prefill-only 계약 위반 | `InterrogationChatScreen`, guidance model |
| P1 | timeline API 미사용 | 서버 시나리오 타임라인을 보여주지 못함 | `PlaySessionRepository`, `GameSessionController`, `TimelineScreen` |
| P2 | scenario `canPlay` 미반영 | 플레이 가능 시나리오를 local allowlist로 관리 | `Scenario`, `ScenarioRepository`, `ScenarioDetailScreen` |
| P2 | 과거 문서/초안 보존 | 원문은 archive에 보존됐고, 루트 `api-spec.md`는 notice로 축소됨 | `api-spec.md`, `docs/archive/*` |
| P2 | `flutter analyze` warning/info | PR 품질 gate로 쓰기 어려움 | lint 대상 파일 |
| P3 | 시나리오 제작/내 기록/마이페이지 | placeholder 또는 local/sample 중심 | 관련 screens/repositories |

## P0. 인증 강제 모드 대비 부족

### 현재 상태

관련 파일:

- `lib/services/auth_service.dart`
- `lib/core/api/api_client.dart`
- `lib/main.dart`

현재 `AuthService`는 토큰 저장/삭제 기능만 있고, 토큰이 없으면 `mock_jwt_token`을 넣는다. `ApiClient`에는 `authTokenProvider` hook이 있지만 app bootstrap에서 `AuthService.instance.token`과 연결되지 않는다.

### 왜 문제인가

현재 백엔드는 MockUserProvider/호환 모드로 프론트 요청을 받아줄 수 있지만, 운영에서 인증 강제가 켜지면 `Authorization` header가 없는 요청은 실패할 수 있다.

### 수정 방향

1. `main.dart`에서 `AuthService.init()` 이후 `ApiClient.instance.authTokenProvider`를 연결한다.
2. 로그인 도입 전이면 backend가 허용하는 dev/mock auth 정책을 문서화한다.
3. 실제 auth API가 확정되면 login/refresh/logout/me flow를 추가한다.

예상 형태:

```dart
await AuthService.instance.init();
ApiClient.instance.authTokenProvider = () => AuthService.instance.token;
```

주의:

- backend가 `mock_jwt_token`을 실제 JWT로 검증하지 않는다면 이 값은 오히려 실패 원인이 될 수 있다.
- 인증 강제 전환 전에는 backend와 token 정책을 맞춰야 한다.

### 완료 기준

- API 요청에 의도한 `Authorization` header가 붙는지 확인
- 인증 미필요/mock 모드와 인증 강제 모드의 동작이 문서화됨
- 로그아웃 시 token clear 후 보호 API 호출 UX가 정의됨

## P0/P1. Active Session 복구 미사용

### 현재 상태

관련 파일:

- `lib/repositories/play_session_repository.dart`
- `lib/controllers/game_session_controller.dart`
- `lib/screens/case_screen.dart`

현재 프론트는 `SharedPreferences`의 `active_play_session_{scenarioId}` 값이 있으면 resume을 시도한다. 값이 없고 `POST /api/play-sessions`가 409를 반환하면 사용자는 자동 복구를 못 한다.

### 백엔드 기준

최신 백엔드 계약은 active session 조회 endpoint를 제공하는 방향이다.

```http
GET /api/play-sessions/active?scenarioId={scenarioId}
```

### 왜 문제인가

다른 기기, 다른 브라우저, 앱 재설치, local storage 손실 후에는 서버에 PLAYING 세션이 있어도 프론트가 sessionId를 모른다. 그러면 `POST /api/play-sessions`는 409가 나고, 프론트는 기존 세션으로 이어갈 수 없다.

### 수정 방향

1. `PlaySessionRepository`에 `activeSession(int scenarioId)` 추가
2. `GameSessionController.loadFromServer()` 시작 시 local saved session보다 server active session을 먼저 확인하거나, local 실패 후 확인
3. 409 발생 시 active endpoint 재조회
4. 사용자는 “이어하기 / 포기하고 새로 시작” 선택 가능

추천 흐름:

```text
진입
-> local saved session 있으면 resume 시도
-> 실패 또는 없음
-> GET /active?scenarioId=
-> active session 있으면 resume
-> 없으면 POST /play-sessions
-> 409이면 GET /active 재시도
```

### 완료 기준

- local 저장 session이 없어도 server active session으로 이어가기 가능
- 409 화면에서 “기존 세션 이어하기”와 “포기 후 새로 시작”을 구분
- 자동 abandon은 사용자가 명시적으로 선택한 경우에만 실행

## P1. FCM Device Token 등록 미구현

### 현재 상태

관련 파일:

- `lib/main.dart`
- `android/app/src/main/AndroidManifest.xml`

현재 Firebase Messaging 초기화, 권한 요청, token 획득, token refresh listener는 있다. 하지만 `_registerFcmTokenWithBackend()`는 debug print만 하고, TODO도 오래된 `PATCH /api/users/me`를 가리킨다.

### 백엔드 기준

최신 backend endpoint 기준:

```http
POST /api/device-tokens
```

### 왜 문제인가

운영 알림/QA 알림/리텐션 알림을 보내려면 백엔드가 device token을 알아야 한다. 현재는 앱에서 token을 받아도 서버에 저장되지 않는다.

### 수정 방향

1. device token request DTO 추가
2. repository 또는 service 추가
3. 로그인/익명/mock user 정책과 연결
4. token refresh 시 재등록
5. 로그아웃 시 필요하면 token revoke/delete 정책 추가

### 완료 기준

- 앱 시작 또는 로그인 후 `POST /api/device-tokens` 호출
- token refresh 시 재등록
- backend 로그/DB에서 token 등록 확인
- 실패해도 앱 진입을 막지 않는 best-effort 처리

## P1. Evidence Guidance 미구현

### 현재 상태

관련 파일:

- `lib/models/play_evidence_models.dart`
- `lib/screens/evidence_detail_screen.dart`
- `lib/screens/evidence_detail_widgets.dart`

현재 `EvidenceDetail`은 `description`, `relatedSuspects`, `relatedTimelineEvents`만 파싱한다. 백엔드 guidance 응답은 파싱하지 않는다.

### 백엔드 기준

증거 상세 응답에 optional `guidance`가 추가되는 계약이다.

```json
{
  "guidance": {
    "readingPoints": [],
    "compareEvidences": [],
    "suggestedQuestions": []
  }
}
```

### 왜 문제인가

QA에서 나온 “증거를 봐도 뭘 비교해야 할지 모르겠다”는 문제가 이 guidance UX로 해결될 예정이다. 백엔드가 데이터를 내려줘도 프론트가 표시하지 않으면 UX 개선 효과가 없다.

### 수정 방향

1. `EvidenceGuidance`, `CompareEvidenceInfo`, `SuggestedQuestionInfo` 모델 추가
2. `EvidenceDetail.fromJson()`에서 `guidance` 파싱
3. evidence detail 화면에 아래 섹션 추가
4. suggested question tap 시 심문 화면으로 이동하되 자동 전송 금지

UI 섹션 후보:

```text
관찰 포인트
함께 볼 증거
이 증거로 물어볼 질문
```

### 완료 기준

- guidance가 없으면 기존 화면 유지
- readingPoints가 있으면 bullet/list로 표시
- locked compare evidence는 `evidenceCode` 없이 title/lock state/unlockHint만 표시
- suggested question은 prefill-only로 동작

## P1. Suggested Question UX 계약 불일치

### 현재 상태

관련 파일:

- `lib/screens/interrogation_chat_screen.dart`
- `lib/models/play_interrogation_models.dart`

현재 심문 화면에는 hardcoded `_suggestedQuestions`가 있고, chip을 누르면 즉시 `_sendMessage(q, questionType: QuestionType.recommended)`가 실행된다.

### 백엔드/UX 기준

Guidance suggested question 정책:

```text
자동 전송 금지
입력창 prefill만 허용
사용자가 직접 전송 버튼을 눌러야 함
증거 기반 질문은 EVIDENCE_PRESENTED + presentedEvidenceId 사용
target suspect가 현재 플레이에서 유효하지 않으면 chip 숨김/비활성화
```

### 왜 문제인가

추천 질문은 사실상 시스템이 고른 AI 입력이다. 자동 전송되면 사용자가 AI 호출과 증거 제시를 통제하지 못한다. 또한 `RECOMMENDED`는 guidance evidence path와 맞지 않는다.

### 수정 방향

1. hardcoded global suggested question은 제거하거나 fallback 도움말로 격하
2. evidence detail guidance에서 넘어온 question을 `InterrogationChatScreen` 초기 입력값으로 전달
3. `presentedEvidenceId`가 있으면 `EVIDENCE_PRESENTED`로 전송
4. 전송은 사용자가 send button을 누를 때만 실행

### 완료 기준

- chip tap만으로 AI API 호출이 발생하지 않음
- 입력창에 question이 prefill되고 cursor가 끝에 위치
- 기존 draft를 덮어쓸지 정책이 명확함
- evidence-based question은 `presentedEvidenceId` 포함

## P1. Timeline API 미사용

### 현재 상태

관련 파일:

- `lib/screens/timeline_screen.dart`
- `lib/models/sample_case.dart`
- `lib/repositories/play_session_repository.dart`

현재 timeline 화면은 `sampleCase.timeline`을 사용한다. 백엔드 timeline API 호출 메서드가 없다.

### 백엔드 기준

```http
GET /api/play-sessions/{sessionId}/timeline
```

### 왜 문제인가

공식 시나리오별 timeline seed가 백엔드에 있어도 프론트 화면에는 반영되지 않는다. CL-001 외 시나리오에서는 “타임라인 준비 중”으로 보일 수 있다.

### 수정 방향

1. `TimelineEvent` DTO 추가
2. `PlaySessionRepository.timeline(sessionId)` 추가
3. `GameSessionController`에 timeline state 추가
4. `TimelineScreen`이 sample fallback 대신 controller timeline 사용
5. API 실패 시 empty/error state 분리

### 완료 기준

- 서버 timeline 이벤트 표시
- conflict/suspect/all filter가 서버 데이터 기준으로 동작
- 데이터 없는 시나리오는 empty state
- CL-001 sample fallback은 제거 또는 archive 처리

## P2. Scenario `canPlay` 미반영

### 현재 상태

관련 파일:

- `lib/models/scenario.dart`
- `lib/repositories/scenario_repository.dart`
- `lib/screens/scenario_detail_screen.dart`

현재 상세 화면은 `_kLocalPlayableIds = {'1', '4', '5', '10', '11'}`로 플레이 가능 시나리오를 하드코딩한다.

### 왜 문제인가

백엔드 seed/공개 상태가 바뀌면 앱 배포 없이 플레이 가능 여부를 바꿀 수 없다. 문서/운영 상태와 앱 UI가 어긋날 수 있다.

### 수정 방향

1. `Scenario` 모델에 `canPlay` 추가
2. summary/detail mapper에서 `canPlay` 파싱
3. `ScenarioDetailScreen._isPlayable`을 backend 값 기반으로 변경
4. fallback은 backend 필드가 null일 때만 사용

### 완료 기준

- backend `canPlay=false`면 시작 버튼 비활성화
- local allowlist 제거 또는 fallback으로만 유지
- QA 시나리오 추가 시 프론트 코드 수정 불필요

## P2. 과거 문서/초안 보존

### 현재 상태

관련 파일:

- `api-spec.md`
- `docs/archive/README.md`
- `docs/archive/frontend-legacy-20260602/api-spec_mvp-v0.1_legacy.md`
- `docs/archive/frontend-legacy-20260602/backend-requests_2026-06-02_v1.md`
- `docs/archive/frontend-legacy-20260602/backend-handoff-basic-gameplay_2026-06-04.md`
- `docs/archive/frontend-legacy-20260602/ux-fix-plan_2026-06-02.md`

과거 기준 문서는 삭제하지 않고 archive로 이동했다. 루트 `api-spec.md`는 최신 API 정본이 아니라는 notice로 축소했다.

예:

- timeline/locations 미구현 전제
- active endpoint 404 전제
- 구 auth endpoint 초안
- 추천 질문 endpoint 초안

### 수정 방향

1. 새 구현/리뷰 기준은 CURRENT 문서만 사용
2. archive 문서는 근거 추적용으로만 사용
3. 구현 PR이 들어오면 drift 문서의 항목을 해결 상태로 갱신
4. 필요하면 archive 원문 상단에 historical 경고 배너 추가

### 완료 기준

- 새 팀원이 루트 문서만 보고 오래된 API를 정본으로 착각하지 않음
- 문서 index에서 CURRENT/HISTORICAL 상태가 명확함

## P2. Analyze warning/info

### 현재 상태

최근 확인:

```text
flutter analyze: 25 issues found
```

주요 유형:

- unnecessary underscores
- unused local variable/import
- unused element parameter
- null-aware collection suggestion
- doc comment angle bracket warning

### 수정 방향

기능 PR과 분리해서 lint cleanup PR로 처리하는 편이 안전하다.

### 완료 기준

```text
flutter analyze: PASS
flutter test: PASS
```

## P3. Placeholder / 샘플 중심 화면

| 항목 | 현재 상태 | 후속 |
|---|---|---|
| 시나리오 제작 | AppShell 만들기 탭 placeholder | 제작 기능 범위 확정 후 별도 PR |
| 내 기록 | 구현 상태 후속 확인 필요 | `GET /api/play-sessions/me` 연동 여부 결정 |
| 마이페이지 | profile 하드코딩, 메뉴 대부분 준비 중 | auth/user API 확정 후 연동 |
| 리뷰/bookmark | 일부 local/sample 중심 | backend community API 범위 재확인 |

## 권장 구현 순서

1. Auth token wiring 정책 확정
2. Active session recovery
3. FCM device token registration
4. Evidence guidance model + detail UI
5. Suggested question prefill-only navigation
6. Timeline API
7. Scenario canPlay
8. Analyze cleanup
9. 오래된 문서 흡수/아카이브

이 순서는 앱이 깨질 수 있는 P0를 먼저 닫고, QA에서 확인된 진행성 UX 문제를 다음으로 닫는 기준이다.
