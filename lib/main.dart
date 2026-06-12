// lib/main.dart
import 'package:clueroom/core/api/api_client.dart';
import 'package:clueroom/screens/splash_screen.dart';
import 'package:clueroom/services/auth_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('FCM background message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // AuthService 초기화 — 저장된 토큰 로드
  await AuthService.instance.init();
  ApiClient.instance.authTokenProvider = () => AuthService.instance.bearerToken;

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await _configureFirebaseMessaging();

  runApp(const MyApp());
}

Future<void> _configureFirebaseMessaging() async {
  final messaging = FirebaseMessaging.instance;

  final settings = await messaging.requestPermission();
  debugPrint(
    'FCM 알림 권한: ${settings.authorizationStatus.name}',
  );

  final token = await messaging.getToken();
  debugPrint('FCM token: $token');
  if (token != null) {
    await _registerFcmTokenWithBackend(token);
  }

  messaging.onTokenRefresh.listen((newToken) async {
    debugPrint('FCM token 갱신: $newToken');
    await _registerFcmTokenWithBackend(newToken);
  });

  FirebaseMessaging.onMessage.listen((message) {
    debugPrint(
      'FCM 포그라운드 수신: ${message.messageId}, data: ${message.data}',
    );
  });

  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    debugPrint(
      'FCM 알림 탭: ${message.messageId}, data: ${message.data}',
    );
  });

  final initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null) {
    debugPrint(
      'FCM 초기 메시지: ${initialMessage.messageId}',
    );
  }
}

Future<void> _registerFcmTokenWithBackend(String token) async {
  debugPrint('백엔드에 FCM 토큰 등록 예정: $token');
  // TODO: AuthService 로그인 후 PATCH /api/users/me 로 fcmToken 전송
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