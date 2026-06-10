# Frontend Guidance UX Implementation Plan

기준일: 2026-06-11

대상 repo: `C:\java\assignment\spring\start-up-fe`

백엔드 기준:

- `GET /api/play-sessions/{sessionId}/evidences/{evidenceId}`
- evidence detail optional `guidance`
- locked compare evidence는 `evidenceCode`가 내려오지 않을 수 있음
- suggested question은 자동 전송 금지, prefill-only
- evidence 기반 질문은 `QuestionType.EVIDENCE_PRESENTED`와 `presentedEvidenceId` 사용

## 목표

증거 상세 화면에서 플레이어가 막히지 않도록 “무엇을 읽어야 하는지, 무엇과 비교해야 하는지, 누구에게 어떤 질문을 던져야 하는지”를 안내한다.

단, 앱이 정답 경로를 대신 풀어주는 느낌을 주면 안 된다.

```text
좋은 guidance:
이 증거에서 읽을 관찰 포인트와 비교 방향을 알려준다.

나쁜 guidance:
특정 인물의 진술이 거짓이라고 단정하거나 범인 경로를 고정한다.
```

## UX 원칙

| 원칙 | 설명 |
|---|---|
| prefill-only | 추천 질문 chip은 심문 입력창에만 채운다. 자동 전송하지 않는다 |
| user control | 최종 AI 호출은 사용자가 직접 전송 버튼을 누를 때만 발생한다 |
| evidence-aware | 증거 기반 질문은 `EVIDENCE_PRESENTED`와 `presentedEvidenceId`를 함께 사용한다 |
| lock-safe | locked compare evidence는 상세 이동을 막고 unlock hint 수준으로만 보여준다 |
| target-safe | target suspect가 현재 세션에서 유효하지 않으면 chip을 숨기거나 disabled 처리한다 |
| spoiler-safe | guidance 문구는 정답/범인/variant truth를 직접 또는 간접적으로 단정하지 않는다 |

## 백엔드 응답 계약

증거 상세 응답의 optional `guidance` 예시:

```json
{
  "evidenceId": 12,
  "title": "들뜬 MARK 9 테이프 끝",
  "description": "...",
  "guidance": {
    "readingPoints": [
      "테이프 한쪽 끝이 완전히 밀착되지 않고 들떠 있다.",
      "접착면 안쪽의 흔적과 현재 위치가 맞는지 비교해야 한다."
    ],
    "compareEvidences": [
      {
        "evidenceId": 18,
        "evidenceCode": "EVIDENCE_MATTE_GEL_SMEAR_ON_TAPE_LINE",
        "title": "테이프 선 위의 무광 겔 자국",
        "isUnlocked": true,
        "unlockHint": null
      },
      {
        "title": "아직 확인되지 않은 비교 증거",
        "isUnlocked": false,
        "unlockHint": "현장 단서를 더 확보하면 비교할 수 있습니다."
      }
    ],
    "suggestedQuestions": [
      {
        "targetCharacterCode": "SUSPECT_ACTOR",
        "targetSuspectId": 3,
        "targetName": "서이라",
        "question": "MARK 9 위치를 리허설 중 다시 확인하거나 조정한 적 있나요?"
      }
    ]
  }
}
```

실제 field 명은 backend API spec과 PR #57 계약을 기준으로 맞춘다.

## 구현 대상 파일

| 영역 | 파일 | 작업 |
|---|---|---|
| 모델 | `lib/models/play_evidence_models.dart` | `EvidenceGuidance`, `CompareEvidenceInfo`, `SuggestedQuestionInfo` 추가 |
| 증거 상세 | `lib/screens/evidence_detail_screen.dart` | guidance 데이터를 위젯에 전달 |
| 증거 상세 위젯 | `lib/screens/evidence_detail_widgets.dart` | reading/compare/question 섹션 추가 |
| 심문 화면 | `lib/screens/interrogation_chat_screen.dart` | prefill input 지원, auto-send 금지 |
| 네비게이션 | `lib/screens/suspect_detail_bottom_bar.dart` 또는 호출부 | target suspect + evidence + question 전달 |
| 세션 상태 | `lib/controllers/game_session_controller.dart` | target suspect 유효성 조회 helper 후보 |
| 테스트 | `test/models/play_models_test.dart` 또는 신규 test | guidance parsing test 추가 |

