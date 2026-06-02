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
  /// 백엔드 플레이 세션 ID. 세션 생성 성공 후 채워진다.
  int? backendSessionId;

  bool _loading = false;
  String? _loadError;
  bool get isLoading => _loading;
  String? get loadError => _loadError;

  /// 서버에 이미 진행 중인 세션이 있어(409) 새 세션 생성이 막힌 상태.
  bool _sessionConflict = false;
  bool get sessionConflict => _sessionConflict;

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

  /// timeline/scene 화면의 하드코딩 CL-001 샘플 데이터(`sampleCase.timeline`,
  /// scene_screen 의 `_locations`)는 CL-001 케이스에서만 유효하다.
  /// 백엔드 `GET .../timeline` · `.../locations` 가 아직 404(미구현)라, 그 외
  /// 시나리오(4·5 등)에서 이 샘플을 그대로 띄우면 스포일러/서사 모순이 된다.
  /// 따라서 CL-001(샘플 id 'demoday-eve' 또는 백엔드 시드 '1')에서만 표시한다.
  /// 엔드포인트 구현 시 이 게이트를 제거하고 실데이터로 교체할 것.
  bool get usesCl001SampleCaseData =>
      scenarioId == 'demoday-eve' || scenarioId == '1';

  // ── 진행 중 세션 영속화(재진입 시 재개용) ─────────────────────────────────
  // 백엔드에 '내 활성 세션 조회' 엔드포인트가 없고, 409 응답도 기존 세션 ID를
  // 돌려주지 않는다. 그래서 세션 생성 시 ID를 기기에 저장해 두고, 재진입/콜드
  // 스타트 때 그 세션이 아직 PLAYING이면 새로 만들지 않고 그대로 이어한다.
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

  /// 진행 중인 세션 생성/로딩 future. 생성 직후 이탈(abandon) 시 이 future 의
  /// 완료를 기다려 backendSessionId 를 확보한 뒤 정리하기 위해 보관한다.
  Future<void>? _loadFuture;

  /// 서버에서 세션을 확보 + 초기 데이터(대시보드/용의자/증거) 로딩.
  /// 저장된 세션이 아직 진행 중이면 재개하고, 없으면 새로 생성한다.
  Future<void> loadFromServer() async {
    final sid = _backendScenarioId;
    if (sid == null) return; // 샘플 시나리오는 서버 연동 생략
    _loading = true;
    _loadError = null;
    _sessionConflict = false;
    notifyListeners();
    try {
      // 1) 재개: 직전에 생성한 세션이 아직 PLAYING이면 그대로 이어한다.
      final saved = await _readSavedSession(sid);
      if (saved != null && await _tryResume(saved, sid)) {
        return; // 재개 성공(_refreshAll 완료)
      }
      // 2) 신규 세션 생성
      final session = await _repo.createSession(sid);
      backendSessionId = session.sessionId;
      await _saveSession(sid, session.sessionId);
      await _refreshAll();
    } on ApiException catch (e) {
      if (e.status == 409) {
        // 진행 중 세션이 있으나 ID를 알 수 없는 경우(영속 ID 유실/다른 기기 등).
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

  /// 저장된 세션을 재개 시도. 아직 PLAYING이면 데이터를 채우고 true 반환.
  /// 완료/포기/소멸된 세션이면 저장 기록을 지우고 false(→ 신규 생성).
  Future<bool> _tryResume(int savedId, int scenarioId) async {
    try {
      backendSessionId = savedId;
      await _refreshAll();
    } on ApiException catch (e) {
      backendSessionId = null;
      if (e.isNetwork) rethrow; // 네트워크 오류는 상위 catch에서 처리
      await _clearSavedSession(scenarioId); // 404 등 → 정리 후 신규 생성
      return false;
    }
    if (_dashboard?.status == PlaySessionStatus.playing) return true;
    // 이미 끝난 세션 → 재개 불가
    backendSessionId = null;
    await _clearSavedSession(scenarioId);
    return false;
  }

  /// 로딩 실패 후 재시도(에러 화면의 '다시 시도').
  Future<void> retry() => loadFromServer();

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
        interrogationCount: s.interrogationCount,
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

  // ── 심문 로그 ─────────────────────────────────────────────────────────────
  final List<InterrogationLog> _logs = [];
  List<InterrogationLog> get interrogationLogs => List.unmodifiable(_logs);

  // ── 세션 상태 ─────────────────────────────────────────────────────────────
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
    // 서버 세션 생성 + 데이터 로딩(비동기). future 를 보관해 생성 중 이탈 시 대기 가능.
    _loadFuture = loadFromServer();
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

  // ── 심문 로그 저장 ────────────────────────────────────────────────────────
  void addInterrogationLog(InterrogationLog log) {
    _logs.add(log);
    notifyListeners();
  }

  // ── 세션 종료 ─────────────────────────────────────────────────────────────
  /// 최종 제출 완료 표시. 점수/등급은 결과 화면에서 서버 값으로 표시한다.
  void completeSession() {
    _isCompleted = true;
    _timer?.cancel();
    // 종료된 세션은 재개 대상이 아니므로 저장 기록 정리(다음 진입은 신규 생성).
    final sid = _backendScenarioId;
    if (sid != null) _clearSavedSession(sid);
    notifyListeners();
  }

  /// 진행 중인 수사를 중단(포기)한다. 뒤로가기 이탈 등에서 호출.
  /// 서버 active_key(userId_scenarioId) 유니크 제약상 PLAYING 세션을 남기면
  /// 다음 진입이 409로 막히므로 abandon API로 정리한다. 네트워크 실패는
  /// 무시(best-effort)하되, 로컬 재개 기록과 타이머는 반드시 정리한다.
  Future<void> abandonSession() async {
    if (_isCompleted) return; // 이미 끝난 세션은 포기 대상이 아니다
    // 세션 생성이 진행 중이면 완료를 기다려 backendSessionId 를 확보한 뒤 정리한다.
    // (생성 직후 이탈 시 PLAYING 세션이 서버에 잔류해 다음 진입이 409가 되는 레이스 방지)
    try {
      await _loadFuture;
    } catch (_) {
      // 로딩 실패는 무시 — 아래에서 backendSessionId 유무로 분기
    }
    _timer?.cancel();
    final id = backendSessionId;
    if (id == null) {
      // 정리할 서버 세션이 없으면 로컬 기록만 정리
      final sid = _backendScenarioId;
      if (sid != null) await _clearSavedSession(sid);
      return;
    }
    bool abandoned = false;
    try {
      await _repo.abandon(id);
      abandoned = true;
    } catch (_) {
      // 서버 정리 실패: 로컬 재개 기록을 보존해 다음 진입에서 재개/복구가 가능하도록 한다.
      // (키를 지우면 서버엔 PLAYING 세션이 남아 409가 나는데 재개할 ID도 잃는다)
    }
    backendSessionId = null;
    if (abandoned) {
      final sid = _backendScenarioId;
      if (sid != null) await _clearSavedSession(sid);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
