import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../core/api/api_exception.dart';
import '../models/case.dart';
import '../models/play_models.dart';
import '../models/session_models.dart';
import '../repositories/play_session_repository.dart';

class GameSessionController extends ChangeNotifier {
  GameSessionController({required this.scenarioId})
      : sessionId = _generateSessionId();

  final String scenarioId;

  /// 클라이언트 측 임시 ID(로깅/표시용). 실제 서버 세션은 [backendSessionId].
  final String sessionId;

  static String _generateSessionId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(0xFFFF).toRadixString(16).padLeft(4, '0');
    return 'sess_${now}_$rand';
  }

  final PlaySessionRepository _repo = playSessionRepo;

  // ── 서버 세션 ─────────────────────────────────────────────────────────────
  /// 백엔드 플레이 세션 ID. 세션 생성 성공 후 채워진다.
  int? backendSessionId;

  bool _loading = false;
  String? _loadError;
  bool get isLoading => _loading;
  String? get loadError => _loadError;

  DashboardInfo? _dashboard;
  DashboardInfo? get dashboard => _dashboard;

  List<Suspect> _suspects = const [];
  List<Suspect> get suspects => _suspects;

  final Map<String, PlaySuspect> _suspectRaw = {};
  PlaySuspect? rawSuspect(String id) => _suspectRaw[id];

  List<Evidence> _evidences = const [];
  List<Evidence> get evidences => _evidences;

  final Map<String, PlayEvidence> _evidenceRaw = {};
  PlayEvidence? rawEvidence(String id) => _evidenceRaw[id];

  /// 시나리오 식별자를 정수 백엔드 ID로 변환. 변환 불가(샘플 시나리오) 시 null.
  int? get _backendScenarioId {
    final parsed = int.tryParse(scenarioId);
    if (parsed != null) return parsed;
    // 샘플 데모 시나리오 식별자 → 백엔드 시드 시나리오(1) 매핑
    if (scenarioId == 'demoday-eve') return 1;
    return null;
  }

  bool get isServerBacked => _backendScenarioId != null;

  /// 서버에서 세션 생성 + 초기 데이터(대시보드/용의자/증거) 로딩.
  Future<void> loadFromServer() async {
    final sid = _backendScenarioId;
    if (sid == null) return; // 샘플 시나리오는 서버 연동 생략
    _loading = true;
    _loadError = null;
    notifyListeners();
    try {
      final session = await _repo.createSession(sid);
      backendSessionId = session.sessionId;
      await _refreshAll();
    } on ApiException catch (e) {
      _loadError = e.message;
    } catch (_) {
      _loadError = '플레이 데이터를 불러오지 못했습니다.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshAll() async {
    final id = backendSessionId;
    if (id == null) return;
    final results = await Future.wait([
      _repo.dashboard(id),
      _repo.suspects(id),
      _repo.evidences(id, includeLocked: true),
    ]);
    _dashboard = results[0] as DashboardInfo;

    final rawSuspects = results[1] as List<PlaySuspect>;
    _suspectRaw
      ..clear()
      ..addEntries(rawSuspects.map((s) => MapEntry(s.suspectId.toString(), s)));
    _suspects = rawSuspects.map(_toSuspect).toList();

    final rawEvidences = results[2] as List<PlayEvidence>;
    _evidenceRaw
      ..clear()
      ..addEntries(
          rawEvidences.map((e) => MapEntry(e.evidenceId.toString(), e)));
    _evidences = rawEvidences.map(_toEvidence).toList();
    _syncUnlockedFromServer(rawEvidences);
  }

  /// 증거/대시보드만 다시 로드(심문으로 증거 해금 후, 시간 경과 후 등).
  Future<void> refreshEvidences() async {
    final id = backendSessionId;
    if (id == null) return;
    try {
      final results = await Future.wait([
        _repo.dashboard(id),
        _repo.evidences(id, includeLocked: true),
      ]);
      _dashboard = results[0] as DashboardInfo;
      final rawEvidences = results[1] as List<PlayEvidence>;
      _evidenceRaw
        ..clear()
        ..addEntries(
            rawEvidences.map((e) => MapEntry(e.evidenceId.toString(), e)));
      _evidences = rawEvidences.map(_toEvidence).toList();
      _syncUnlockedFromServer(rawEvidences);
      notifyListeners();
    } catch (_) {
      // 새로고침 실패는 조용히 무시(기존 데이터 유지)
    }
  }

  void _syncUnlockedFromServer(List<PlayEvidence> raw) {
    _unlockedEvidenceIds
      ..clear()
      ..addAll(
          raw.where((e) => e.isUnlocked).map((e) => e.evidenceId.toString()));
  }

  Suspect _toSuspect(PlaySuspect s) => Suspect(
        id: s.suspectId.toString(),
        name: s.name,
        role: s.role ?? '',
        suspicion: s.suspicionLevel,
      );

  Evidence _toEvidence(PlayEvidence e) => Evidence(
        id: e.evidenceId.toString(),
        name: e.title,
        location: e.locationName ?? (e.isUnlocked ? '미상' : '???'),
        icon: _iconForImportance(e.importance),
        isLocked: !e.isUnlocked,
        // 핵심(CORE) 증거는 '핵심 증거' 필터에 노출되도록 표시
        isAnalyzed: e.importance == EvidenceImportance.core,
      );

  static IconData _iconForImportance(EvidenceImportance imp) => switch (imp) {
        EvidenceImportance.core => Icons.gpp_maybe_outlined,
        EvidenceImportance.high => Icons.priority_high,
        EvidenceImportance.fake => Icons.block_outlined,
        _ => Icons.description_outlined,
      };

  // ── 타이머(경과 시간 표시용) ─────────────────────────────────────────────────
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  Duration get elapsed => _elapsed;

  String get elapsedLabel {
    final m = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── 해금된 증거(서버 동기화) ─────────────────────────────────────────────────
  final Set<String> _unlockedEvidenceIds = {};
  Set<String> get unlockedEvidenceIds => Set.unmodifiable(_unlockedEvidenceIds);

  int get unlockedCount =>
      _dashboard?.unlockedEvidenceCount ?? _unlockedEvidenceIds.length;
  int get totalEvidenceCount =>
      _dashboard?.totalEvidenceCount ?? _evidences.length;

  // ── 힌트 ─────────────────────────────────────────────────────────────────
  final List<HintRecord> _usedHints = [];
  List<HintRecord> get usedHints => List.unmodifiable(_usedHints);

  int get hintPenalty => _usedHints.fold(0, (sum, h) => sum + h.penalty);

  // ── 심문 로그 ─────────────────────────────────────────────────────────────
  final List<InterrogationLog> _logs = [];
  List<InterrogationLog> get interrogationLogs => List.unmodifiable(_logs);

  // ── 세션 상태 ─────────────────────────────────────────────────────────────
  bool _isStarted = false;
  bool _isCompleted = false;
  bool get isStarted => _isStarted;
  bool get isCompleted => _isCompleted;

  int? _finalScore;
  int? get finalScore => _finalScore;

  // ── 진행률 ────────────────────────────────────────────────────────────────
  int progressPercent({int totalUnlockable = totalUnlockableCount}) {
    if (_isCompleted) return 100;
    if (!_isStarted) return 0;
    final total = totalEvidenceCount > 0 ? totalEvidenceCount : totalUnlockable;
    return ((unlockedCount / total) * 80).clamp(0, 80).round();
  }

  // 진행률 fallback 분모(서버 카운트가 없을 때만 사용)
  static const int totalUnlockableCount = 8;

  // ── 세션 시작 ─────────────────────────────────────────────────────────────
  void startSession() {
    if (_isStarted) return;
    _isStarted = true;
    _startTimer();
    notifyListeners();
    // 서버 세션 생성 + 데이터 로딩(비동기)
    loadFromServer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed += const Duration(seconds: 1);
      notifyListeners();
    });
  }

  bool isEvidenceUnlocked(String evidenceId) =>
      _unlockedEvidenceIds.contains(evidenceId);

  /// 조건 기반 수동 해금(로컬 즉시 반영). 서버 새로고침은 [refreshEvidences].
  void unlockEvidence(String evidenceId) {
    if (_unlockedEvidenceIds.add(evidenceId)) {
      notifyListeners();
    }
  }

  // ── 힌트 사용 ─────────────────────────────────────────────────────────────
  void useHint(HintLevel level) {
    final record = HintRecord(level: level, usedAt: _elapsed);
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
    _finalScore = (rawScore - hintPenalty).clamp(0, 100).toInt();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
