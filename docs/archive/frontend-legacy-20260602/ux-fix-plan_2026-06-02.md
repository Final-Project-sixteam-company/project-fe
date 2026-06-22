# Historical Notice

이 문서는 2026-06-02 기준 과거 UX 개선 계획서다. 완료/잔여 상태가 현재 코드와 다를 수 있으므로 최신 구현 계획은 상위 CURRENT 문서를 기준으로 확인한다.

---

# UX 개선 사이클 계획서

> 출처: 플레이어 관점 UX 감사(2026-06-02, 멀티에이전트 워크플로 / 31건 검증 통과 → 27건 병합).
> 모든 발견은 실제 코드 `file:line`로 검증됨. ★ = 사용자가 직접 지적한 항목.

## 원칙
- **1 사이클 = 1 세션 = 1 PR(또는 1 커밋 묶음)**. 세션 간 작업 파일이 겹치지 않도록 분할 → 충돌 없이 순차/병렬 진행 가능.
- 각 사이클 끝에 **검증**(빌드 + 정적분석 + 가능 시 ADB 시각 확인) 후 커밋. 검증 통과 전 다음 사이클 금지.
- 우선순위: 사용자 직접 지적(★) + HIGH 먼저 → MEDIUM → LOW.
- 디자인 토큰(`AppTokens`, `AppColors`, `MSButton` 등) 기존 패턴 재사용. 새 컴포넌트 최소화.

## 검증 환경 메모 (감사·메모리 기반)
- 에뮬레이터 ~1fps → 시각 확인 시 긴 settle 대기, 크롭으로 좌표 탐색, `input text` 사용(`keyevent 4` 금지).
- 플레이 가능 데모 시나리오는 **CL-001** 한정(`_kPlayableIds` 게이트 + DB PUBLISHED). 그 외 시나리오는 샘플/게이팅 경로.
- 제출 탭은 SubmitScreen을 직접 엶.
- 백엔드 미구현: timeline(§9.9)/locations 404 → 샘플 폴백 상태 유지(코드에서 임의로 라이브 호출 추가 금지).

---

## 사이클 개요

| # | 사이클 | 주요 파일 | 항목 수 | 최고 심각도 |
|---|--------|-----------|--------|------------|
| 1 | 심문 화면 (★ 핵심) | `interrogation_chat_screen.dart` | 3 | HIGH |
| 2 | 마이페이지 안전성 | `my_page_screen.dart`, `my_records_screen.dart` | 3 | HIGH |
| 3 | 시나리오 선택 & 리뷰 위치 (★) | `scenario_library_screen.dart`, `scenario_detail_screen.dart`, `result_screen.dart`(진입점) | 4 | HIGH |
| 4 | 진입 경험 (온보딩/스플래시) | `onboarding_screen.dart`, `splash_screen.dart` | 5 | HIGH |
| 5 | 사건 시작/브리핑/HUD | `case_screen.dart`, `case_briefing_screen.dart` | 3 | HIGH |
| 6 | 현장/증거/타임라인 | `scene_screen.dart`, `evidence_detail_screen.dart`, `timeline_screen.dart`, `evidence_tile.dart` | 4 | MEDIUM |
| 7 | 제출/결과 | `submit_screen.dart`, `result_screen.dart` | 5 | HIGH |

**총 7 사이클 / 27개 수정.**

> 교차 의존성 1건: 사이클 3에서 `scenario_detail`의 리뷰 버튼을 제거하고 **완료 후 진입점(result_screen)**으로 옮긴다. result_screen 본문 레이아웃은 사이클 7에서 손대므로, 사이클 3은 result_screen에는 *리뷰 진입 버튼 추가만* 하고 레이아웃 재배치는 7로 미룬다. (3 → 7 순서 권장이나 파일 영역이 달라 충돌은 없음.)

---

## 사이클 1 — 심문 화면 (★ 사용자 핵심 지적)
**목표:** 핵심 메커닉인 "증거 제시"의 발견성과 채팅 입력 영역 터치 안전성 확보.
**파일:** `lib/screens/interrogation_chat_screen.dart`

