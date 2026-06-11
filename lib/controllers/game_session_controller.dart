// lib/controllers/game_session_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api/api_exception.dart';
import '../models/case.dart';
import '../models/play_models.dart';
import '../models/session_models.dart';
import '../repositories/play_session_repository.dart';

class GameSessionController extends ChangeNotifier {
  GameSessionController({required this.scenarioId, PlaySessionRepository? repo})
      : _repo = repo ?? playSessionRepo;

  final String scenarioId;
  final PlaySessionRepository _repo;

  // ── 서버 세션 ─────────────────────────────────────────────────────────────
  int? backendSessionId;

  bool _loading = false;
  String? _loadError;
  bool get isLoading => _loading;
  String? get loadError => _loadError;

  bool _sessionConflict = false;
  bool get sessionConflict => _sessionConflict;

  DashboardInfo? _dashboard;
  DashboardInfo? get dashboard => _dashboard;

  List<Suspect> _suspects = const [];

  /// 전체 캐릭터 목록 (용의자 + 증인).
  List<Suspect> get suspects => _suspects;

  /// 범인 지목 가능한 용의자만(culpritEligible). 증인·레드헤링 등 지목불가 캐릭터 제외.
  /// SubmitScreen 드롭다운과 BottomBar 버튼 모두 이 getter를 사용한다.
  List<Suspect> get accusableSuspects =>
      _suspects.where((s) => s.culpritEligible).toList();

  final Map<String, PlaySuspect> _suspectRaw = {};
  PlaySuspect? rawSuspect(String id) => _suspectRaw[id];

  List<Evidence> _evidences = const [];
  List<Evidence> get evidences => _evidences;

  final Map<String, PlayEvidence> _evidenceRaw = {};
  PlayEvidence? rawEvidence(String id) => _evidenceRaw[id];

  /// 현장(장소) 정보. 비핵심 데이터라 로딩 실패해도 무시(null 유지).
  PlayLocations? _locations;
  PlayLocations? get locations => _locations;

  /// 시나리오 식별자를 정수 백엔드 ID로 변환. 변환 불가(샘플 시나리오) 시 null.
  int? get _backendScenarioId {
    final parsed = int.tryParse(scenarioId);
    if (parsed != null) return parsed;
    if (scenarioId == 'demoday-eve') return 1;
    return null;
  }

  bool get isServerBacked => _backendScenarioId != null;

  /// CL-001(데모데이 전야) 정적 샘플 데이터를 사용하는 세션인지 여부.
  /// 타임라인·힌트 텍스트 등 하드코딩 샘플 데이터를 표시해도 되는지 판단하는 게이트.
  /// 프론트가 서버 timeline API를 연동하면 항상 false로 교체한다.
  bool get usesCl001SampleCaseData =>
      scenarioId == 'demoday-eve' || _backendScenarioId == 1;

  // ── 세션 영속화 ───────────────────────────────────────────────────────────
  static String _activeSessionKey(int scenarioId) =>
      'active_play_session_$scenarioId';

