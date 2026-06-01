import 'package:flutter/foundation.dart';

/// API 환경 설정.
///
/// - 안드로이드 에뮬레이터에서는 호스트 PC의 localhost 가 `10.0.2.2` 로 매핑된다.
/// - iOS 시뮬레이터/데스크톱에서는 `localhost` 가 그대로 호스트를 가리킨다.
/// - 릴리즈 빌드에서는 운영 서버를 사용한다.
class ApiConfig {
  ApiConfig._();

  static const String _prodBaseUrl = 'https://api.clueroom.xyz';
  static const int _devPort = 8080;

  /// 현재 빌드 환경에 맞는 API base URL.
  static String get baseUrl {
    if (kReleaseMode) return _prodBaseUrl;

    // 디버그/프로파일: 로컬 도커 백엔드(localhost:8080)
    final host = defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2' // 안드로이드 에뮬레이터 → 호스트 localhost
        : 'localhost';
    return 'http://$host:$_devPort';
  }

  /// 모든 컨트롤러 경로 공통 prefix.
  static const String apiPrefix = '/api';

  /// 네트워크 타임아웃.
  static const Duration timeout = Duration(seconds: 20);
}
