import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../morning/screens/morning_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // ✨ 파이어베이스의 로그인 상태 변화를 실시간으로 감지
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. 데이터가 들어오는 중이면 (로딩)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. 로그인된 유저가 있으면 -> 홈 화면으로
        if (snapshot.hasData) {
          return const MorningScreen();
        }

        // 3. 로그인된 유저가 없으면 -> 로그인 화면으로
        return const LoginScreen();
      },
    );
  }
}