  Future<int?> _readSavedSession(int scenarioId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_activeSessionKey(scenarioId));
  }

  Future<void> _saveSession(int scenarioId, int sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_activeSessionKey(scenarioId), sessionId);
  }

  Future<void> _clearSavedSession(int scenarioId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeSessionKey(scenarioId));
  }

  Future<void> loadFromServer() async {
    final sid = _backendScenarioId;
    if (sid == null) return;
    _loading = true;
    _loadError = null;
    _sessionConflict = false;
    notifyListeners();
    try {
      final saved = await _readSavedSession(sid);
      if (saved != null && await _tryResume(saved, sid)) return;
      final session = await _repo.createSession(sid);
      backendSessionId = session.sessionId;
      await _saveSession(sid, session.sessionId);
      await _refreshAll();
    } on ApiException catch (e) {
      if (e.status == 409) {
        _sessionConflict = true;
        _loadError = '이미 진행 중인 세션이 있어 새로 시작할 수 없습니다.';
      } else {
        _loadError = e.message;
      }
    } catch (_) {
      _loadError = '플레이 데이터를 불러오지 못했습니다.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> _tryResume(int savedId, int scenarioId) async {
    try {
      backendSessionId = savedId;
      await _refreshAll();
    } on ApiException catch (e) {
      backendSessionId = null;
      if (e.isNetwork) rethrow;
      await _clearSavedSession(scenarioId);
      return false;
    }
    if (_dashboard?.status == PlaySessionStatus.playing) return true;
    backendSessionId = null;
    await _clearSavedSession(scenarioId);
    return false;
  }

  Future<void> retry() => loadFromServer();

  /// 409(이미 진행 중 세션) 복구: 이 기기에 저장된 세션 ID가 있으면 abandon 으로
  /// 정리한 뒤 새로 시작한다. 저장 ID가 없으면(다른 기기/창에서 점유 중) 서버가
  /// 활성 세션 ID를 돌려주지 않아 FE 단독 정리가 불가하므로 안내만 갱신한다.
  Future<void> abandonConflictAndRestart() async {
    final sid = _backendScenarioId;
    if (sid == null) return;
    final saved = await _readSavedSession(sid);
    if (saved != null) {
      try {
        await _repo.abandon(saved);
      } catch (_) {
        // 정리 실패(이미 종료/네트워크 등)는 무시 — 아래에서 신규 생성을 시도한다.
      }
      await _clearSavedSession(sid);
      await loadFromServer();
      return;
    }
    // 저장된 세션이 없으면 자동 복구 불가 — 안내 문구를 명확히 갱신한다.
    _loadError = '이 기기에서 시작한 세션 기록이 없어 자동으로 정리할 수 없습니다. '
        '다른 기기/창에서 진행 중인 수사를 마치거나 중단한 뒤 다시 시도해 주세요.';
    notifyListeners();
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
      ..addEntries(
          rawSuspects.map((s) => MapEntry(s.suspectId.toString(), s)));
    _suspects = rawSuspects.map(_toSuspect).toList();

    final rawEvidences = results[2] as List<PlayEvidence>;
    _evidenceRaw
      ..clear()
      ..addEntries(
          rawEvidences.map((e) => MapEntry(e.evidenceId.toString(), e)));
    _evidences = rawEvidences.map(_toEvidence).toList();
    _syncUnlockedFromServer(rawEvidences);

    // 현장 정보는 비핵심 — 실패해도 핵심 로딩 결과를 깨뜨리지 않도록 분리 호출.
    try {
      _locations = await _repo.locations(id);
    } catch (_) {
      // 미제공/오류 시 null 유지(화면은 '현장 정보 없음'으로 표시).
    }
  }

  /// 증거/대시보드(+현장)만 다시 로드(심문으로 증거 해금 후, 시간 경과 후 등).
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
      // 현장 탭의 장소별 해금 카운트도 HUD 총합과 어긋나지 않도록 함께 갱신한다.
      // 비핵심 데이터라 실패해도 증거 갱신 결과는 유지한다.
      try {
        _locations = await _repo.locations(id);
      } catch (_) {
        // 미제공/오류 시 기존 현장 정보 유지
      }
      notifyListeners();
    } catch (_) {}
  }

  void _syncUnlockedFromServer(List<PlayEvidence> raw) {
    _unlockedEvidenceIds
      ..clear()
      ..addAll(raw
          .where((e) => e.isUnlocked)
          .map((e) => e.evidenceId.toString()));
  }

  // ── 모델 변환 ─────────────────────────────────────────────────────────────

  Suspect _toSuspect(PlaySuspect s) => Suspect(
        id: s.suspectId.toString(),
        name: s.name,
        role: s.role ?? '',
        suspicion: s.suspicionLevel,
        interrogationCount: s.interrogationCount,
        portraitUrl: s.portraitAssetKey,
        portraitAssetKey: s.portraitAssetKey,
        isWitness: s.isWitness,
        culpritEligible: s.culpritEligible,
      );

  Evidence _toEvidence(PlayEvidence e) => Evidence(
        id: e.evidenceId.toString(),
        name: e.title,
        location: e.locationName ?? (e.isUnlocked ? '미상' : '???'),
        icon: _iconForImportance(e.importance),
        isLocked: !e.isUnlocked,
        // 핵심(CORE) 증거는 '핵심 증거' 필터에 노출되도록 표시
        isAnalyzed: e.importance == EvidenceImportance.core,
        oneLine: e.oneLine,
        imageUrl: e.imageUrl,
        imageAssetKey: e.imageAssetKey,
        categoryLabel: e.categoryLabel,
        phase: e.phase,
        proofDimensions: e.proofDimensions,
        category: e.category,
      );

  static IconData _iconForImportance(EvidenceImportance imp) => switch (imp) {
    EvidenceImportance.core => Icons.gpp_maybe_outlined,
    EvidenceImportance.high => Icons.priority_high,
    EvidenceImportance.fake => Icons.block_outlined,
    _ => Icons.description_outlined,
  };

  // ── 타이머 ────────────────────────────────────────────────────────────────
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  Duration get elapsed => _elapsed;

  String get elapsedLabel {
    final m = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── 해금 증거 ─────────────────────────────────────────────────────────────
  final Set<String> _unlockedEvidenceIds = {};
  Set<String> get unlockedEvidenceIds =>
      Set.unmodifiable(_unlockedEvidenceIds);

  int get unlockedCount =>
      _dashboard?.unlockedEvidenceCount ?? _unlockedEvidenceIds.length;
  int get totalEvidenceCount =>
      _dashboard?.totalEvidenceCount ?? _evidences.length;

  // ── 심문 로그 ─────────────────────────────────────────────────────────────
  final List<InterrogationLog> _logs = [];
  List<InterrogationLog> get interrogationLogs => List.unmodifiable(_logs);

  // ── 세션 상태 ─────────────────────────────────────────────────────────────
  /// loadFromServer() 의 진행 중인 Future.
  /// abandonSession()이 세션 생성 완료를 기다렸다가 /abandon을 호출할 수 있도록 보관.
  Future<void>? _loadFuture;

  bool _isStarted = false;
  bool _isCompleted = false;
  bool get isStarted => _isStarted;
  bool get isCompleted => _isCompleted;

  // ── 탭 전환 인텐트 ────────────────────────────────────────────────────────
  // 증거 상세(별도 push 라우트)는 CaseScreen 의 GameSessionProvider 하위가 아니라
  // 바텀 탭 인덱스를 직접 바꿀 수 없다. 그래서 공유 컨트롤러를 인텐트 버스로 써서
  // 원하는 탭 인덱스를 올려두면 CaseScreen 이 이를 소비해 탭을 전환한다.
  int? _tabRequest;
  int? get tabRequest => _tabRequest;

  /// 특정 탭으로 전환 요청(예: 증거 상세 → 용의자 심문 탭 2).
  void requestTab(int index) {
    _tabRequest = index;
    notifyListeners();
  }

  /// CaseScreen 이 전환을 처리한 뒤 인텐트를 비운다(재알림 없음 → 루프 방지).
  void consumeTabRequest() {
    _tabRequest = null;
  }

  // ── 세션 시작 ─────────────────────────────────────────────────────────────
  void startSession() {
    if (_isStarted) return;
    _isStarted = true;
    _startTimer();
    notifyListeners();
    // Future를 보관해 abandon 시 완료 대기가 가능하도록 한다.
    _loadFuture = loadFromServer();
  }

  /// 시간 기반(TIME) 증거 해금 자동 반영을 위한 폴링 주기.
  /// 백엔드는 경과 시간(예: 2/3/5분)에 따라 증거를 해금하지만 별도 푸시가 없어,
  /// 주기적으로 다시 불러와야 새로 풀린 증거가 화면에 나타난다.
  static const int _evidencePollSeconds = 30;

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed += const Duration(seconds: 1);
      notifyListeners();
      // 30초마다 증거/대시보드 폴링 — 진행 중(PLAYING) 세션에서만.
      if (backendSessionId != null &&
          _dashboard?.status == PlaySessionStatus.playing &&
          _elapsed.inSeconds % _evidencePollSeconds == 0) {
        refreshEvidences();
      }
    });
  }

  bool isEvidenceUnlocked(String evidenceId) =>
      _unlockedEvidenceIds.contains(evidenceId);

  void unlockEvidence(String evidenceId) {
    if (_unlockedEvidenceIds.add(evidenceId)) notifyListeners();
  }

  void addInterrogationLog(InterrogationLog log) {
    _logs.add(log);
    notifyListeners();
  }

  void completeSession() {
    _isCompleted = true;
    _timer?.cancel();
    final sid = _backendScenarioId;
    if (sid != null) _clearSavedSession(sid);
    notifyListeners();
  }

  Future<void> abandonSession() async {
    if (_isCompleted) return;
    // 세션 생성이 진행 중이면 완료를 기다린 후 abandon을 실행한다.
    // fire-and-forget으로 두면 backendSessionId가 아직 null인 채로
    // abandon이 실행되어 /abandon 호출을 건너뛰고, 이후 in-flight load가
    // PLAYING 세션을 저장해 dispose된 컨트롤러에 notify하는 race가 생긴다.
    if (_loadFuture != null) {
      await _loadFuture!.catchError((_) {});
    }
    _timer?.cancel();
    final id = backendSessionId;
    final sid = _backendScenarioId;

    if (id != null) {
      try {
        await _repo.abandon(id);
        // abandon 성공 시에만 로컬 세션 키를 삭제한다.
        // 실패하면 백엔드 세션이 PLAYING으로 남으므로 키를 보존해
        // 다음 진입 시 _tryResume 경로로 재개할 수 있게 한다.
        // 키를 지우면 createSession → 409 + 복구 불가 상태가 된다.
        backendSessionId = null;
        if (sid != null) await _clearSavedSession(sid);
      } catch (_) {
        // best-effort: 서버 정리 실패 → 키 보존, 타이머만 정리.
        backendSessionId = null;
        // sid 키는 의도적으로 유지.
      }
    } else {
      backendSessionId = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
