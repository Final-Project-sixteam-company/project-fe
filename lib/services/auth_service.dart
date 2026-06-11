// lib/services/auth_service.dart
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

  String? _cachedAccessToken;
  String? _cachedRefreshToken;

  /// 실제 accessToken. 없으면 null — Authorization 헤더 미전송 판단 기준.
  String? get accessToken => _cachedAccessToken;

  /// 실제 refreshToken. 없으면 null.
  String? get refreshToken => _cachedRefreshToken;

  /// Authorization 헤더에 붙일 Bearer 값.
  /// 실제 토큰이 있을 때만 반환하고, 없으면 null을 반환해 헤더를 생략한다.
  String? get bearerToken => _cachedAccessToken;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_accessKey);

    // mock_jwt_token 등 더미 값은 실제 토큰으로 취급하지 않는다.
    // 실제 JWT는 'ey'로 시작하는 Base64 인코딩 구조를 가진다.
    if (stored != null && stored.startsWith('ey')) {
      _cachedAccessToken  = stored;
      _cachedRefreshToken = prefs.getString(_refreshKey);
    } else {
      // 더미 값이 남아 있다면 정리한다.
      if (stored != null) {
        await prefs.remove(_accessKey);
        await prefs.remove(_refreshKey);
      }
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

  Future<void> clearTokens() async {
    _cachedAccessToken  = null;
    _cachedRefreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
  }

  bool get isLoggedIn => _cachedAccessToken != null;
}