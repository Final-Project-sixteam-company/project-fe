// lib/controllers/game_session_controller.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/session_models.dart';

class GameSessionController extends ChangeNotifier {
  GameSessionController({required this.scenarioId});

  final String scenarioId;

  // ── 타이머 ────────────────────────────────────────────────────────────────
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  Duration get elapsed => _elapsed;

  String get elapsedLabel {
    final m = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── 해금된 증거 ───────────────────────────────────────────────────────────
  final Set<String> _unlockedEvidenceIds = {};
  Set<String> get unlockedEvidenceIds =>
      Set.unmodifiable(_unlockedEvidenceIds);

  // ── 힌트 ─────────────────────────────────────────────────────────────────
  final List<HintRecord> _usedHints = [];
  List<HintRecord> get usedHints => List.unmodifiable(_usedHints);

  int get hintPenalty =>
      _usedHints.fold(0, (sum, h) => sum + h.penalty);

  // ── 심문 로그 ─────────────────────────────────────────────────────────────
  final List<InterrogationLog> _logs = [];
  List<InterrogationLog> get interrogationLogs =>
      List.unmodifiable(_logs);

  // ── 세션 상태 ─────────────────────────────────────────────────────────────
  bool _isStarted = false;
  bool _isCompleted = false;
  bool get isStarted => _isStarted;
  bool get isCompleted => _isCompleted;

  int? _finalScore;
  int? get finalScore => _finalScore;

  // ── 진행률 ────────────────────────────────────────────────────────────────
  // 총 unlock 가능한 증거 수 대비 해금 비율로 산정
  // 최종 제출 완료 시 100으로 고정
  int progressPercent({int totalUnlockable = totalUnlockableCount}) {
    if (_isCompleted) return 100;
    if (!_isStarted) return 0;
    final unlocked = _unlockedEvidenceIds.length;
    return ((unlocked / totalUnlockable) * 80).clamp(0, 80).round();
  }

  // ── 세션 시작 ─────────────────────────────────────────────────────────────
  void startSession() {
    if (_isStarted) return;
    _isStarted = true;
    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed += const Duration(seconds: 1);
      _checkTimeUnlocks();
      notifyListeners();
    });
  }

  // ── 시간 기반 증거 해금 ───────────────────────────────────────────────────
  // PRD 8.8: 게임 시작 후 특정 시간이 지나면 증거 해금
  void _checkTimeUnlocks() {
    for (final rule in timeUnlockRules) {
      if (_elapsed >= rule.after &&
          !_unlockedEvidenceIds.contains(rule.evidenceId)) {
        _unlockedEvidenceIds.add(rule.evidenceId);
        // notifyListeners는 타이머 콜백에서 이미 호출됨
      }
    }
  }

  // ── CL-001 시간 해금 규칙 ────────────────────────────────────────────────────
  // evidenceId 는 sample_case.dart 의 Evidence.id 와 반드시 1:1 대응해야 한다.
  // PRD 8.8 기준 시간값. 개발 중 빠른 확인이 필요하면 Duration(seconds: N) 으로 변경.
  static const timeUnlockRules = <_TimeUnlockRule>[
    _TimeUnlockRule(
      evidenceId: 'e6', // 카페 결제자 정보
      after: Duration(minutes: 2),
    ),
    _TimeUnlockRule(
      evidenceId: 'e7', // 휴대폰 위치 기록
      after: Duration(minutes: 4),
    ),
    _TimeUnlockRule(
      evidenceId: 'e8', // 회계 파일
      after: Duration(minutes: 6),
    ),
    _TimeUnlockRule(
      evidenceId: 'e9', // 에피펜 발견 위치
      after: Duration(minutes: 8),
    ),
    _TimeUnlockRule(
      evidenceId: 'e10', // 사망 후 발신 메시지 원본
      after: Duration(minutes: 10),
    ),
  ];

  // 해금 가능한 총 증거 수 — progressPercent 계산에 사용
  static const int totalUnlockableCount = 5;

  bool isEvidenceUnlocked(String evidenceId) =>
      _unlockedEvidenceIds.contains(evidenceId);

  /// 조건 기반 해금 (특정 심문 후 or 증거 확인 후 트리거)
  void unlockEvidence(String evidenceId) {
    if (_unlockedEvidenceIds.add(evidenceId)) {
      notifyListeners();
    }
  }

  // ── 힌트 사용 ─────────────────────────────────────────────────────────────
  void useHint(HintLevel level) {
    final record = HintRecord(
      level: level,
      usedAt: _elapsed,
    );
    _usedHints.add(record);
    notifyListeners();
  }

  bool get canUseHint => !_isCompleted;

  // ── 심문 로그 저장 ────────────────────────────────────────────────────────
  void addInterrogationLog(InterrogationLog log) {
    _logs.add(log);
    notifyListeners();
  }

  // ── 세션 종료 ─────────────────────────────────────────────────────────────
  void completeSession({required int rawScore}) {
    _isCompleted = true;
    _timer?.cancel();
    _finalScore = (rawScore - hintPenalty).clamp(0, 100);
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// ── 내부 해금 규칙 모델 ───────────────────────────────────────────────────────

class _TimeUnlockRule {
  const _TimeUnlockRule({
    required this.evidenceId,
    required this.after,
  });

  final String evidenceId;
  final Duration after;
}