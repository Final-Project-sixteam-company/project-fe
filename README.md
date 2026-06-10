# ClueRoom Flutter Frontend

ClueRoom 프론트엔드 앱이다.

사용자는 공식 시나리오를 선택하고, 사건 브리핑과 현장/증거/용의자 정보를 확인한 뒤 AI 심문과 최종 추리 제출을 통해 사건을 해결한다.

이 repo는 Flutter/Dart 기반 앱이며, 백엔드는 별도 Spring Boot repo인 `start-up`에서 제공한다.

## 현재 기준

| 항목 | 값 |
|---|---|
| 앱 이름 | ClueRoom |
| 기술 스택 | Flutter / Dart |
| Dart SDK | `^3.12.0` |
| Android package | `xyz.clueroom.clueroom` |
| 운영 API | `https://api.clueroom.xyz` |
| 로컬 API 기본값 | Android emulator `http://10.0.2.2:18080`, desktop `http://localhost:18080` |
| API override | `--dart-define=API_BASE_URL=...` |
| 주요 상태 저장 | `shared_preferences` |
| Push token | Firebase Messaging token 획득까지만 구현 |

## 문서

| 문서 | 역할 |
|---|---|
| [docs/README.md](docs/README.md) | 프론트 문서 index / 흡수 계획 |
| [docs/FRONTEND_DOCUMENT_AUDIT.md](docs/FRONTEND_DOCUMENT_AUDIT.md) | 현재 문서/코드 인벤토리와 백엔드 계약 drift |
| [docs/FRONTEND_IMPLEMENTATION_STATUS.md](docs/FRONTEND_IMPLEMENTATION_STATUS.md) | 실제 Flutter 코드 기준 구현 현황 |
| [docs/FRONTEND_BACKEND_DRIFT.md](docs/FRONTEND_BACKEND_DRIFT.md) | 백엔드 최신 계약 대비 drift와 수정 우선순위 |
| [docs/FRONTEND_API_INTEGRATION_GUIDE.md](docs/FRONTEND_API_INTEGRATION_GUIDE.md) | 백엔드 최신 계약 반영을 위한 프론트 구현 가이드 |
| [docs/FRONTEND_GUIDANCE_UX_IMPLEMENTATION_PLAN.md](docs/FRONTEND_GUIDANCE_UX_IMPLEMENTATION_PLAN.md) | evidence guidance와 suggested question UX 구현 계획 |
| [api-spec.md](api-spec.md) | 최신 API 정본 위치를 안내하는 notice |
| [docs/archive/README.md](docs/archive/README.md) | 흡수 완료된 과거 프론트 문서 archive |

백엔드 API/운영/시나리오 정본은 backend repo의 아래 문서를 기준으로 본다.

```text
start-up/docs/CaseLab_AI_API_Spec.md
start-up/docs/frontend/CLUEROOM_APP_FLOW_API_GUIDE.md
start-up/docs/scenarios/SCENARIO_GUIDANCE_UX_SPEC.md
start-up/docs/RUN_AND_DEPLOY.md
```

## 실행

의존성 설치:

```bash
flutter pub get
```

로컬 백엔드에 연결:

```bash
flutter run
```

디버그 기본 URL은 플랫폼별로 자동 결정된다.

```text
Android emulator: http://10.0.2.2:18080
desktop/iOS simulator: http://localhost:18080
```

특정 API 서버로 override:

```bash
flutter run --dart-define=API_BASE_URL=https://api.clueroom.xyz
```

로컬 백엔드 포트가 다르면:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

릴리즈 APK 빌드 예시:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://api.clueroom.xyz
```

## 검증

테스트:

```bash
flutter test
```

정적 분석:

```bash
flutter analyze
```

현재 기준:

```text
flutter test: PASS
flutter analyze: warning/info 25건으로 FAIL
```

`flutter analyze`는 compile error가 아니라 lint/warning 중심이지만, PR 전에는 별도 정리 대상이다.

## 폴더 구조

```text
lib/
  core/api/          API base URL, 공통 HTTP client, API exception
  services/          AuthService 등 앱 공통 서비스
  repositories/      backend API 호출 계층
  controllers/       플레이 세션 상태와 화면 공유 state
  models/            화면/백엔드 DTO 모델
  screens/           Flutter 화면
  components/        공통 UI 컴포넌트
  theme/             색상, 텍스트, 토큰, 테마

