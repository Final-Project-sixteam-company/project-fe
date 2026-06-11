# Historical Notice

이 문서는 2026-06-02 기준 과거 FE -> BE 요청 문서다. 일부 요청은 이미 해결되었거나 최신 백엔드 계약과 달라졌다.

---

# 백엔드 요청 사항 — ClueRoom FE

- **문서 버전:** v1
- **작성일:** 2026-06-02
- **작성:** ClueRoom Android(FE) / `feat/api-integration`
- **검증 기준:** CL-001 시나리오 · `localhost:8080` · `X-User-Id: 1`

각 항목에 **현상**, **FE 영향**, **요청/제안 계약**을 적었습니다. 우선순위(P0→P3) 순.

---

## P0 — 진행 중 세션 복구 (재진입 409)

**현상:** 활성 세션이 있을 때 `POST /api/play-sessions` 가 409를 반환하는데, **기존 세션 ID를 알 방법이 없습니다.**

- `GET /api/play-sessions/active` → 404 (없음)
- `GET /api/play-sessions` (목록) → 405 METHOD_NOT_ALLOWED
- 409 응답 body에 sessionId 없음:
  ```json
  {"success":false,"error":{"code":"P002","error":"CONFLICT",
   "message":"이미 진행 중인 플레이 세션이 존재합니다.","status":409}}
  ```

**FE 영향:** 앱은 세션 ID를 로컬(SharedPreferences)에 저장해 재진입 시 재개하도록 임시 우회했으나, 로컬 저장이 없는 경우(앱 데이터 삭제·다른 기기·서버에만 PLAYING 잔존)에는 FE가 ID를 몰라 **재개도 정리도 불가** → 사용자가 막힘.

**요청 (둘 중 택1, ①이 더 간단):**

1. **409 응답에 기존 sessionId 포함** — 예: `error.details.activeSessionId` 또는 `data.sessionId`. FE가 이 ID로 재개(`/dashboard`) 또는 정리(`/abandon`) 가능.
2. **활성 세션 조회 엔드포인트 신설** — 예: `GET /api/play-sessions/active?scenarioId={id}` → 진행 중 세션의 `{sessionId, status, ...}` 반환, 없으면 204/404.

**부가:** 에러 코드 불일치 — 문서/주석은 `SESSION_ALREADY_EXISTS`, 실제 응답은 `P002`. 하나로 통일 부탁드립니다.

---

## P1 — 문서엔 있으나 미구현(404)인 엔드포인트 2종

유효한 PLAYING 세션(예: id 25)에서도 404가 납니다. (`/dashboard`, `/evidences`, `/suspects`, `/interrogations`, `/hints` 등은 정상 200)

### 1) 타임라인 — `GET /api/play-sessions/{sessionId}/timeline` (api-spec §9.9)

- **현재:** 404 (미구현). FE는 정적 샘플 데이터로 임시 표시 중 → 수사 진행과 무관하고 모순 단서가 처음부터 노출(스포일러).
- **요청:** 문서화된 형태대로 구현. (이미 §9.9에 정의됨)
  ```json
  [{"time":"22:05","title":"카페 결제","description":"...","eventType":"FACT","isTrueEvent":true,"relatedEvidenceId":3}]
  ```

### 2) 현장 정보 — `GET /api/play-sessions/{sessionId}/locations` (api-spec §9.3)

- **현재:** 404 (미구현). FE 현장(맵) 화면이 하드코딩 더미(장소·단서 개수)로 표시 중.
- **요청:** 문서화된 형태대로 구현.
  ```json
  [{"locationId":1,"name":"데모룸","description":"...","mapX":120,"mapY":80,
    "evidenceCount":3,"evidences":[{"evidenceId":1,"title":"찢긴 컵 라벨","isUnlocked":true}]}]
  ```

---

## P2 — 추가 데이터 필드

### 1) 최종 추리 — 종합 추리 서술 필드 (`POST .../final-deduction`)

- **현상:** FE는 "종합 추리 설명"을 **필수 입력**으로 받지만, 현재 요청 스키마(`selectedCulpritId, motiveText, methodText, coverUpText, selectedEvidenceIds`)에 해당 필드가 없어 **전송되지 않습니다.**
- **요청 (택1):**
  - (A) 채점/피드백에 반영할 거면 `summaryText`(또는 `reasoningText`) 필드 추가 → FE가 실어 보냄.
  - (B) 사용 안 할 거면 "받지 않음" 확정 → FE가 필수 입력을 선택/제거.
- **결정 필요:** A/B 중 어느 쪽인지 알려주시면 FE가 맞추겠습니다.

### 2) 심문 응답에 증거 적합도/결정타 플래그 (`POST .../interrogations`)

- **현상:** 응답(`answer`, `unlockedEvidences`)에 **제시한 증거가 결정적이었는지/유효했는지** 나타내는 필드가 없어, 플레이어가 증거 제시의 효과를 알 수 없습니다.
- **요청 (선택/개선):** 응답에 `evidenceRelevance`(예: `CRITICAL|RELATED|IRRELEVANT`) 또는 `isDecisive`/`contradiction` 류 플래그 추가. → FE가 말풍선에 반응 배지 표시.

---

## P3 — (선택) 결과 채점 항목별 사유

- `result` 응답의 `matchedParts`/`missedParts`는 **이미 내려오고 있어 FE에서 렌더만 하면 됩니다(백엔드 작업 불필요).**
- 다만 항목별(범인/동기/방법/은폐/증거) **짧은 채점 사유 텍스트**가 있으면 "왜 틀렸는지" 첨삭이 가능해집니다. 여유 있으면 검토 부탁.

---

## 요약

| 우선순위 | 항목 | 핵심 |
|---|---|---|
| **P0** | 진행 중 세션 복구 | 409에 sessionId 포함(권장) 또는 활성 세션 조회 API |
| **P1** | timeline 구현 | §9.9 문서화됨, 현재 404 |
| **P1** | locations 구현 | §9.3 문서화됨, 현재 404 |
| **P2** | final-deduction `summaryText` | 수용 여부 결정 필요 |
| **P2** | interrogate 증거 적합도 플래그 | 선택/개선 |
| **P3** | 채점 항목별 사유 | 선택 (matchedParts/missedParts는 이미 제공됨) |

> **핵심:** P0(409 복구)와 P1(timeline·locations 구현)이 최우선. P0는 **409 응답에 sessionId만 포함**해 주셔도 FE가 완전히 해결 가능 → 비용이 가장 작습니다.
