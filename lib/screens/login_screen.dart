import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import '../components/ms_button.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../core/api/api_client.dart';
import 'app_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailCtrl = TextEditingController();
  bool _isLoading = false;
  String? _errorMsg;

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

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      await AuthService.instance.loginDev(email);
      if (AuthService.instance.isLoggedIn) {
        // 로그인 성공 시 FCM 토큰 백엔드에 재등록
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

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AppShell()),
        );
      } else {
        setState(() => _errorMsg = '로그인에 실패했습니다. 올바른 정보를 입력했는지 확인해주세요.');
      }
    } catch (e) {
      setState(() => _errorMsg = '오류가 발생했습니다: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

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
                    border: Border.all(color: c.primary.withValues(alpha: .6), width: 1.5),
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

              // Dev Login form
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
              if (_errorMsg != null) ...[
                const SizedBox(height: AppTokens.sp2),
                Text(
                  _errorMsg!,
                  style: AppText.caption.copyWith(color: AppColors.roseBase),
                ),
              ],
              const SizedBox(height: AppTokens.sp6),
              MSButton(
                label: '로그인',
                variant: MSButtonVariant.primary,
                expanded: true,
                loading: _isLoading,
                onPressed: _isLoading ? null : _loginDev,
              ),
              const SizedBox(height: AppTokens.sp8),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: c.line)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTokens.sp4),
                    child: Text(
                      '또는',
                      style: AppText.caption.copyWith(color: c.textMute),
                    ),
                  ),
                  Expanded(child: Divider(color: c.line)),
                ],
              ),
              const SizedBox(height: AppTokens.sp8),

              // OAuth placeholders (Phase 2)
              MSButton(
                label: 'Google 로그인 (준비 중)',
                variant: MSButtonVariant.secondary,
                expanded: true,
                onPressed: null,
              ),
              const SizedBox(height: AppTokens.sp4),
              MSButton(
                label: 'Apple 로그인 (준비 중)',
                variant: MSButtonVariant.secondary,
                expanded: true,
                onPressed: null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
