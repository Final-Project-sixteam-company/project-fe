-- 데모데이 전야 살인사건 (scenario id=1) 전체 플레이 그래프 시드
-- 멱등성: 이미 용의자가 있으면 중단하지 않고 그대로 두되, 중복 실행 방지를 위해 수동 1회 실행 권장.
SET NAMES utf8mb4;
SET @sid = 1;

-- ── 장소 ──────────────────────────────────────────────────────────────────────
INSERT INTO scenario_locations (created_at, scenario_id, name, description, map_x, map_y, sort_order) VALUES
(NOW(6), @sid, '데모룸', '피해자가 발견된 발표 시연 공간', 120, 80, 1),
(NOW(6), @sid, '재무팀 사무실', '박재민의 자리와 서랍이 있는 공간', 200, 80, 2),
(NOW(6), @sid, '복도', '데모룸과 사무실을 잇는 통로', 160, 120, 3),
(NOW(6), @sid, '대표실', '피해자의 노트북과 자료가 있던 공간', 80, 80, 4),
(NOW(6), @sid, '회사 근처 카페', '사건 전 음료가 구매된 장소', 40, 160, 5);

-- ── 피해자 ────────────────────────────────────────────────────────────────────
INSERT INTO victims (scenario_id, name, age, role, description, cause_of_death, found_condition, found_location_id, created_at) VALUES
(@sid, '강도현', 34, '모노로그랩스 대표',
 '독단적이고 성과 중심적인 대표. 심한 견과류 알레르기가 있다.',
 '알레르기 쇼크', '데모룸 바닥에 쓰러진 상태로 발견됨',
 (SELECT id FROM scenario_locations WHERE scenario_id=@sid AND name='데모룸'), NOW(6));

-- ── 용의자 ────────────────────────────────────────────────────────────────────
INSERT INTO suspects (created_at, updated_at, scenario_id, name, role, relation_to_victim, public_profile, public_statement, alibi, personality_prompt, suspicion_level, sort_order) VALUES
(NOW(6), NOW(6), @sid, '박재민', 'CFO / 재무이사', '공동창업자, 5년간 함께 일함',
 '모노로그랩스의 재무이사이자 공동창업자. 회사 투자금·운영비·재무 자료를 총괄한다.',
 '저는 그날 밤 재무팀 자리에서 투자 자료를 정리하고 있었습니다. 데모룸 근처에는 가지 않았습니다.',
 '사건 당시 재무팀 자리에서 투자 자료를 정리하고 있었다고 주장한다.',
 '차분하지만 방어적이다. 불리한 질문에는 짧게 회피하고 직접 자백하지 않는다.', 85, 1),
(NOW(6), NOW(6), @sid, '이준호', 'CTO / 기술총괄', '기술 성과를 두고 갈등',
 '핵심 AI 모델 개발을 주도한 기술총괄. 대표가 성과를 가로챈다고 느꼈다.',
 '저는 사건 당시 서버실과 제 자리를 오가며 데모 시연 코드를 점검하고 있었습니다.',
 '서버실과 본인 자리 주변에 있었다고 주장한다.',
 '논리적이고 냉정하다. 기술 얘기엔 적극적이나 개인 감정은 숨긴다.', 55, 2),
(NOW(6), NOW(6), @sid, '서유라', '마케팅 리드', '과거 연인 관계, 현재 갈등',
 '마케팅을 총괄한다. 피해자와 한때 연인이었으나 관계가 틀어졌다.',
 '저는 그날 사무실에서 데모데이 홍보 자료를 마무리하고 있었습니다.',
 '사무실에서 홍보 자료를 작업했다고 주장한다.',
 '감정 기복이 있고 방어적이다. 과거 관계 언급을 꺼린다.', 50, 3),
(NOW(6), NOW(6), @sid, '김나은', '인턴 / 운영보조', '피해자에게 책임을 떠넘겨진 경험이 있음',
 '운영보조 인턴. 잡무와 준비를 도맡으며 대표에게 자주 질책받았다.',
 '저는 발표 준비물을 챙기느라 회의실과 복도를 오갔습니다.',
 '회의실과 복도를 오갔다고 주장한다.',
 '소심하고 위축되어 있다. 질문에 장황하게 변명한다.', 35, 4),
