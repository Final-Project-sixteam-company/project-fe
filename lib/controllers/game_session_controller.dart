// lib/controllers/game_session_controller.dart
//
// 백엔드 PlaySession과 연동.
// - startSession() 시 POST /api/play-sessions 호출 후 serverSessionId 저장
// - 타이머 틱마다 시간 해금 규칙 적용 (로컬)
// - completeSession() 시 최종 추리 제출 로직과 연계

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/session_models.dart';
import '../repositories/play_session_repository.dart';

class GameSessionController extends ChangeNotifier {
  GameSessionController({required this.scenarioId})
      : sessionId = _generateSessionId();

  final String scenarioId;

  /// 로컬 세션 ID (UI 추적용)
  final String sessionId;

  /// 백엔드에서 발급받은 세션 ID
  int? serverSessionId;

  static String _generateSessionId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(0xFFFF).toRadixString(16).padLeft(4, '0');
    return 'sess_${now}_$rand';
  }

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
  bool _isLoading = false;

  bool get isStarted => _isStarted;
  bool get isCompleted => _isCompleted;
  bool get isLoading => _isLoading;

  int? _finalScore;
  int? get finalScore => _finalScore;

  // ── 진행률 ────────────────────────────────────────────────────────────────
  int progressPercent({int totalUnlockable = totalUnlockableCount}) {
    if (_isCompleted) return 100;
    if (!_isStarted) return 0;
    return ((_unlockedEvidenceIds.length / totalUnlockable) * 80)
        .clamp(0, 80)
        .round();
  }

  // ── 세션 시작 — 백엔드 연동 ───────────────────────────────────────────────

  Future<void> startSession() async {
    if (_isStarted) return;
    _isLoading = true;
    notifyListeners();

    try {
      // 시나리오 ID가 숫자이면 API 호출
      final numericId = int.tryParse(scenarioId);
      if (numericId != null) {
        final dto = await playSessionRepo.startSession(numericId);
        if (dto != null) serverSessionId = dto.sessionId;
      } else {
        // 로컬 샘플 시나리오 (demoday-eve 등)
        debugPrint('[GameSession] 로컬 시나리오 — 서버 세션 없음');
      }
    } catch (e) {
      debugPrint('[GameSession] startSession 오류: $e');
    } finally {
      _isStarted = true;
      _isLoading = false;
      _startTimer();
      notifyListeners();
    }
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

  void _checkTimeUnlocks() {
    for (final rule in timeUnlockRules) {
      if (_elapsed >= rule.after &&
          !_unlockedEvidenceIds.contains(rule.evidenceId)) {
        _unlockedEvidenceIds.add(rule.evidenceId);
        // 서버에도 해금 알림 (fire-and-forget)
        _notifyServerUnlock(rule.evidenceId);
      }
    }
  }

  void _notifyServerUnlock(String localEvidenceId) async { // async 추가
    if (serverSessionId == null) return;
    final evidenceNumId = int.tryParse(localEvidenceId.replaceFirst('e', ''));
    if (evidenceNumId == null) return;

    try {
      await playSessionRepo.unlockEvidence(serverSessionId!, evidenceNumId, 'TIME_UNLOCK');
    } catch (e) {
      // 실패해도 로컬 상태는 이미 업데이트됨
      debugPrint('[GameSession] 서버 해금 알림 실패: $e');
    }
  }

  // ── CL-001 시간 해금 규칙 ─────────────────────────────────────────────────
  static const timeUnlockRules = <_TimeUnlockRule>[
    _TimeUnlockRule(evidenceId: 'e6', after: Duration(minutes: 2)),
    _TimeUnlockRule(evidenceId: 'e7', after: Duration(minutes: 4)),
    _TimeUnlockRule(evidenceId: 'e8', after: Duration(minutes: 6)),
    _TimeUnlockRule(evidenceId: 'e9', after: Duration(minutes: 8)),
    _TimeUnlockRule(evidenceId: 'e10', after: Duration(minutes: 10)),
  ];

  static const int totalUnlockableCount = 5;

  bool isEvidenceUnlocked(String evidenceId) =>
      _unlockedEvidenceIds.contains(evidenceId);

  void unlockEvidence(String evidenceId) {
    if (_unlockedEvidenceIds.add(evidenceId)) {
      notifyListeners();
    }
  }

  // ── 힌트 사용 ─────────────────────────────────────────────────────────────
  void useHint(HintLevel level) {
    _usedHints.add(HintRecord(level: level, usedAt: _elapsed));
    notifyListeners();
  }

  bool get canUseHint => !_isCompleted;

  // ── 심문 로그 ─────────────────────────────────────────────────────────────
  void addInterrogationLog(InterrogationLog log) {
    _logs.add(log);
    notifyListeners();
  }

  // ── 세션 종료 ─────────────────────────────────────────────────────────────
  void completeSession({required int rawScore}) {
    _isCompleted = true;
    _timer?.cancel();
    _finalScore = (rawScore - hintPenalty).clamp(0, 100).toInt();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class _TimeUnlockRule {
  const _TimeUnlockRule({required this.evidenceId, required this.after});

  final String evidenceId;
  final Duration after;
}