## 1. 모델 추가

파일: `lib/models/play_evidence_models.dart`

### EvidenceDetail 변경

```dart
class EvidenceDetail {
  const EvidenceDetail({
    required this.evidenceId,
    required this.title,
    required this.importance,
    this.description,
    this.imageUrl,
    this.locationName,
    this.relatedSuspects = const [],
    this.relatedTimelineEvents = const [],
    this.guidance,
  });

  final EvidenceGuidance? guidance;
}
```

### Guidance 모델 후보

```dart
class EvidenceGuidance {
  const EvidenceGuidance({
    this.readingPoints = const [],
    this.compareEvidences = const [],
    this.suggestedQuestions = const [],
  });

  final List<String> readingPoints;
  final List<CompareEvidenceInfo> compareEvidences;
  final List<SuggestedQuestionInfo> suggestedQuestions;
}
```

### CompareEvidenceInfo 후보

```dart
class CompareEvidenceInfo {
  const CompareEvidenceInfo({
    this.evidenceId,
    this.evidenceCode,
    required this.title,
    required this.isUnlocked,
    this.unlockHint,
  });

  final int? evidenceId;
  final String? evidenceCode;
  final String title;
  final bool isUnlocked;
  final String? unlockHint;
}
```

locked compare evidence는 `evidenceCode`가 없을 수 있다. 프론트는 `evidenceCode`를 required로 두면 안 된다.

### SuggestedQuestionInfo 후보

```dart
class SuggestedQuestionInfo {
  const SuggestedQuestionInfo({
    this.targetCharacterCode,
    this.targetSuspectId,
    this.targetName,
    required this.question,
  });

  final String? targetCharacterCode;
  final int? targetSuspectId;
  final String? targetName;
  final String question;
}
```

target 식별자는 backend 응답 확정 필드에 맞춰 조정한다. 프론트에서는 `targetSuspectId`가 있으면 가장 안정적이다.

## 2. Evidence Detail UI

파일:

- `lib/screens/evidence_detail_screen.dart`
- `lib/screens/evidence_detail_widgets.dart`

### 섹션 구조

증거가 unlocked이고 `guidance`가 있을 때만 노출한다.

추천 순서:

```text
관찰 정보
관찰 포인트
함께 볼 증거
이 증거로 물어볼 질문
CTA
```

### 관찰 포인트

UI:

```text
관찰 포인트
- ...
- ...
```

정책:

- empty면 섹션 숨김
- 문장 그대로 표시
- “정답”, “범인” 같은 marker는 backend validator가 막지만, 프론트는 별도 필터링하지 않는다

### 함께 볼 증거

unlocked compare evidence:

```text
[이동 가능] 증거 제목
```

동작:

- `isUnlocked == true`이고 `evidenceId != null`이면 해당 evidence detail로 이동 가능
- 현재 evidence와 같은 evidenceId면 이동 버튼 숨김

locked compare evidence:

```text
[잠김] 증거 제목
해금 힌트: ...
```

동작:

- detail 이동 금지
- `evidenceCode`를 UI에 표시하지 않음
- `unlockHint`가 있으면 보조 텍스트로 표시

주의:

- locked title 자체가 스포일러일 수 있으므로 seed 리뷰에서 title naming을 조심해야 한다.
- 프론트는 backend가 내려준 title을 임의로 더 구체화하지 않는다.

### 추천 질문

UI:

```text
이 증거로 물어볼 질문
[서이라에게] MARK 9 위치를 리허설 중 다시 확인하거나 조정한 적 있나요?
```

동작:

- tap 시 심문 화면 이동
- 질문 입력창에 prefill
- presented evidence는 현재 evidence로 설정
- 자동 전송 금지

