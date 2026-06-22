// lib/main.dart
import 'dart:async';

import 'package:clueroom/core/api/api_client.dart';
import 'package:clueroom/core/oauth/oauth_config.dart';
import 'package:clueroom/screens/splash_screen.dart';
import 'package:clueroom/services/auth_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'theme/app_theme.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('FCM background message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await KakaoSdk.init(nativeAppKey: OAuthConfig.kakaoNativeAppKey);
  await GoogleSignIn.instance.initialize(
    serverClientId: OAuthConfig.googleServerClientId,
  );
  await Firebase.initializeApp();

  // AuthService 초기화 — 저장된 토큰 로드
  await AuthService.instance.init();
  ApiClient.instance.authTokenProvider = () => AuthService.instance.bearerToken;
  ApiClient.instance.authRefreshProvider = () =>
      AuthService.instance.refreshTokens();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await _configureFirebaseMessaging();

  runApp(const MyApp());
}

Future<void> _configureFirebaseMessaging() async {
  final messaging = FirebaseMessaging.instance;

  final settings = await messaging.requestPermission();
  debugPrint('FCM 알림 권한: ${settings.authorizationStatus.name}');

  final token = await messaging.getToken();
  debugPrint('FCM token: ${_describeFcmToken(token)}');
  if (token != null) {
    unawaited(_registerFcmTokenWithBackend(token));
  }

  messaging.onTokenRefresh.listen((newToken) {
    debugPrint('FCM token 갱신: ${_describeFcmToken(newToken)}');
    unawaited(_registerFcmTokenWithBackend(newToken));
  });

  FirebaseMessaging.onMessage.listen((message) {
    debugPrint('FCM 포그라운드 수신: ${message.messageId}, data: ${message.data}');
  });

  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    debugPrint('FCM 알림 탭: ${message.messageId}, data: ${message.data}');
  });

  final initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null) {
    debugPrint('FCM 초기 메시지: ${initialMessage.messageId}');
  }
}

Future<void> _registerFcmTokenWithBackend(String token) async {
  debugPrint('백엔드에 FCM 토큰 등록 시작: ${_describeFcmToken(token)}');
  try {
    // Phase 2: 실제 device-tokens 엔드포인트 호출
    await ApiClient.instance.post(
      '/api/device-tokens',
      body: {
        'token': token,
        // 필요에 따라 'deviceType': Platform.isIOS ? 'IOS' : 'ANDROID' 추가 가능
      },
    );
    debugPrint('FCM 토큰 백엔드 등록 성공');
  } catch (e) {
    debugPrint('FCM 토큰 백엔드 등록 실패: $e');
  }
}

String _describeFcmToken(String? token) {
  if (token == null || token.isEmpty) {
    return 'present=false, length=0';
  }

  return 'present=true, length=${token.length}, sample=${_maskToken(token)}';
}

String _maskToken(String token) {
  if (token.length <= 8) {
    return '<redacted:${token.length}>';
  }

  return '${token.substring(0, 4)}...${token.substring(token.length - 4)}';
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClueRoom',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const SplashScreen(),
    );
  }
}
