import 'package:clueroom/controllers/game_session_controller.dart';
import 'package:clueroom/core/api/api_exception.dart';
import 'package:clueroom/models/play_models.dart';
import 'package:clueroom/repositories/play_session_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('GameSessionController active session recovery', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('resumes server active session when local storage is empty', () async {
      final repo = _FakePlaySessionRepository(
        activeResponses: [
          const ActivePlaySession(
            hasActiveSession: true,
            activeSessionId: 42,
            scenarioId: 1,
            status: PlaySessionStatus.playing,
          ),
        ],
      );
      final controller = GameSessionController(scenarioId: '1', repo: repo);

      await controller.loadFromServer();

      expect(controller.backendSessionId, 42);
      expect(controller.dashboard?.status, PlaySessionStatus.playing);
      expect(controller.loadError, isNull);
      expect(controller.sessionConflict, false);
      expect(repo.createSessionCalls, 0);

      controller.dispose();
    });

    test('recovers through active lookup after create returns 409', () async {
      final repo = _FakePlaySessionRepository(
        activeResponses: [
          null,
          const ActivePlaySession(
            hasActiveSession: true,
            activeSessionId: 77,
            scenarioId: 1,
            status: PlaySessionStatus.playing,
          ),
        ],
        createError: const ApiException(
          code: 'SESSION_ALREADY_EXISTS',
          message: '이미 진행 중인 세션이 있습니다.',
          status: 409,
        ),
      );
      final controller = GameSessionController(scenarioId: '1', repo: repo);

      await controller.loadFromServer();

      expect(controller.backendSessionId, 77);
      expect(controller.dashboard?.sessionId, 77);
      expect(controller.loadError, isNull);
      expect(controller.sessionConflict, false);
      expect(repo.createSessionCalls, 1);
      expect(repo.activeSessionCalls, 2);

      controller.dispose();
    });
  });
}

class _FakePlaySessionRepository extends PlaySessionRepository {
  _FakePlaySessionRepository({
    this.activeResponses = const [],
    this.createError,
  });

  final List<ActivePlaySession?> activeResponses;
  final ApiException? createError;
  int activeSessionCalls = 0;
  int createSessionCalls = 0;

  @override
  Future<ActivePlaySession?> activeSession(int scenarioId) async {
    final index = activeSessionCalls++;
    if (index < activeResponses.length) return activeResponses[index];
    return null;
  }

  @override
  Future<PlaySessionInfo> createSession(int scenarioId) async {
    createSessionCalls++;
    final error = createError;
    if (error != null) throw error;
    return PlaySessionInfo(
      sessionId: 100 + createSessionCalls,
      scenarioId: scenarioId,
      status: PlaySessionStatus.playing,
    );
  }

  @override
  Future<DashboardInfo> dashboard(int sessionId) async => DashboardInfo(
    sessionId: sessionId,
    scenarioId: 1,
    scenarioTitle: '테스트 사건',
    status: PlaySessionStatus.playing,
    elapsedSeconds: 0,
    unlockedEvidenceCount: 0,
    totalEvidenceCount: 0,
    hintUsedCount: 0,
    interrogationCount: 0,
    briefing: const Briefing(
      victimName: '미상',
      foundLocation: '미상',
      summary: '',
    ),
  );

  @override
  Future<List<PlaySuspect>> suspects(int sessionId) async => const [];

  @override
  Future<List<PlayEvidence>> evidences(
    int sessionId, {
    bool includeLocked = false,
  }) async => const [];

  @override
  Future<PlayLocations> locations(int sessionId) async => const PlayLocations();
}
