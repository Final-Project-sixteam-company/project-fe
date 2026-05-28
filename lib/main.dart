import 'package:clueroom/screens/splash_screen.dart';
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
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await _configureFirebaseMessaging();

  runApp(const MyApp());
}

Future<void> _configureFirebaseMessaging() async {
  final messaging = FirebaseMessaging.instance;

  final settings = await messaging.requestPermission();
  debugPrint(
    'FCM notification permission: ${settings.authorizationStatus.name}',
  );

  final token = await messaging.getToken();
  debugPrint('FCM token: $token');
  if (token != null) {
    await _registerFcmTokenWithBackend(token);
  }

  messaging.onTokenRefresh.listen((newToken) async {
    debugPrint('FCM token refreshed: $newToken');
    await _registerFcmTokenWithBackend(newToken);
  });

  FirebaseMessaging.onMessage.listen((message) {
    debugPrint(
      'FCM foreground message: ${message.messageId}, data: ${message.data}',
    );
  });

  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    debugPrint(
      'FCM notification opened: ${message.messageId}, data: ${message.data}',
    );
  });

  final initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null) {
    debugPrint(
      'FCM initial notification: ${initialMessage.messageId}, data: ${initialMessage.data}',
    );
  }
}

Future<void> _registerFcmTokenWithBackend(String token) async {
  debugPrint('Register this FCM token with backend: $token');
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