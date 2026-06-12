# ClueRoom Frontend E2E QA - 2026-06-12

## 0. Final Judgment

```text
전체 판단: Active session recovery는 current Flutter code 기준 PASS.
가장 큰 확인 사항: 앱 재설치/로컬 저장소 유실 유사 상태에서도 server active session으로 복구되어 "세션이 이미 있음" 시작 차단이 재현되지 않음.
운영 서버 영향: 운영 API 쓰기 없이 local fake API로 E2E 수행. prod API APK는 빌드만 하고 실행하지 않음.
회귀 방지: active recovery controller tests 2개 추가.
미검증 범위: guidance rendering, suggested question chip prefill-only, timeline, final submit/result full E2E는 이번 범위 밖.
추가 판단: active-session blocker는 current-pass지만, 6/11의 guidance/chip/timeline/spoiler-metadata 이슈는 current code에도 남아 있어 전체 frontend QA PASS로 보면 안 된다.
```

## 1. Scope

| Item | Value |
|---|---|
| Frontend repo | `C:\java\assignment\spring\start-up-fe` |
| Branch / commit | `develop` / `ca84f39` |
| Worktree note | current worktree includes QA/test changes from this run |
| Flutter | `3.44.0 stable` |
| Dart | `3.12.0` |
| Device | Android emulator `emulator-5554`, Android 17 API 37 |
| Fake API base URL | `http://10.0.2.2:18081` |
| Prod API build target | `https://api.clueroom.xyz` |
| Test time | 2026-06-12 KST |

## 2. Safety / Data Boundary

```text
운영 서버 직접 세션 생성/abandon/final submit은 수행하지 않았다.
active-session E2E는 local fake API로만 수행했다.
prod API 대상 debug APK는 마지막에 다시 빌드했지만 실행하지 않았다.
raw token, 실제 session id, secret 값은 문서에 기록하지 않는다.
```

앱 시작 시 주의할 점:

```text
main.dart는 앱 시작 시 FCM token을 얻으면 `/api/device-tokens`를 호출한다.
따라서 prod API APK를 단순 실행하는 것도 운영 API write가 될 수 있다.
운영 E2E는 QA 계정/승인 후 수행한다.
```

## 3. Commands / Checks

```powershell
flutter --version
flutter devices
flutter test
flutter analyze
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:18081
flutter build apk --debug --dart-define=API_BASE_URL=https://api.clueroom.xyz
adb install -r build\app\outputs\flutter-apk\app-debug.apk
adb shell pm clear xyz.clueroom.clueroom
adb shell am start -n xyz.clueroom.clueroom/.MainActivity
```

명령 위험도:

```text
flutter test/analyze/build: 로컬 검증/빌드만 수행.
adb install/pm clear/am start: emulator local app state만 변경.
local fake API: 운영 서버/DB와 무관.
prod API build: 산출물만 생성, 실행하지 않음.
```

## 4. Execution Results

| Check | Result | Evidence |
|---|---|---|
| `flutter test` | PASS | 11 tests passed |
| `flutter analyze` | PASS | No issues found |
| Fake API debug APK build | PASS | `API_BASE_URL=http://10.0.2.2:18081` |
| Prod API debug APK build | PASS | `API_BASE_URL=https://api.clueroom.xyz` |
| Emulator install/launch | PASS | `emulator-5554` |
| Home -> Library | PASS | fake scenario list loaded |
| Library -> Detail -> Briefing | PASS | fake scenario detail loaded |
| Briefing -> Case screen | PASS | active session dashboard/evidence/location loaded |
| Active recovery | PASS | `GET /active` called, create POST not called |

## 5. Active Session Recovery E2E

목표:

```text
앱 로컬 저장소가 비어 있는 상태에서 서버에 PLAYING active session이 이미 있으면,
POST /api/play-sessions로 새 세션을 만들다가 409로 막히지 않고,
GET /api/play-sessions/active?scenarioId=... 결과로 기존 세션에 진입해야 한다.
```

재현 방식:

```text
1. local fake API를 18081 포트로 실행
2. fake API가 `/api/play-sessions/active?scenarioId=1`에 active session 응답
3. emulator app data clear로 fresh install/reinstall 유사 상태 생성
4. fake API APK 설치/실행
5. Home -> Library -> Scenario Detail -> Briefing -> Case Screen 이동
6. fake API request log 확인
```

Fake API request summary:

