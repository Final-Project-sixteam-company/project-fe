/// OAuth client-side configuration.
///
/// These values identify public OAuth clients and are safe to ship in the app.
/// Server verification secrets such as JWT_SECRET must never be added here.
abstract final class OAuthConfig {
  OAuthConfig._();

  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '236168911575-onncfs98p3bbeo94v8bitdqmm7g5u0dt.apps.googleusercontent.com',
  );

  static const String kakaoNativeAppKey = String.fromEnvironment(
    'KAKAO_NATIVE_APP_KEY',
    defaultValue: '17ecda588dc1798c2dd902f5dd1084f1',
  );

  static const bool enableDevLogin = bool.fromEnvironment(
    'ENABLE_DEV_LOGIN',
    defaultValue: false,
  );
}