(NOW(6), NOW(6), @sid, '오세훈', '투자사 심사역', '투자 조건을 두고 갈등',
 '투자사 심사역. 데모데이 투자 조건을 두고 대표와 신경전이 있었다.',
 '저는 외부 미팅을 마치고 늦게 회사에 들렀다가 바로 나왔습니다.',
 '외부 미팅 후 잠시 들렀다고 주장한다.',
 '계산적이고 거리를 둔다. 손해되는 말은 하지 않는다.', 45, 5);

-- ── 증거 ──────────────────────────────────────────────────────────────────────
-- 초기 공개(is_initial_public=1, unlock_type=NONE)
INSERT INTO evidences (created_at, scenario_id, location_id, title, description, evidence_type, importance, is_initial_public, unlock_type, unlock_after_minutes, sort_order) VALUES
(NOW(6), @sid, (SELECT id FROM scenario_locations WHERE scenario_id=@sid AND name='데모룸'),
 '찢긴 컵 라벨', '쓰레기통에서 발견된 컵 라벨 조각에 ''...MOND LAT...''라는 글자가 남아 있다.', 'PHYSICAL', 'CORE', 1, 'NONE', NULL, 1),
(NOW(6), @sid, (SELECT id FROM scenario_locations WHERE scenario_id=@sid AND name='데모룸'),
 '피해자 견과류 알레르기 정보', '피해자는 심한 견과류 알레르기가 있었고 에피펜을 늘 소지했다.', 'TESTIMONY', 'HIGH', 1, 'NONE', NULL, 2),
(NOW(6), @sid, (SELECT id FROM scenario_locations WHERE scenario_id=@sid AND name='회사 근처 카페'),
 '카페 결제 내역', '사건 당일 밤 오트라떼 1잔과 아몬드라떼 1잔이 같은 카드로 결제되었다.', 'DOCUMENT', 'HIGH', 1, 'NONE', NULL, 3),
(NOW(6), @sid, (SELECT id FROM scenario_locations WHERE scenario_id=@sid AND name='복도'),
 'CCTV 사각지대 출입 로그', '복도 출입 로그에 사각지대에서 머문 흔적이 남아 있다.', 'DIGITAL_LOG', 'NORMAL', 1, 'NONE', NULL, 4),
(NOW(6), @sid, (SELECT id FROM scenario_locations WHERE scenario_id=@sid AND name='대표실'),
 '데모 시연 코드 변경 로그', '발표 전날 밤 데모 시연 코드가 일부 수정된 기록.', 'DIGITAL_LOG', 'LOW', 1, 'NONE', NULL, 5);

-- 시간 해금(is_initial_public=0, unlock_type=TIME)
INSERT INTO evidences (created_at, scenario_id, location_id, title, description, evidence_type, importance, is_initial_public, unlock_type, unlock_after_minutes, sort_order) VALUES
(NOW(6), @sid, (SELECT id FROM scenario_locations WHERE scenario_id=@sid AND name='복도'),
 '피해자 휴대폰 위치 기록', '사망 추정 시간 이후에도 피해자 휴대폰이 복도 근처에서 신호를 보냈다.', 'DIGITAL_LOG', 'HIGH', 0, 'TIME', 2, 6),
(NOW(6), @sid, (SELECT id FROM scenario_locations WHERE scenario_id=@sid AND name='대표실'),
 '회계 파일', '운영비 일부가 외부 계좌로 빠져나간 정황이 담긴 회계 자료.', 'DOCUMENT', 'CORE', 0, 'TIME', 3, 7),
(NOW(6), @sid, (SELECT id FROM scenario_locations WHERE scenario_id=@sid AND name='재무팀 사무실'),
 '박재민 서랍의 에피펜', '박재민의 서랍에서 피해자의 것으로 보이는 에피펜이 발견되었다.', 'PHYSICAL', 'CORE', 0, 'TIME', 5, 8);

