// lib/services/api_client.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

/// MVP 공통 Dio 클라이언트.
/// 모든 Repository는 이 싱글턴을 통해 백엔드를 호출한다.
class ApiClient {
  ApiClient._privateConstructor() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        contentType: 'application/json',
        responseType: ResponseType.json,
      ),
    );
    _dio.interceptors.addAll([
      _AuthInterceptor(),
      _ResponseInterceptor(),
      if (kDebugMode) _LogInterceptor(),
    ]);
  }

  static final ApiClient instance = ApiClient._privateConstructor();

  static const String _baseUrl = kDebugMode
      ? 'http://10.0.2.2:8080' // Android Emulator → localhost
      : 'https://api.clueroom.xyz';

  late final Dio _dio;

  /// 테스트·Mock 주입용
  Dio get dio => _dio;

  // ── GET ───────────────────────────────────────────────────────────────────

  Future<ApiResult<T>> get<T>(
      String path, {
        Map<String, dynamic>? query,
        bool auth = true,
        required T Function(dynamic) fromJson,
      }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: query,
        options: _options(auth: auth),
      );
      return _parse(res, fromJson);
    } on DioException catch (e) {
      return ApiResult.failure(_dioError(e));
    }
  }

  // ── POST ──────────────────────────────────────────────────────────────────

  Future<ApiResult<T>> post<T>(
      String path, {
        Map<String, dynamic>? body,
        bool auth = true,
        required T Function(dynamic) fromJson,
      }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        path,
        data: body,
        options: _options(auth: auth),
      );
      return _parse(res, fromJson);
    } on DioException catch (e) {
      return ApiResult.failure(_dioError(e));
    }
  }

  // ── PATCH ─────────────────────────────────────────────────────────────────

  Future<ApiResult<T>> patch<T>(
      String path, {
        Map<String, dynamic>? body,
        bool auth = true,
        required T Function(dynamic) fromJson,
      }) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        path,
        data: body,
        options: _options(auth: auth),
      );
      return _parse(res, fromJson);
    } on DioException catch (e) {
      return ApiResult.failure(_dioError(e));
    }
  }

  // ── DELETE ────────────────────────────────────────────────────────────────

  Future<ApiResult<T>> delete<T>(
      String path, {
        bool auth = true,
        required T Function(dynamic) fromJson,
      }) async {
    try {
      final res = await _dio.delete<Map<String, dynamic>>(
        path,
        options: _options(auth: auth),
      );
      return _parse(res, fromJson);
    } on DioException catch (e) {
      return ApiResult.failure(_dioError(e));
    }
  }

  // ── 공통 헬퍼 ────────────────────────────────────────────────────────────

  Options _options({required bool auth}) => Options(
    extra: {'auth': auth},
  );

  ApiResult<T> _parse<T>(
      Response<Map<String, dynamic>> res,
      T Function(dynamic) fromJson,
      ) {
    final body = res.data;
    if (body == null) {
      return ApiResult.failure(
        const ApiError(code: 'EMPTY_BODY', message: '응답 본문이 비어 있습니다.'),
      );
    }
    final success = body['success'] as bool? ?? false;
    if (success) {
      try {
        return ApiResult.success(fromJson(body['data']));
      } catch (e) {
        return ApiResult.failure(
          ApiError(code: 'PARSE_ERROR', message: 'JSON 파싱 오류: $e'),
        );
      }
    }
    final err = body['error'] as Map<String, dynamic>?;
    return ApiResult.failure(ApiError(
      code: err?['code'] as String? ?? 'UNKNOWN',
      message: err?['message'] as String? ?? '알 수 없는 오류',
    ));
  }

  ApiError _dioError(DioException e) {
    final status = e.response?.statusCode;
    final msg = switch (e.type) {
      DioExceptionType.connectionTimeout => '연결 시간 초과',
      DioExceptionType.receiveTimeout => '응답 시간 초과',
      DioExceptionType.badResponse => 'HTTP $status 오류',
      DioExceptionType.connectionError => '네트워크 연결 실패',
      _ => e.message ?? '알 수 없는 네트워크 오류',
    };
    return ApiError(code: 'NETWORK_${status ?? e.type.name.toUpperCase()}', message: msg);
  }
}

// ── 인터셉터: JWT 자동 첨부 ───────────────────────────────────────────────────

class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final needsAuth = options.extra['auth'] as bool? ?? true;
    if (needsAuth) {
      final token = AuthService.instance.token;
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }
}

// ── 인터셉터: 401 토큰 만료 처리 ─────────────────────────────────────────────

class _ResponseInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // TODO: Phase 2 — refresh token 재발급 후 재시도
      debugPrint('[ApiClient] 401 — 토큰 만료. 재로그인 필요.');
    }
    handler.next(err);
  }
}

// ── 인터셉터: 디버그 로그 ─────────────────────────────────────────────────────

class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('[API →] ${options.method} ${options.path}');
    if (options.data != null) debugPrint('       body: ${options.data}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('[API ←] ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('[API ✗] ${err.response?.statusCode} ${err.requestOptions.path} — ${err.message}');
    handler.next(err);
  }
}

// ── 공통 결과 타입 ────────────────────────────────────────────────────────────

class ApiResult<T> {
  const ApiResult._({this.data, this.error});

  factory ApiResult.success(T data) => ApiResult._(data: data);
  factory ApiResult.failure(ApiError error) => ApiResult._(error: error);

  final T? data;
  final ApiError? error;

  bool get isSuccess => error == null && data != null;
}

class ApiError {
  const ApiError({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String toString() => '[$code] $message';
}