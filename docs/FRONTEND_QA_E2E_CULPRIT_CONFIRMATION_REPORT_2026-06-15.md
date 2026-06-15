# ClueRoom Frontend QA E2E / Culprit Confirmation Report - 2026-06-15

## 0. Scope

이 문서는 2026-06-15 Flutter Android emulator 실행과 운영 API fallback QA 결과를 프론트엔드 관점에서 정리한 보고서다.
앱 UI E2E 성공 보고서가 아니라, 앱 로그인 blocker와 API fallback 성공/한계를 함께 기록한 QA 보고서다.

```text
Frontend repo: local checkout
Frontend branch/commit: develop / 51a1ac8
Backend API: https://api.clueroom.xyz
Device: Pixel_10 Android emulator, Android 17 API 37
Flutter/Dart: Flutter 3.44.0, Dart 3.12.0
Test date: 2026-06-15 KST
```

주의:

```text
정답 범인명, 정답 수법/동기/은폐 원문, raw session id, token 값은 기록하지 않는다.
결과 점수/등급/부분 정오답 breakdown은 private artifact로 분리한다.
프론트 repo의 기존 pubspec.yaml/pubspec.lock 변경은 이번 문서 작업에서 건드리지 않는다.
```

## 1. Final Judgment

```text
Android app E2E: FAIL
가장 큰 blocker: 운영 API 연결 앱에서 로그인 통과 불가
API-only fallback: 두 공식 시나리오 모두 최종 제출 및 범인 지목 성공 확인
30~50턴 UX 목표: 미달
프론트 핵심 반복 이슈: suggested question 자동 전송, spoiler-like metadata 소비, 운영 auth UX 부재
```

## 2. Findings First

| Priority | Finding | Evidence | Expected | Actual | Impact | Recommended Action |
|---|---|---|---|---|---|---|
| P0 | 운영 앱 로그인 blocker | fresh install 후 Dev Login은 disabled, Google/Apple은 준비 중 | QA/신규 유저가 앱에서 시나리오 목록으로 진입 | 로그인 화면에서 차단 | Android UI E2E 불가 | QA용 계정/토큰 경로 또는 실제 OAuth 연결 |
| P0/P1 | 앱 로그인 gate와 API 접근 정책 불일치 | 앱은 login required, public API fallback은 세션 생성/심문/제출 가능 | 앱과 API의 auth 정책 일치 | UI와 API가 다른 접근 모델 | QA/운영/보안 정책 혼선 | FE login gate와 BE auth enforcement 정책 동기화 |
| P1 | hardcoded suggested question chip 자동 전송 반복 | `InterrogationChatScreen` 기본 chip tap이 `_sendMessage(...RECOMMENDED)` 호출 | chip tap은 prefill-only | 기본 chip은 즉시 AI 호출 | 사용자 전송 통제권 상실 | 기본 chip 제거 또는 prefill-only로 변경 |
| P1 | locked/public metadata를 UI가 소비할 수 있음 | `importance == CORE`가 `isAnalyzed`로 변환되고 핵심 증거 필터/분석완료 UI에 사용 | locked evidence는 중요도/정답성 추론 불가 | locked 응답 metadata가 UI affordance로 이어질 수 있음 | blind 플레이 shortcut 가능 | locked 상태에서는 importance 무시, public-safe displayState 사용 |
| P1 | 30~50턴 내 추리 보조 부족 | API fallback에서 범인 확정까지 서월채 약 80턴, 스튜디오9 약 100턴 필요 | guidance가 후보 축소를 30~50턴 안에 도와야 함 | extended interrogation 후에야 submit-ready | 신규 유저 이탈 또는 찍기 제출 가능 | guidance visibility와 next compare UX 강화 |
| P2 | docs drift | 기존 FE status/drift 문서 일부는 guidance/timeline 미구현으로 설명하지만 현재 코드는 일부 구현됨 | 문서가 코드 SoT 반영 | QA 기준 문서와 실제 코드가 어긋남 | 리뷰/수정 우선순위 혼선 | `FRONTEND_IMPLEMENTATION_STATUS.md`, `FRONTEND_BACKEND_DRIFT.md` 갱신 |

## 3. 반복 이슈 강조

아래 문제는 이전 QA에서도 반복적으로 나온 항목이며, 이번에도 종료 처리할 수 없다.

| Repeated Issue | 현재 상태 | Owner |
|---|---|---|
| 추천 질문 자동 전송 | guidance route prefill은 있으나 기본 hardcoded chip은 자동 전송 | Frontend |
| spoiler-like metadata 소비 | `importance`, `culpritEligible`류 public contract와 UI 소비 위험이 남아 있음 | Frontend/Backend |
| 30~50턴 후보 축소 미달 | 범인 확정은 가능하지만 목표 턴 수를 크게 초과 | Scenario/AI/Frontend |
| 운영 QA 계정/인증 정책 부재 | 운영 앱 로그인은 막히고 API fallback은 가능 | Backend/Frontend/Ops |

