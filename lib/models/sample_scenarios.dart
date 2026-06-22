// lib/models/sample_scenarios.dart
import 'scenario.dart';

const sampleScenarios = <Scenario>[
  Scenario(
    id: 'demoday-eve',
    code: 'CL-001',
    title: '데모데이 전야 살인사건',
    subtitle: 'DEMODAY EVE MURDER',
    type: ScenarioType.official,
    difficulty: Difficulty.hard,
    estimatedMinutes: 30,
    suspectsCount: 5,
    evidenceCount: 12,
    rating: 4.8,
    plays: 12400,
    tags: ['스타트업', '밀실', '알레르기'],
    synopsis:
        'AI 스타트업 모노로그랩스의 대표 강도현이 데모데이 전날 밤 데모룸에서 사망한 채 발견되었다. '
        '처음에는 알레르기 쇼크로 추정됐지만, 현장에는 찢긴 컵 라벨과 사라진 에피펜, '
        '사망 이후 전송된 메시지가 남아 있었다. 외부 침입 흔적은 없고, 그날 밤 건물에 남아 있던 '
        '관계자는 총 4명. 모두 알리바이를 주장하지만 타임라인에는 설명되지 않는 공백이 있다.',
  ),
  Scenario(
    id: 'lab-fire',
    code: 'CL-002',
    title: '401호 실험실 화재',
    subtitle: 'LAB 401 ARSON',
    type: ScenarioType.official,
    difficulty: Difficulty.easy,
    estimatedMinutes: 20,
    suspectsCount: 3,
    evidenceCount: 8,
    rating: 4.3,
    plays: 8200,
    tags: ['학교', '방화', '실험실'],
    synopsis:
        '대학교 공학관 401호 실험실에서 심야 화재가 발생했다. '
        '소화기가 제자리에 없었고, CCTV는 묘하게 꺼져 있었다. '
        '세 명의 대학원생이 그날 밤 건물에 남아 있었다.',
  ),
  Scenario(
    id: 'mt-fund',
    code: 'CL-003',
    title: 'MT 별장 회비 실종',
    subtitle: 'MISSING FUNDS',
    type: ScenarioType.official,
    difficulty: Difficulty.easy,
    estimatedMinutes: 15,
    suspectsCount: 4,
    evidenceCount: 6,
    rating: 4.1,
    plays: 5600,
    tags: ['동아리', '절도', '별장'],
    synopsis:
        '동아리 MT 첫날 밤, 공동 회비 봉투가 사라졌다. '
        '별장 안 4명 중 한 명이 범인이다. '
        '영수증 한 장이 결정적 단서가 될 수 있다.',
  ),
  Scenario(
    id: 'cafe-last-order',
    code: 'CL-004',
    title: '카페 단골의 마지막 주문',
    subtitle: 'THE LAST ORDER',
    type: ScenarioType.official,
    difficulty: Difficulty.hard,
    estimatedMinutes: 45,
    suspectsCount: 5,
    evidenceCount: 14,
    rating: 4.9,
    plays: 7100,
    tags: ['카페', '독살', '단골'],
    synopsis:
        '도심 소규모 카페의 단골손님이 아메리카노를 마신 뒤 급사했다. '
        '독물 검출 결과가 양성이었고, 그날 카페에 있던 인물은 모두 사연이 있었다. '
        '마지막 주문 기록과 영수증이 열쇠다.',
  ),
  Scenario(
    id: 'q4-leak',
    code: 'CL-005',
    title: 'Q4 자료 유출 사건',
    subtitle: 'Q4 DATA BREACH',
    type: ScenarioType.official,
    difficulty: Difficulty.medium,
    estimatedMinutes: 30,
    suspectsCount: 4,
    evidenceCount: 10,
    rating: 4.5,
    plays: 4300,
    tags: ['회사', '산업스파이', '내부고발'],
    synopsis:
        '분기 마감 전날, 경쟁사에 Q4 핵심 자료가 유출됐다. '
        '접근 권한이 있는 4명 중 한 명이 범인이다. '
        '서버 접속 로그와 이메일 기록이 단서다.',
  ),
  Scenario(
    id: 'workshop-betrayal',
    code: 'CL-006',
    title: '여름 워크샵의 배신자',
    subtitle: 'SUMMER WORKSHOP',
    type: ScenarioType.custom,
    author: '탐정왕김철수',
    difficulty: Difficulty.hard,
    estimatedMinutes: 45,
    suspectsCount: 6,
    evidenceCount: 15,
    rating: 4.7,
    plays: 2100,
    tags: ['동아리', '배신', '여름'],
    synopsis:
        '해변 워크샵 마지막 날, 동아리 대표가 계좌 이체 기록과 함께 사라졌다. '
        '6명의 동아리 임원 중 누군가가 오래 전부터 계획을 세워왔다.',
  ),
];

final samplePlaySessions = <PlaySession>[
  PlaySession(
    id: 'ps1',
    scenarioId: 'demoday-eve',
    scenarioTitle: '데모데이 전야 살인사건',
    scenarioCode: 'CL-001',
    state: PlayState.inProgress,
    progressPercent: 62,
    startedAt: DateTime(2026, 5, 26, 21, 14),
  ),
  PlaySession(
    id: 'ps2',
    scenarioId: 'cafe-last-order',
    scenarioTitle: '카페 단골의 마지막 주문',
    scenarioCode: 'CL-004',
    state: PlayState.completed,
    progressPercent: 100,
    grade: 'A',
    score: 84,
    startedAt: DateTime(2026, 5, 20, 19, 0),
    completedAt: DateTime(2026, 5, 20, 20, 12),
  ),
  PlaySession(
    id: 'ps3',
    scenarioId: 'lab-fire',
    scenarioTitle: '401호 실험실 화재',
    scenarioCode: 'CL-002',
    state: PlayState.completed,
    progressPercent: 100,
    grade: 'S',
    score: 96,
    startedAt: DateTime(2026, 5, 14, 15, 30),
    completedAt: DateTime(2026, 5, 14, 16, 8),
  ),
  PlaySession(
    id: 'ps4',
    scenarioId: 'mt-fund',
    scenarioTitle: 'MT 별장 회비 실종',
    scenarioCode: 'CL-003',
    state: PlayState.abandoned,
    progressPercent: 35,
    startedAt: DateTime(2026, 5, 10, 11, 0),
  ),
];
