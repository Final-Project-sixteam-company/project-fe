// lib/core/api/api_client.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';

/// Authorization 헤더를 붙이지 않을 경로 목록.
///
/// 포함 기준: ANDROID_AUTH_INTEGRATION_GUIDE.md §7 을 정본으로 따른다.
///
/// > "Do not attach Bearer token to these auth endpoints if the HTTP client
/// >  can exclude them: POST /api/auth/oauth, /api/auth/refresh,
/// >  /api/auth/logout, /api/auth/dev"
///
/// /api/auth/logout 은 api-spec.md 상 인증 필요('O')로 표기되어 있으나,
/// ANDROID_AUTH_INTEGRATION_GUIDE.md §7 이 명시적으로 제외를 지시하므로
/// 해당 가이드를 우선한다. 백엔드가 logout 계약을 변경하면 재검토한다.
///
/// /api/auth/signup, /api/auth/login 은 두 문서 모두 인증 불필요로 일치한다.
const _kNoAuthPaths = <String>{
  '/api/auth/signup', // 인증 불필요 (api-spec.md + guide 일치)
  '/api/auth/login', // 인증 불필요 (api-spec.md + guide 일치)
  '/api/auth/oauth', // ANDROID_AUTH_INTEGRATION_GUIDE.md §7
  '/api/auth/refresh', // ANDROID_AUTH_INTEGRATION_GUIDE.md §7
  '/api/auth/logout', // ANDROID_AUTH_INTEGRATION_GUIDE.md §7 (guide 우선)
  '/api/auth/dev', // ANDROID_AUTH_INTEGRATION_GUIDE.md §7
};

/// 페이지네이션 응답(`PageResponse<T>`) 표현.
class Page<T> {
  const Page({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.hasNext,
  });

  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool hasNext;

  factory Page.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemMapper,
  ) {
    final rawContent = (json['content'] as List<dynamic>? ?? const []);
    return Page<T>(
      content: rawContent
          .map((e) => itemMapper(e as Map<String, dynamic>))
          .toList(growable: false),
      page: (json['page'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? rawContent.length,
      totalElements:
          (json['totalElements'] as num?)?.toInt() ?? rawContent.length,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      hasNext: json['hasNext'] as bool? ?? false,
    );
  }
}

/// 백엔드 공통 응답 포맷(`{success, data, error}`)을 처리하는 HTTP 클라이언트.
///
/// Authorization 헤더 정책:
///   - 실제 accessToken이 존재할 때만 `Authorization: Bearer {token}` 을 첨부한다.
///   - _kNoAuthPaths 에 포함된 경로에는 헤더를 붙이지 않는다.
///   - mock/더미/만료 토큰은 AuthService.init()에서 걸러지므로 여기서는 null 여부만 확인한다.
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  /// 외부에서 토큰을 주입할 수 있도록 제공자 연결
  String? Function()? authTokenProvider;

  /// accessToken이 없거나 만료된 보호 API 호출 전에 refresh를 시도하는 hook.
  Future<bool> Function()? authRefreshProvider;

  final http.Client _http = http.Client();

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
    Duration? timeout,
  }) => _send('GET', path, query: query, timeout: timeout);

  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    Duration? timeout,
  }) => _send('POST', path, body: body, query: query, timeout: timeout);

  Future<dynamic> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body);

  Future<dynamic> delete(String path, {Object? body}) =>
      _send('DELETE', path, body: body);

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    Duration? timeout,
  }) async {
    final uri = _buildUri(path, query);
    final requiresAuth = !_kNoAuthPaths.contains(path);
    final encodedBody = body == null ? null : jsonEncode(body);

    var headers = await _headersFor(path);
    var res = await _sendOnce(
      method,
      uri,
      headers: headers,
      encodedBody: encodedBody,
      timeout: timeout,
    );

    if (requiresAuth && res.statusCode == 401 && await _tryRefresh()) {
      headers = await _headersFor(path, refreshIfMissing: false);
      res = await _sendOnce(
        method,
        uri,
        headers: headers,
        encodedBody: encodedBody,
        timeout: timeout,
      );
    }

    return _parse(res);
  }

  Future<Map<String, String>> _headersFor(
    String path, {
    bool refreshIfMissing = true,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };

    if (_kNoAuthPaths.contains(path)) {
      return headers;
    }

    var token = authTokenProvider?.call();
    if ((token == null || token.isEmpty) && refreshIfMissing) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        token = authTokenProvider?.call();
      }
    }

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<http.Response> _sendOnce(
    String method,
    Uri uri, {
    required Map<String, String> headers,
    String? encodedBody,
    Duration? timeout,
  }) async {
    try {
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (encodedBody != null) request.body = encodedBody;
      final streamed = await _http
          .send(request)
          .timeout(timeout ?? ApiConfig.timeout);
      return http.Response.fromStream(streamed);
    } on TimeoutException {
      throw ApiException.timeout();
    } on SocketException {
      throw ApiException.network();
    } on http.ClientException {
      throw ApiException.network();
    }
  }

  Future<bool> _tryRefresh() async {
    final refresh = authRefreshProvider;
    if (refresh == null) return false;

    try {
      return await refresh();
    } catch (_) {
      return false;
    }
  }

  Uri _buildUri(String path, Map<String, dynamic>? query) {
    final base = Uri.parse('${ApiConfig.baseUrl}$path');
    if (query == null || query.isEmpty) return base;
    final qp = <String, String>{};
    query.forEach((key, value) {
      if (value != null) qp[key] = value.toString();
    });
    return base.replace(queryParameters: {...base.queryParameters, ...qp});
  }

  dynamic _parse(http.Response res) {
    Map<String, dynamic> map;
    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is! Map<String, dynamic>) throw ApiException.parse();
      map = decoded;
    } on FormatException {
      throw ApiException.parse();
    }

    final success = map['success'] == true;
    if (success) return map['data'];

    final error = map['error'];
    if (error is Map<String, dynamic>) {
      throw ApiException(
        code: error['code']?.toString() ?? 'UNKNOWN',
        message: error['message']?.toString() ?? '알 수 없는 오류가 발생했습니다.',
        status: (error['status'] as num?)?.toInt() ?? res.statusCode,
        details: error['details'] as Map<String, dynamic>?,
      );
    }
    throw ApiException(
      code: 'UNKNOWN',
      message: '알 수 없는 오류가 발생했습니다.',
      status: res.statusCode,
    );
  }
}
