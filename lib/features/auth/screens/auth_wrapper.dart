import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import 'nickname_setup_screen.dart';
import '../../morning/screens/morning_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, child) {
        // 인증 상태 확인이 끝나지 않았다면 로딩
        if (!authController.isAuthCheckDone) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 로그인된 상태
        if (authController.isAuthenticated) {
          final userModel = authController.userModel;

          // 유저 정보를 불러오는 중이라면
          if (userModel == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // 초기 닉네임/추천인 설정이 안 된 상태라면
          if (!userModel.isSetupComplete) {
            return const NicknameSetupScreen();
          }

          // 모든 설정이 끝났으면 메인
          return const MorningScreen();
        }

        // 로그인 안됨
        return const LoginScreen();
      },
    );
  }
}
