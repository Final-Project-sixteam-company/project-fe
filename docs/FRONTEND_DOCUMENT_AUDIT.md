# Frontend Document Audit

기준일: 2026-06-11

대상 repo: `start-up-fe`

목적:

- 프론트 문서 정리를 삭제 중심이 아니라 흡수 중심으로 진행한다.
- 현재 Flutter 코드가 실제로 구현한 범위와 문서가 설명하는 범위를 분리한다.
- 백엔드 최신 정본 계약과 프론트 구현 사이의 drift를 이후 단계에서 바로 수정할 수 있게 고정한다.

## 현재 프로젝트 상태

| 항목 | 상태 |
|---|---|
| 앱 기술 | Flutter / Dart |
| 앱 이름 | ClueRoom |
| main package | `lib/` |
| API base URL | prod `https://api.clueroom.xyz`, debug 기본 `http://10.0.2.2:18080` 또는 `http://localhost:18080` |
| API override | `--dart-define=API_BASE_URL=...` |
| Firebase | `firebase_core`, `firebase_messaging` 의존성 있음. FCM token 획득까지만 구현 |
| 테스트 | `test/models/play_models_test.dart` 모델 파싱 테스트만 존재 |
| 분석 상태 | `flutter analyze` 경고/정보 25건 |

## 코드 인벤토리

| 영역 | 주요 파일 | 현재 역할 |
|---|---|---|
| API config/client | `lib/core/api/api_config.dart`, `lib/core/api/api_client.dart` | base URL 결정, 공통 `{success,data,error}` 응답 파싱, timeout 처리 |
| 인증 저장 | `lib/services/auth_service.dart` | SharedPreferences token 저장. 현재 토큰 없으면 `mock_jwt_token` 사용 |
| 시나리오 API | `lib/repositories/scenario_repository.dart` | `GET /api/scenarios`, `GET /api/scenarios/{id}` |
| 플레이 API | `lib/repositories/play_session_repository.dart` | 세션 생성, dashboard, locations, evidences, suspects, hints, interrogations, final deduction, result |
| 세션 상태 | `lib/controllers/game_session_controller.dart` | 로컬 active session 저장, dashboard/suspect/evidence/location 로딩, polling |
| 시나리오 화면 | `lib/screens/scenario_library_screen.dart`, `lib/screens/scenario_detail_screen.dart` | 목록/상세 API 연동, 플레이 가능 여부는 local allowlist |
| 플레이 화면 | `lib/screens/case_screen.dart`, `lib/screens/scene_screen.dart`, `lib/screens/evidence_screen.dart`, `lib/screens/suspects_screen.dart` | 사건 탭 구조, 현장/증거/용의자 표시 |
| 증거 상세 | `lib/screens/evidence_detail_screen.dart`, `lib/models/play_evidence_models.dart` | 해금 증거 상세 조회, description/relatedSuspects/relatedTimelineEvents 표시 |
| 심문 | `lib/screens/interrogation_chat_screen.dart`, `lib/models/play_interrogation_models.dart` | 심문 전송, 증거 제시, hardcoded suggested questions |
| 최종 추리/결과 | `lib/screens/submit_screen.dart`, `lib/screens/result_screen.dart`, `lib/models/play_result_models.dart` | 최종 추리 제출, 결과 polling/표시 |
| 타임라인 | `lib/screens/timeline_screen.dart`, `lib/models/sample_case.dart` | 현재 sample timeline 사용. 서버 timeline API 미연동 |

## 현재 사용 중인 API

| Endpoint | 사용 위치 | 상태 |
|---|---|---|
| `GET /api/scenarios` | `scenario_repository.dart` | 사용 중 |
| `GET /api/scenarios/{scenarioId}` | `scenario_repository.dart` | 사용 중 |
| `POST /api/play-sessions` | `play_session_repository.dart` | 사용 중 |
| `GET /api/play-sessions/{sessionId}/dashboard` | `play_session_repository.dart` | 사용 중 |
| `GET /api/play-sessions/{sessionId}/locations` | `play_session_repository.dart` | 사용 중 |
| `GET /api/play-sessions/{sessionId}/evidences?includeLocked=true` | `play_session_repository.dart` | 사용 중 |
| `GET /api/play-sessions/{sessionId}/evidences/{evidenceId}` | `play_session_repository.dart` | 사용 중 |
| `GET /api/play-sessions/{sessionId}/suspects` | `play_session_repository.dart` | 사용 중 |
| `GET /api/play-sessions/{sessionId}/hints` | `play_session_repository.dart` | 사용 중 |
| `POST /api/play-sessions/{sessionId}/hints/{hintId}/use` | `play_session_repository.dart` | 사용 중 |
| `POST /api/play-sessions/{sessionId}/abandon` | `play_session_repository.dart` | 사용 중 |
| `POST /api/play-sessions/{sessionId}/interrogations` | `play_session_repository.dart` | 사용 중 |
| `GET /api/play-sessions/{sessionId}/interrogations` | `play_session_repository.dart` | repository 구현 있음 |
| `POST /api/play-sessions/{sessionId}/final-deduction` | `play_session_repository.dart` | 사용 중 |
| `GET /api/play-sessions/{sessionId}/result` | `play_session_repository.dart` | 사용 중 |

