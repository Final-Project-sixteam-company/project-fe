class AuthService {
  AuthService._privateConstructor();
  static final AuthService instance = AuthService._privateConstructor();

  // TODO: 추후 실제 로그인 로직 및 JWT 토큰 저장 로직 구현
  // 현재는 임시 하드코딩 토큰 혹은 기기 저장소에서 읽어오도록 설계
  // 현재는 로컬 테스트용 가짜 토큰을 반환합니다.
  // 배포(Release) 버전에서는 백엔드가 401 에러로 거부하므로
  // 실제 로그인 로직 및 기기 저장소(SecureStorage 등)에서 JWT를 읽어오도록 수정해야 합니다.
  String? get token => 'mock_or_saved_jwt_token_here';
}