docs/                프론트 문서 정본 후보와 audit
docs/archive/        흡수 완료된 과거 작업/handoff 문서
test/                모델 파싱 테스트
```

## 현재 구현된 주요 API 연동

| 기능 | Endpoint |
|---|---|
| 시나리오 목록 | `GET /api/scenarios` |
| 시나리오 상세 | `GET /api/scenarios/{scenarioId}` |
| 플레이 세션 생성 | `POST /api/play-sessions` |
| 대시보드 | `GET /api/play-sessions/{sessionId}/dashboard` |
| 현장 정보 | `GET /api/play-sessions/{sessionId}/locations` |
| 증거 목록 | `GET /api/play-sessions/{sessionId}/evidences?includeLocked=true` |
| 증거 상세 | `GET /api/play-sessions/{sessionId}/evidences/{evidenceId}` |
| 용의자 목록 | `GET /api/play-sessions/{sessionId}/suspects` |
| 힌트 목록/사용 | `GET /api/play-sessions/{sessionId}/hints`, `POST /api/play-sessions/{sessionId}/hints/{hintId}/use` |
| AI 심문 | `POST /api/play-sessions/{sessionId}/interrogations` |
| 심문 로그 조회 | `GET /api/play-sessions/{sessionId}/interrogations` |
| 최종 추리 제출 | `POST /api/play-sessions/{sessionId}/final-deduction` |
| 결과 조회 | `GET /api/play-sessions/{sessionId}/result` |
| 세션 포기 | `POST /api/play-sessions/{sessionId}/abandon` |

## 백엔드 최신 계약 대비 주의할 점

아래 항목은 현재 코드와 백엔드 최신 계약 사이에 drift가 있다.

| 우선순위 | 항목 | 현재 상태 |
|---|---|---|
| P0 | 인증 강제 모드 대비 | `AuthService`는 mock token 중심이고 `ApiClient.authTokenProvider`와 실제 연결되지 않았다 |
| P0/P1 | active session 복구 | local `SharedPreferences` 저장 session만 사용한다. `GET /api/play-sessions/active?scenarioId=...` 미사용 |
| P1 | FCM device token 등록 | token 획득만 하고 backend 등록은 TODO. 최신 endpoint는 `POST /api/device-tokens` |
| P1 | evidence guidance | evidence detail 응답의 `guidance` 모델/화면 미구현 |
| P1 | suggested question UX | hardcoded chip을 `RECOMMENDED`로 즉시 전송한다. 최신 계약은 prefill-only, 자동 전송 금지 |
| P1 | timeline API | `GET /api/play-sessions/{sessionId}/timeline` 미사용. 현재 sample timeline 표시 |
| P2 | scenario canPlay | `_kLocalPlayableIds` local allowlist 사용. backend `canPlay` 신뢰 구조로 전환 필요 |
| P2 | 과거 API 문서 | `api-spec.md`는 최신 정본 notice이고, 원문은 `docs/archive/`에 보존되어 있다 |

## 현재 플레이 흐름

```text
시나리오 목록
-> 시나리오 상세
-> 플레이 세션 생성
-> 사건 브리핑 / 대시보드
-> 현장 / 증거 / 용의자
-> AI 심문
-> 최종 추리 제출
-> 결과 조회
```

## 개발 원칙

- 프론트 문서는 backend repo의 최신 API 정본과 충돌하지 않게 유지한다.
- 오래된 문서는 삭제보다 흡수를 우선한다.
- 증거/정답/해설 관련 문서는 public-safe 기준을 지킨다.
- suggested question은 사용자가 최종 전송을 통제해야 하며, 자동 전송 UX로 구현하지 않는다.
- locked evidence와 locked compare evidence는 백엔드 마스킹 정책을 그대로 존중한다.
- 인증 강제 전환에 대비해 token wiring을 문서/구현에서 명확히 분리한다.

## 다음 문서 작업

1. 필요하면 `docs/FRONTEND_QA_CHECKLIST.md`를 추가해 프론트 수동 QA 절차를 정리한다.
2. 구현 PR이 올라오면 `FRONTEND_BACKEND_DRIFT.md`의 P0/P1 항목을 해결 상태로 갱신한다.
