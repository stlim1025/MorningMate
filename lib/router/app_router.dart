import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

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
import '../data/models/diary_model.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation:
        FirebaseAuth.instance.currentUser == null ? '/login' : '/morning',
    refreshListenable:
        GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
    redirect: (context, state) {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final isLoggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }
      if (isLoggedIn && isLoggingIn) {
        return '/morning';
      }
      return null;
    },
    routes: [
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
          return DiaryDetailScreen(diaries: diaries, initialDate: initialDate);
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
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('페이지를 찾을 수 없습니다: ${state.uri}'),
      ),
    ),
  );
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
