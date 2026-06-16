# ClueRoom Frontend E2E QA - 2026-06-11

> Current develop note - 2026-06-15:
> This document is a historical 2026-06-11 baseline. After the later develop
> updates, server active-session recovery, `GET /api/play-sessions/{sessionId}/timeline`,
> and evidence guidance model/rendering/navigation are implemented. Treat the
> original rows for those areas as superseded; still-open frontend QA items are
> suggested-question auto-send, spoiler-adjacent metadata usage, locked evidence
> title UX, and full final submit/result E2E.

## 0. Final Judgment

```text
전체 판단(2026-06-11 기준): Basic app smoke는 PASS, QA 프롬프트의 guidance/chip/timeline/active 복구 기준은 FAIL/PARTIAL.
최신 develop 반영 후 변경: active recovery, evidence guidance, timeline API는 후속 PR에서 구현됨.
현재도 남은 큰 blocker: 추천 질문 chip 자동 전송과 spoiler-adjacent metadata UI 사용.
정답 누설 위험: candidate/importance 계열 metadata를 UI가 직접 사용한다.
최종 제출: 화면 진입만 확인, 실제 제출은 수행하지 않음.
30~50턴 추리 동선: 최신 코드 기준으로 guidance/timeline은 재검증 필요, chip 자동 전송과 metadata 의존은 여전히 측정 blocker.
```

## 1. Scope

| Item | Value |
|---|---|
| Frontend repo | local checkout |
| Branch / commit | `docs/frontend-consolidation-20260611` / `31671f3` |
| API base URL | `https://api.clueroom.xyz` |
| Build | Debug APK with `--dart-define=API_BASE_URL=https://api.clueroom.xyz` |
| Device | Android emulator `emulator-5554`, Android 17 API 37 |
| Flutter | `3.44.0 stable` |
| Dart | `3.12.0` |
| Test time | 2026-06-11 22:28 KST |

QA prompt coverage note:

```text
docs/QA_BLIND_RETEST_PROMPT_2026-06-11.md already requires Android app UI first,
basic E2E flow, evidence guidance, chip prefill-only, active session recovery,
timeline, final submit, and result screen checks.
```

## 2. Spoiler Safety

```text
No private seed, solution file, DB direct query, or result API was used.
Raw session id was not recorded.
Generated screenshots were not retained in docs because they may include locked evidence titles.
```

## 3. Commands Run

```powershell
flutter --version
flutter devices
flutter emulators
flutter doctor -v
flutter test
flutter analyze
flutter build apk --debug --dart-define=API_BASE_URL=https://api.clueroom.xyz
adb install -r -d build\app\outputs\flutter-apk\app-debug.apk
adb shell am start -n xyz.clueroom.clueroom/.MainActivity
```

Notes:

```text
Initial install without -d failed because emulator already had versionCode 4001.
Debug build versionCode is 1, so downgrade install was required for this QA run.
```

## 4. Execution Results

| Check | Result | Evidence |
|---|---|---|
| `flutter test` | PASS | 9 model parsing tests passed |
| `flutter analyze` | FAIL | 25 info/warning issues |
| Debug APK build | PASS | `build\app\outputs\flutter-apk\app-debug.apk` built |
| Emulator install | PASS | Installed with downgrade flag |
| App launch | PASS | Home screen reached |
| Scenario list | PASS | Official scenario list loaded from API |
| Scenario detail | PASS | Detail screen opened |
| Briefing | PASS | Briefing screen opened |
| Session start | PASS | Case screen entered, evidence counter shown |
| Evidence list/detail | PARTIAL | 2026-06-11 baseline: data loads, but guidance is not rendered. Latest develop implements guidance rendering |
| Interrogation | PARTIAL | Chat opens and AI responds, but chip auto-sends |
| Timeline | FAIL | 2026-06-11 baseline: shows "timeline preparing", not server timeline. Latest develop integrates timeline API |
| Submit screen | PASS | Final deduction form opens |
| Actual final submit/result | NOT RUN | Avoided changing session to terminal state during FE smoke |

## 5. Findings First

| Priority | Area | Finding | Reproduction | Expected | Actual | Impact | Recommended Action |
|---|---|---|---|---|---|---|---|
| P0 | Spoiler safety | UI consumes candidate/answer-adjacent metadata | Suspect list/detail and final submit use `culpritEligible`; evidence list/filter uses `importance` | User should not receive backend truth/candidate narrowing metadata | App filters/labels candidates and core evidence from server-provided metadata | Player can narrow candidates by UI affordance instead of deduction | Remove truth-adjacent fields from public API or map them to non-spoiler UI-only states server-side |
| P1 | Suggested question UX | Chip tap auto-sends an AI call | Open suspect interrogation, tap first suggested chip | Chip should prefill input only; user must press send | User message bubble appears immediately and AI response is requested | User loses control of AI calls; QA prompt C fails | Replace hardcoded chip auto-send with prefill-only flow and draft confirm |
| Resolved after 6/11 | Evidence guidance | Historical baseline: guidance was not parsed or rendered | Open unlocked evidence detail | Show readingPoints, compareEvidences, suggestedQuestions | 6/11 detail showed description/timeline/internal fields only | Superseded by latest develop after #23 | Keep guidance full E2E/widget coverage as follow-up |
| P1 | Locked evidence masking | Locked evidence titles are visible in evidence list | Open Evidence tab after fresh session | Locked evidence should avoid spoiler-specific titles or show generic locked label | Locked rows show concrete titles with lock icon and masked description | Locked future investigation path is exposed early | Backend should mask locked titles or frontend should display generic copy for locked rows |
| Resolved after 6/11 | Active session recovery | Historical baseline: server active endpoint was not used | Code review of session load path | Use `GET /api/play-sessions/active?scenarioId=` before/after create conflict | 6/11 only used local `SharedPreferences` session id | Covered by 6/12 active-session recovery tests | Keep regression tests and prod-QA spot check |
| Resolved after 6/11 | Timeline | Historical baseline: server timeline API was unused | Open Timeline tab during official scenario | Display backend timeline data | 6/11 UI showed "timeline preparing" | Superseded by latest develop after #22 | Keep timeline full E2E as follow-up |
| P2 | Evidence detail UI | Internal fields are displayed | Open evidence detail | Show user-facing clue info and guidance | `EVIDENCE ID` and `STATUS` are shown | Debug/internal vocabulary leaks into product UX | Remove or hide internal ids/status from user screen |
| P2 | Initial suspicion score | Suspicion numbers start visible | Open suspect list/detail | Candidate ranking should emerge from play | UI shows numeric suspicion immediately | App feels like it pre-ranks suspects | Hide initial suspicion or make it derived from player actions only |
| P2 | Static analysis | Analyzer is failing | Run `flutter analyze` | PR quality gate should pass | 25 issues found | CI/review signal is noisy | Separate lint cleanup PR |
| P2 | Test coverage | No widget/E2E tests for QA-critical UX | Inspect `test/` and run tests | Guidance/chip/timeline/active recovery covered | Only model parsing tests exist | Regressions in QA-critical UX are easy | Add widget tests for chip prefill and guidance rendering |