```text
GET /health
POST /api/device-tokens
GET /api/scenarios?sort=popular&page=0&size=20
GET /api/scenarios/1
GET /api/play-sessions/active?scenarioId=1
GET /api/play-sessions/<active-session>/evidences?includeLocked=true
GET /api/play-sessions/<active-session>/suspects
GET /api/play-sessions/<active-session>/dashboard
GET /api/play-sessions/<active-session>/locations

active_get_count=1
create_post_count=0
```

판정:

```text
PASS.
current Flutter code는 server active endpoint를 먼저 확인하고,
active session이 있으면 create POST 없이 case screen에 진입한다.
```

로컬 산출물:

```text
build/codex-e2e/31_home.png
build/codex-e2e/32_library.png
build/codex-e2e/33_detail.png
build/codex-e2e/34_briefing.png
build/codex-e2e/35_case.png
build/codex-e2e/fake_api.log
```

주의:

```text
build/ 산출물은 Git에 포함하지 않는다.
fake API의 dummy token/session 값은 운영 값이 아니다.
```

## 6. Regression Tests Added

추가 파일:

```text
test/controllers/game_session_controller_test.dart
```

검증 케이스:

```text
1. local storage가 비어 있고 server active session이 있으면 createSession을 호출하지 않고 resume한다.
2. createSession이 409를 반환해도 active lookup으로 기존 세션을 찾아 resume한다.
```

관련 current code path:

```text
lib/controllers/game_session_controller.dart
  - local saved session resume
  - server active session lookup
  - createSession
  - 409 fallback active lookup

lib/repositories/play_session_repository.dart
  - GET /api/play-sessions/active
```

## 7. Findings First

| Priority | Area | Finding | Expected | Actual | Impact | Recommended Action |
|---|---|---|---|---|---|---|
| P1 | Active session recovery | 6/10 APK QA의 “세션 이미 있음” 시작 차단은 current code에서 재현되지 않음 | local storage가 없어도 server active session으로 복구 | fake API E2E에서 active lookup 후 case screen 진입 | 재설치/다른 기기 사용자가 시작 전에 막히는 위험 감소 | regression test 유지, prod QA 계정으로 승인 후 spot check |
| P2 | Docs drift | 6/11 frontend E2E 문서는 active endpoint 미사용으로 기록되어 현재 코드와 다름 | QA 문서가 current code를 반영 | 6/12 기준 current code는 active endpoint 사용 | 팀이 이미 해결된 active recovery를 계속 open blocker로 볼 수 있음 | 이 문서를 최신 follow-up으로 참조 |
| P2 | Startup write behavior | 앱 시작 시 device-token 등록 API가 호출될 수 있음 | 운영 E2E 전에 write 범위를 인지 | fake API 로그에서도 `POST /api/device-tokens` 호출됨 | prod API 단순 실행도 운영 write가 될 수 있음 | 운영 QA는 승인/QA 계정/로컬 fake API 중 하나로 진행 |
| P2 | E2E automation | 현재 검증은 adb coordinate tap 기반 | 안정적 integration_test 또는 patrol/maestro flow | 좌표 보정이 여러 번 필요했음 | 회귀 QA 반복성이 낮음 | active recovery flow를 integration_test 또는 external mobile test script로 승격 |
| P2 | Full frontend QA | guidance/chip/timeline/final submit은 6/12 active recovery E2E 범위 밖 | QA prompt 전체 항목을 앱에서 재검증 | 이번에는 active session bug만 집중 확인 | 프론트 전체 PASS로 오해할 수 있음 | 별도 full E2E 문서/테스트 실행 |
| P0/P1 | Spoiler metadata dependency | `culpritEligible`/`importance`를 UI state에 사용함 | public-safe 상태만 사용 | 후보 필터/핵심 증거 계산이 서버 truth-adjacent field에 의존 | backend가 필드를 제거해도 FE 동시 수정 없이는 회귀/파손 가능 | BE public DTO 변경과 함께 FE 모델/필터 수정 |
| P1 | Suggested question UX | hardcoded chip이 즉시 AI 전송됨 | chip tap은 draft prefill-only | current code는 `QuestionType.recommended`로 `_sendMessage` 호출 | 사용자가 질문을 검토/수정하기 전에 AI call 발생 | chip prefill-only widget/controller test 추가 |
| P1 | Evidence guidance | guidance model/rendering이 아직 없음 | evidence detail에서 reading points/compare targets/suggested questions 표시 | current evidence detail model은 guidance를 파싱하지 않음 | backend guidance를 내려도 앱에서 후보 축소 UX가 개선되지 않음 | guidance model, detail UI, interrogation navigation 구현 |
| P1 | Timeline | timeline API를 사용하지 않음 | official scenario timeline을 서버에서 로드 | `sampleCase.timeline` fallback 사용 | 시간순 단서 파악이 약하고 QA prompt timeline 항목 실패 | timeline repository/controller/model/UI 연결 |

