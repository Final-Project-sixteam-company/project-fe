// test/models/play_models_test.dart
// play_models.dart의 JSON 파싱/enum 변환 단위 테스트.
// 외부 mock 패키지 없이 flutter_test만으로 동작한다.

import 'package:flutter_test/flutter_test.dart';
import 'package:clueroom/models/play_models.dart';

void main() {
  group('enum 변환', () {
    test('evidenceImportanceFromApi — 알려진 값/미상/null 폴백', () {
      expect(evidenceImportanceFromApi('LOW'), EvidenceImportance.low);
      expect(evidenceImportanceFromApi('HIGH'), EvidenceImportance.high);
      expect(evidenceImportanceFromApi('CORE'), EvidenceImportance.core);
      expect(evidenceImportanceFromApi('FAKE'), EvidenceImportance.fake);
      // 'NORMAL'은 명시적으로 매핑되지 않고 default로 normal이 된다.
      expect(evidenceImportanceFromApi('NORMAL'), EvidenceImportance.normal);
      expect(evidenceImportanceFromApi('UNKNOWN'), EvidenceImportance.normal);
      expect(evidenceImportanceFromApi(null), EvidenceImportance.normal);
    });

    test('questionType — toApi / fromApi 왕복 + 폴백', () {
      expect(questionTypeToApi(QuestionType.free), 'FREE');
      expect(questionTypeToApi(QuestionType.recommended), 'RECOMMENDED');
      expect(
          questionTypeToApi(QuestionType.evidencePresented), 'EVIDENCE_PRESENTED');

      expect(questionTypeFromApi('RECOMMENDED'), QuestionType.recommended);
      expect(questionTypeFromApi('EVIDENCE_PRESENTED'),
          QuestionType.evidencePresented);
      // 미상/null은 free로 폴백.
      expect(questionTypeFromApi('FREE'), QuestionType.free);
      expect(questionTypeFromApi('???'), QuestionType.free);
      expect(questionTypeFromApi(null), QuestionType.free);
    });

    test('playSessionStatusFromApi — 알려진 값/폴백', () {
      expect(playSessionStatusFromApi('SUBMITTED'), PlaySessionStatus.submitted);
      expect(playSessionStatusFromApi('COMPLETED'), PlaySessionStatus.completed);
      expect(playSessionStatusFromApi('ABANDONED'), PlaySessionStatus.abandoned);
      // PLAYING/미상/null은 playing으로 폴백.
      expect(playSessionStatusFromApi('PLAYING'), PlaySessionStatus.playing);
      expect(playSessionStatusFromApi('xyz'), PlaySessionStatus.playing);
      expect(playSessionStatusFromApi(null), PlaySessionStatus.playing);
    });
  });

  group('PlayEvidence.fromJson', () {
    test('전체 필드 + relatedSuspects 파싱', () {
      final e = PlayEvidence.fromJson({
        'evidenceId': 7,
        'title': '회계 파일',
        'importance': 'CORE',
        'isUnlocked': true,
        'description': '조작된 회계 장부',
        'locationName': '대표실',
        'unlockHint': null,
        'relatedSuspects': [
          {'suspectId': 1, 'name': '박재민'},
          {'suspectId': 2, 'name': '이준호'},
        ],
      });

      expect(e.evidenceId, 7);
      expect(e.title, '회계 파일');
      expect(e.importance, EvidenceImportance.core);
      expect(e.isUnlocked, true);
      expect(e.locationName, '대표실');
      expect(e.relatedSuspects, hasLength(2));
      expect(e.relatedSuspects.first.suspectId, 1);
      expect(e.relatedSuspects.first.name, '박재민');
    });

    test('선택 필드 누락 시 안전한 기본값', () {
      final e = PlayEvidence.fromJson({'evidenceId': 1});

      expect(e.evidenceId, 1);
      expect(e.title, '');
      expect(e.importance, EvidenceImportance.normal);
      expect(e.isUnlocked, false);
      expect(e.description, isNull);
      expect(e.relatedSuspects, isEmpty);
    });
  });

  group('InterrogationResult.fromJson', () {
    test('unlockedEvidences가 {evidenceId,title}로 매핑된다', () {
      final r = InterrogationResult.fromJson({
        'interrogationId': 10,
        'suspectId': 2,
        'suspectName': '이준호',
        'question': '어디 있었나요?',
        'answer': '서버실에 있었습니다.',
        'unlockedEvidences': [
          {'evidenceId': 5, 'title': '데모 시연 코드 변경 로그'},
        ],
        'createdAt': '2026-06-02T10:00:00',
      });

      expect(r.interrogationId, 10);
      expect(r.suspectId, 2);
      expect(r.suspectName, '이준호');
      expect(r.question, '어디 있었나요?');
      expect(r.answer, '서버실에 있었습니다.');
      // 현재 구현은 evidenceId/title을 RelatedSuspect.suspectId/name에 적재한다.
      expect(r.unlockedEvidences, hasLength(1));
      expect(r.unlockedEvidences.first.suspectId, 5);
      expect(r.unlockedEvidences.first.name, '데모 시연 코드 변경 로그');
      expect(r.createdAt, DateTime.parse('2026-06-02T10:00:00'));
    });

    test('unlockedEvidences/createdAt 누락 시 기본값', () {
      final r = InterrogationResult.fromJson({
        'interrogationId': 1,
        'suspectId': 1,
      });

      expect(r.suspectName, '');
      expect(r.unlockedEvidences, isEmpty);
      expect(r.createdAt, isNull);
    });
  });

  group('DeductionResult.fromJson', () {
    test('matched/matchedParts/missedParts/correctCulprit 전체 파싱', () {
      final d = DeductionResult.fromJson({
        'sessionId': 25,
        'score': 30,
        'grade': 'D',
        'correctCulprit': {
          'suspectId': 1,
          'name': '박재민',
          'role': 'CFO / 재무이사',
        },
        'matched': {
          'culprit': true,
          'motive': false,
          'method': false,
          'coverUp': false,
          'keyEvidences': 0,
        },
        'matchedParts': ['범인을 정확히 지목했습니다.'],
        'missedParts': [
          '범행 방법을 파악하지 못했습니다.',
          '범행 동기를 파악하지 못했습니다.',
        ],
        'feedback': '핵심 추리는 정확합니다.',
        'fullExplanation': '범인은 CFO 박재민이다.',
        'keyEvidences': [
          {'evidenceId': 1, 'title': '찢긴 컵 라벨'},
        ],
        'nextRecommendedScenarios': [
          {'scenarioId': 2, 'title': '밀실의 유산'},
        ],
      });

      expect(d.sessionId, 25);
      expect(d.score, 30);
      expect(d.grade, 'D');
      expect(d.correctCulprit, isNotNull);
      expect(d.correctCulprit!.name, '박재민');
      expect(d.correctCulprit!.role, 'CFO / 재무이사');
      expect(d.matched.culprit, true);
      expect(d.matched.motive, false);
      expect(d.matched.keyEvidences, 0);
      expect(d.matchedParts, ['범인을 정확히 지목했습니다.']);
      expect(d.missedParts, hasLength(2));
      expect(d.feedback, '핵심 추리는 정확합니다.');
      expect(d.keyEvidences.single.title, '찢긴 컵 라벨');
      expect(d.nextRecommendedScenarios.single.scenarioId, 2);
    });

    test('선택 필드 누락 시 안전한 기본값', () {
      final d = DeductionResult.fromJson({'sessionId': 1});

      expect(d.sessionId, 1);
      expect(d.score, 0);
      expect(d.grade, '-');
      expect(d.correctCulprit, isNull);
      // matched 누락 → 모든 항목 false/0.
      expect(d.matched.culprit, false);
      expect(d.matched.keyEvidences, 0);
      expect(d.matchedParts, isEmpty);
      expect(d.missedParts, isEmpty);
      expect(d.feedback, '');
      expect(d.fullExplanation, '');
      expect(d.keyEvidences, isEmpty);
      expect(d.nextRecommendedScenarios, isEmpty);
    });
  });
}
