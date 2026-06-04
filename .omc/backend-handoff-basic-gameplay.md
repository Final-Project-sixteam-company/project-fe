# 백엔드 핸드오프 — 기본 게임플레이 e2e (2026-06-04)

검증 환경: 실제 백엔드 docker-compose 기동 (start-up-project), host 포트 **18080** (8080은 무관한 theo-core 점유). MySQL :33306 / Redis :16379. 시나리오 1~5 seed (1=데모데이, 2=밀실의유산[stub], 3=동아리회비[stub,CUSTOM], 4=서월채, 5=studio9).

## ✅ 정상 동작 (기본 게임플레이 전 구간 GREEN)
시나리오 1·4 기준 전 루프 실 API 검증 완료:
목록 → 상세 → 세션생성 → dashboard → locations(5) → evidences(includeLocked/status) → evidences/{id} → suspects(5) → suspects/{id} → timeline → hints(3) → interrogations(AI) → final-deduction(AI) → result. 전부 200 + 데이터.
- 시나리오 1: 최종추리 채점 OK (56/D), result에 matchedParts/missedParts/keyEvidences 정상.
- 시나리오 4(서월채): 최종추리 채점 OK (에러 없음). **기존 "4/5 = 500 AI012"는 해소됨.**

## ⚠️ 백엔드 협조 필요 (핸드오프)

| # | 항목 | 현상 | 영향 | 요청 |
|---|------|------|------|------|
| H1 | **시나리오 5(studio9) 정답 미seed** | final-deduction → `AI011 정답 정보 없음` | studio9는 FE 플레이 허용목록에 있으나 최종 제출에서 막힘 | studio9 solution/scoring seed, 또는 출시 전까지 비활성 합의 |
| H2 | **timeline 콘텐츠 없음** | `/timeline` 200이지만 모든 시나리오 0건 | 타임라인 탭 항상 empty | YAML/DB에 timeline 이벤트 seed (없으면 FE는 empty state 유지) |
| H3 | **`canPlay` 목록 DTO 누락** | `GET /api/scenarios`(목록)엔 canPlay 없음 (상세엔 있음) | FE가 하드코딩 allowlist `_kPlayableIds={'1','4','5'}` 유지해야 함 | 목록 응답에 canPlay 포함 → FE allowlist 제거 가능 |
| H4 | **409 P002에 activeSessionId 없음** | 활성 세션 존재 시 409만, 세션ID 미반환 | FE가 "기존 세션 이어하기/포기" 복구 불가 | 409 body에 activeSessionId 포함 또는 `GET /play-sessions/active?scenarioId=` 추가 |

## 비차단 / 환경 메모
- 이미지 URL 전부 null: 로컬에 `AWS_S3_PUBLIC_BASE_URL` 미설정 때문. 코드 버그 아님 → FE placeholder. (운영/스테이징에선 채워짐)
- nextRecommendedScenarios 빈 배열 (result CTA용, 마이너).
- 시나리오 2·3은 stub(콘텐츠 미완) → 플레이 불가가 정상.

## 추가 핸드오프 (사이클 B 실데이터 와이어 중 발견, 2026-06-04)

| # | 항목 | 현상 | 영향 | 요청 |
|---|------|------|------|------|
| H5 | **플레이 DTO에 증거 이미지/용의자 portrait 필드 없음** | `GET /play-sessions/{id}/evidences`·`/suspects`(목록·상세) 응답에 `imageUrl`/`portraitImageUrl` 자체가 없음(작성용 DTO·시나리오 cover/map·user profile에만 존재) | B6(증거 이미지/용의자 portrait 와이어) 불가 → FE 아이콘/이니셜 placeholder 유지 | 플레이 증거/용의자 DTO에 이미지 URL 필드 추가 시 FE 와이어 가능 |
| H6 | **`canPlay`가 신뢰 불가** | 상세 `canPlay`가 스텁(3: 용의자0·증거0)·정답 미시드(5)에도 `true` | H3의 "canPlay로 allowlist 제거" 불가 — `_kPlayableIds={'1','4'}` 유지 | canPlay를 "끝까지 플레이 가능"(solution seed + 콘텐츠 완비) 기준으로 산출 |
