import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import 'package:alarm/alarm.dart';
import 'dart:async';

import '../features/auth/screens/auth_wrapper.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/morning/screens/morning_screen.dart';
import '../features/morning/screens/writing_screen.dart';
import '../features/character/screens/character_room_screen.dart';
import '../features/character/screens/decoration_screen.dart';
import '../features/social/screens/social_screen.dart';
import '../features/social/screens/friend_room_screen.dart';
import '../features/notification/screens/notification_screen.dart';
import '../features/archive/screens/archive_screen.dart';
import '../features/archive/screens/diary_detail_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/settings/screens/notification_settings_screen.dart';
import '../features/settings/screens/terms_of_service_screen.dart';
import '../features/settings/screens/privacy_policy_screen.dart';
import '../features/alarm/screens/alarm_screen.dart';
import '../features/alarm/screens/alarm_ring_screen.dart';

import '../features/auth/controllers/auth_controller.dart';
import '../data/models/diary_model.dart';

import '../features/auth/screens/splash_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static GoRouter createRouter(AuthController authController) {
    return GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: '/splash', // 🚨 시작 위치를 스플래시로 변경
      refreshListenable: authController, // AuthController 변경 감지
      redirect: (context, state) {
        // 🚨 2. 로딩 중(파이어베이스 확인 중)이면 무조건 스플래시 유지
        if (!authController.isAuthCheckDone) {
          return '/splash';
        }

        final isLoggedIn = authController.userModel != null;
        final isGoingToLogin = state.matchedLocation == '/login' ||
            state.matchedLocation == '/signup';
        final isGoingToSplash = state.matchedLocation == '/splash';

        // 3. 로딩 끝남 & 로그인 되어 있음
        if (isLoggedIn) {
          // 스플래시나 로그인 화면에 있었다면 -> 메인(morning)으로
          if (isGoingToSplash ||
              isGoingToLogin ||
              state.matchedLocation == '/') {
            return '/morning';
          }
        }
        // 4. 로딩 끝남 & 로그인 안 되어 있음
        else {
          // 로그인하러 가는 게 아니라면 -> 로그인 화면으로
          if (!isGoingToLogin && !isGoingToSplash) {
            // !isGoingToSplash 추가: 로딩 끝난 직후 /splash에 있으면 /login으로 보내야 함.
            // 위 로직에서 isLoggedIn이 false면 여기로 옴.
            // 만약 현재 /splash라면 /login으로 가야함.
            // 만약 isGoingToLogin이면 null 반환(통과).
            return '/login';
          }
          if (isGoingToSplash) {
            return '/login';
          }
        }

        return null;
      },
      routes: [
        // 🚨 3. 스플래시 라우트 추가
        GoRoute(
          path: '/splash',
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),

        // Auth Wrapper (Root) - 사용하지 않게 됨 (혹은 유지)
        GoRoute(
          path: '/',
          name: 'authWrapper',
          builder: (context, state) => const AuthWrapper(),
        ),

        // Auth Routes
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          name: 'signup',
          builder: (context, state) => const SignupScreen(),
        ),

        // Main Routes
        GoRoute(
          path: '/morning',
          name: 'morning',
          builder: (context, state) => const MorningScreen(),
        ),
        GoRoute(
          path: '/writing',
          name: 'writing',
          builder: (context, state) {
            final question = state.extra as String?;
            return WritingScreen(initialQuestion: question);
          },
        ),

        // Character Routes
        GoRoute(
          path: '/character',
          name: 'character',
          builder: (context, state) => const CharacterRoomScreen(),
          routes: [
            GoRoute(
              path: 'decoration',
              name: 'decoration',
              builder: (context, state) => const DecorationScreen(),
            ),
          ],
        ),

        // Social Routes
        GoRoute(
          path: '/social',
          name: 'social',
          builder: (context, state) => const SocialScreen(),
        ),
        GoRoute(
          path: '/notification',
          name: 'notification',
          builder: (context, state) => const NotificationScreen(),
        ),
        GoRoute(
          path: '/friend/:friendId',
          name: 'friendRoom',
          builder: (context, state) {
            final friendId = state.pathParameters['friendId']!;
            return FriendRoomScreen(friendId: friendId);
          },
        ),

        // Archive Routes
        GoRoute(
          path: '/archive',
          name: 'archive',
          builder: (context, state) => const ArchiveScreen(),
        ),
        GoRoute(
          path: '/diary-detail',
          name: 'diaryDetail',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            final diaries = extra['diaries'] as List<DiaryModel>;
            final initialDate = extra['initialDate'] as DateTime;
            return DiaryDetailScreen(
                diaries: diaries, initialDate: initialDate);
          },
        ),

        // Settings Routes
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
          routes: [
            GoRoute(
              path: 'notifications',
              name: 'notificationSettings',
              builder: (context, state) => const NotificationSettingsScreen(),
            ),
            GoRoute(
              path: 'terms',
              name: 'termsOfService',
              builder: (context, state) => const TermsOfServiceScreen(),
            ),
            GoRoute(
              path: 'privacy',
              name: 'privacyPolicy',
              builder: (context, state) => const PrivacyPolicyScreen(),
            ),
          ],
        ),

        // Alarm Routes
        GoRoute(
          path: '/alarm',
          name: 'alarm',
          builder: (context, state) => const AlarmScreen(),
        ),
        GoRoute(
          path: '/alarm-ring',
          name: 'alarm-ring',
          builder: (context, state) {
            final alarmSettings = state.extra as AlarmSettings;
            return AlarmRingScreen(alarmSettings: alarmSettings);
          },
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text('페이지를 찾을 수 없습니다: ${state.uri}'),
        ),
      ),
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
