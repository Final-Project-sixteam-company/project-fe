import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';

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

  /// `{content, page, size, totalElements, totalPages, hasNext}` 형태 파싱.
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
      totalElements: (json['totalElements'] as num?)?.toInt() ?? rawContent.length,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      hasNext: json['hasNext'] as bool? ?? false,
    );
  }
}

/// 백엔드 공통 응답 포맷(`{success, data, error}`)을 처리하는 HTTP 클라이언트.
///
/// - 성공 시 `data` 필드(원본 JSON: Map / List / 스칼라)를 그대로 반환한다.
/// - 실패 시 [ApiException] 을 던진다.
/// - 네트워크/타임아웃/파싱 오류도 [ApiException] 으로 정규화한다.
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  final http.Client _http = http.Client();

  /// 인증 토큰 공급자. Phase 5(인증) 도입 시 AuthService 와 연결한다.
  /// 현재 백엔드는 MockUserProvider(userId=1)를 사용하므로 미설정 시 헤더를 생략한다.
  String? Function()? authTokenProvider;

  Future<dynamic> get(String path, {Map<String, dynamic>? query, Duration? timeout}) =>
      _send('GET', path, query: query, timeout: timeout);

  Future<dynamic> post(String path, {Object? body, Map<String, dynamic>? query, Duration? timeout}) =>
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
      'Accept': 'application/json',
    };
    final token = authTokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final encodedBody = body == null ? null : jsonEncode(body);

    http.Response res;
    try {
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (encodedBody != null) request.body = encodedBody;
      final streamed = await _http.send(request).timeout(timeout ?? ApiConfig.timeout);
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
    return base.replace(queryParameters: {...base.queryParameters, ...qp});
  }

  dynamic _parse(http.Response res) {
    Map<String, dynamic> map;
    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw ApiException.parse();
      }
      map = decoded;
    } on FormatException {
      throw ApiException.parse();
    }

    final success = map['success'] == true;
    if (success) {
      return map['data'];
    }

    final error = map['error'];
    if (error is Map<String, dynamic>) {
      throw ApiException(
        code: error['code']?.toString() ?? 'UNKNOWN',
        message: error['message']?.toString() ?? '알 수 없는 오류가 발생했습니다.',
        status: (error['status'] as num?)?.toInt() ?? res.statusCode,
      );
    }
    throw ApiException(
      code: 'UNKNOWN',
      message: '알 수 없는 오류가 발생했습니다.',
      status: res.statusCode,
    );
  }
}
