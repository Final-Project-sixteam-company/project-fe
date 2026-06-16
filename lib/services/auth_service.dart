// lib/services/auth_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api/api_client.dart';
import '../core/api/api_exception.dart';
import '../core/device/device_id_provider.dart';

typedef AuthTokenStoreProvider = Future<AuthTokenStore> Function();

abstract class AuthTokenStore {
  String? getString(String key);
  Future<bool> setString(String key, String value);
  Future<bool> remove(String key);
}

class _SecureAuthTokenStore implements AuthTokenStore {
  _SecureAuthTokenStore._(this._storage, this._cache);

  final FlutterSecureStorage _storage;
  final Map<String, String> _cache;

  static Future<_SecureAuthTokenStore> create({
    required String accessKey,
    required String refreshKey,
  }) async {
    const storage = FlutterSecureStorage();
    final cache = <String, String>{};

    final secureReadSucceeded = await _readTokenPairIntoCache(
      storage: storage,
      cache: cache,
      accessKey: accessKey,
      refreshKey: refreshKey,
    );
    if (secureReadSucceeded) {
      await _migrateLegacyPrefsIfNeeded(
        storage: storage,
        cache: cache,
        accessKey: accessKey,
        refreshKey: refreshKey,
      );
    } else {
      await _removeLegacyPrefsIfPresent(accessKey, refreshKey);
    }

    return _SecureAuthTokenStore._(storage, cache);
  }

  static Future<bool> _readTokenPairIntoCache({
    required FlutterSecureStorage storage,
    required Map<String, String> cache,
    required String accessKey,
    required String refreshKey,
  }) async {
    try {
      await _readIntoCache(storage, cache, accessKey);
      await _readIntoCache(storage, cache, refreshKey);
      return true;
    } catch (_) {
      cache.clear();
      await _deleteSecurePairIgnoringErrors(storage, accessKey, refreshKey);
      return false;
    }
  }

  static Future<void> _readIntoCache(
    FlutterSecureStorage storage,
    Map<String, String> cache,
    String key,
  ) async {
    final value = await storage.read(key: key);
    if (value != null) {
      cache[key] = value;
    }
  }