-- ── 증거-용의자 관계 ──────────────────────────────────────────────────────────
INSERT INTO evidence_suspects (created_at, evidence_id, suspect_id, relation_type) VALUES
(NOW(6), (SELECT id FROM evidences WHERE scenario_id=@sid AND title='찢긴 컵 라벨'), (SELECT id FROM suspects WHERE scenario_id=@sid AND name='박재민'), 'SUSPECTED'),
(NOW(6), (SELECT id FROM evidences WHERE scenario_id=@sid AND title='카페 결제 내역'), (SELECT id FROM suspects WHERE scenario_id=@sid AND name='박재민'), 'OWNER'),
(NOW(6), (SELECT id FROM evidences WHERE scenario_id=@sid AND title='회계 파일'), (SELECT id FROM suspects WHERE scenario_id=@sid AND name='박재민'), 'SUBJECT'),
(NOW(6), (SELECT id FROM evidences WHERE scenario_id=@sid AND title='박재민 서랍의 에피펜'), (SELECT id FROM suspects WHERE scenario_id=@sid AND name='박재민'), 'OWNER'),
(NOW(6), (SELECT id FROM evidences WHERE scenario_id=@sid AND title='피해자 휴대폰 위치 기록'), (SELECT id FROM suspects WHERE scenario_id=@sid AND name='박재민'), 'SUSPECTED'),
(NOW(6), (SELECT id FROM evidences WHERE scenario_id=@sid AND title='데모 시연 코드 변경 로그'), (SELECT id FROM suspects WHERE scenario_id=@sid AND name='이준호'), 'CREATOR');

-- ── 힌트 ──────────────────────────────────────────────────────────────────────
INSERT INTO hints (created_at, scenario_id, hint_level, content, unlock_after_minutes, penalty_score) VALUES
(NOW(6), @sid, 1, '피해자가 마신 음료와 알레르기 정보를 함께 살펴보세요.', NULL, 5),
(NOW(6), @sid, 2, '사라진 에피펜이 누구의 손에 있었는지 추적해보세요.', 5, 10),
(NOW(6), @sid, 3, '사망 추정 시간 이후 전송된 메시지의 발신자를 의심해보세요.', 10, 20);

-- ── 변형(정답 묶음) ──────────────────────────────────────────────────────────
INSERT INTO scenario_variants (created_at, updated_at, scenario_id, variant_name, variant_type, description, is_active, sort_order) VALUES
(NOW(6), NOW(6), @sid, '정본', 'SECRETARY', '데모데이 전야 살인사건 기본 정답 변형', 1, 1);

-- ── 정답 ──────────────────────────────────────────────────────────────────────
INSERT INTO variant_solutions (created_at, updated_at, variant_id, culprit_suspect_id, culprit_name, culprit_role, motive, method, cover_up, full_explanation, key_evidence_ids) VALUES
(NOW(6), NOW(6),
 (SELECT id FROM scenario_variants WHERE scenario_id=@sid AND is_active=1 ORDER BY sort_order LIMIT 1),
 (SELECT id FROM suspects WHERE scenario_id=@sid AND name='박재민'),
 '박재민', 'CFO / 재무이사',
 '회사 운영비 유용 사실이 데모데이에서 공개될 위기에 놓이자 이를 막기 위해.',
 '피해자의 견과류 알레르기를 이용해 아몬드라떼를 오트라떼로 착각하게 만들고, 미리 에피펜을 빼내 응급처치를 막았다.',
 '컵 라벨을 찢어 음료명을 숨기고, 사망 이후 피해자 휴대폰으로 메시지를 보내 생존한 것처럼 위장했다.',
 '범인은 CFO 박재민이다. 그는 회계 비리 발각을 막기 위해 강도현의 알레르기를 이용한 위장 살인을 저질렀다.',
 (SELECT CONCAT('[', GROUP_CONCAT(id ORDER BY id), ']') FROM evidences WHERE scenario_id=@sid AND importance='CORE'));

-- 결과 확인
SELECT 'locations' t, COUNT(*) n FROM scenario_locations WHERE scenario_id=@sid
UNION ALL SELECT 'suspects', COUNT(*) FROM suspects WHERE scenario_id=@sid
UNION ALL SELECT 'evidences', COUNT(*) FROM evidences WHERE scenario_id=@sid
UNION ALL SELECT 'evidence_suspects', COUNT(*) FROM evidence_suspects WHERE evidence_id IN (SELECT id FROM evidences WHERE scenario_id=@sid)
UNION ALL SELECT 'hints', COUNT(*) FROM hints WHERE scenario_id=@sid
UNION ALL SELECT 'variants', COUNT(*) FROM scenario_variants WHERE scenario_id=@sid
UNION ALL SELECT 'solutions', COUNT(*) FROM variant_solutions WHERE variant_id IN (SELECT id FROM scenario_variants WHERE scenario_id=@sid);
