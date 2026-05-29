class AuthService {
  AuthService._privateConstructor();
  static final AuthService instance = AuthService._privateConstructor();

  // TODO: 추후 실제 로그인 로직 및 JWT 토큰 저장 로직 구현
  // 현재는 임시 하드코딩 토큰 혹은 기기 저장소에서 읽어오도록 설계
  String? get token => 'mock_or_saved_jwt_token_here';
}