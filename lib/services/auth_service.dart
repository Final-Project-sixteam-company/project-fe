// lib/services/auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';

/// JWT 토큰 저장/조회 서비스.
/// Phase 2(로그인 도입) 전까지는 mock_token을 사용한다.
class AuthService {
  AuthService._privateConstructor();
  static final AuthService instance = AuthService._privateConstructor();

  static const String _accessKey = 'access_token';
  static const String _refreshKey = 'refresh_token';

  String? _cachedToken;

  String? get token => _cachedToken;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_accessKey);
    // Phase 1: 토큰 없으면 mock 사용
    _cachedToken ??= 'mock_jwt_token';
  }

  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    _cachedToken = access;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey, access);
    await prefs.setString(_refreshKey, refresh);
  }

  Future<void> clearTokens() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
  }

  bool get isLoggedIn =>
      _cachedToken != null && _cachedToken != 'mock_jwt_token';
}