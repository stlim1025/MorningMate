import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import 'package:alarm/alarm.dart';
import 'package:morning_mate/services/alarm_service.dart';
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

  static GoRouter createRouter(
      AuthController authController, String initialRoute) {
    return GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: initialRoute,
      refreshListenable: authController, // AuthController 변경 감지
      redirect: (context, state) {
        final String location = state.uri.toString();

        if (AlarmService.ringingAlarm != null) {
          if (!location.contains('alarm-ring')) {
            return '/alarm-ring';
          }
          return null;
        }

        if (!authController.isAuthCheckDone) {
          return '/splash';
        }

        final isLoggedIn = authController.userModel != null;

        // 2. 로그인 성공 시 메인으로 보내는 로직 수정
        if (isLoggedIn) {
          // 💡 이미 알람 화면에 있다면 절대로 /morning으로 보내면 안 됨!
          if (location.contains('alarm-ring') || location.contains('writing')) {
            return null;
          }

          if (location == '/splash' ||
              location == '/login' ||
              location == '/signup' ||
              location == '/') {
            return '/morning';
          }
        }
        // 4. 로딩 끝남 & 로그인 안 되어 있음
        else {
          // 로그인하러 가는 게 아니라면 -> 로그인 화면으로
          if (location != '/login' && location != '/splash') {
            // !isGoingToSplash 추가: 로딩 끝난 직후 /splash에 있으면 /login으로 보내야 함.
            // 위 로직에서 isLoggedI
            // n이 false면 여기로 옴.
            // 만약 현재 /splash라면 /login으로 가야함.
            // 만약 isGoingToLogin이면 null 반환(통과).
            return '/login';
          }
          if (location == '/splash') {
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
          builder: (context, state) {
            AlarmSettings? alarmSettings;

            if (state.extra is AlarmSettings) {
              alarmSettings = state.extra as AlarmSettings;
            } else if (state.extra is Map<String, dynamic>) {
              // 💡 종료 상태에서 진입 시 Map으로 들어오므로 수동 변환
              alarmSettings =
                  AlarmSettings.fromJson(state.extra as Map<String, dynamic>);
            } else {
              // 데이터가 없으면 서비스에서 현재 울리는 알람 참조
              alarmSettings = AlarmService.ringingAlarm;
            }

            // 🚨 여전히 null이면 MorningScreen으로 보내지 말고 '로딩/빈화면'을 띄우세요.
            // 여기서 MorningScreen()을 호출하면 의존성 때문에 또 터질 수 있습니다.
            if (alarmSettings == null) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

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