## 6. Code References

| Concern | File / line |
|---|---|
| hardcoded suggested questions | `lib/screens/interrogation_chat_screen.dart:31` |
| chip auto-send | `lib/screens/interrogation_chat_screen.dart:283` |
| `RECOMMENDED` question type still modeled | `lib/models/play_interrogation_models.dart:65` |
| evidence guidance absent from model on 6/11, superseded in latest develop | `lib/models/play_evidence_models.dart`, `lib/screens/evidence_detail_widgets.dart` |
| evidence list uses `includeLocked=true` | `lib/controllers/game_session_controller.dart:166`, `lib/controllers/game_session_controller.dart:200` |
| culprit eligibility filters candidates | `lib/controllers/game_session_controller.dart:40`, `lib/screens/submit_screen.dart:157`, `lib/screens/suspect_detail_bottom_bar.dart:31` |
| local-only active session path on 6/11, superseded by server active lookup | `lib/controllers/game_session_controller.dart`, `lib/repositories/play_session_repository.dart` |
| create session 409 without server active recovery on 6/11, superseded by active fallback | `lib/controllers/game_session_controller.dart` |
| timeline placeholder/sample gate on 6/11, superseded by timeline API integration | `lib/screens/timeline_screen.dart`, `lib/models/play_timeline_models.dart` |
| local playable allowlist | `lib/screens/scenario_detail_screen.dart:17` |
| auth token provider not wired | `lib/core/api/api_client.dart:61` |
| FCM backend registration TODO | `lib/main.dart:67` |

## 7. Flow Notes

```text
Home -> Library -> Scenario Detail -> Case Briefing -> Start Investigation:
  PASS. App reached playing case screen and showed evidence count 7/25.

Evidence:
  2026-06-11 baseline PARTIAL. List/detail loaded, but locked titles were visible and guidance was absent.
  Current develop update: guidance model/rendering/navigation is implemented; locked title UX still needs product decision.

Suspects:
  PARTIAL. Suspect list/detail load, but suspicion score and candidate eligibility create early ranking/selection signals.

Interrogation:
  PARTIAL. Chat works and AI response returns, but suggested chip sends immediately.

Timeline:
  2026-06-11 baseline FAIL. Official scenario timeline displayed placeholder instead of backend data.
  Current develop update: timeline API integration is implemented; full app E2E still needs a current run.

Submit:
  PASS for screen entry. Actual final submission intentionally not executed.
```

## 8. June 10/11 Cross-Reference

These frontend results strengthen issues already seen in the API/blind QA:

```text
1. Guidance coverage was a frontend rendering gap on 6/11; latest develop implements the model/rendering/navigation path, so this is no longer an open implementation blocker.
2. Suggested question prefill-only requirement is still violated by hardcoded chip auto-send.
3. Locked evidence exposure persists into actual UI, not just API response.
4. Candidate narrowing metadata is consumed by frontend controls, not only present in API.
5. Timeline was unavailable on 6/11; latest develop integrates the timeline API, so this needs current E2E confirmation rather than implementation work.
```

## 9. Recommended Fix Order

1. Remove answer-adjacent public metadata from UI/API contract: `culpritEligible`, `importance=CORE/FAKE`, role-derived candidate controls.
2. Stop chip auto-send immediately: tap should only fill input and require explicit send.
3. Evidence guidance model/rendering/navigation: implemented after this baseline; keep current E2E/widget coverage.
4. Mask locked evidence titles or replace with generic locked labels in the app.
5. Server active session recovery: implemented and covered by the 6/12 regression tests.
6. Timeline API: implemented after this baseline; keep current E2E coverage.
7. Hide internal evidence id/status from user-facing evidence detail.
8. Add/keep widget/E2E tests for chip, guidance, timeline, and active recovery.
9. Clean analyzer warnings.

## 10. Residual Risk

```text
This was an emulator UI smoke plus code/API-contract review, not a full 30~50 turn deduction run.
The full deduction run was already covered by the backend/API blind retest.
Frontend cannot be judged PASS for the blind QA prompt until chip behavior, spoiler-adjacent metadata usage, and final submit/result E2E are addressed. Guidance/timeline are implemented in latest develop but still need current full-flow QA coverage.
```
