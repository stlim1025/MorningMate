import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import 'package:alarm/alarm.dart';
import 'package:morning_mate/services/alarm_service.dart';
import 'dart:async';

import '../features/auth/screens/auth_wrapper.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/morning/screens/morning_screen.dart';
import '../features/morning/screens/writing_screen.dart';
import '../features/challenge/screens/challenge_screen.dart';
import '../features/character/screens/decoration_screen.dart';
import '../features/character/screens/shop_screen.dart';
import '../features/character/screens/character_decoration_screen.dart';
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

import '../features/common/screens/main_shell.dart';

import '../features/admin/screens/admin_screen.dart';

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

        if (isLoggedIn) {
          // 관리자 리다이렉트 로직
          final email = authController.userModel?.email;
          const adminEmails = ['admin@morningmate.com', 'admin@test.com'];
          if (adminEmails.contains(email)) {
            // 이미 관리자 페이지에 있거나 관리자 페이지로 이동 중이면 리다이렉트 하지 않음
            if (location.startsWith('/admin')) {
              return null;
            }
            // 그 외의 경우 (로그인 직후, 스플래시 등) 관리자 페이지로 강제 이동
            return '/admin';
          }

          if (location.contains('alarm-ring') || location.contains('writing')) {
            return null;
          }

          // 생체 인증이 필요한 경우 체크
          final user = authController.userModel;
          final needsBiometric = user?.biometricEnabled ?? false;
          final isVerified = authController.isBiometricVerified;

          if (needsBiometric && !isVerified) {
            // 생체 인증이 필요한데 아직 안 된 경우에는 스플래시로 강제 이동하거나 유지
            if (location != '/splash') {
              return '/splash';
            }
            return null;
          }

          if (location == '/splash' ||
              location == '/login' ||
              location == '/signup' ||
              location == '/') {
            return '/morning';
          }
        } else {
          if (location != '/login' &&
              location != '/splash' &&
              location != '/signup') {
            return '/login';
          }
          if (location == '/splash') {
            return '/login';
          }
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),

        GoRoute(
          path: '/',
          name: 'authWrapper',
          builder: (context, state) => const AuthWrapper(),
        ),

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

        // Main Tab Shell
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainShell(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/morning',
                  name: 'morning',
                  builder: (context, state) => const MorningScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/challenge',
                  name: 'challenge',
                  builder: (context, state) => const ChallengeScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/social',
                  name: 'social',
                  builder: (context, state) => const SocialScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/archive',
                  name: 'archive',
                  builder: (context, state) => const ArchiveScreen(),
                ),
              ],
            ),
          ],
        ),

        GoRoute(
          parentNavigatorKey: navigatorKey,
          path: '/writing',
          name: 'writing',
          builder: (context, state) {
            final question = state.extra as String?;
            return WritingScreen(initialQuestion: question);
          },
        ),
        GoRoute(
          parentNavigatorKey: navigatorKey,
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

        GoRoute(
          parentNavigatorKey: navigatorKey,
          path: '/decoration',
          name: 'decoration',
          builder: (context, state) => const DecorationScreen(),
        ),
        GoRoute(
          parentNavigatorKey: navigatorKey,
          path: '/character-decoration',
          name: 'characterDecoration',
          builder: (context, state) => const CharacterDecorationScreen(),
        ),
        GoRoute(
          parentNavigatorKey: navigatorKey,
          path: '/shop',
          name: 'shop',
          builder: (context, state) => const ShopScreen(),
        ),
        GoRoute(
          parentNavigatorKey: navigatorKey,
          path: '/notification',
          name: 'notification',
          builder: (context, state) => const NotificationScreen(),
        ),
        GoRoute(
          parentNavigatorKey: navigatorKey,
          path: '/friend/:friendId',
          name: 'friendRoom',
          builder: (context, state) {
            final friendId = state.pathParameters['friendId']!;
            return FriendRoomScreen(friendId: friendId);
          },
        ),

        GoRoute(
          parentNavigatorKey: navigatorKey,
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          parentNavigatorKey: navigatorKey,
          path: '/settings/notifications',
          name: 'notificationSettings',
          builder: (context, state) => const NotificationSettingsScreen(),
        ),
        GoRoute(
          parentNavigatorKey: navigatorKey,
          path: '/settings/terms',
          name: 'termsOfService',
          builder: (context, state) => const TermsOfServiceScreen(),
        ),
        GoRoute(
          parentNavigatorKey: navigatorKey,
          path: '/settings/privacy',
          name: 'privacyPolicy',
          builder: (context, state) => const PrivacyPolicyScreen(),
        ),

        // Alarm Routes
        GoRoute(
          parentNavigatorKey: navigatorKey,
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
              alarmSettings =
                  AlarmSettings.fromJson(state.extra as Map<String, dynamic>);
            } else {
              alarmSettings = AlarmService.ringingAlarm;
            }

            if (alarmSettings == null) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            return AlarmRingScreen(alarmSettings: alarmSettings);
          },
        ),
        GoRoute(
          parentNavigatorKey: navigatorKey,
          path: '/admin',
          name: 'admin',
          builder: (context, state) => const AdminScreen(),
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