| 심각도 | 항목 | 근거 | 수정 방향 |
|--------|------|------|-----------|
| HIGH ★ | 증거 제시 버튼이 AppBar ghost 텍스트뿐 → 발견성 낮음 | `:311-314` (AppBar actions, `MSButtonVariant.ghost`) | 입력창(`_InputBar`) 옆 또는 추천 질문 영역에 강조형(secondary) "증거 제시" 액션 배치. 라벨 '증거'→'증거 제시'. AppBar 버튼은 보조로 유지 가능. |
| MEDIUM ★ | 추천 질문 배지가 입력창에 붙음 → 오탭 | `:248-256` (`_SuggestedQuestions`↔`_InputBar` 사이 간격 위젯 없음; 정의 `:495`, `:545`) | 두 위젯 사이 `SizedBox(height: AppTokens.sp3~sp4)` 추가. |
| MEDIUM | 증거 제시 메시지 시각 구분 약함(테두리 색만) | `:429,442` (`_DetectiveBubble` border만 success/primary) | 증거 제시 버블에 배경 강조 또는 `[증거 제시]` 라벨/아이콘 추가. |

**완료 정의:** `flutter analyze` 0 error → 심문 화면에서 증거 제시 버튼이 본문에서 한눈에 보임 + 배지/입력창 간격 시각 확인(ADB, CL-001 심문 진입).

---

## 사이클 2 — 마이페이지 안전성
**목표:** "버그처럼 보이는" 무동작 메뉴 제거 + 파괴적 액션(로그아웃) 보호.
**파일:** `lib/screens/my_page_screen.dart`, `lib/screens/my_records_screen.dart`

| 심각도 | 항목 | 근거 | 수정 방향 |
|--------|------|------|-----------|
| HIGH | 메뉴 4개 전부 `onTap: () {}` 무동작 | `my_page_screen.dart:145` | 구현 가능한 항목은 핸들러 연결, 미구현은 '준비 중입니다' 스낵바 또는 비활성(`disabled`) 처리. ripple만 남는 상태 제거. |
| HIGH | 로그아웃 확인 다이얼로그 없음(복구 불가) | `my_page_screen.dart:139,145` (+ `AuthService.clearTokens()`) | 로그아웃 탭 시 확인 다이얼로그(`game_modals`/`overlays` 기존 패턴 재사용) → 확정 시에만 토큰 클리어. |
| MEDIUM | 기록 빈 상태가 필터 문맥 미반영 | `my_records_screen.dart:122-129` (`_RecordsFilter` all/completed/inProgress/mine) | `_filter` 분기로 메시지 차별화('완료된 사건이 없습니다' / '제작한 시나리오가 없습니다' 등). `MSEmpty.subtitle` 활용. |

**완료 정의:** 모든 메뉴 탭에 명확한 피드백, 로그아웃 2단계 확인, 필터별 빈 상태 문구 확인.

---

## 사이클 3 — 시나리오 선택 & 리뷰 위치 (★)
**목표:** 리뷰 작성 시점을 흐름에 맞게 이전 + 필터 칩 터치/여백 정리.
**파일:** `lib/screens/scenario_detail_screen.dart`, `lib/screens/scenario_library_screen.dart`, `lib/screens/result_screen.dart`(리뷰 진입점 추가만)

| 심각도 | 항목 | 근거 | 수정 방향 |
|--------|------|------|-----------|
| MEDIUM ★ | 리뷰 작성 버튼이 조사 시작 전부터 노출 | `scenario_detail_screen.dart:189-196` (무조건 노출) | 상세 본문에서 리뷰 버튼 제거. **완료 후 진입점**(result_screen 하단 또는 기록 상세)으로 이전. result_screen에는 진입 버튼만 추가(레이아웃 재배치는 사이클 7). |
| HIGH | 마지막 필터 칩 우측 여백 0 → 터치 타깃 부족 | `scenario_library_screen.dart:201` (`right: ...last ? sp2 : 0`) | 모든 칩 동일 우측 여백 또는 Row 우측 패딩으로 처리. |
| MEDIUM | 첫 필터 칩 좌측 여백 부족(비대칭) | `scenario_library_screen.dart:192-209` | Row 시작에 `left: sp2` 패딩. |
| MEDIUM | 필터 영역↔결과 목록 경계 모호 | `scenario_library_screen.dart:111-142` | 구분선(Divider) 또는 필터 영역 배경(`bgElev`)으로 분리. |

**완료 정의:** 시작 전 화면에 리뷰 버튼 없음 / 완료 후 리뷰 진입 가능 / 필터 칩 좌우 여백 대칭 + 끝 칩 터치 가능.

---

## 사이클 4 — 진입 경험 (온보딩/스플래시)
**목표:** 첫인상 구간의 발견성·피드백·리듬 개선.
**파일:** `lib/screens/onboarding_screen.dart`, `lib/screens/splash_screen.dart`

