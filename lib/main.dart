import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'core/theme/app_theme.dart';
import 'router/app_router.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/firestore_service.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/morning/controllers/morning_controller.dart';
import 'features/character/controllers/character_controller.dart';
import 'features/social/controllers/social_controller.dart';

import 'package:intl/date_symbol_data_local.dart';

// FCM 백그라운드 핸들러 (최상위 함수)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('백그라운드 메시지 수신: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 날짜 형식 초기화 (한국어)
  await initializeDateFormatting('ko_KR', null);

  // Firebase 초기화
  await Firebase.initializeApp();

  // FCM 백그라운드 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MorningMateApp());
}

class MorningMateApp extends StatelessWidget {
  const MorningMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<NotificationService>(
          create: (_) => NotificationService(),
        ),
        Provider<FirestoreService>(
          create: (_) => FirestoreService(),
        ),

        // Controllers
        ChangeNotifierProvider<AuthController>(
          create: (context) => AuthController(
            context.read<AuthService>(),
            context.read<FirestoreService>(),
            context.read<NotificationService>(),
          ),
        ),
        ChangeNotifierProxyProvider<AuthController, MorningController>(
          create: (context) => MorningController(
            context.read<FirestoreService>(),
          ),
          update: (context, auth, previous) =>
              previous ?? MorningController(context.read<FirestoreService>()),
        ),
        ChangeNotifierProxyProvider<AuthController, CharacterController>(
          create: (context) => CharacterController(
            context.read<FirestoreService>(),
          ),
          update: (context, auth, previous) =>
              previous ?? CharacterController(context.read<FirestoreService>()),
        ),
        ChangeNotifierProxyProvider<AuthController, SocialController>(
          create: (context) => SocialController(
            context.read<FirestoreService>(),
            context.read<NotificationService>(),
          ),
          update: (context, auth, previous) =>
              previous ??
              SocialController(
                context.read<FirestoreService>(),
                context.read<NotificationService>(),
              ),
        ),
      ],
      child: MaterialApp.router(
        title: 'Morning Mate',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark, // 기상 직후 시력 보호를 위한 다크모드 기본
        routerConfig: AppRouter.router,
      ),
    );
  }
}
