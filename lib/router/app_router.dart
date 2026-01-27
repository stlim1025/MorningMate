import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/morning/screens/morning_screen.dart';
import '../features/morning/screens/writing_screen.dart';
import '../features/character/screens/character_room_screen.dart';
import '../features/social/screens/social_screen.dart';
import '../features/social/screens/friend_room_screen.dart';
import '../features/archive/screens/archive_screen.dart';
import '../features/settings/screens/settings_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
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
      ),

      // Social Routes
      GoRoute(
        path: '/social',
        name: 'social',
        builder: (context, state) => const SocialScreen(),
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

      // Settings Routes
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
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
