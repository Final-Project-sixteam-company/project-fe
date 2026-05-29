// lib/models/sample_case.dart
//
// CL-001 「데모데이 전야 살인사건」 샘플 데이터
//
// Evidence 구조:
//   e1~e5  : 초기 공개 증거 (isLocked: false)
//   e6~e10 : 시간 해금 증거 (isLocked: true) — PRD 8.8 대응
//            game_session_controller.dart 의 timeUnlockRules 와 ID가 1:1 매핑됨
//
// [주의] timeUnlockRules 의 evidenceId 를 변경할 경우 반드시 이 파일도 함께 수정.

import 'package:flutter/material.dart';
import 'case.dart';

const sampleCase = (
suspects: <Suspect>[
  Suspect(
    id: 's1',
    name: '박재민',
    role: 'CTO · 공동창업자',
    suspicion: 72,
  ),
  Suspect(
    id: 's2',
    name: '이수진',
    role: '재무이사 · 투자유치 담당',
    suspicion: 48,
  ),
  Suspect(
    id: 's3',
    name: '한도윤',
    role: '보안팀장 · 전직 형사',
    suspicion: 35,
  ),
  Suspect(
    id: 's4',
    name: '최아영',
    role: '인턴 · 데모룸 운영',
    suspicion: 19,
  ),
],
evidences: <Evidence>[
  // ── 초기 공개 증거 (e1~e5) ──────────────────────────────────────────────
  Evidence(
    id: 'e1',
    name: '아몬드라떼 컵',
    location: '6F · 데모룸 · 22:18',
    icon: Icons.local_cafe_outlined,
    isNew: true,
  ),
  Evidence(
    id: 'e2',
    name: '파쇄된 USB 드라이브',
    location: '6F · 서버실 · 22:31',
    icon: Icons.usb_outlined,
    isNew: true,
  ),
  Evidence(
    id: 'e3',
    name: '출입 기록 로그',
    location: '보안실 · 출력본 · 22:45',
    icon: Icons.badge_outlined,
    isAnalyzed: true,
  ),
  Evidence(
    id: 'e4',
    name: '지문 채취 봉투',
    location: '6F · 비상계단 손잡이',
    icon: Icons.fingerprint,
    isAnalyzed: true,
  ),
  Evidence(
    id: 'e5',
    name: '삭제된 슬랙 메시지',
    location: '디지털 포렌식 · 복원본',
    icon: Icons.chat_bubble_outline,
  ),
  // ── 시간 해금 증거 (e6~e10) — PRD 8.8 ──────────────────────────────────
  // game_session_controller.dart timeUnlockRules 와 ID 동기화 필수
  Evidence(
    id: 'e6',
    name: '카페 결제자 정보',
    location: '카페 · 영수증 원본 · 해금 대기',
    icon: Icons.receipt_long_outlined,
    isLocked: true,
    // 해금 조건: 게임 시작 2분 후
  ),
  Evidence(
    id: 'e7',
    name: '휴대폰 위치 기록',
    location: '통신사 · 위치 로그 · 해금 대기',
    icon: Icons.location_on_outlined,
    isLocked: true,
    // 해금 조건: 게임 시작 4분 후
  ),
  Evidence(
    id: 'e8',
    name: '회계 파일',
    location: '재무팀 서버 · 암호화 해제 · 해금 대기',
    icon: Icons.insert_drive_file_outlined,
    isLocked: true,
    // 해금 조건: 게임 시작 6분 후
  ),
  Evidence(
    id: 'e9',
    name: '에피펜 발견 위치',
    location: '데모룸 창고 · 은닉 위치 · 해금 대기',
    icon: Icons.medical_services_outlined,
    isLocked: true,
    // 해금 조건: 게임 시작 8분 후
  ),
  Evidence(
    id: 'e10',
    name: '사망 후 발신 메시지 원본',
    location: '피해자 휴대폰 · 포렌식 복원 · 해금 대기',
    icon: Icons.mark_email_unread_outlined,
    isLocked: true,
    // 해금 조건: 게임 시작 10분 후
  ),
],
timeline: <TimelineEntry>[
  TimelineEntry(
    time: '21:50',
    label: '박재민, 6층 데모룸 단독 입장 확인',
  ),
  TimelineEntry(
    time: '22:05',
    label: '박재민, 아몬드라떼 구매 지시 — 최아영 경유',
  ),
  TimelineEntry(
    time: '22:18',
    label: '아몬드라떼 컵, 데모룸 테이블 위 발견',
  ),
  TimelineEntry(
    time: '22:31',
    label: '서버실 USB 드라이브 파쇄 추정 시각',
    conflict: '박재민 출입 기록상 22:28 이미 퇴장 — 현장 접근 불가',
  ),
  TimelineEntry(
    time: '22:45',
    label: '한도윤, 보안실에서 출입 기록 출력 요청',
  ),
  TimelineEntry(
    time: '23:10',
    label: '이수진, 비상계단 통해 주차장 이동 CCTV 포착',
  ),
],
);