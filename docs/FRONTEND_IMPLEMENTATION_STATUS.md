# Frontend Implementation Status

기준일: 2026-06-11

대상 repo: `start-up-fe`

> 상태: HISTORICAL SNAPSHOT.
> 이 문서는 2026-06-11 당시 Flutter 앱 구현 상태를 보존한 기록이다.
> 최신 Android 앱 정본은 [../README.md](../README.md)를 따른다.
> 특히 `flutter analyze 25 issues`, auth partial, active session/timeline/guidance 미구현 표기는 당시 상태이며, 현재 release/readme 상태로 해석하지 않는다.
> 최신 공개 요약은 `32 PASS`, `flutter analyze No issues`, OAuth/session/gameplay API 연동, active session recovery 기준이다.

이 문서는 2026-06-11 당시 Flutter 코드가 실제로 구현한 범위를 정리한다. 최신 구현 상태는 루트 README를 우선한다.

## 요약

| 영역 | 상태 | 설명 |
|---|---|---|
| 앱 셸/홈 | IMPLEMENTED | 홈, 라이브러리, 기록, 만들기 placeholder, 마이페이지 탭 구조 |
| 시나리오 목록/상세 | IMPLEMENTED | backend `GET /api/scenarios`, `GET /api/scenarios/{id}` 연동 |
| 플레이 세션 생성 | IMPLEMENTED | `POST /api/play-sessions` 연동. active session 복구는 로컬 저장 중심 |
| 사건 대시보드 | IMPLEMENTED | dashboard 로딩, HUD timer/evidence count 표시 |
| 현장 정보 | PARTIAL | backend locations 연동. 데이터 없으면 CL-001 샘플 fallback |
| 증거 목록/상세 | PARTIAL | backend evidence API 연동. guidance 미구현 |
| 용의자/증인 | IMPLEMENTED | suspects API 연동, 증인/용의자 필터, 상세/심문 진입 |
| AI 심문 | PARTIAL | interrogation API 연동. suggested question은 hardcoded + auto-send |
| 힌트 | IMPLEMENTED | hints 목록/사용 API 연동 |
| 타임라인 | NOT_IMPLEMENTED | backend timeline API 미사용. sample timeline만 사용 |
| 최종 추리 제출 | IMPLEMENTED | final-deduction API 연동 |
| 결과 화면 | IMPLEMENTED | result API polling/표시 |
| 인증 | PARTIAL | token 저장 서비스만 있음. 실제 로그인/API token wiring 없음 |
| FCM | PARTIAL | Firebase init/token 획득. backend 등록 미구현 |
| 시나리오 제작 | PLACEHOLDER | 앱 셸의 만들기 탭은 준비 중 화면 |
| 테스트 | PARTIAL | 모델 파싱 테스트만 있음 |

## 실행/환경 구현

| 파일 | 구현 내용 |
|---|---|
| `lib/core/api/api_config.dart` | 운영 URL, 로컬 URL, `API_BASE_URL` dart-define override, 일반/AI timeout |
| `lib/core/api/api_client.dart` | 공통 `{success,data,error}` 응답 파싱, JSON encode/decode, timeout/network/parse error 정규화 |
| `android/app/src/debug/AndroidManifest.xml` | debug build에서 cleartext HTTP 허용 |
| `android/app/src/main/AndroidManifest.xml` | `POST_NOTIFICATIONS` 권한 선언 |
| `android/app/build.gradle.kts` | Android applicationId `xyz.clueroom.clueroom`, Google services plugin |

현재 디버그 기본값:

```text
Android emulator: http://10.0.2.2:18080
desktop/iOS simulator: http://localhost:18080
release: https://api.clueroom.xyz
```

## API 계층 구현 상태

### ScenarioRepository

파일: `lib/repositories/scenario_repository.dart`

| 메서드 | Endpoint | 상태 |
|---|---|---|
| `queryPage` | `GET /api/scenarios` | IMPLEMENTED |
| `query` | `GET /api/scenarios` | IMPLEMENTED |
| `popular` | `GET /api/scenarios?sort=popular` | IMPLEMENTED |
| `detail` | `GET /api/scenarios/{scenarioId}` | IMPLEMENTED |

특이사항:

- backend에 표시용 `CL-XXX` 코드가 없어 scenarioId로 합성한다.
- `canPlay`는 모델에 반영되어 있지 않다.
- bookmark는 backend API가 아니라 로컬 `SharedPreferences` 기반이다.

### PlaySessionRepository

파일: `lib/repositories/play_session_repository.dart`

