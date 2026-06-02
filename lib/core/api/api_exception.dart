/// API 호출 중 발생하는 모든 오류의 통일 표현.
///
/// 백엔드 표준 에러 바디(`error: {code, message, status, ...}`)와
/// 네트워크/파싱 단계의 클라이언트 오류를 함께 감싼다.
class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.status,
  });

  /// 백엔드 에러 코드(예: `SCENARIO_001`, `C008`) 또는 클라이언트 코드.
  final String code;

  /// 사용자에게 보여줄 수 있는 메시지.
  final String message;

  /// HTTP 상태 코드. 네트워크 단계 실패 시 null.
  final int? status;

  /// 서버에 도달하지 못한 클라이언트/네트워크 오류 여부.
  bool get isNetwork => status == null;

  bool get isNotFound => status == 404;
  bool get isUnauthorized => status == 401;

  /// 네트워크 연결 실패.
  factory ApiException.network([String? message]) => ApiException(
        code: 'NETWORK_ERROR',
        message: message ?? '서버에 연결할 수 없습니다. 네트워크를 확인해주세요.',
      );

  /// 요청 타임아웃.
  factory ApiException.timeout() => const ApiException(
        code: 'TIMEOUT',
        message: '요청 시간이 초과되었습니다. 잠시 후 다시 시도해주세요.',
      );

  /// 응답 파싱 실패.
  factory ApiException.parse([String? message]) => ApiException(
        code: 'PARSE_ERROR',
        message: message ?? '서버 응답을 처리하지 못했습니다.',
      );

  @override
  String toString() => 'ApiException($code${status != null ? ', $status' : ''}): $message';
}
