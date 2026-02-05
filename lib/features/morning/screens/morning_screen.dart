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
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../data/models/room_decoration_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/store_button.dart';
import '../widgets/diary_button.dart';
import '../widgets/decoration_button.dart';
import '../../common/widgets/custom_bottom_navigation_bar.dart';

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

  void _showMemoDialog(RoomPropModel prop) {
    if (prop.type != 'sticky_note' || prop.metadata == null) return;

    final userId = context.read<AuthController>().currentUser?.uid;
    if (userId == null) return;

    final content = prop.metadata!['content'] ?? '';
    final localHeartCount = prop.metadata!['heartCount'] ?? 0;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            width: 320,
            height: 320,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. 메모지 배경 이미지
                Positioned.fill(
                  child: Image.asset(
                    'assets/items/StickyNote.png',
                    fit: BoxFit.contain,
                  ),
                ),
                // 2. 텍스트 내용 (중앙)
                Padding(
                  padding: const EdgeInsets.fromLTRB(40, 60, 40, 60),
                  child: Center(
                    child: SingleChildScrollView(
                      child: Text(
                        content,
                        style: const TextStyle(
                          fontFamily: 'NanumPenScript-Regular',
                          fontSize: 24,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                // 3. 하트 (왼쪽 아래) - 스트림 연동
                Positioned(
                  bottom: 30,
                  left: 35,
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .collection('memos')
                        .doc(prop.id)
                        .snapshots(),
                    builder: (context, snapshot) {
                      int displayHeartCount = localHeartCount;
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data =
                            snapshot.data!.data() as Map<String, dynamic>;
                        displayHeartCount =
                            data['heartCount'] ?? localHeartCount;
                      }

                      return Row(
                        children: [
                          Image.asset(
                            'assets/images/Pink_Heart.png',
                            width: 24,
                            height: 24,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$displayHeartCount',
                            style: const TextStyle(
                              fontFamily: 'NanumPenScript-Regular',
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                // 4. 닫기 버튼 (오른쪽 위 - x 버튼)
                Positioned(
                  top: 35,
                  right: 15,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close,
                        color: Colors.black54, size: 24),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _initializeScreen() async {
    final authController = context.read<AuthController>();
    final morningController = context.read<MorningController>();

    try {
      String? userId = authController.currentUser?.uid;
      if (userId == null) {
        userId = FirebaseAuth.instance.currentUser?.uid;
      }

      if (userId != null) {
        // 병렬로 데이터 로드
        await Future.wait([
          morningController.checkTodayDiary(userId),
          context.read<CharacterController>().checkAndClearExpiredMemos(userId),
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

          if (characterController.showLevelUpDialog && mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                AppDialog.show(
                  context: context,
                  key: AppDialogKey.levelUp,
                );
                characterController.consumeLevelUpDialog();
              }
            });
          }

          return Stack(
            children: [
              // 1. 3D 방이 전체 영역을 채움 (배경은 창문을 통해서만 표시)
              Positioned.fill(
                child: _buildEnhancedCharacterRoom(
                  context,
                  isAwake,
                  characterController,
                  todaysMood: morningController.todayDiary?.mood,
                ),
              ),

              // 2. Subtle Top Overlay for UI readability
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 180,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          (isAwake && !isDarkMode)
                              ? Colors.white.withOpacity(0.2)
                              : Colors.black.withOpacity(0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 3. 상점/꾸미기 버튼 (왼쪽)
              Positioned(
                left: 20,
                bottom: isAwake ? 15 : 120, // 일기 작성 후에는 하단 탭 바로 위, 작성 전에는 위쪽
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const DecorationButton(),
                      const SizedBox(height: 8),
                      const StoreButton(),
                    ],
                  ),
                ),
              ),

              // 4. 일기작성하기 버튼 (중앙 하단)
              if (!isAwake)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 15, // 하단 탭 바 바로 위
                  child: SafeArea(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: DiaryButton(
                          onTap: () async {
                            if (morningController.currentQuestion == null) {
                              await morningController.fetchRandomQuestion();
                            }
                            if (context.mounted) {
                              context.push('/writing',
                                  extra: morningController.currentQuestion);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),

              // 4. Main Content (헤더, 하단 섹션 오버레이)
              SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildHeader(context, isAwake, colorScheme, isDarkMode),
                    const Spacer(),
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
      bottomNavigationBar: _buildBottomNavigationBar(context),
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
    final characterController = context.watch<CharacterController>();
    final userId =
        authController.userModel?.uid ?? authController.currentUser?.uid;
    final backgroundId =
        characterController.currentUser?.roomDecoration.backgroundId ??
            'default';

    // 배경이 밝은지 여부 판단 (기본 하늘이나 황금태양 배경일 때)
    final bool isBrightBackground =
        (isAwake && !isDarkMode) || backgroundId == 'golden_sun';

    final textColor =
        isBrightBackground ? const Color(0xFF1A1A1A) : Colors.white;
    final shadowColor = isBrightBackground
        ? Colors.white.withOpacity(0.9)
        : Colors.black.withOpacity(0.85);

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
                    shadows: [
                      Shadow(
                        color: shadowColor,
                        blurRadius: 15,
                        offset: const Offset(0, 1),
                      ),
                      Shadow(
                        color: shadowColor.withOpacity(0.5),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${characterController.currentUser?.consecutiveDays ?? 0}일 연속 기록 중 🔥',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textColor.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        color: shadowColor,
                        blurRadius: 10,
                      ),
                      Shadow(
                        color: shadowColor.withOpacity(0.4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
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
                      Container(
                        decoration: BoxDecoration(
                          color: shadowColor.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.notifications_outlined,
                            color: textColor,
                          ),
                          onPressed: () {
                            context.pushNamed('notification');
                          },
                        ),
                      ),
                      if (hasUnread)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: colorScheme.error,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: shadowColor.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
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
    CharacterController characterController, {
    String? todaysMood,
  }) {
    final isDarkMode =
        Provider.of<ThemeController>(context, listen: false).isDarkMode;
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;

    return EnhancedCharacterRoomWidget(
      key: const ValueKey('main_character_room'),
      isAwake: isAwake,
      isDarkMode: isDarkMode,
      colorScheme: colorScheme,
      characterLevel: characterController.currentUser?.characterLevel ?? 1,
      consecutiveDays: characterController.currentUser?.consecutiveDays ?? 0,
      roomDecoration: characterController.currentUser?.roomDecoration,
      currentAnimation: characterController.currentAnimation,
      onPropTap: (prop) => _showMemoDialog(prop),
      todaysMood: todaysMood,
    );
  }

  Widget _buildBottomSection(
    BuildContext context,
    MorningController controller,
    bool isAwake,
    AppColorScheme colorScheme,
    bool isDarkMode,
  ) {
    return const SizedBox.shrink();
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return CustomBottomNavigationBar(
      currentIndex: 0,
      onTap: (index) {}, // Navigation handled inside the widget
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '좋은 아침이에요!';
    if (hour < 18) return '좋은 오후에요!';
    return '좋은 저녁이에요!';
  }
}
