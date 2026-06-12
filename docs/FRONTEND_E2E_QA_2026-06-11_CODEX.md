# ClueRoom Frontend E2E QA - 2026-06-11

## 0. Final Judgment

```text
전체 판단: Basic app smoke는 PASS, QA 프롬프트의 guidance/chip/timeline/active 복구 기준은 FAIL/PARTIAL.
가장 큰 blocker: 추천 질문 chip 자동 전송과 evidence guidance 미구현.
정답 누설 위험: candidate/importance 계열 metadata를 UI가 직접 사용한다.
최종 제출: 화면 진입만 확인, 실제 제출은 수행하지 않음.
30~50턴 추리 동선: 프론트 UI 기준으로는 guidance 미구현과 자동 전송 때문에 측정 부적합.
```

## 1. Scope

| Item | Value |
|---|---|
| Frontend repo | `C:\java\assignment\spring\start-up-fe` |
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
| Evidence list/detail | PARTIAL | Data loads, but guidance is not rendered |
| Interrogation | PARTIAL | Chat opens and AI responds, but chip auto-sends |
| Timeline | FAIL | Shows "timeline preparing", not server timeline |
| Submit screen | PASS | Final deduction form opens |
| Actual final submit/result | NOT RUN | Avoided changing session to terminal state during FE smoke |

## 5. Findings First

| Priority | Area | Finding | Reproduction | Expected | Actual | Impact | Recommended Action |
|---|---|---|---|---|---|---|---|
| P0 | Spoiler safety | UI consumes candidate/answer-adjacent metadata | Suspect list/detail and final submit use `culpritEligible`; evidence list/filter uses `importance` | User should not receive backend truth/candidate narrowing metadata | App filters/labels candidates and core evidence from server-provided metadata | Player can narrow candidates by UI affordance instead of deduction | Remove truth-adjacent fields from public API or map them to non-spoiler UI-only states server-side |
| P1 | Suggested question UX | Chip tap auto-sends an AI call | Open suspect interrogation, tap first suggested chip | Chip should prefill input only; user must press send | User message bubble appears immediately and AI response is requested | User loses control of AI calls; QA prompt C fails | Replace hardcoded chip auto-send with prefill-only flow and draft confirm |
| P1 | Evidence guidance | Guidance is not parsed or rendered | Open unlocked evidence detail | Show readingPoints, compareEvidences, suggestedQuestions | Detail shows description/timeline/internal fields only | 2026-06-10 "what to read/compare/ask" issue remains unresolved in app | Add guidance models, render sections, and wire suggested question navigation |
| P1 | Locked evidence masking | Locked evidence titles are visible in evidence list | Open Evidence tab after fresh session | Locked evidence should avoid spoiler-specific titles or show generic locked label | Locked rows show concrete titles with lock icon and masked description | Locked future investigation path is exposed early | Backend should mask locked titles or frontend should display generic copy for locked rows |
| P1 | Active session recovery | Server active endpoint is not used | Code review of session load path | Use `GET /api/play-sessions/active?scenarioId=` before/after create conflict | Only local `SharedPreferences` session id is used; 409 has limited recovery | Different device/app reinstall can strand user in conflict state | Add repository method and recovery UX for server active session |
| P1 | Timeline | Server timeline API is unused | Open Timeline tab during official scenario | Display backend timeline data | UI shows "timeline preparing" | QA prompt A/E timeline-based deduction support fails | Add timeline repository/controller/model and remove sample/placeholder gate |
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
| evidence guidance absent from model | `lib/models/play_evidence_models.dart:142` |
| evidence list uses `includeLocked=true` | `lib/controllers/game_session_controller.dart:166`, `lib/controllers/game_session_controller.dart:200` |
| culprit eligibility filters candidates | `lib/controllers/game_session_controller.dart:40`, `lib/screens/submit_screen.dart:157`, `lib/screens/suspect_detail_bottom_bar.dart:31` |
| local-only active session key | `lib/controllers/game_session_controller.dart:72` |
| create session 409 without server active recovery | `lib/controllers/game_session_controller.dart:100`, `lib/controllers/game_session_controller.dart:105` |
| timeline placeholder/sample gate | `lib/screens/timeline_screen.dart:48` |
| local playable allowlist | `lib/screens/scenario_detail_screen.dart:17` |
| auth token provider not wired | `lib/core/api/api_client.dart:61` |
| FCM backend registration TODO | `lib/main.dart:67` |

## 7. Flow Notes

```text
Home -> Library -> Scenario Detail -> Case Briefing -> Start Investigation:
  PASS. App reached playing case screen and showed evidence count 7/25.

Evidence:
  PARTIAL. List/detail load, but locked titles are visible and guidance is absent.

Suspects:
  PARTIAL. Suspect list/detail load, but suspicion score and candidate eligibility create early ranking/selection signals.

Interrogation:
  PARTIAL. Chat works and AI response returns, but suggested chip sends immediately.

Timeline:
  FAIL. Official scenario timeline displays placeholder instead of backend data.

Submit:
  PASS for screen entry. Actual final submission intentionally not executed.
```

## 8. June 10/11 Cross-Reference

These frontend results strengthen issues already seen in the API/blind QA:

```text
1. Guidance coverage issue is not just backend data coverage; frontend does not render guidance at all.
2. Suggested question prefill-only requirement is explicitly violated by app behavior.
3. Locked evidence exposure persists into actual UI, not just API response.
4. Candidate narrowing metadata is consumed by frontend controls, not only present in API.
5. Timeline remains unavailable to the player, so timeline-based deduction must be done from scattered evidence text.
```

## 9. Recommended Fix Order

1. Remove answer-adjacent public metadata from UI/API contract: `culpritEligible`, `importance=CORE/FAKE`, role-derived candidate controls.
2. Stop chip auto-send immediately: tap should only fill input and require explicit send.
3. Implement evidence guidance model/rendering/navigation.
4. Mask locked evidence titles or replace with generic locked labels in the app.
5. Add server active session recovery.
6. Integrate timeline API.
7. Hide internal evidence id/status from user-facing evidence detail.
8. Add widget/E2E tests for chip, guidance, timeline, and active recovery.
9. Clean analyzer warnings.

## 10. Residual Risk

```text
This was an emulator UI smoke plus code/API-contract review, not a full 30~50 turn deduction run.
The full deduction run was already covered by the backend/API blind retest.
Frontend cannot be judged PASS for the blind QA prompt until guidance and chip behavior are fixed.
```
