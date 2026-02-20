import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

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
import 'features/admin/controllers/admin_controller.dart';
import 'core/theme/theme_controller.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // import flutter_localizations
import 'core/localization/language_provider.dart';
import 'core/localization/app_localizations.dart';

// FCM 백그라운드 핸들러 (최상위 함수)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('백그라운드 메시지 수신: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 가로 회전 방지 (세로 모드 고정)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 저사양 기기를 위한 이미지 캐시 제한 설정
  PaintingBinding.instance.imageCache.maximumSize = 50; // 최대 50개 이미지
  PaintingBinding.instance.imageCache.maximumSizeBytes =
      50 * 1024 * 1024; // 50MB

  // 날짜 형식 초기화 (한국어)
  await initializeDateFormatting('ko_KR', null);

  // Firebase 초기화
  try {
    await Firebase.initializeApp();
    debugPrint('Firebase 초기화 성공');
  } catch (e) {
    debugPrint('Firebase 초기화 실패: $e');
  }

  // 카카오 SDK 초기화
  // TODO: 카카오 개발자 콘솔에서 발급받은 네이티브 앱 키를 입력하세요
  try {
    KakaoSdk.init(
      nativeAppKey:
          'b85bd2621b6bf24cf21211b92e352c50', // 카카오 개발자 콘솔에서 발급받은 네이티브 앱 키
    );
    debugPrint('카카오 SDK 초기화 성공');
  } catch (e) {
    debugPrint('카카오 SDK 초기화 실패: $e');
  }

  // Firebase App Check 초기화 (개발 환경용 디버그 모드)
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
    debugPrint('Firebase App Check 초기화 성공 (디버그 모드)');
  } catch (e) {
    debugPrint('Firebase App Check 초기화 실패: $e');
  }

  // 광고 SDK 초기화
  try {
    MobileAds.instance.initialize();
    debugPrint('광고 SDK 초기화 성공');
  } catch (e) {
    debugPrint('광고 SDK 초기화 실패: $e');
  }

  // 로그인 상태 유지 설정 (모든 플랫폼에서 명시적으로 LOCAL 설정 시도)
  try {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  } catch (e) {
    debugPrint('Persistence Error: $e');
  }

  // FCM 백그라운드 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(MorniApp(initialRoute: '/splash'));
}

class MorniApp extends StatefulWidget {
  final String initialRoute;
  const MorniApp({super.key, required this.initialRoute});

  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  State<MorniApp> createState() => _MorniAppState();
}

class _MorniAppState extends State<MorniApp> {
  late final AuthService _authService;
  late final UserService _userService;
  late final NotificationService _notificationService;
  late final DiaryService _diaryService;
  late final QuestionService _questionService;
  late final FriendService _friendService;

  late final AuthController _authController;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    // 1. 서비스 초기화
    _authService = AuthService();
    _userService = UserService();
    _notificationService = NotificationService();
    _notificationService.setScaffoldMessengerKey(
      MorniApp.scaffoldMessengerKey,
    );
    _notificationService.setNavigatorKey(AppRouter.navigatorKey);

    _diaryService = DiaryService();
    _questionService = QuestionService();
    _friendService = FriendService(_userService);

    // 2. AuthController 초기화 (서비스 의존성 주입)
    _authController = AuthController(
      _authService,
      _userService,
      _notificationService,
    );

    // 3. Router 초기화 (AuthController 의존성 주입)
    _router = AppRouter.createRouter(_authController, widget.initialRoute);

    // 5. 광고 로드 (화면 빌드 후)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 이 시점에는 context가 유효함 (하지만 Provider.value로 주입된 서비스/컨트롤러 사용 권장)
      // CharacterController는 아래 ProxyProvider를 통해 생성되므로,
      // 여기서는 직접 접근하기보다 Route가 세팅된 후 화면 진입 시 처리하는 것이 안전할 수 있음.
      // 기존 로직 유지:
      // final rootContext = AppRouter.navigatorKey.currentContext;
      // ...
      // 하지만 여기서 바로 호출하기는 어려움 (CharacterController가 아직 생성되지 않았을 수 있음 - build 실행 전)
      // 따라서 build 내의 Consumer/WidgetsBinding을 유지하거나 생략.
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services (이미 생성된 인스턴스 주입)
        Provider.value(value: _authService),
        Provider.value(value: _notificationService),
        Provider.value(value: _userService),
        Provider.value(value: _diaryService),
        Provider.value(value: _questionService),
        Provider.value(value: _friendService),