## 3. Target Suspect 유효성 검증

관련 파일:

- `lib/controllers/game_session_controller.dart`
- `lib/screens/evidence_detail_widgets.dart`
- `lib/screens/interrogation_chat_screen.dart`

검증 기준:

```text
targetSuspectId가 현재 session.suspects에 존재해야 함
target이 witness라도 심문 가능한 대상이면 허용
현재 플레이에서 숨겨진/미해금/이탈 인물이라면 숨김 또는 disabled
```

helper 후보:

```dart
Suspect? findSuspectByBackendId(int suspectId) {
  final id = suspectId.toString();
  return _suspects.where((s) => s.id == id).firstOrNull;
}
```

정책:

| 상태 | UI |
|---|---|
| target valid | chip 표시 |
| target missing | chip 숨김 |
| target known but disabled policy | disabled + 짧은 사유 |

MVP에서는 target missing 시 숨김이 가장 안전하다.

## 4. Interrogation Prefill

파일: `lib/screens/interrogation_chat_screen.dart`

### 생성자 확장 후보

```dart
class InterrogationChatScreen extends StatefulWidget {
  const InterrogationChatScreen({
    required this.suspect,
    this.initialQuestion,
    this.presentedEvidenceId,
    this.presentedEvidenceTitle,
    super.key,
  });

  final Suspect suspect;
  final String? initialQuestion;
  final String? presentedEvidenceId;
  final String? presentedEvidenceTitle;
}
```

### init 동작

`didChangeDependencies()` 또는 `initState()`에서 최초 1회만 input에 prefill한다.

```dart
if (widget.initialQuestion?.trim().isNotEmpty == true) {
  _inputCtrl.text = widget.initialQuestion!.trim();
  _inputCtrl.selection = TextSelection.collapsed(offset: _inputCtrl.text.length);
}
```

주의:

- 화면 rebuild 때마다 덮어쓰면 안 된다.
- 사용자가 이미 입력한 draft가 있는 상태에서 guidance chip을 누른 경우 정책 필요.

추천 draft 정책:

```text
guidance chip으로 심문 화면에 진입하면 검증된 추천 질문으로 override
이미 심문 화면 안에서 chip을 누르는 구조라면 confirm 또는 replace
```

현재 구조에서는 evidence detail -> interrogation 진입이므로 override가 단순하다.

## 5. 전송 시 QuestionType 결정

현재 `_sendMessage()`는 `evidenceId`가 있으면 `EVIDENCE_PRESENTED`로 강제한다. 이 정책은 유지한다.

Guidance prefill로 들어온 경우:

```text
initialQuestion 있음
presentedEvidenceId 있음
사용자가 send tap
-> _sendMessage(input, evidenceId: presentedEvidenceId)
-> QuestionType.evidencePresented
```

자동 호출 금지:

```text
InterrogationChatScreen 진입
-> input prefill
-> 아무 API 호출 없음
-> 사용자가 전송 버튼 tap
-> POST /interrogations
```

## 6. Hardcoded Suggested Questions 처리

현재:

```dart
const _suggestedQuestions = [
  '어젯밤 10시에 어디 있었나요?',
  ...
];
```

현재 chip tap:

```dart
_sendMessage(q, questionType: QuestionType.recommended)
```

문제:

- 시나리오/증거와 무관함
- 자동 전송
- 최신 guidance 계약과 다름

처리 방안:

| 방안 | 설명 | 추천 |
|---|---|---|
| 제거 | guidance 기반 질문만 사용 | 최종 목표 |
| fallback 도움말 | guidance가 없을 때 "직접 질문해 보세요" 정도만 표시 | MVP 허용 |
| 유지하되 prefill | hardcoded question도 자동 전송하지 않음 | 과도기 가능 |

추천:

1. 자동 전송은 즉시 중단
2. hardcoded question은 guidance가 없을 때만 prefill chip으로 격하
3. evidence 기반 suggested question이 들어오면 hardcoded question 숨김

## 7. 네비게이션 흐름

### 증거 상세 -> 추천 질문 -> 심문

