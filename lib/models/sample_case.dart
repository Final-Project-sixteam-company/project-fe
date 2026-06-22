// lib/models/sample_case.dart
//
// 로컬 컴포넌트 프리뷰용 중립 샘플 데이터.
// production/server-backed flow에서는 GameSessionController gate로 노출하지 않는다.

import 'package:flutter/material.dart';
import 'case.dart';

const sampleCase = (
  suspects: <Suspect>[
    Suspect(id: 's1', name: '인물 A', role: '관계자'),
    Suspect(id: 's2', name: '인물 B', role: '관계자'),
    Suspect(id: 's3', name: '인물 C', role: '참고인', isWitness: true),
    Suspect(id: 's4', name: '인물 D', role: '관계자'),
  ],
  evidences: <Evidence>[
    Evidence(
      id: 'e1',
      name: '현장 메모',
      location: '공개 장소 · 초기 확보',
      icon: Icons.description_outlined,
      isNew: true,
    ),
    Evidence(
      id: 'e2',
      name: '출입 기록',
      location: '관리 구역 · 초기 확보',
      icon: Icons.badge_outlined,
      isNew: true,
    ),
    Evidence(
      id: 'e3',
      name: '통화 기록',
      location: '디지털 자료 · 초기 확보',
      icon: Icons.call_outlined,
    ),
    Evidence(
      id: 'e4',
      name: '사진 자료',
      location: '현장 기록 · 초기 확보',
      icon: Icons.photo_outlined,
    ),
    Evidence(
      id: 'e5',
      name: '관계자 진술',
      location: '인터뷰 기록 · 초기 확보',
      icon: Icons.record_voice_over_outlined,
    ),
    Evidence(
      id: 'e6',
      name: '추가 영수증',
      location: '외부 자료 · 해금 대기',
      icon: Icons.receipt_long_outlined,
      isLocked: true,
    ),
    Evidence(
      id: 'e7',
      name: '이동 기록',
      location: '동선 자료 · 해금 대기',
      icon: Icons.location_on_outlined,
      isLocked: true,
    ),
    Evidence(
      id: 'e8',
      name: '업무 파일',
      location: '문서함 · 해금 대기',
      icon: Icons.insert_drive_file_outlined,
      isLocked: true,
    ),
    Evidence(
      id: 'e9',
      name: '보관 위치 메모',
      location: '보관함 · 해금 대기',
      icon: Icons.inventory_2_outlined,
      isLocked: true,
    ),
    Evidence(
      id: 'e10',
      name: '추가 메시지',
      location: '디지털 자료 · 해금 대기',
      icon: Icons.mark_email_unread_outlined,
      isLocked: true,
    ),
  ],
  timeline: <TimelineEntry>[
    TimelineEntry(time: '00:00', label: '사건 접수 및 현장 보존 시작'),
    TimelineEntry(time: '00:10', label: '초기 관계자 진술 확보'),
    TimelineEntry(
      time: '00:20',
      label: '공개 증거 목록 정리',
      conflict: '일부 진술의 시간대가 추가 확인 필요',
    ),
    TimelineEntry(time: '00:30', label: '추가 자료 요청'),
    TimelineEntry(time: '00:40', label: '분석 대기 항목 등록'),
  ],

  clue1HintText: '공개된 증거의 시간대와 관계자 진술이 서로 맞는지 확인해 보세요.',
  clue2HintText: '같은 장소나 시간에 연결된 증거를 함께 비교하면 다음 질문을 정하기 쉽습니다.',
  decisiveHintText: '아직 결론을 확정하지 말고 동기, 방법, 은폐 가능성을 각각 분리해서 검토하세요.',
);