## 백엔드 최신 계약 대비 미사용/미반영 항목

| 항목 | 백엔드 기준 | 프론트 현재 상태 | 후속 문서화 |
|---|---|---|---|
| Active session recovery | `GET /api/play-sessions/active?scenarioId=...` | 로컬 SharedPreferences session id만 사용 | `FRONTEND_BACKEND_DRIFT.md` P0/P1 |
| Device token registration | `POST /api/device-tokens` | FCM token 출력만 함. TODO는 오래된 `PATCH /api/users/me` | `FRONTEND_BACKEND_DRIFT.md` P1 |
| Evidence guidance | evidence detail `guidance` | 모델/화면 미구현 | `FRONTEND_GUIDANCE_UX_IMPLEMENTATION_PLAN.md` |
| Suggested question chip | prefill-only, 자동 전송 금지, evidence 기반은 `EVIDENCE_PRESENTED` | hardcoded chip을 `RECOMMENDED`로 즉시 전송 | `FRONTEND_GUIDANCE_UX_IMPLEMENTATION_PLAN.md` |
| Timeline API | `GET /api/play-sessions/{sessionId}/timeline` | sample timeline 사용 | `FRONTEND_BACKEND_DRIFT.md` P1 |
| Scenario playability | backend `canPlay` 신뢰 | `_kLocalPlayableIds` 하드코딩 | `FRONTEND_BACKEND_DRIFT.md` P2 |
| Real auth | backend auth enforcement 대비 token wiring 필요 | `ApiClient.authTokenProvider` 미연결, mock token 중심 | `FRONTEND_BACKEND_DRIFT.md` P0 |

## 기존 문서 상태

| 문서 | 현재 상태 | 문제 | 흡수 방향 |
|---|---|---|---|
| `README.md` | CURRENT | Flutter 기본 템플릿을 ClueRoom 실행/구조/API 요약 정본으로 교체함 | 유지 |
| `api-spec.md` | CURRENT NOTICE | 오래된 API 초안을 archive로 이동하고 최신 백엔드 정본 위치를 안내함 | 유지 |
| `docs/archive/frontend-legacy-20260602/api-spec_mvp-v0.1_legacy.md` | HISTORICAL | 과거 API 초안 원문 | archive 보존 |
| `docs/archive/frontend-legacy-20260602/backend-requests_2026-06-02_v1.md` | HISTORICAL | active session, timeline, locations 등 과거 요청 | archive 보존 |
| `docs/archive/frontend-legacy-20260602/backend-handoff-basic-gameplay_2026-06-04.md` | HISTORICAL | 과거 handoff. 일부 해결 이슈가 미해결처럼 남아 있었음 | archive 보존 |
| `docs/archive/frontend-legacy-20260602/ux-fix-plan_2026-06-02.md` | HISTORICAL | 과거 UX 수정 계획. 완료/미완료 상태가 혼재 | archive 보존 |

## 분석/검증 결과

### `flutter test`

```text
All tests passed.
```

범위:

- enum 변환
- `PlayEvidence.fromJson`
- `InterrogationResult.fromJson`
- `DeductionResult.fromJson`

한계:

- repository API test 없음
- screen/widget test 없음
- guidance/active-session/device-token/timeline test 없음

### `flutter analyze`

```text
25 issues found.
```

성격:

- 대부분 lint/info
- warning 4건 확인
- 기능 차단급 compile error는 아님

후속 문서에서는 analyze 결과를 프론트 품질 debt로 분리한다.

## 1단계 결론

현재 프론트는 기본 플레이 루프 API 연동은 되어 있지만, 백엔드 최신 계약 중 UX/운영 연계 항목이 아직 반영되지 않았다.

다음 단계 문서 작업은 아래 순서가 안전하다.

1. 루트 [README.md](../README.md)를 ClueRoom Flutter 앱 정본으로 교체한다.
2. 실제 구현 상태를 `FRONTEND_IMPLEMENTATION_STATUS.md`로 분리한다.
3. 백엔드 계약 대비 drift를 `FRONTEND_BACKEND_DRIFT.md`로 분리한다.
4. evidence guidance와 suggested question UX는 별도 구현 계획서로 만든다.
5. 오래된 문서는 `docs/archive/frontend-legacy-20260602/`로 보존하고, 루트 `api-spec.md`는 notice로 축소했다.