| 심각도 | 항목 | 근거 | 수정 방향 |
|--------|------|------|-----------|
| HIGH | '건너뛰기' 버튼 발견성 낮음(대비 4.2:1) | `onboarding_screen.dart:88-101` (`TextButton`+`textMute`) | `MSButton(ghost)`로 교체 또는 색 `c.text` 상향 + 터치 타깃 48dp 명시. |
| HIGH | '시작하기' 직후 피드백 부재 → 이중 탭 | `onboarding_screen.dart:135-139`, `:56-62` (`loading` 미지정) | 비동기 동안 `loading=true` 전달로 잠금 + (옵션)`HapticFeedback`. |
| MEDIUM | 스플래시 320ms 페이드 후 ~1.9초 침묵 | `splash_screen.dart:43`(dur3=320ms), `:52`(delayed 2200ms) | 애니메이션을 노출시간에 맞게 연장 또는 순차 등장 모션 추가. |
| MEDIUM | 인디케이터-버튼 간격 16px | `onboarding_screen.dart:134` (`sp4`) | `sp6`(24px) 이상으로. |
| MEDIUM | 슬라이드 상하 여백 미명시(태블릿 부유) | `onboarding_screen.dart:171-174` | `Spacer` 추가 또는 `spaceEvenly`. |

**완료 정의:** 건너뛰기 즉시 인지, 시작하기 중복 탭 불가, 스플래시 정적 구간 제거, 간격/여백 시각 확인.

---

## 사이클 5 — 사건 시작/브리핑/HUD
**목표:** 게임 시작·진행 중 핵심 진입점/회복 경로의 위계 정리.
**파일:** `lib/screens/case_screen.dart`, `lib/screens/case_briefing_screen.dart`

| 심각도 | 항목 | 근거 | 수정 방향 |
|--------|------|------|-----------|
| HIGH | 세션 로드 실패 시 '나가기'가 ghost로 약함 | `case_screen.dart:94-112`, `:85` | 회복 불가(예 409)일 때 '나가기'를 primary 위계로 / 에러 메시지 구체화. (메모리: 세션 리셋은 abandon API로만 — 임의 SQL 금지) |
| HIGH | 브리핑 재확인 아이콘 약함 + 터치 ~32dp | `case_screen.dart:194-206` (`size:16`,`textMute`,`sp2` padding) | '브리핑' 라벨 + 아이콘 20~24px + padding 확대로 48dp 확보, 색 primary 상향. |
| MEDIUM | 브리핑 시작 버튼 로딩 피드백 부재 | `case_briefing_screen.dart:145-154` (`pushReplacement` 직행) | 버튼 `loading` 또는 오버레이 스피너. |

**완료 정의:** 실패 화면 탈출구 명확, 브리핑 재확인 버튼 발견·터치 용이, 시작 시 로딩 표시.

---

## 사이클 6 — 현장/증거/타임라인
**목표:** 조사 단계의 다음 액션 경로 + 상태/빈 상태 명료화.
**파일:** `lib/screens/scene_screen.dart`, `lib/screens/evidence_detail_screen.dart`, `lib/screens/timeline_screen.dart`, `lib/components/evidence_tile.dart`

| 심각도 | 항목 | 근거 | 수정 방향 |
|--------|------|------|-----------|
| MEDIUM | 증거 상세 → 심문 CTA 없음 | `evidence_detail_screen.dart:192` | 하단에 '용의자 심문하기' CTA 추가(해당 탭 이동). |
| MEDIUM | 타임라인 '모순 발견' 빈 상태 범용 메시지 | `timeline_screen.dart:15,39-46,82-85,50-57` | 필터별 메시지 분기('현재까지 발견된 모순이 없습니다' 등). 백엔드 미구현 폴백 상태 유지. |
| MEDIUM | 현장 맵 비활성 의도 불명확 | `scene_screen.dart:98,101-119` | `showSample=false`일 때 지도 위 '준비 중' 오버레이 배지. |
| MEDIUM | EvidenceTile 배지 누락 시 상태 불명확 | `evidence_tile.dart:123-128` vs `evidence_item.dart:81-85` | else 분기로 '대기' 배지(`MSPillTone.mute`) — EvidenceItem과 통일. |

**완료 정의:** 증거 확보 후 다음 단계 경로 존재, 빈 상태 문맥 반영, 맵 비활성 인지, 모든 증거 배지 표시.

---

## 사이클 7 — 제출/결과
**목표:** 제출 차단 조건 가시성 + 결과 정보 구조/일관성.
**파일:** `lib/screens/submit_screen.dart`, `lib/screens/result_screen.dart`