## 4. 신규 발견 / 더 선명해진 문제

| New / Sharpened Finding | Detail | Impact |
|---|---|---|
| 운영 앱 로그인 자체가 현재 E2E blocker | Dev Login disabled 상태에서 대체 로그인 버튼이 비활성 | 앱 기준 QA를 API-only로 우회해야 함 |
| public API fallback과 앱 로그인 UX 불일치 | 동일 운영 API에서 앱은 막히지만 API는 gameplay 가능 | 사용자/QA/session isolation 정책이 불명확 |
| FE 문서가 current code보다 늦음 | guidance model/rendering, timeline API가 일부 구현됐는데 문서에는 미구현으로 남은 항목 존재 | 개발자가 이미 해결된 항목을 다시 open으로 오해 가능 |
| final submit 세부 피드백 alignment 필요 | 범인 지목은 성공했지만 일부 세부 추론 채점은 private note 기준 불일치 | 결과 화면 설명과 플레이 중 guidance 연결성 개선 필요 |

## 5. Android App E2E Result

```text
APK build:
  flutter build apk --debug --dart-define=API_BASE_URL=https://api.clueroom.xyz
  result: PASS

Install/run:
  emulator: Pixel_10 / Android 17
  notification permission popup: 표시됨, QA에서는 거부
  onboarding: 표시됨, skip 가능
  login screen: 표시됨

Login:
  Dev Login: AUTH_001 / Dev login is disabled
  Google Login: 준비 중
  Apple Login: 준비 중

Outcome:
  Android UI E2E는 로그인에서 중단
```

## 6. API Fallback Result

앱 로그인 blocker 때문에 public play API fallback으로 두 공식 시나리오를 이어서 검증했다.

```text
서월채:
  evidence unlock: 25/25
  turns before final submit: 약 80
  final submit: 완료
  result after submit: 범인 지목 성공 확인, 세부 결과 private

스튜디오9:
  evidence unlock: 35/35
  turns before final submit: 약 100
  final submit: 완료
  result after submit: 범인 지목 성공 확인, 세부 결과 private
```

프론트 UX 관점 해석:

```text
시나리오는 끝까지 풀 수 있다.
그러나 현재 guidance/심문/증거 비교 경험만으로는 신규 유저가 30~50턴 안에 범인을 확정하기 어렵다.
프론트는 "다음에 무엇을 비교할지"를 더 직접적으로 보여줘야 한다.
```

## 7. Code-State Notes

이번 QA 중 코드 확인으로 아래 상태를 확인했다.

```text
이미 일부 구현된 것:
  - evidence guidance model parsing
  - evidence detail guidance rendering
  - evidence-detail suggested question prefill path
  - timeline API repository/controller/screen path
  - server active session lookup path

아직 문제인 것:
  - hardcoded interrogation suggested question 자동 전송
  - locked/public evidence importance를 UI state로 매핑하는 구조
  - 운영 로그인 UX 부재
  - 일부 문서가 current code 상태와 불일치
```

## 8. Recommended Frontend Actions

| Priority | Action |
|---|---|
| P0 | 운영 QA/신규 유저가 통과할 수 있는 로그인 경로 제공 |
| P0/P1 | BE auth 정책과 FE login gate 정책을 맞춤 |
| P1 | hardcoded suggested question chip을 prefill-only로 변경하거나 제거 |
| P1 | locked evidence에서는 importance 기반 `isAnalyzed`, 핵심 필터, 분석완료 표시를 비활성화 |
| P1 | evidence guidance 화면에서 next compare가 더 눈에 띄도록 UX 강화 |
| P1 | 최종 제출 전 추리 정리 화면에서 동기/수단/기회/은폐 체크리스트 제공 검토 |
| P2 | `FRONTEND_IMPLEMENTATION_STATUS.md`, `FRONTEND_BACKEND_DRIFT.md`를 현재 코드 기준으로 갱신 |
| P2 | 운영 API E2E 전용 QA 계정/토큰 절차를 문서화 |

## 9. Verification

```text
flutter build apk --debug --dart-define=API_BASE_URL=https://api.clueroom.xyz: PASS
flutter test: PASS
flutter analyze: FAIL, 기존 lint/info 4건
git status before docs: pubspec.yaml/pubspec.lock pre-existing changes present
bidi/hidden control character scan: PASS
destructive command: 실행하지 않음
feature code edit: 없음
```

## 10. Private Artifact Notice

아래 항목은 이 문서에 포함하지 않았다.

```text
raw session id
raw access token
정답 범인명
정답 수법/동기/은폐 원문
solution fullExplanation
점수/등급/부분 정오답 breakdown
제출 후보별 상세 반증 매트릭스
AI 답변 전체 원문
```
