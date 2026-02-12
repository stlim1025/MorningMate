import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../controllers/auth_controller.dart';
import '../../../core/widgets/app_dialog.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    if (_isInitializing) return;
    _isInitializing = true;

    // AuthController의 초기화 완료를 기다림
    final authController = context.read<AuthController>();

    // AuthCheckDone이 완료될 때까지 잠시 대기 (필요 시)
    while (!authController.isAuthCheckDone) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (!mounted) return;

    final user = authController.userModel;
    if (user != null &&
        user.biometricEnabled &&
        !authController.isBiometricVerified) {
      // 생체 인증이 켜져 있고 아직 인증되지 않은 경우
      final authenticated = await authController.authenticateWithBiometric();

      if (authenticated) {
        authController.setBiometricVerified(true);
        if (mounted) context.go('/morning');
      } else {
        if (mounted) {
          final retry = await _showBiometricRetryDialog(context);
          if (retry) {
            _isInitializing = false;
            _checkInitialState();
          } else {
            await authController.signOut();
            if (mounted) context.go('/login');
          }
        }
      }
    } else {
      // 생체 인증이 필요 없거나 이미 완료된 경우 라우팅은 GoRouter의 redirect에서 처리됨
      // 하지만 Splash에서 수동으로 보내줘야 할 수도 있음 (redirect가 안 먹는 경우 대비)
      if (mounted) {
        if (user != null) {
          context.go('/morning');
        } else {
          context.go('/login');
        }
      }
    }
  }

  Future<bool> _showBiometricRetryDialog(BuildContext context) async {
    final result = await AppDialog.show<bool>(
      context: context,
      key: AppDialogKey.biometricRetry,
      barrierDismissible: false,
      actions: [
        AppDialogAction(
          label: '로그아웃',
          onPressed: () => Navigator.pop(context, false),
        ),
        AppDialogAction(
          label: '다시 시도',
          onPressed: () => Navigator.pop(context, true),
          useHighlight: true,
        ),
      ],
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/Charactor_Icon.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            const Text("Morning Mate",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'BMJUA',
                  color: Color(0xFF4E342E),
                )),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              color: Color(0xFF4E342E),
            ),
          ],
        ),
      ),
    );
  }
}