  static Future<void> _removeLegacyPrefsIfPresent(
    String accessKey,
    String refreshKey,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(accessKey) != null) {
      await prefs.remove(accessKey);
    }
    if (prefs.getString(refreshKey) != null) {
      await prefs.remove(refreshKey);
    }
  }

  static Future<void> _migrateLegacyPrefsIfNeeded({
    required FlutterSecureStorage storage,
    required Map<String, String> cache,
    required String accessKey,
    required String refreshKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final legacyAccess = prefs.getString(accessKey);
    final legacyRefresh = prefs.getString(refreshKey);
    final shouldMigrateAccess =
        legacyAccess != null &&
        legacyAccess.isNotEmpty &&
        cache[accessKey]?.isNotEmpty != true;
    final shouldMigrateRefresh =
        legacyRefresh != null &&
        legacyRefresh.isNotEmpty &&
        cache[refreshKey]?.isNotEmpty != true;
    final migratedKeys = <String>[];

    if (shouldMigrateAccess || shouldMigrateRefresh) {
      try {
        if (shouldMigrateAccess) {
          await storage.write(key: accessKey, value: legacyAccess);
          cache[accessKey] = legacyAccess;
          migratedKeys.add(accessKey);
        }
        if (shouldMigrateRefresh) {
          await storage.write(key: refreshKey, value: legacyRefresh);
          cache[refreshKey] = legacyRefresh;
          migratedKeys.add(refreshKey);
        }
      } catch (_) {
        for (final key in migratedKeys) {
          cache.remove(key);
        }
        await _deleteSecureKeysIgnoringErrors(storage, migratedKeys);
      }
    }

    await _removeLegacyPrefsIfPresent(accessKey, refreshKey);
  }

  static Future<void> _deleteSecurePairIgnoringErrors(
    FlutterSecureStorage storage,
    String accessKey,
    String refreshKey,
  ) => _deleteSecureKeysIgnoringErrors(storage, [accessKey, refreshKey]);

  static Future<void> _deleteSecureKeysIgnoringErrors(
    FlutterSecureStorage storage,
    Iterable<String> keys,
  ) async {
    for (final key in keys) {
      try {
        await storage.delete(key: key);
      } catch (_) {
        // Migration cleanup best-effort: startup should continue logged out.
      }
    }
  }

  @override
  String? getString(String key) => _cache[key];

  @override
  Future<bool> setString(String key, String value) async {
    await _storage.write(key: key, value: value);
    _cache[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    await _storage.delete(key: key);
    _cache.remove(key);
    return true;
  }
}

/// JWT 토큰 저장/조회 서비스.
///
/// Phase 1(Mock) 단계에서는 토큰이 없으므로 Authorization 헤더를 붙이지 않는다.
/// Phase 2(OAuth) 도입 후 saveTokens()로 실제 토큰을 저장하면 자동으로 활성화된다.
class AuthService {
  AuthService._privateConstructor();
  static final AuthService instance = AuthService._privateConstructor();

  static const String _accessKey = 'access_token';
  static const String _refreshKey = 'refresh_token';
  static const Set<String> _terminalRefreshFailureCodes = {
    'AUTH_004',
    'AUTH_005',
    'AUTH_006',
    'AUTH_007',
  };

  /// 만료 임박 판단 여유 시간. 이 시간 이내로 남은 토큰은 만료로 취급한다.
  static const Duration _expiryBuffer = Duration(seconds: 30);

  String? _cachedAccessToken;
  String? _cachedRefreshToken;
  Future<bool>? _refreshInFlight;
  Future<void> _tokenStoreLock = Future.value();
  AuthTokenStoreProvider _tokenStoreProvider = _defaultTokenStoreProvider;
  int _authGeneration = 0;

  static Future<AuthTokenStore> _defaultTokenStoreProvider() =>
      _SecureAuthTokenStore.create(
        accessKey: _accessKey,
        refreshKey: _refreshKey,
      );

  /// Authorization 헤더에 붙일 Bearer 값.
  ///
  /// 호출 시점에 토큰이 여전히 유효한지 재확인한다.
  /// 앱이 장시간 포그라운드에 머물거나 백그라운드에서 복귀했을 때
  /// init() 통과 후 만료된 토큰이 헤더에 실리는 상황을 방지한다.
  ///
  /// 만료가 감지되면 accessToken 캐시만 즉시 비운다. refreshToken은 보존해
  /// startup silent refresh 또는 명시적인 refresh 플로우에서 사용할 수 있게 한다.
  String? get bearerToken {
    final token = _cachedAccessToken;
    if (token == null) return null;

    if (!_isUsableToken(token)) {
      // accessToken만 만료 - 메모리/저장소에서 제거하되 refreshToken은 유지한다.
      _cachedAccessToken = null;
      _evictStoredAccessToken(token);
      return null;
    }

    return token;
  }

  /// refreshToken. 갱신 플로우(/api/auth/refresh)에서 사용한다.
  /// accessToken이 만료된 상태에서도 유효할 수 있으므로 별도로 관리한다.
  String? get refreshToken => _cachedRefreshToken;

  /// 실제 유효한 accessToken이 있으면 true.
  bool get isLoggedIn => bearerToken != null;

  Future<void> init() async {
    final AuthTokenStore store;
    final String? stored;
    final String? refresh;
    try {
      store = await _tokenStore();
      stored = store.getString(_accessKey);
      refresh = store.getString(_refreshKey);
    } catch (_) {
      _cachedAccessToken = null;
      _cachedRefreshToken = null;
      return;
    }

    if (stored != null && _isUsableToken(stored)) {
      // accessToken이 유효하면 둘 다 복원한다.
      _cachedAccessToken = stored;
      _cachedRefreshToken = refresh;
      return;
    }

    _cachedAccessToken = null;
    _cachedRefreshToken = refresh;
    await _removeTokenIgnoringErrors(store, _accessKey);

    if (refresh != null && refresh.isNotEmpty) {
      // accessToken이 만료되었더라도 refreshToken이 있으면 먼저 세션 복원을 시도한다.
      final refreshed = await refreshTokens();
      if (refreshed) return;
    } else {
      // 저장된 토큰 자체가 없음 - 완전 미인증 상태
      _cachedAccessToken = null;
      _cachedRefreshToken = null;
    }
  }

  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    _invalidateInFlightRefreshes();
    await _withTokenStoreLock(
      () => _persistTokens(access: access, refresh: refresh),
    );
  }

  /// accessToken과 refreshToken을 모두 삭제한다.
  /// 로그아웃 또는 terminal refresh 실패(AUTH_004~007) 시 호출한다.
  Future<void> _clearTokens() async {
    _invalidateInFlightRefreshes();
    await _withTokenStoreLock(() async {
      _cachedAccessToken = null;
      _cachedRefreshToken = null;
      try {
        final store = await _tokenStore();
        await _removeTokenPairIgnoringErrors(store);
      } catch (_) {
        // Secure storage가 복원/손상 상태여도 logout/revoke 흐름은 계속 진행한다.
      }
    });
  }

  // ── API 통합 ──────────────────────────────────────────────────────────────

  /// Dev 로그인 (Phase 1 / MVP)
  Future<void> loginDev(String email) async {
    final deviceId = await DeviceIdProvider.getOrCreate();
    final res = await ApiClient.instance.post(
      '/api/auth/dev',
      body: {'email': email, 'deviceId': deviceId},
    );
    // 응답이 { accessToken: ..., refreshToken: ..., user: ... } 형태라고 가정
    final access = res['accessToken'] as String?;
    final refresh = res['refreshToken'] as String?;

    if (access != null && refresh != null) {
      await saveTokens(access: access, refresh: refresh);
    }
  }

  /// OAuth 로그인 (Phase 2)
  ///
  /// Google은 SDK가 반환한 ID Token을 `idToken`으로, Kakao는 SDK가 반환한
  /// Access Token을 `accessToken`으로 백엔드에 전달한다.
  Future<void> loginOAuth({
    required String provider,
    String? idToken,
    String? accessToken,
  }) async {
    if (provider == 'GOOGLE' && (idToken == null || idToken.isEmpty)) {
      throw const ApiException(
        code: 'GOOGLE_ID_TOKEN_EMPTY',
        message: 'Google ID Token을 받지 못했습니다.',
      );
    }
    if (provider == 'KAKAO' && (accessToken == null || accessToken.isEmpty)) {
      throw const ApiException(
        code: 'KAKAO_ACCESS_TOKEN_EMPTY',
        message: 'Kakao Access Token을 받지 못했습니다.',
      );
    }

    final deviceId = await DeviceIdProvider.getOrCreate();
    final body = <String, dynamic>{'provider': provider, 'deviceId': deviceId};
    if (idToken != null && idToken.isNotEmpty) {
      body['idToken'] = idToken;
    }
    if (accessToken != null && accessToken.isNotEmpty) {
      body['accessToken'] = accessToken;
    }

    final res = await ApiClient.instance.post('/api/auth/oauth', body: body);
    final access = res['accessToken'] as String?;
    final refresh = res['refreshToken'] as String?;

    if (access != null && refresh != null) {
      await saveTokens(access: access, refresh: refresh);
      return;
    }

    throw const ApiException(
      code: 'AUTH_RESPONSE_INVALID',
      message: '로그인 응답에 토큰이 없습니다.',
    );
  }

  /// 로그아웃
  Future<void> logout() async {
    final refresh = _cachedRefreshToken;
    final inFlightRefresh = _refreshInFlight;

    // 이미 진행 중인 refresh가 이후 새 토큰을 받으면 저장하지 않고 서버 revoke한다.
    await _clearTokens();
    await _revokeRefreshToken(refresh);
    await _waitForRefreshRevoke(inFlightRefresh);
  }

  /// 토큰 갱신
  Future<bool> refresh() => refreshTokens();

  Future<bool> refreshTokens() {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;

    final generation = _authGeneration;
    final future = _refreshTokensInternal(generation);
    _refreshInFlight = future;
    return future.whenComplete(() {
      if (identical(_refreshInFlight, future)) {
        _refreshInFlight = null;
      }
    });
  }

  Future<bool> _refreshTokensInternal(int generation) async {
    final token = _cachedRefreshToken;
    if (token == null || token.isEmpty) return false;

    try {
      final deviceId = await DeviceIdProvider.getOrCreate();
      final res = await ApiClient.instance.post(
        '/api/auth/refresh',
        body: {'refreshToken': token, 'deviceId': deviceId},
      );
      final access = res['accessToken'] as String?;
      final newRefresh = res['refreshToken'] as String?;

      if (access != null && newRefresh != null) {
        final saved = await _saveRefreshTokensIfCurrent(
          generation: generation,
          expectedRefreshToken: token,
          access: access,
          refresh: newRefresh,
        );
        if (!saved) {
          await _revokeRefreshToken(newRefresh);
        }
        return saved;
      }
    } on ApiException catch (e) {
      // refresh token이 실제로 무효/만료된 응답일 때만 로컬 세션을 정리한다.
      if (_isTerminalRefreshFailure(e) &&
          _isCurrentRefresh(generation, token)) {
        await _clearTokens();
      }
    } catch (_) {
      // 네트워크/예상 밖 실패는 유효할 수 있는 refresh token을 보존한다.
    }
    return false;
  }

  /// 내 정보 조회
  Future<Map<String, dynamic>> fetchMe() async {
    final res = await ApiClient.instance.get('/api/auth/me');
    return res as Map<String, dynamic>;
  }

  // ── 내부 헬퍼 ────────────────────────────────────────────────────────────

  void _invalidateInFlightRefreshes() {
    _authGeneration += 1;
    _refreshInFlight = null;
  }

  Future<T> _withTokenStoreLock<T>(Future<T> Function() action) {
    final previous = _tokenStoreLock;
    final completer = Completer<void>();
    _tokenStoreLock = previous.then((_) => completer.future);

    return previous.then((_) async {
      try {
        return await action();
      } finally {
        completer.complete();
      }
    });
  }

  Future<void> _persistTokens({
    required String access,
    required String refresh,
  }) async {
    final store = await _tokenStore();
    await _writeTokenPairOrClear(
      store: store,
      access: access,
      refresh: refresh,
    );
    _cachedAccessToken = access;
    _cachedRefreshToken = refresh;
  }

  Future<bool> _saveRefreshTokensIfCurrent({
    required int generation,
    required String expectedRefreshToken,
    required String access,
    required String refresh,
  }) async {
    return _withTokenStoreLock(() async {
      if (!_isCurrentRefresh(generation, expectedRefreshToken)) {
        return false;
      }

      final store = await _tokenStore();
      if (!_isCurrentRefresh(generation, expectedRefreshToken)) {
        return false;
      }

      await _writeTokenPairOrClear(
        store: store,
        access: access,
        refresh: refresh,
      );
      if (!_isCurrentRefresh(generation, expectedRefreshToken)) {
        await _removeIfStillEqual(store, _accessKey, access);
        await _removeIfStillEqual(store, _refreshKey, refresh);
        return false;
      }

      _cachedAccessToken = access;
      _cachedRefreshToken = refresh;
      return true;
    });
  }

  bool _isCurrentRefresh(int generation, String expectedRefreshToken) {
    return generation == _authGeneration &&
        _cachedRefreshToken == expectedRefreshToken;
  }

  bool _isTerminalRefreshFailure(ApiException exception) {
    return _terminalRefreshFailureCodes.contains(exception.code);
  }

  Future<void> _revokeRefreshToken(String? refresh) async {
    if (refresh == null || refresh.isEmpty) return;

    try {
      await ApiClient.instance.post(
        '/api/auth/logout',
        body: {'refreshToken': refresh},
      );
    } catch (_) {
      // 로그아웃 API 실패해도 로컬 토큰은 지운 상태를 유지한다.
    }
  }

  Future<void> _waitForRefreshRevoke(Future<bool>? inFlightRefresh) async {
    if (inFlightRefresh == null) return;

    try {
      await inFlightRefresh;
    } catch (_) {
      // refresh 실패는 logout 결과를 되돌리지 않는다.
    }
  }

  /// bearerToken getter에서 만료 감지 시 accessToken만 저장소에서 비동기 제거한다.
  /// refreshToken은 건드리지 않는다.
  Future<void> _removeIfStillEqual(
    AuthTokenStore store,
    String key,
    String expectedValue,
  ) async {
    if (store.getString(key) == expectedValue) {
      await store.remove(key);
    }
  }

  void _evictStoredAccessToken(String expiredToken) {
    unawaited(
      _withTokenStoreLock(() async {
        final store = await _tokenStore();
        await _removeIfStillEqual(store, _accessKey, expiredToken);
      }),
    );
  }

  Future<AuthTokenStore> _tokenStore() => _tokenStoreProvider();

  Future<void> _writeTokenPairOrClear({
    required AuthTokenStore store,
    required String access,
    required String refresh,
  }) async {
    try {
      final accessSaved = await store.setString(_accessKey, access);
      final refreshSaved = await store.setString(_refreshKey, refresh);
      if (!accessSaved || !refreshSaved) {
        throw StateError('Failed to persist auth tokens');
      }
    } catch (_) {
      _cachedAccessToken = null;
      _cachedRefreshToken = null;
      await _removeTokenPairIgnoringErrors(store);
      rethrow;
    }
  }

  Future<void> _removeTokenPairIgnoringErrors(AuthTokenStore store) async {
    await _removeTokenIgnoringErrors(store, _accessKey);
    await _removeTokenIgnoringErrors(store, _refreshKey);
  }

  Future<void> _removeTokenIgnoringErrors(
    AuthTokenStore store,
    String key,
  ) async {
    try {
      await store.remove(key);
    } catch (_) {
      // 저장/복구 실패 후 partial state 정리가 목적이므로 정리 실패는 원 예외를 유지한다.
    }
  }

  void setTokenStoreProviderForTesting(AuthTokenStoreProvider provider) {
    _tokenStoreProvider = provider;
  }

  void resetForTesting() {
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    _refreshInFlight = null;
    _tokenStoreLock = Future.value();
    _authGeneration = 0;
    _tokenStoreProvider = _defaultTokenStoreProvider;
  }

  /// 토큰이 실제 JWT 형식이고 아직 유효한지 확인한다.
  ///
  /// 판단 기준:
  ///   1. 'ey'로 시작하는 Base64 JWT 형식인가 (더미/mock 값 제외)
  ///   2. payload의 `exp` 클레임이 현재 시각 + buffer 이후인가 (만료 토큰 제외)
  ///
  /// `exp` 클레임이 없는 JWT는 서버 정책에 맡기고 유효로 처리한다.
  /// 파싱에 실패하면 안전하게 false를 반환한다.
  static bool _isUsableToken(String token) {
    if (!token.startsWith('ey')) return false;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;

      // Base64Url 패딩 보정 후 payload 디코딩
      final payload = parts[1];
      final padded = payload.padRight(
        payload.length + (4 - payload.length % 4) % 4,
        '=',
      );
      final decoded =
          jsonDecode(utf8.decode(base64Url.decode(padded)))
              as Map<String, dynamic>?;

      if (decoded == null) return false;

      final exp = decoded['exp'];
      if (exp == null) {
        // exp 클레임 없는 JWT — 서버 정책에 위임, 유효로 취급
        return true;
      }

      final expiry = DateTime.fromMillisecondsSinceEpoch(
        (exp as num).toInt() * 1000,
      );
      return expiry.isAfter(DateTime.now().add(_expiryBuffer));
    } catch (_) {
      // 파싱 실패 — 안전하게 무효 처리
      return false;
    }
  }
}
