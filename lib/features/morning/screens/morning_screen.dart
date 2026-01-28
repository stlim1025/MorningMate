import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/morning_controller.dart';
import '../../character/controllers/character_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../widgets/random_question.dart';
import '../../settings/screens/settings_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MorningScreen extends StatefulWidget {
  const MorningScreen({super.key});

  @override
  State<MorningScreen> createState() => _MorningScreenState();
}

class _MorningScreenState extends State<MorningScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _initializeScreen();

    // 캐릭터 bounce 애니메이션
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
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
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<MorningController, CharacterController>(
        builder: (context, morningController, characterController, child) {
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

  Widget _buildHeader(BuildContext context, bool isAwake) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
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
      child: Column(
        children: [
          // 태양/달
          Align(
            alignment: Alignment.topRight,
            child: _buildSunMoon(isAwake),
          ),

          const SizedBox(height: 20),

          // 방 내부
          _buildRoomInterior(isAwake, characterController),
        ],
      ),
    );
  }

  Widget _buildSunMoon(bool isAwake) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isAwake ? const Color(0xFFFFD700) : const Color(0xFFFFF8DC),
        boxShadow: [
          BoxShadow(
            color: (isAwake ? const Color(0xFFFFD700) : const Color(0xFFFFF8DC))
                .withOpacity(0.6),
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
      ),
    );
  }

  Widget _buildRoomInterior(
      bool isAwake, CharacterController characterController) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        // 낮/밤에 따라 방 배경색을 극명하게 변경
        color: isAwake
            ? const Color(0xFFFDF5E6) // 밝은 베이지
            : const Color(0xFF2C3E50).withOpacity(0.8), // 어두운 남색
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isAwake ? Colors.white : Colors.white10,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // 벽 장식 (액자들)
          _buildWallDecoration(isAwake),

          const SizedBox(height: 20),

          // 침대와 캐릭터
          _buildBedAndCharacter(isAwake, characterController),

          const SizedBox(height: 20),

          // 바닥 장식 (화분들)
          _buildFloorDecoration(),
        ],
      ),
    );
  }

  Widget _buildWallDecoration(bool isAwake) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildFrame(Icons.local_florist,
            isAwake ? const Color(0xFFDEB887) : Colors.brown.shade800),
        const SizedBox(width: 40),
        _buildFrame(Icons.spa,
            isAwake ? const Color(0xFF90EE90) : Colors.green.shade900),
      ],
    );
  }

  Widget _buildFrame(IconData icon, Color color) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        border: Border.all(color: const Color(0xFF8B7355), width: 3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 30),
    );
  }

  Widget _buildBedAndCharacter(
      bool isAwake, CharacterController characterController) {
    return SizedBox(
      height: 200, // 캐릭터 이동 공간 확보
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 침대 (잠잘 때는 중앙, 깨어나면 뒤쪽으로 배치된 효과)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 800),
            top: isAwake ? 0 : 20,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color:
                    isAwake ? const Color(0xFF8B7355) : const Color(0xFF5D4037),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    decoration: BoxDecoration(
                      color: isAwake
                          ? const Color(0xFFA0826D)
                          : const Color(0xFF4E342E),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: (isAwake
                                ? const Color(0xFFFFB6C1)
                                : const Color(0xFF9575CD))
                            .withOpacity(0.7),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 캐릭터
          AnimatedPositioned(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            // 잠잘 때는 침대 위(top: 40), 깨어나면 바닥 중앙(top: 100)
            top: isAwake ? 80 : 30,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedBuilder(
                animation: _bounceAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, isAwake ? -_bounceAnimation.value : 0),
                    child: _buildCharacter(isAwake),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacter(bool isAwake) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFFF0F5).withOpacity(0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 캐릭터 몸
          Container(
            width: 90,
            height: 100,
            decoration: const BoxDecoration(
              color: Color(0xFF87CEEB), // 하늘색
              borderRadius: BorderRadius.all(Radius.circular(45)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 얼굴 부분 (크림색)
                Container(
                  width: 70,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8DC),
                    borderRadius: BorderRadius.circular(35),
                  ),
                  child: Stack(
                    children: [
                      // 눈
                      Positioned(
                        top: 25,
                        left: 20,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 25,
                        right: 20,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // 부리
                      Positioned(
                        top: 32,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 12,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF8C00),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 볼터치
                      Positioned(
                        top: 40,
                        right: 12,
                        child: Container(
                          width: 15,
                          height: 10,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB6C1).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 날개
          Positioned(
            right: 5,
            top: 25,
            child: Container(
              width: 20,
              height: 30,
              decoration: const BoxDecoration(
                color: Color(0xFF87CEEB),
                borderRadius: BorderRadius.all(Radius.circular(15)),
              ),
            ),
          ),

          // Z 표시 (잠잘 때)
          if (!isAwake)
            Positioned(
              top: -20,
              right: 0,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Stack(
                    children: [
                      // 첫 번째 Z
                      Transform.translate(
                        offset: Offset(
                          10 * (1 - _animationController.value),
                          -20 * _animationController.value,
                        ),
                        child: Opacity(
                          opacity:
                              (1 - _animationController.value).clamp(0.0, 1.0),
                          child: const Text(
                            'Z',
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // 두 번째 Z (약간의 시차)
                      Transform.translate(
                        offset: Offset(
                          20 * (1 - ((_animationController.value + 0.5) % 1.0)),
                          -30 * ((_animationController.value + 0.5) % 1.0),
                        ),
                        child: Opacity(
                          opacity:
                              (1 - ((_animationController.value + 0.5) % 1.0))
                                  .clamp(0.0, 1.0),
                          child: const Padding(
                            padding: EdgeInsets.only(left: 15, top: 10),
                            child: Text(
                              'z',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white60,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFloorDecoration() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildPlant(const Color(0xFF90EE90)),
        const SizedBox(width: 20),
        _buildPlant(const Color(0xFF98FB98)),
      ],
    );
  }

  Widget _buildPlant(Color color) {
    return Container(
      width: 50,
      height: 60,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 잎
          Icon(Icons.spa, color: color, size: 35),
          // 화분
          Container(
            width: 50,
            height: 25,
            decoration: BoxDecoration(
              color: const Color(0xFFD2691E).withOpacity(0.7),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(8),
              ),
            ),
          ),
        ],
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