| 심각도 | 항목 | 근거 | 수정 방향 |
|--------|------|------|-----------|
| HIGH | 제출 요건 체크리스트 시각 위계 약함 | `submit_screen.dart:302-354` (`bgElev`+`line`+`textSub`) | 배경 `warningSoft/dangerSoft` + 좌측 accent bar로 우선순위 상향. |
| MEDIUM | 서버 에러 시 입력 보존 피드백 부재 | `submit_screen.dart:146-148,163-169` (SnackBar 5초 후 소멸) | 입력 영역 상단 persistent banner로 보존 상태 지속 표시. |
| MEDIUM | 증거 최대(3) 도달 시 비활성 칩 구분 약함 | `submit_screen.dart:554-580` | 비활성 시 배경 `bgHover`/opacity 0.5로 상태 강조. |
| MEDIUM | 결과 해설이 너무 아래 배치 | `result_screen.dart:231-266` | 등급/점수 → 해설 → 상세 채점표 순 재배열(또는 아코디언). + 사이클 3의 리뷰 진입점 최종 배치 정리. |
| LOW | 'CASE CLOSED' 영문 톤 불일치 | `result_screen.dart:298` | '사건 종결 · 최종 판정' 등 한국어 통일. |

**완료 정의:** 차단 조건 즉시 인지, 에러 후 입력 보존 안심, 결과 첫 화면에 해설 노출, 톤 일관.

---

## 사이클 공통 체크리스트 (매 세션)
1. 대상 파일만 수정(다른 사이클 파일 건드리지 않기).
2. `flutter analyze` → error 0.
3. `flutter build`(또는 hot reload)로 컴파일 확인.
4. 가능 시 ADB 시각 확인(CL-001 경로, 긴 settle 대기).
5. 변경 요약 커밋 — 메시지 예: `feat: UX 개선 사이클 N — <요약>`.
6. 이 문서의 해당 사이클에 ✅ 체크 + 비고 기록.

## 진행 현황
- [x] 사이클 3 — 시나리오 선택 & 리뷰 위치 (★) — 2026-06-02. ① 리뷰 작성 진입점 이전: scenario_detail 본문 '리뷰 작성하기' 버튼 제거(시작 전 노출 차단, 리뷰 열람만 유지) → ResultScreen 하단에 '이 사건 리뷰 작성하기' 버튼 추가(scenarioId param, submit_screen에서 controller.scenarioId 전달). _ReviewWriteSheet은 components/review_write_sheet.dart로 공용 추출(showReviewWriteSheet). 결과 본문 레이아웃 재배치는 사이클 7로 유지. ② 필터 칩 좌우 여백 대칭(첫 칩 left sp2 + 전 칩 right sp2). ③ 끝 칩 터치 여유 확보. ④ 필터 영역↔결과 목록 Divider. `flutter analyze` 0 issues(전체). ADB 검증: 칩 여백·구분선·상세 리뷰버튼 제거 확인. 결과화면 리뷰버튼은 코드/analyze 검증(풀플레이 시각확인은 턴 이미지 한도로 보류).
- [x] 사이클 2 — 마이페이지 안전성 — 2026-06-02. ① 메뉴 무동작 제거: 알림설정/도움말/이용약관 '준비 중입니다' 스낵바, 로그아웃은 확인 다이얼로그 연결(액션 enum) ② 로그아웃 2단계 확인(showMSModal danger)→확정 시에만 clearTokens()+SplashScreen 스택 리셋(로그인 화면 도입 전 단일 게이팅 지점) ③ 기록 빈 상태 필터별 문구(전체/완료/진행중/내시나리오)+subtitle. 부수: showMSModal에 Material 래퍼 추가(텍스트 밑줄 누수 결함 수정, overlays.dart). `flutter analyze` 0 issues. ADB 시각확인 완료(스낵바·다이얼로그·취소 보존·내시나리오 빈상태).
- [x] 사이클 1 — 심문 화면 (★) — 2026-06-02. ① 입력창 위 강조형 secondary '증거 제시' 버튼 추가(AppBar는 IconButton+툴팁 보조 진입점으로 정리) ② 추천질문↔입력창 `SizedBox(sp3)` 간격 ③ 증거 제시 버블 배경 `successSoft`+`[증거 제시]` 라벨/아이콘. `flutter analyze` 0 issues. ADB 시각확인 완료(emulator-5554, CL-001 오민석 심문): 강조 버튼 노출·증거 모달 동작·증거 버블 success 강조+라벨 모두 확인.
- [ ] 사이클 2 — 마이페이지 안전성
- [ ] 사이클 3 — 시나리오 선택 & 리뷰 위치 (★)
- [ ] 사이클 4 — 진입 경험
- [ ] 사이클 5 — 사건 시작/브리핑/HUD
- [ ] 사이클 6 — 현장/증거/타임라인
- [ ] 사이클 7 — 제출/결과
