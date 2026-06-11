// lib/services/auth_service.dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// JWT 토큰 저장/조회 서비스.
///
/// Phase 1(Mock) 단계에서는 토큰이 없으므로 Authorization 헤더를 붙이지 않는다.
/// Phase 2(OAuth) 도입 후 saveTokens()로 실제 토큰을 저장하면 자동으로 활성화된다.
class AuthService {
  AuthService._privateConstructor();
  static final AuthService instance = AuthService._privateConstructor();

  static const String _accessKey  = 'access_token';
  static const String _refreshKey = 'refresh_token';

  /// 만료 임박 판단 여유 시간. 이 시간 이내로 남은 토큰은 만료로 취급한다.
  static const Duration _expiryBuffer = Duration(seconds: 30);

  String? _cachedAccessToken;
  String? _cachedRefreshToken;

  /// Authorization 헤더에 붙일 Bearer 값.
  ///
  /// 호출 시점에 토큰이 여전히 유효한지 재확인한다.
  /// 앱이 장시간 포그라운드에 머물거나 백그라운드에서 복귀했을 때
  /// init() 통과 후 만료된 토큰이 헤더에 실리는 상황을 방지한다.
  ///
  /// 만료가 감지되면 accessToken 캐시만 즉시 비운다.
  /// refreshToken은 갱신 플로우(/api/auth/refresh)에서 사용할 수 있으므로 보존한다.
  String? get bearerToken {
    final token = _cachedAccessToken;
    if (token == null) return null;

    if (!_isUsableToken(token)) {
      // accessToken만 만료 — 메모리·저장소에서 제거하되 refreshToken은 유지한다.
      _cachedAccessToken = null;
      _evictStoredAccessToken();
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
    final prefs   = await SharedPreferences.getInstance();
    final stored  = prefs.getString(_accessKey);
    final refresh = prefs.getString(_refreshKey);

    if (stored != null) {
      if (_isUsableToken(stored)) {
        // accessToken이 유효하면 둘 다 복원한다.
        _cachedAccessToken  = stored;
        _cachedRefreshToken = refresh;
      } else {
        // accessToken이 만료되었거나 유효하지 않으면 access/refresh 모두 완전 삭제
        await clearTokens();
      }
    } else {
      // 저장된 토큰 자체가 없음 — 완전 미인증 상태
      _cachedAccessToken  = null;
      _cachedRefreshToken = null;
    }
  }

  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    _cachedAccessToken  = access;
    _cachedRefreshToken = refresh;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey,  access);
    await prefs.setString(_refreshKey, refresh);
  }

  /// accessToken과 refreshToken을 모두 삭제한다.
  /// 로그아웃 또는 refresh 실패(AUTH_004/005) 시 호출한다.
  Future<void> clearTokens() async {
    _cachedAccessToken  = null;
    _cachedRefreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
  }

  // ── 내부 헬퍼 ────────────────────────────────────────────────────────────

  /// bearerToken getter에서 만료 감지 시 accessToken만 저장소에서 비동기 제거한다.
  /// refreshToken은 건드리지 않는다.
  void _evictStoredAccessToken() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove(_accessKey);
    });
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
      final padded  = payload.padRight(
        payload.length + (4 - payload.length % 4) % 4,
        '=',
      );
      final decoded = jsonDecode(
        utf8.decode(base64Url.decode(padded)),
      ) as Map<String, dynamic>?;

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