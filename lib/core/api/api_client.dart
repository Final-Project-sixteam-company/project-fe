// lib/core/api/api_client.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../services/auth_service.dart';
import 'api_config.dart';
import 'api_exception.dart';

/// Authorization 헤더를 붙이지 않을 경로 접두사 목록.
/// 인증 엔드포인트 자체에 만료된 Bearer가 실려서 401이 나는 상황을 방지한다.
const _kNoAuthPaths = <String>{
  '/api/auth/oauth',
  '/api/auth/refresh',
  '/api/auth/logout',
  '/api/auth/dev',
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
      page:          (json['page']          as num?)?.toInt() ?? 0,
      size:          (json['size']          as num?)?.toInt() ?? rawContent.length,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? rawContent.length,
      totalPages:    (json['totalPages']    as num?)?.toInt() ?? 1,
      hasNext:        json['hasNext']       as bool?          ?? false,
    );
  }
}

/// 백엔드 공통 응답 포맷(`{success, data, error}`)을 처리하는 HTTP 클라이언트.
///
/// Authorization 헤더 정책:
///   - 실제 accessToken이 존재할 때만 `Authorization: Bearer {token}` 을 첨부한다.
///   - _kNoAuthPaths 에 포함된 인증 전용 경로에는 헤더를 붙이지 않는다.
///   - mock/더미 토큰은 AuthService.init()에서 걸러지므로 여기서는 null 여부만 확인한다.
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  final http.Client _http = http.Client();

  Future<dynamic> get(
      String path, {
        Map<String, dynamic>? query,
        Duration? timeout,
      }) =>
      _send('GET', path, query: query, timeout: timeout);

  Future<dynamic> post(
      String path, {
        Object? body,
        Map<String, dynamic>? query,
        Duration? timeout,
      }) =>
      _send('POST', path, body: body, query: query, timeout: timeout);

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
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept':       'application/json',
    };

    // 실제 accessToken이 있고, 인증 전용 경로가 아닐 때만 헤더를 첨부한다.
    if (!_kNoAuthPaths.contains(path)) {
      final token = AuthService.instance.bearerToken;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    final encodedBody = body == null ? null : jsonEncode(body);

    http.Response res;
    try {
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (encodedBody != null) request.body = encodedBody;
      final streamed = await _http
          .send(request)
          .timeout(timeout ?? ApiConfig.timeout);
      res = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw ApiException.timeout();
    } on SocketException {
      throw ApiException.network();
    } on http.ClientException {
      throw ApiException.network();
    }

    return _parse(res);
  }

  Uri _buildUri(String path, Map<String, dynamic>? query) {
    final base = Uri.parse('${ApiConfig.baseUrl}$path');
    if (query == null || query.isEmpty) return base;
    final qp = <String, String>{};
    query.forEach((key, value) {
      if (value != null) qp[key] = value.toString();
    });
    return base.replace(
      queryParameters: {...base.queryParameters, ...qp},
    );
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
        code:    error['code']?.toString()    ?? 'UNKNOWN',
        message: error['message']?.toString() ?? '알 수 없는 오류가 발생했습니다.',
        status:  (error['status'] as num?)?.toInt() ?? res.statusCode,
      );
    }
    throw ApiException(
      code:    'UNKNOWN',
      message: '알 수 없는 오류가 발생했습니다.',
      status:  res.statusCode,
    );
  }
}