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
  Evidence(
    id: 'e1',
    name: '아몬드라떼 컵',
    location: '6F · 데모룸 · 22:18',
    icon: Icons.local_cafe_outlined,
    isNew: true,
    isAnalyzed: false,
  ),
  Evidence(
    id: 'e2',
    name: '파쇄된 USB 드라이브',
    location: '6F · 서버실 · 22:31',
    icon: Icons.usb_outlined,
    isNew: true,
    isAnalyzed: false,
  ),
  Evidence(
    id: 'e3',
    name: '출입 기록 로그',
    location: '보안실 · 출력본 · 22:45',
    icon: Icons.badge_outlined,
    isNew: false,
    isAnalyzed: true,
  ),
  Evidence(
    id: 'e4',
    name: '지문 채취 봉투',
    location: '6F · 비상계단 손잡이',
    icon: Icons.fingerprint,
    isNew: false,
    isAnalyzed: true,
  ),
  Evidence(
    id: 'e5',
    name: '삭제된 슬랙 메시지',
    location: '디지털 포렌식 · 복원본',
    icon: Icons.chat_bubble_outline,
    isNew: false,
    isAnalyzed: false,
  ),
  Evidence(
    id: 'e6',
    name: '암호화된 노트북',
    location: '6F · 대표실 · 잠금 해제 필요',
    icon: Icons.laptop_outlined,
    isLocked: true,
  ),
  Evidence(
    id: 'e7',
    name: '금고 내부 문서',
    location: '지하 1층 · 금고실 · 접근 제한',
    icon: Icons.folder_outlined,
    isLocked: true,
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