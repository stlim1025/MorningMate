import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/morning_controller.dart';
import '../../character/controllers/character_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../settings/screens/settings_screen.dart';
import '../../notification/controllers/notification_controller.dart';
import '../../../data/models/notification_model.dart';
import '../widgets/enhanced_character_room_widget.dart';
import '../widgets/twinkling_stars.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/app_dialog.dart';

class MorningScreen extends StatefulWidget {
  const MorningScreen({super.key});

  @override
  State<MorningScreen> createState() => _MorningScreenState();
}

class _MorningScreenState extends State<MorningScreen>
    with SingleTickerProviderStateMixin {
  bool _hasCheckedBiometric = false;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    final authController = context.read<AuthController>();
    final morningController = context.read<MorningController>();
    final characterController = context.read<CharacterController>();

    try {
      String? userId = authController.currentUser?.uid;
      if (userId == null) {
        userId = FirebaseAuth.instance.currentUser?.uid;
      }

      if (userId != null) {
        // 병렬로 데이터 로드
        await Future.wait([
          morningController.checkTodayDiary(userId),
          characterController.loadUserData(userId),
          if (morningController.currentQuestion == null)
            morningController.fetchRandomQuestion(),
        ]);

        if (mounted) {
          _maybeAuthenticateOnLaunch(context);
        }
      }
    } catch (e) {
      debugPrint('Error initializing morning screen: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;
    final isDarkMode = Provider.of<ThemeController>(context).isDarkMode;

    return Scaffold(
      body: Consumer<MorningController>(
        builder: (context, morningController, child) {
          final isAwake = morningController.hasDiaryToday;
          final characterController = context.watch<CharacterController>();

          return Stack(
            children: [
              // 1. Sky Gradient Background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isAwake
                        ? [
                            const Color(0xFF87CEEB),
                            const Color(0xFFB0E0E6),
                            const Color(0xFFFFF8DC),
                          ]
                        : [
                            const Color(0xFF0F2027),
                            const Color(0xFF203A43),
                            const Color(0xFF2C5364),
                          ],
                  ),
                ),
              ),

              // 2. Stars (Night only)
              if (!isAwake) const Positioned.fill(child: TwinklingStars()),

              // 3. Sun/Moon (Background Element)
              Positioned(
                top: 90,
                right: 30,
                child: _buildSunMoon(isAwake, colorScheme),
              ),

              // 4. Main Content
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context, isAwake, colorScheme, isDarkMode),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 60),
                            _buildEnhancedCharacterRoom(
                              context,
                              isAwake,
                              characterController,
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                    _buildBottomSection(
                      context,
                      morningController,
                      isAwake,
                      colorScheme,
                      isDarkMode,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context, colorScheme),
    );
  }

  Widget _buildSunMoon(bool isAwake, AppColorScheme colorScheme) {
    final color = isAwake ? colorScheme.pointStar : const Color(0xFFFFF8DC);
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: 30,
            spreadRadius: 8,
          ),
        ],
      ),
    );
  }

  void _maybeAuthenticateOnLaunch(BuildContext context) {
    if (_hasCheckedBiometric) return;
    final authController = context.read<AuthController>();
    final userModel = authController.userModel;
    if (userModel == null) return;
    _hasCheckedBiometric = true;
    if (!userModel.biometricEnabled) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final authenticated = await authController.authenticateWithBiometric();
      if (!authenticated && mounted) {
        final retry = await _showBiometricRetryDialog(context);
        if (retry && mounted) {
          _hasCheckedBiometric = false;
          _maybeAuthenticateOnLaunch(context);
        } else if (mounted) {
          await authController.signOut();
          if (mounted) {
            context.go('/login');
          }
        }
      }
    });
  }

  Future<bool> _showBiometricRetryDialog(BuildContext context) async {
    final result = await AppDialog.show<bool>(
      context: context,
      key: AppDialogKey.biometricRetry,
      barrierDismissible: false,
      actions: [
        AppDialogAction(
          label: '로그아웃',
          onPressed: () => Navigator.pop(context, false),
        ),
        AppDialogAction(
          label: '다시 시도',
          onPressed: () => Navigator.pop(context, true),
          useHighlight: true,
        ),
      ],
    );
    return result ?? false;
  }

  Widget _buildHeader(BuildContext context, bool isAwake,
      AppColorScheme colorScheme, bool isDarkMode) {
    final authController = context.read<AuthController>();
    final userId =
        authController.userModel?.uid ?? authController.currentUser?.uid;
    final textColor =
        (isAwake && !isDarkMode) ? const Color(0xFF2C3E50) : Colors.white;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Consumer<CharacterController>(
                  builder: (context, controller, child) {
                    return Text(
                      '${controller.currentUser?.consecutiveDays ?? 0}일 연속 기록 중 🔥',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: textColor.withOpacity(0.8),
                          ),
                    );
                  },
                ),
              ],
            ),
          ),
          Row(
            children: [
              StreamBuilder<List<NotificationModel>>(
                stream: userId == null
                    ? const Stream.empty()
                    : context
                        .read<NotificationController>()
                        .getNotificationsStream(userId),
                builder: (context, snapshot) {
                  final notifications = snapshot.data ?? [];
                  final hasUnread =
                      notifications.any((notification) => !notification.isRead);
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.notifications_outlined,
                          color: textColor,
                        ),
                        onPressed: () {
                          context.pushNamed('notification');
                        },
                      ),
                      if (hasUnread)
                        Positioned(
                          right: 12,
                          top: 10,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.settings, color: textColor),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedCharacterRoom(
    BuildContext context,
    bool isAwake,
    CharacterController characterController,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: EnhancedCharacterRoomWidget(
        isAwake: isAwake,
        characterLevel: characterController.currentUser?.characterLevel ?? 1,
        consecutiveDays: characterController.currentUser?.consecutiveDays ?? 0,
      ),
    );
  }

  Widget _buildBottomSection(
    BuildContext context,
    MorningController controller,
    bool isAwake,
    AppColorScheme colorScheme,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadowColor.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isAwake) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.cardAccent.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome,
                            color: colorScheme.accent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '오늘의 질문',
                          style: TextStyle(
                            color: colorScheme.textPrimary.withOpacity(0.7),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => controller.fetchRandomQuestion(),
                          child: Icon(
                            Icons.refresh,
                            color: colorScheme.textSecondary.withOpacity(0.5),
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      controller.currentQuestion ?? '오늘의 질문을 불러오는 중...',
                      style: TextStyle(
                        color: colorScheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    if (controller.currentQuestion == null) {
                      await controller.fetchRandomQuestion();
                    }
                    if (context.mounted) {
                      context.push('/writing',
                          extra: controller.currentQuestion);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primaryButton,
                    foregroundColor: colorScheme.primaryButtonForeground,
                    elevation: 4,
                    shadowColor: colorScheme.primaryButton.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.edit_note, size: 24),
                      SizedBox(width: 8),
                      Text(
                        '오늘의 일기 작성하기',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: colorScheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.success.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: colorScheme.success,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '오늘의 일기 작성 완료!',
                            style: TextStyle(
                              color: colorScheme.success,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '내일 아침에 다시 만나요 😊',
                            style: TextStyle(
                              color: colorScheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(
      BuildContext context, AppColorScheme colorScheme) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 0,
      backgroundColor:
          Theme.of(context).bottomNavigationBarTheme.backgroundColor,
      selectedItemColor: colorScheme.tabSelected,
      unselectedItemColor: colorScheme.tabUnselected,
      elevation: 10,
      onTap: (index) {
        switch (index) {
          case 0:
            break;
          case 1:
            context.go('/character');
            break;
          case 2:
            context.go('/social');
            break;
          case 3:
            context.go('/archive');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
        BottomNavigationBarItem(icon: Icon(Icons.pets), label: '캐릭터'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: '친구'),
        BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today), label: '아카이브'),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '좋은 아침이에요!';
    if (hour < 18) return '좋은 오후에요!';
    return '좋은 저녁이에요!';
  }
}
