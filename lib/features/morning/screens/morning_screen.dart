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
          // 로딩 중이거나 초기화가 아직 안 된 경우
          if (morningController.isLoading ||
              !morningController.hasInitialized) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6B9AC4),
              ),
            );
          }

          final hasDiary = morningController.hasDiaryToday;
          // 일기가 있으면 무조건 깨어있는 상태(isAwake=true)가 되도록 강제
          final isAwake = hasDiary || characterController.isAwake;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isAwake
                    ? [
                        const Color(0xFF87CEEB), // 하늘색
                        const Color(0xFFB0E0E6), // 파우더 블루
                        const Color(0xFFFFF8DC), // 코니실크
                      ]
                    : [
                        const Color(0xFF0F2027), // 어두운 밤
                        const Color(0xFF203A43),
                        const Color(0xFF2C5364),
                      ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // 헤더
                  _buildHeader(context, isAwake),

                  const SizedBox(height: 8),

                  // 캐릭터 방 (메인 콘텐츠)
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
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

                  // 하단 버튼 영역
                  _buildBottomSection(
                    context,
                    morningController,
                    isAwake,
                  ),
                ],
              ),
            ),
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
                        color: isAwake ? const Color(0xFF2C3E50) : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Consumer<CharacterController>(
                  builder: (context, controller, child) {
                    return Text(
                      '${controller.currentUser?.consecutiveDays ?? 0}일 연속 기록 중 🔥',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isAwake
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
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        color: isAwake
            ? Colors.white.withOpacity(0.9)
            : Colors.black.withOpacity(0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isAwake) ...[
            // 랜덤 질문 표시
            GestureDetector(
              onTap: () => controller.fetchRandomQuestion(),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5DC).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF8B7355).withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: Color(0xFFFFD700), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '오늘의 질문',
                          style: TextStyle(
                            color: const Color(0xFF2C3E50).withOpacity(0.7),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.refresh,
                          color: const Color(0xFF2C3E50).withOpacity(0.5),
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      controller.currentQuestion ?? '오늘의 질문을 불러오는 중...',
                      style: const TextStyle(
                        color: Color(0xFF2C3E50),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 작성 시작 버튼
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  // 이미 화면에 표시된 질문이 있으므로 새로 가져오지 않고 바로 이동
                  if (controller.currentQuestion == null) {
                    await controller.fetchRandomQuestion();
                  }
                  if (context.mounted) {
                    context.push('/writing', extra: controller.currentQuestion);
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF6B9AC4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 3,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.edit_note, size: 24),
                    SizedBox(width: 8),
                    Text(
                      '오늘의 일기 작성하기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF90EE90).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF90EE90).withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF228B22),
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '오늘의 일기 작성 완료!',
                          style: TextStyle(
                            color: Color(0xFF228B22),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '내일 아침에 다시 만나요 😊',
                          style: TextStyle(
                            color: Color(0xFF2C3E50),
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
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 0,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF6B9AC4),
      unselectedItemColor: Colors.grey,
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
