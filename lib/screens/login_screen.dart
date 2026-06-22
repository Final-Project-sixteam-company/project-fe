import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import '../core/api/api_exception.dart';
import '../services/auth_service.dart';
import '../core/oauth/oauth_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import '../components/ms_button.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../core/api/api_client.dart';
import 'app_shell.dart';

enum _LoginAction { dev, google, kakao }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailCtrl = TextEditingController();
  _LoginAction? _loadingAction;
  String? _errorMsg;

  bool get _isLoading => _loadingAction != null;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _loginDev() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMsg = '이메일을 입력해주세요.');
      return;
    }

    _beginLogin(_LoginAction.dev);

    try {
      await AuthService.instance.loginDev(email);
      if (AuthService.instance.isLoggedIn) {
        await _finishLogin();
      } else {
        setState(() => _errorMsg = '로그인에 실패했습니다. 올바른 정보를 입력했는지 확인해주세요.');
      }
    } catch (e) {
      setState(() => _errorMsg = '오류가 발생했습니다: ${e.toString()}');
    } finally {
      _endLogin();
    }
  }

  Future<void> _loginGoogle() async {
    _beginLogin(_LoginAction.google);

    try {
      final signIn = GoogleSignIn.instance;
      if (!signIn.supportsAuthenticate()) {
        throw const ApiException(
          code: 'GOOGLE_AUTH_UNSUPPORTED',
          message: '현재 플랫폼에서 Google 로그인을 지원하지 않습니다.',
        );
      }

      final account = await signIn.authenticate(
        scopeHint: const <String>['email', 'profile'],
      );
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const ApiException(
          code: 'GOOGLE_ID_TOKEN_EMPTY',
          message: 'Google ID Token을 받지 못했습니다.',
        );
      }

      await AuthService.instance.loginOAuth(
        provider: 'GOOGLE',
        idToken: idToken,
      );
      await _finishLogin();
    } on GoogleSignInException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = e.code == GoogleSignInExceptionCode.canceled
            ? 'Google 로그인이 취소되었습니다.'
            : 'Google 로그인에 실패했습니다: ${e.description ?? e.code.name}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMsg = _errorMessage(e, 'Google 로그인에 실패했습니다.'));
    } finally {
      _endLogin();
    }
  }

  Future<void> _loginKakao() async {
    _beginLogin(_LoginAction.kakao);

    try {
      final kakaoToken = await _requestKakaoToken();
      await AuthService.instance.loginOAuth(
        provider: 'KAKAO',
        accessToken: kakaoToken.accessToken,
      );
      await _finishLogin();
    } on KakaoClientException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = e.reason == ClientErrorCause.cancelled
            ? 'Kakao 로그인이 취소되었습니다.'
            : 'Kakao 로그인에 실패했습니다: ${e.msg}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMsg = _errorMessage(e, 'Kakao 로그인에 실패했습니다.'));
    } finally {
      _endLogin();
    }
  }

  void _beginLogin(_LoginAction action) {
    setState(() {
      _loadingAction = action;
      _errorMsg = null;
    });
  }

  void _endLogin() {
    if (mounted) setState(() => _loadingAction = null);
  }

  Future<OAuthToken> _requestKakaoToken() async {
    if (await isKakaoTalkInstalled()) {
      try {
        return await UserApi.instance.loginWithKakaoTalk();
      } on PlatformException catch (e) {
        if (e.code == 'CANCELED') {
          throw KakaoClientException(
            ClientErrorCause.cancelled,
            e.message ?? 'Kakao login canceled.',
          );
        }
      } on KakaoClientException catch (e) {
        if (e.reason == ClientErrorCause.cancelled) rethrow;
      } catch (_) {
        // 카카오톡 로그인 실패 시 카카오계정 로그인으로 대체한다.
      }
    }

    return UserApi.instance.loginWithKakaoAccount();
  }

  Future<void> _finishLogin() async {
    if (!AuthService.instance.isLoggedIn) {
      throw const ApiException(
        code: 'AUTH_TOKEN_MISSING',
        message: '로그인 토큰을 저장하지 못했습니다.',
      );
    }

    unawaited(_registerDeviceTokenBestEffort());

    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const AppShell()));
  }

  Future<void> _registerDeviceTokenBestEffort() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();
      if (token != null) {
        await ApiClient.instance.post(
          '/api/device-tokens',
          body: {'token': token},
        );
      }
    } catch (_) {
      // 토큰 등록 실패해도 로그인 흐름은 계속 진행
    }
  }

  String _errorMessage(Object error, String fallback) {
    if (error is ApiException) {
      return '$fallback ${error.message}';
    }
    if (error is KakaoException && error.message != null) {
      return '$fallback ${error.message}';
    }
    return '$fallback ${error.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    const showDevLogin = OAuthConfig.enableDevLogin;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.sp8,
            vertical: AppTokens.sp12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Logo/Title area
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.bgElev,
                    border: Border.all(
                      color: c.primary.withValues(alpha: .6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: c.primary.withValues(alpha: .18),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'CR',
                      style: AppText.titleM.copyWith(
                        color: c.primary,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.sp8),
              Text(
                '환영합니다',
                style: AppText.titleL.copyWith(color: c.text, fontSize: 28),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTokens.sp2),
              Text(
                'ClueRoom 사건 조사 파일에 접근하려면\n로그인해주세요.',
                style: AppText.body.copyWith(color: c.textSub, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              if (showDevLogin) ...[
                Text(
                  '개발자 로그인 (Dev Login)',
                  style: AppText.bodySm.copyWith(color: c.textMute),
                ),
                const SizedBox(height: AppTokens.sp2),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: AppText.body.copyWith(color: c.text),
                  decoration: InputDecoration(
                    hintText: '이메일을 입력하세요 (예: user@example.com)',
                    hintStyle: AppText.body.copyWith(color: c.textMute),
                    filled: true,
                    fillColor: c.bgElev,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTokens.r4),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTokens.r4),
                      borderSide: BorderSide(color: c.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.sp6),
                MSButton(
                  label: '로그인',
                  variant: MSButtonVariant.primary,
                  expanded: true,
                  loading: _loadingAction == _LoginAction.dev,
                  onPressed: _isLoading ? null : _loginDev,
                ),
                const SizedBox(height: AppTokens.sp8),
              ],

              if (_errorMsg != null) ...[
                const SizedBox(height: AppTokens.sp2),
                Text(
                  _errorMsg!,
                  style: AppText.caption.copyWith(color: AppColors.roseBase),
                ),
                const SizedBox(height: AppTokens.sp6),
              ],

              if (showDevLogin) ...[
                Row(
                  children: [
                    Expanded(child: Divider(color: c.line)),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.sp4,
                      ),
                      child: Text(
                        '또는',
                        style: AppText.caption.copyWith(color: c.textMute),
                      ),
                    ),
                    Expanded(child: Divider(color: c.line)),
                  ],
                ),
                const SizedBox(height: AppTokens.sp8),
              ],

              MSButton(
                label: 'Google 로그인',
                variant: MSButtonVariant.secondary,
                expanded: true,
                loading: _loadingAction == _LoginAction.google,
                onPressed: _isLoading ? null : _loginGoogle,
              ),
              const SizedBox(height: AppTokens.sp4),
              MSButton(
                label: 'Kakao 로그인',
                variant: MSButtonVariant.secondary,
                expanded: true,
                loading: _loadingAction == _LoginAction.kakao,
                onPressed: _isLoading ? null : _loginKakao,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
