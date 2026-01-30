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
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';

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
      // AuthController의 유저 정보가 아직 null이라면 FirebaseAuth에서 직접 가져옴
      String? userId = authController.currentUser?.uid;

      if (userId == null) {
        userId = FirebaseAuth.instance.currentUser?.uid;
      }

      if (userId != null) {
        // 1. 오늘의 일기 여부 먼저 확인
        await morningController.checkTodayDiary(userId);
        await morningController.syncConsecutiveDays(userId);

        // 2. 일기가 있으면 캐릭터 상태 동기화
        if (morningController.hasDiaryToday) {
          characterController.setAwake(true);
        } else {
          characterController.setAwake(false);
          // 일기가 없으면 랜덤 질문 가져오기
          await morningController.fetchRandomQuestion();
        }

        // 3. 나머지 유저 데이터 로드
        await characterController.loadUserData(userId);
      } else {
        morningController.finishLoading();
      }
    } catch (e) {
      print('초기화 오류: $e');
      morningController.finishLoading();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<MorningController, CharacterController>(
        builder: (context, morningController, characterController, child) {
          _maybeAuthenticateOnLaunch(context);
          if (morningController.isLoading ||
              !morningController.hasInitialized) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6B9AC4),
              ),
            );
          }

          final hasDiary = morningController.hasDiaryToday;
          final isAwake = hasDiary || characterController.isAwake;

          return Stack(
            children: [
              // 1. Background Gradient
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
                child: _buildSunMoon(isAwake),
              ),

              // 4. Main Content
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context, isAwake),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(
                                height:
                                    60), // Adjusted space since moon is moved/resized
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
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildSunMoon(bool isAwake) {
    return Container(
      width: 60, // Reduced from 100
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isAwake ? const Color(0xFFFFD700) : const Color(0xFFFFF8DC),
        boxShadow: [
          BoxShadow(
            color: (isAwake ? const Color(0xFFFFD700) : const Color(0xFFFFF8DC))
                .withOpacity(0.6),
            blurRadius: 30, // Reduced blur proportional to size
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

    if (userModel == null) {
      return;
    }

    _hasCheckedBiometric = true;

    if (!userModel.biometricEnabled) {
      return;
    }

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
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          '생체 인증 실패',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          '생체 인증에 실패했습니다. 다시 시도하거나 로그아웃할 수 있습니다.',
          style: TextStyle(color: Color(0xFF5A6C7D)),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF0F0F0),
              foregroundColor: const Color(0xFF5A6C7D),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('로그아웃'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: const Color(0xFF2C3E50),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '다시 시도',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Widget _buildHeader(BuildContext context, bool isAwake) {
    final authController = context.read<AuthController>();
    final userId =
        authController.userModel?.uid ?? authController.currentUser?.uid;
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
                        color: (isAwake &&
                                !Provider.of<ThemeController>(context)
                                    .isDarkMode)
                            ? const Color(0xFF2C3E50)
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Consumer<CharacterController>(
                  builder: (context, controller, child) {
                    return Text(
                      '${controller.currentUser?.consecutiveDays ?? 0}일 연속 기록 중 🔥',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: (isAwake &&
                                    !Provider.of<ThemeController>(context)
                                        .isDarkMode)
                                ? const Color(0xFF5A6C7D)
                                : Colors.white70,
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
                          color:
                              isAwake ? const Color(0xFF2C3E50) : Colors.white,
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
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.settings,
                    color: isAwake ? const Color(0xFF2C3E50) : Colors.white),
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

  // 향상된 캐릭터 룸 (이미지 참조 스타일)
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
  ) {
    final isDarkMode = Provider.of<ThemeController>(context).isDarkMode;
    // 따뜻한 느낌의 앱 테마 색상 적용 (AppColors.backgroundLight)
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4A574).withOpacity(0.15),
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
              // 질문 표시 영역
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: AppColors.awakeMode, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '오늘의 질문',
                          style: TextStyle(
                            color: AppColors.textPrimary.withOpacity(0.7),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => controller.fetchRandomQuestion(),
                          child: Icon(
                            Icons.refresh,
                            color: AppColors.textSecondary.withOpacity(0.5),
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      controller.currentQuestion ?? '오늘의 질문을 불러오는 중...',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 크고 눈에 띄는 작성 버튼
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
                    backgroundColor: AppColors.primary, // 따뜻한 골드/카라멜 색상
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: AppColors.primary.withOpacity(0.4),
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
              // 작성 완료 상태
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? const Color(0xFF81C784).withOpacity(0.1)
                      : const Color(0xFF90EE90).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDarkMode
                        ? const Color(0xFF81C784).withOpacity(0.5)
                        : const Color(0xFF90EE90).withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: isDarkMode
                          ? const Color(0xFF81C784)
                          : const Color(0xFF228B22),
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
                              color: isDarkMode
                                  ? const Color(0xFF81C784)
                                  : const Color(0xFF228B22),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '내일 아침에 다시 만나요 😊',
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.white70
                                  : AppColors.textPrimary,
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

  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 0,
      backgroundColor:
          Theme.of(context).bottomNavigationBarTheme.backgroundColor,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Provider.of<ThemeController>(context).isDarkMode
          ? const Color(0xFF3E3224)
          : Colors.grey,
      elevation: 10,
      onTap: (index) {
        switch (index) {
          case 0:
            // 현재 화면
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
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: '홈',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.pets),
          label: '캐릭터',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: '친구',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: '아카이브',
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return '좋은 아침이에요!';
    } else if (hour < 18) {
      return '좋은 오후에요!';
    } else {
      return '좋은 저녁이에요!';
    }
  }
}

extension MorningControllerExt on MorningController {
  bool isDarkMode(BuildContext context) {
    return Provider.of<ThemeController>(context, listen: false).isDarkMode;
  }
}