        // Controllers
        // AuthController (이미 생성된 인스턴스 주입)
        ChangeNotifierProvider.value(value: _authController),

        // LanguageProvider
        ChangeNotifierProvider(create: (_) => LanguageProvider()),

        // ProxyManagers (의존성 있는 컨트롤러들은 기존대로 Proxy 사용)
        ChangeNotifierProxyProvider<AuthController, MorningController>(
          create: (context) =>
              MorningController(_diaryService, _questionService, _userService),
          update: (context, auth, previous) {
            final controller = previous ??
                MorningController(
                  _diaryService,
                  _questionService,
                  _userService,
                );
            if (auth.userModel == null) {
              controller.clear();
            }
            return controller;
          },
        ),
        ChangeNotifierProxyProvider<AuthController, CharacterController>(
          create: (context) => CharacterController(_userService),
          update: (context, auth, previous) {
            final controller = previous ?? CharacterController(_userService);
            if (auth.userModel == null) {
              controller.clear();
            } else {
              controller.updateFromUser(auth.userModel);
            }
            return controller;
          },
        ),
        ChangeNotifierProxyProvider<AuthController, SocialController>(
          create: (context) => SocialController(_friendService),
          update: (context, auth, previous) {
            final controller = previous ?? SocialController(_friendService);
            if (auth.userModel == null) {
              controller.clear();
            } else {
              // 사용자 정보가 로드되면 친구 목록을 미리 로드
              Future.microtask(
                () => controller.initialize(auth.currentUser!.uid),
              );
            }
            return controller;
          },
        ),
        ChangeNotifierProvider<NotificationController>(
          create: (_) => NotificationController(),
        ),
        ChangeNotifierProxyProvider<AuthController, AdminController>(
          create: (_) => AdminController(null),
          update: (_, auth, previous) {
            final email = auth.userModel?.email ?? auth.currentUser?.email;
            if (previous != null && previous.currentUserEmail == email) {
              return previous;
            }
            // 이메일이 변경되었거나 처음 생성된 경우
            // 새 컨트롤러를 생성하되, 데이터가 필요하다면 여기서 fetch할 수도 있음.
            // 하지만 AdminScreen 진입 시 fetch하므로 괜찮음.
            return AdminController(email);
          },
        ),
        ChangeNotifierProxyProvider<AuthController, ThemeController>(
          create: (_) => ThemeController(),
          update: (context, auth, previous) {
            final controller = previous ?? ThemeController();
            Future.microtask(() {
              if (auth.userModel != null) {
                controller.syncWithUserTheme(auth.userModel!.currentThemeId);
              } else {
                controller.resetToDefault();
              }
            });
            return controller;
          },
        ),
      ],
      child: Builder(
        // ThemeController 접근을 위해 Builder 또는 Consumer 사용
        builder: (context) {
          // 광고 로드 (Context 접근 가능)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              context.read<CharacterController>().loadRewardedAd(
                    context: context,
                  );
            } catch (_) {}
          });

          return Consumer2<ThemeController, LanguageProvider>(
            builder: (context, themeController, languageProvider, child) {
              return MaterialApp.router(
                title: 'Morni',
                debugShowCheckedModeBanner: false,
                theme: themeController.themeData,
                scaffoldMessengerKey: MorniApp.scaffoldMessengerKey,
                routerConfig: _router, // 생성된 라우터 사용
                // Localization
                locale: languageProvider.locale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [Locale('ko', ''), Locale('en', '')],
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.noScaling),
                    child: child!,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