| 메서드 | Endpoint | 상태 |
|---|---|---|
| `createSession` | `POST /api/play-sessions` | IMPLEMENTED |
| `dashboard` | `GET /api/play-sessions/{sessionId}/dashboard` | IMPLEMENTED |
| `evidences` | `GET /api/play-sessions/{sessionId}/evidences` | IMPLEMENTED |
| `evidenceDetail` | `GET /api/play-sessions/{sessionId}/evidences/{evidenceId}` | IMPLEMENTED |
| `suspects` | `GET /api/play-sessions/{sessionId}/suspects` | IMPLEMENTED |
| `locations` | `GET /api/play-sessions/{sessionId}/locations` | IMPLEMENTED |
| `hints` | `GET /api/play-sessions/{sessionId}/hints` | IMPLEMENTED |
| `useHint` | `POST /api/play-sessions/{sessionId}/hints/{hintId}/use` | IMPLEMENTED |
| `abandon` | `POST /api/play-sessions/{sessionId}/abandon` | IMPLEMENTED |
| `interrogate` | `POST /api/play-sessions/{sessionId}/interrogations` | IMPLEMENTED |
| `interrogationLogs` | `GET /api/play-sessions/{sessionId}/interrogations` | IMPLEMENTED |
| `submitFinalDeduction` | `POST /api/play-sessions/{sessionId}/final-deduction` | IMPLEMENTED |
| `result` | `GET /api/play-sessions/{sessionId}/result` | IMPLEMENTED |

미구현:

- `GET /api/play-sessions/active?scenarioId=...`
- `GET /api/play-sessions/{sessionId}/timeline`
- `POST /api/device-tokens`

## 상태 관리 구현

파일: `lib/controllers/game_session_controller.dart`

구현됨:

- 시나리오 ID를 backend numeric ID로 변환
- `POST /api/play-sessions`로 세션 생성
- local `SharedPreferences`에 active session id 저장
- 저장된 session id가 있으면 dashboard refresh로 resume 시도
- dashboard/suspects/evidences/locations 로딩
- 증거 해금 상태 동기화
- 30초마다 evidence/dashboard polling
- 세션 abandon 처리
- 증거 상세에서 탭 전환 요청을 처리하는 intent bus

제약:

- server-side active session endpoint를 호출하지 않는다.
- 409 conflict에서 local saved session이 없으면 자동 복구가 어렵다.
- timer는 앱 로컬 경과 시간이며 backend elapsedSeconds와 완전히 동일한 source of truth는 아니다.
- timeline state가 없다.

## 화면 구현 상태

### 앱 셸/홈

| 화면 | 파일 | 상태 | 설명 |
|---|---|---|---|
| Splash | `lib/screens/splash_screen.dart` | IMPLEMENTED | 앱 진입 화면 |
| AppShell | `lib/screens/app_shell.dart` | IMPLEMENTED | 홈/라이브러리/기록/만들기/내정보 bottom nav |
| Home | `lib/screens/home_screen.dart` | IMPLEMENTED | 라이브러리/만들기/프로필 진입 |
| MyPage | `lib/screens/my_page_screen.dart` | PARTIAL | 프로필은 하드코딩, 메뉴 대부분 준비 중, 로그아웃은 token clear |
| MyRecords | `lib/screens/my_records_screen.dart` | PARTIAL | 별도 실제 기록 API 연동 여부 후속 확인 필요 |
| Scenario Builder | `AppShell` 내부 placeholder | PLACEHOLDER | 만들기 탭은 준비 중 |

### 시나리오

| 화면 | 파일 | 상태 | 설명 |
|---|---|---|---|
| Scenario Library | `lib/screens/scenario_library_screen.dart` | IMPLEMENTED | 목록/검색/필터/페이지 로딩 |
| Scenario Detail | `lib/screens/scenario_detail_screen.dart` | PARTIAL | 상세 API 연동, bookmark local, playable allowlist |
| Case Briefing | `lib/screens/case_briefing_screen.dart` | PARTIAL | scenario synopsis 기반. victim 상세는 세션 시작 후 공개 정책 |

### 플레이

| 화면 | 파일 | 상태 | 설명 |
|---|---|---|---|
| CaseScreen | `lib/screens/case_screen.dart` | IMPLEMENTED | HUD, bottom tab, session loading/error/closed guard |
| Scene | `lib/screens/scene_screen.dart` | PARTIAL | backend locations 우선, 없으면 CL-001 sample fallback |
| Evidence List | `lib/screens/evidence_screen.dart` | IMPLEMENTED | includeLocked evidence 표시, 검색/필터 |
| Evidence Detail | `lib/screens/evidence_detail_screen.dart` | PARTIAL | detail API 연동. guidance 표시 없음 |
| Suspects | `lib/screens/suspects_screen.dart` | IMPLEMENTED | 용의자/증인 필터와 검색 |
| Suspect Detail | `lib/screens/suspect_detail_screen.dart` | IMPLEMENTED | public statement/alibi/logs/related evidence |
| Interrogation Chat | `lib/screens/interrogation_chat_screen.dart` | PARTIAL | AI 심문/증거 제시 구현. 추천 질문 UX는 최신 계약과 다름 |
| Timeline | `lib/screens/timeline_screen.dart` | NOT_IMPLEMENTED | backend timeline API 미사용 |
| Submit | `lib/screens/submit_screen.dart` | IMPLEMENTED | 최종 추리 제출 |
| Result | `lib/screens/result_screen.dart` | IMPLEMENTED | result polling/표시 |

