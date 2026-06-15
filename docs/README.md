# ClueRoom Frontend Docs

이 디렉터리는 ClueRoom Flutter 프론트엔드의 문서 정본을 정리하기 위한 공간이다.

현재 단계는 문서 다이어트 1단계로, 기존 문서를 바로 삭제하지 않고 현재 코드와 백엔드 최신 계약을 기준으로 흡수 대상을 분류한다.

## 문서 정본 후보

| 문서 | 상태 | 역할 |
|---|---|---|
| [FRONTEND_DOCUMENT_AUDIT.md](FRONTEND_DOCUMENT_AUDIT.md) | CURRENT | 현재 문서/코드 인벤토리, 흡수 계획, 백엔드 계약 drift 목록 |
| [FRONTEND_IMPLEMENTATION_STATUS.md](FRONTEND_IMPLEMENTATION_STATUS.md) | CURRENT | 실제 Flutter 코드 기준 구현 현황 |
| [FRONTEND_BACKEND_DRIFT.md](FRONTEND_BACKEND_DRIFT.md) | CURRENT | 백엔드 최신 계약 대비 drift와 수정 우선순위 |
| [FRONTEND_API_INTEGRATION_GUIDE.md](FRONTEND_API_INTEGRATION_GUIDE.md) | CURRENT | 백엔드 최신 계약 반영을 위한 프론트 구현 가이드 |
| [FRONTEND_GUIDANCE_UX_IMPLEMENTATION_PLAN.md](FRONTEND_GUIDANCE_UX_IMPLEMENTATION_PLAN.md) | CURRENT | evidence guidance와 suggested question UX 구현 계획 |
| [FRONTEND_E2E_QA_2026-06-11_CODEX.md](FRONTEND_E2E_QA_2026-06-11_CODEX.md) | REFERENCE | 2026-06-11 frontend E2E QA 기준 리포트. 6/12 문서에서 변경 상태를 추적 |
| [FRONTEND_E2E_QA_2026-06-12_CODEX.md](FRONTEND_E2E_QA_2026-06-12_CODEX.md) | CURRENT | active session recovery 중심 2026-06-12 emulator E2E QA 결과 |
| [FRONTEND_QA_E2E_CULPRIT_CONFIRMATION_REPORT_2026-06-15.md](FRONTEND_QA_E2E_CULPRIT_CONFIRMATION_REPORT_2026-06-15.md) | CURRENT | 2026-06-15 Android E2E login blocker와 API fallback 범인 확정 QA 보고서 |
| [../README.md](../README.md) | CURRENT | ClueRoom Flutter 앱 실행/구조/백엔드 drift 요약 |
| [../api-spec.md](../api-spec.md) | CURRENT | 최신 API 정본 위치를 안내하는 notice |
| [archive/README.md](archive/README.md) | CURRENT | 흡수 완료된 과거 프론트 문서 archive index |
| [archive/frontend-legacy-20260602/api-spec_mvp-v0.1_legacy.md](archive/frontend-legacy-20260602/api-spec_mvp-v0.1_legacy.md) | HISTORICAL | 과거 API 초안 원문 |
| [archive/frontend-legacy-20260602/backend-requests_2026-06-02_v1.md](archive/frontend-legacy-20260602/backend-requests_2026-06-02_v1.md) | HISTORICAL | 2026-06-02 기준 FE -> BE 요청 문서 |
| [archive/frontend-legacy-20260602/backend-handoff-basic-gameplay_2026-06-04.md](archive/frontend-legacy-20260602/backend-handoff-basic-gameplay_2026-06-04.md) | HISTORICAL | 과거 백엔드 handoff |
| [archive/frontend-legacy-20260602/ux-fix-plan_2026-06-02.md](archive/frontend-legacy-20260602/ux-fix-plan_2026-06-02.md) | HISTORICAL | 과거 UX 수정 계획 |

## 백엔드 기준 문서

프론트 문서는 아래 백엔드 정본과 충돌하지 않게 맞춘다.

| 기준 | 백엔드 repo 경로 | 프론트에서 맞춰야 할 내용 |
|---|---|---|
| API 계약 | `start-up-project/docs/CaseLab_AI_API_Spec.md` | request/response, endpoint, status/error shape |
| 화면/API 매핑 | `start-up-project/docs/frontend/CLUEROOM_APP_FLOW_API_GUIDE.md` | 화면별 API 사용, navigation, loading/error policy |
| Guidance UX | `start-up-project/docs/scenarios/SCENARIO_GUIDANCE_UX_SPEC.md` | evidence guidance, suggested question, prefill-only 정책 |
| 실행/배포 | `start-up-project/docs/RUN_AND_DEPLOY.md` | API base URL, prod/dev 연결 기준 |
| 운영/알림 | `start-up-project/docs/infra/OPS_RUNBOOK.md` | FCM/device token, API 운영 확인 흐름 |

`SCENARIO_GUIDANCE_UX_SPEC.md`는 backend #56 문서 통합 PR 머지 후 develop 기준 정본으로 본다.
로컬 checkout 폴더명이 `start-up-project`가 아니면 실제 backend repo 경로에 맞춰 읽는다.

## 다음 단계

1. 필요하면 `FRONTEND_QA_CHECKLIST.md`를 추가해 프론트 수동 QA 절차를 정리한다.
2. 구현 PR이 올라오면 drift 문서의 해결 상태를 갱신한다.
