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
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    if (_isInitializing) return;

    setState(() {
      _isInitializing = true;
      _hasError = false;
    });

    // AuthController의 초기화 완료를 기다림
    final authController = context.read<AuthController>();

    // AuthCheckDone이 완료될 때까지 잠시 대기 (필요 시)
    while (!authController.isAuthCheckDone) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (!mounted) return;

    final user = authController.userModel;

    // 로그인이 안 되어 있으면 /login으로 이동 (Router의 redirect로 처리되기도 하지만 명시적으로 처리)
    if (user == null) {
      if (mounted) context.go('/login');
      return;
    }

    if (user.biometricEnabled && !authController.isBiometricVerified) {
      // 생체 인증이 켜져 있고 아직 인증되지 않은 경우
      final authenticated = await authController.authenticateWithBiometric();

      if (authenticated) {
        authController.setBiometricVerified(true);
        // 여기서 context.go('/morning')을 호출하지 않아도
        // notifyListeners() -> Router redirect에서 자동으로 이동함
        if (mounted) context.go('/morning');
      } else {
        if (mounted) {
          setState(() {
            _isInitializing = false;
            _hasError = true;
          });

          // 다이얼로그도 옵션으로 제공 (사용자 선택에 따라 다시 시도하거나 로그아웃)
          final retry = await _showBiometricRetryDialog(context);
          if (retry && mounted) {
            _checkInitialState();
          }
        }
      }
    } else {
      // 생체 인증이 필요 없거나 이미 완료된 경우
      if (mounted) context.go('/morning');
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
          onPressed: () {
            context.read<AuthController>().signOut();
            Navigator.pop(context, false);
          },
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
            if (_hasError)
              Column(
                children: [
                  const Text(
                    "인증에 실패했습니다.",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                      fontFamily: 'BMJUA',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _checkInitialState,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4E342E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      "다시 시도",
                      style: TextStyle(fontFamily: 'BMJUA'),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await context.read<AuthController>().signOut();
                      if (mounted) context.go('/login');
                    },
                    child: const Text(
                      "다른 계정으로 로그인",
                      style: TextStyle(
                        fontFamily: 'BMJUA',
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              )
            else
              const CircularProgressIndicator(
                color: Color(0xFF4E342E),
              ),
          ],
        ),
      ),
    );
  }
}