## 모델 구현 상태

| 모델 파일 | 상태 | 설명 |
|---|---|---|
| `lib/models/scenario.dart` | PARTIAL | scenario 기본 필드. `canPlay` 없음 |
| `lib/models/play_session_models.dart` | IMPLEMENTED | session/dashboard/briefing |
| `lib/models/play_evidence_models.dart` | PARTIAL | evidence/detail/related timeline. guidance 없음 |
| `lib/models/play_suspect_models.dart` | IMPLEMENTED | suspects, witness, culpritEligible, portrait, locations |
| `lib/models/play_interrogation_models.dart` | PARTIAL | hints/interrogation/questionType. `RECOMMENDED` 유지 |
| `lib/models/play_result_models.dart` | IMPLEMENTED | final result, matched parts, correct culprit, explanation |
| `lib/models/case.dart` | PARTIAL | UI 모델. backend DTO와 일부 별도 관리 |
| `lib/models/sample_case.dart` | HISTORICAL/PARTIAL | sample timeline/location fallback 용도 |
| `lib/models/sample_scenarios.dart` | PARTIAL | fallback scenario data |

## 인증/FCM

### 인증

파일:

- `lib/services/auth_service.dart`
- `lib/core/api/api_client.dart`

현재:

- token을 `SharedPreferences`에 저장/삭제할 수 있다.
- token 없으면 `mock_jwt_token`을 사용한다.
- `ApiClient.authTokenProvider`는 정의되어 있지만 실제 `AuthService`와 연결되어 있지 않다.
- 실제 로그인/refresh/logout/me API 연동 화면은 없다.

리스크:

- 백엔드가 인증 강제 모드가 되면 현재 앱 요청이 실패할 수 있다.

### FCM

파일:

- `lib/main.dart`
- `android/app/src/main/AndroidManifest.xml`

현재:

- Firebase initialize
- background handler 등록
- notification permission request
- FCM token 획득
- token refresh listener
- foreground/opened/initial message debug log

미구현:

- backend device token 등록
- token 삭제/로그아웃 시 backend revoke
- 알림 deep link 처리

## UX/스포일러 관련 구현

구현된 방어:

- 세션 시작 전 briefing에서는 victim 상세를 하드코딩하지 않고 placeholder 표시
- CL-001 외 시나리오에서는 sample location/timeline fallback 노출을 제한
- 완료/종결된 session이 CaseScreen에 노출되면 플레이 탭 대신 closed state 안내
- final result는 result API 화면에서만 표시
- witness/culpritEligible를 기준으로 최종 지목 가능 인물 필터링

주의할 지점:

- Evidence list는 `includeLocked=true`를 사용한다. locked field는 backend masking 정책에 의존한다.
- Evidence filter에 "핵심 증거"가 있고 `importance == CORE`를 사용한다.
- `proofDimensions`, `importance`, `culpritEligible` 등은 backend 응답이 public-safe하게 마스킹되어야 한다.
- suggested question chip은 현재 hardcoded이고 자동 전송된다.

## 테스트 상태

파일: `test/models/play_models_test.dart`

검증 범위:

- `EvidenceImportance` enum 변환
- `QuestionType` enum 변환
- `PlaySessionStatus` enum 변환
- `PlayEvidence.fromJson`
- `InterrogationResult.fromJson`
- `DeductionResult.fromJson`

검증 공백:

- repository API test 없음
- `ApiClient` error parsing test 없음
- widget/screen test 없음
- active session recovery test 없음
- guidance parsing/rendering test 없음
- FCM token registration test 없음
- timeline API test 없음

## 현재 analyze 상태

최근 확인 결과:

```text
flutter analyze: 25 issues found
```

주요 성격:

- 불필요한 underscore lint
- unused local variable/import
- unused element parameter
- null-aware collection lint
- doc comment angle bracket lint

기능 compile error는 아니지만, PR 전 별도 lint cleanup 후보이다.

## 다음 문서 단계에서 다룰 것

1. `FRONTEND_BACKEND_DRIFT.md`
   - 최신 백엔드 계약 대비 P0/P1/P2 drift 목록
   - 각 drift별 영향도와 수정 파일

2. `FRONTEND_API_INTEGRATION_GUIDE.md`
   - active session recovery
   - auth token wiring
   - device token registration
   - timeline API
   - scenario `canPlay`

3. `FRONTEND_GUIDANCE_UX_IMPLEMENTATION_PLAN.md`
   - evidence detail `guidance` model
   - reading points UI
   - compare evidence UI
   - suggested question prefill-only UX
   - target suspect 유효성 검증
