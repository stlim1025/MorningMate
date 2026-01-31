import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'core/theme/app_theme.dart';
import 'router/app_router.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/user_service.dart';
import 'services/diary_service.dart';
import 'services/friend_service.dart';
import 'services/question_service.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/morning/controllers/morning_controller.dart';
import 'features/character/controllers/character_controller.dart';
import 'features/social/controllers/social_controller.dart';
import 'features/notification/controllers/notification_controller.dart';
import 'core/theme/theme_controller.dart';

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
  if (kIsWeb) {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  }
  await FirebaseAuth.instance.authStateChanges().first;

  // FCM 백그라운드 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MorningMateApp());
}

class MorningMateApp extends StatelessWidget {
  const MorningMateApp({super.key});

  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<NotificationService>(
          create: (_) {
            final service = NotificationService();
            service.setScaffoldMessengerKey(scaffoldMessengerKey);
            service.setNavigatorKey(AppRouter.navigatorKey);
            return service;
          },
        ),
        Provider<UserService>(
          create: (_) => UserService(),
        ),
        Provider<DiaryService>(
          create: (_) => DiaryService(),
        ),
        Provider<QuestionService>(
          create: (_) => QuestionService(),
        ),
        Provider<FriendService>(
          create: (context) => FriendService(context.read<UserService>()),
        ),

        // Controllers
        ChangeNotifierProvider<AuthController>(
          create: (context) => AuthController(
            context.read<AuthService>(),
            context.read<UserService>(),
            context.read<NotificationService>(),
          ),
        ),
        ChangeNotifierProxyProvider<AuthController, MorningController>(
          create: (context) => MorningController(
            context.read<DiaryService>(),
            context.read<QuestionService>(),
            context.read<UserService>(),
          ),
          update: (context, auth, previous) =>
              previous ??
              MorningController(
                context.read<DiaryService>(),
                context.read<QuestionService>(),
                context.read<UserService>(),
              ),
        ),
        ChangeNotifierProxyProvider<AuthController, CharacterController>(
          create: (context) => CharacterController(
            context.read<UserService>(),
          ),
          update: (context, auth, previous) {
            final controller =
                previous ?? CharacterController(context.read<UserService>());
            controller.updateFromUser(auth.userModel);
            return controller;
          },
        ),
        ChangeNotifierProxyProvider<AuthController, SocialController>(
          create: (context) => SocialController(
            context.read<FriendService>(),
            context.read<DiaryService>(),
            context.read<NotificationService>(),
          ),
          update: (context, auth, previous) =>
              previous ??
              SocialController(
                context.read<FriendService>(),
                context.read<DiaryService>(),
                context.read<NotificationService>(),
              ),
        ),
        ChangeNotifierProvider<NotificationController>(
          create: (_) => NotificationController(),
        ),
        ChangeNotifierProxyProvider<AuthController, ThemeController>(
          create: (_) => ThemeController(),
          update: (context, auth, previous) {
            final controller = previous ?? ThemeController();
            if (auth.userModel != null) {
              controller.syncWithUserTheme(auth.userModel!.currentThemeId);
            }
            return controller;
          },
        ),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, child) {
          return MaterialApp.router(
            title: 'Morning Mate',
            debugShowCheckedModeBanner: false,
            theme: themeController.themeData,
            scaffoldMessengerKey: scaffoldMessengerKey,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