```text
EvidenceDetailScreen
-> SuggestedQuestion chip tap
-> target suspect 유효성 확인
-> InterrogationChatScreen(
     suspect: target,
     initialQuestion: question,
     presentedEvidenceId: currentEvidence.id,
     presentedEvidenceTitle: currentEvidence.name
   )
-> input prefill
-> 사용자가 직접 전송
```

### 함께 볼 증거 -> 증거 상세

```text
Compare evidence unlocked
-> EvidenceDetailScreen(evidenceId)

Compare evidence locked
-> 이동 없음
-> unlockHint 표시
```

## 8. UI Copy 기준

좋은 문구:

```text
이 증거에서 확인할 점
함께 비교할 증거
이 증거로 물어볼 질문
아직 해금되지 않은 비교 증거입니다.
수사가 진행되면 비교할 수 있습니다.
질문이 입력되었습니다. 전송 전에 내용을 확인하세요.
```

피해야 할 문구:

```text
이 인물의 주장은 거짓입니다.
이 증거가 범인을 가리킵니다.
이 증거를 제시하면 정답에 가까워집니다.
결정적 증거입니다.
```

프론트가 guidance text를 새로 생성하지는 않지만, UI label이 정답 유도처럼 보이지 않게 해야 한다.

## 9. 테스트 계획

### 모델 테스트

파일 후보:

- `test/models/play_models_test.dart`
- 또는 `test/models/evidence_guidance_test.dart`

검증:

```text
guidance null -> EvidenceDetail.guidance == null
readingPoints parsing
unlocked compare evidence parsing
locked compare evidence with no evidenceCode parsing
suggested question target parsing
unknown optional fields ignored
```

### 위젯/동작 테스트 후보

가능하면 후속 PR에서 추가:

```text
suggested question tap does not call API
input is prefilled
send button triggers EVIDENCE_PRESENTED with presentedEvidenceId
locked compare evidence has no navigation action
```

현재 test infra가 모델 중심이라, 1차 PR은 모델 테스트부터 추가하는 것이 현실적이다.

## 10. 수동 QA 체크리스트

```text
[ ] guidance 없는 증거 상세 화면이 기존처럼 표시된다.
[ ] readingPoints가 표시된다.
[ ] unlocked compare evidence를 누르면 해당 증거 상세로 이동한다.
[ ] locked compare evidence는 이동하지 않고 lock/hint만 표시한다.
[ ] suggested question chip을 누르면 심문 화면으로 이동한다.
[ ] 심문 입력창에 질문이 prefill된다.
[ ] chip tap만으로 AI 호출이 발생하지 않는다.
[ ] 전송 버튼을 눌러야 POST /interrogations가 호출된다.
[ ] evidence-based 질문은 EVIDENCE_PRESENTED + presentedEvidenceId로 전송된다.
[ ] target suspect가 없으면 chip이 표시되지 않는다.
```

## 11. 권장 PR 분리

한 PR에 모두 넣으면 UI/모델/navigation/test가 섞여 리뷰가 어려워진다.

권장:

1. `feat: parse evidence guidance`
   - 모델 추가
   - parsing test
   - UI 노출 없음

2. `feat: render evidence guidance`
   - readingPoints
   - compareEvidences
   - locked compare UI

3. `feat: prefill guidance questions`
   - suggested question chip
   - target validation
   - interrogation prefill
   - auto-send 제거

MVP 속도가 필요하면 1~3을 하나로 묶을 수 있지만, 리뷰 체크리스트는 위 분리 기준으로 검증한다.

## 완료 기준

```text
기능:
[ ] guidance model 파싱
[ ] evidence detail guidance 표시
[ ] suggested question prefill-only
[ ] EVIDENCE_PRESENTED 전송 유지
[ ] locked compare evidence code 미노출 가정 준수

품질:
[ ] flutter test PASS
[ ] flutter analyze PASS 또는 기존 warning만 남음
[ ] guidance 없는 시나리오 regression 없음
[ ] public-safe UI copy 유지
```