## 8. Additional Whole-Project Review - 2026-06-12

6/12 문서 작성 뒤 frontend 전체에서 QA 관련 키워드를 다시 확인했다. 아래는 6/11에서 큰 문제였고 current code에서도 남아 있는 항목이다.

| Priority | Issue | Current Code Evidence | Action |
|---|---|---|---|
| P0/P1 | candidate/importance metadata 소비 | `lib/controllers/game_session_controller.dart`의 `accusableSuspects`, `importance == EvidenceImportance.core`, `lib/screens/submit_screen.dart`, `lib/screens/suspect_detail_bottom_bar.dart` | BE public DTO에서 truth-adjacent field 제거와 동시에 FE 필터/모델을 public-safe state로 변경 |
| P1 | suggested question chip 자동 전송 | `lib/screens/interrogation_chat_screen.dart`의 `_suggestedQuestions`, `_sendMessage(q, questionType: QuestionType.recommended)` | chip은 입력창 prefill만 수행하고 사용자가 직접 전송하도록 변경 |
| P1 | evidence guidance 미구현 | `lib/models/play_evidence_models.dart`에 guidance field/model이 없고 `evidence_detail_screen.dart`에서 guidance section이 없음 | guidance parsing, rendering, suggested-question navigation 추가 |
| P1 | timeline API 미연동 | `lib/screens/timeline_screen.dart`가 `sampleCase.timeline`을 사용하고 서버 API 연동 TODO를 남김 | `GET /api/play-sessions/{sessionId}/timeline` repository/controller/model/UI 연결 |
| P2 | app startup write | `lib/main.dart`, `lib/screens/login_screen.dart`에서 `/api/device-tokens` 호출 | prod QA는 QA 계정/승인 후 진행하고, read-only QA는 fake API 또는 device-token 차단 빌드 사용 |

강조 판단:

```text
6/12에서 해결 확인된 것은 active session recovery다.
6/11에서 지적된 guidance/chip/timeline/spoiler-metadata는 아직 current code 기준 open이다.
따라서 frontend QA 상태는 "active recovery PASS, full blind QA PARTIAL/FAIL"로 기록한다.
```

## 9. Relationship To 2026-06-11 Frontend QA

6/11 문서의 일부 항목은 current code 기준으로 상태가 바뀌었다.

```text
Active session recovery:
  6/11: server active endpoint 미사용으로 기록
  6/12: current code에서 active endpoint 사용 확인, emulator E2E PASS

Analyzer:
  6/11: flutter analyze FAIL
  6/12: flutter analyze PASS

Tests:
  6/11: model parsing tests only
  6/12: active recovery controller tests 추가
```

아래 항목은 이번에 full retest하지 않았으므로 6/11 판단을 계속 참고한다.

```text
evidence guidance rendering
suggested question chip prefill-only
timeline API rendering
locked evidence title UX
candidate/importance metadata UI usage
final deduction submit/result screen E2E
```

## 10. Follow-up Checklist

```text
[x] active session endpoint path 확인
[x] local storage empty + server active session E2E 확인
[x] createSession 409 fallback unit test 추가
[x] flutter test PASS
[x] flutter analyze PASS
[x] prod API debug APK 재빌드
[ ] prod API QA 계정으로 active recovery spot check
[ ] `culpritEligible`/`importance` UI dependency 제거 후 spoiler-safe E2E
[ ] suggested question chip prefill-only 구현 및 widget test
[ ] evidence guidance model/rendering/navigation 구현
[ ] timeline API rendering 구현
[ ] guidance/chip/timeline full E2E
[ ] final submit/result frontend E2E
[ ] CI에 active recovery test 포함 여부 확인
```

## 11. Private Artifact Notice

이 문서에는 아래를 포함하지 않는다.

```text
raw session id
raw token
정답 후보명
정답 해설/수법/은폐 원문
운영 DB row dump
스포일러성 화면 캡처
```
