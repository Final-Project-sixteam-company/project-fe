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
  /// 실제 토큰이 있고 아직 유효할 때만 반환한다. 없거나 만료됐으면 null.
  String? get bearerToken => _cachedAccessToken;

  /// refreshToken. 갱신 플로우에서 사용한다.
  String? get refreshToken => _cachedRefreshToken;

  bool get isLoggedIn => _cachedAccessToken != null;

  Future<void> init() async {
    final prefs   = await SharedPreferences.getInstance();
    final stored  = prefs.getString(_accessKey);
    final refresh = prefs.getString(_refreshKey);

    if (stored != null && _isUsableToken(stored)) {
      _cachedAccessToken  = stored;
      _cachedRefreshToken = refresh;
    } else {
      // 더미 값이거나 만료된 토큰은 저장소에서 제거하고 null로 초기화한다.
      // ApiClient는 bearerToken == null 이면 헤더를 붙이지 않으므로
      // 백엔드에 잘못된 Bearer가 전달되는 상황을 방지한다.
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

  // ── 내부 헬퍼 ────────────────────────────────────────────────────────────

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