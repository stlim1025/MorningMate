import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/morning_controller.dart';
import '../../character/controllers/character_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../widgets/random_question.dart';
import '../widgets/progress_indicator_widget.dart';
import '../widgets/night_sky_background.dart';
import '../widgets/character_room_widget.dart';
import '../../settings/screens/settings_screen.dart';

class MorningScreen extends StatefulWidget {
  const MorningScreen({super.key});

  @override
  State<MorningScreen> createState() => _MorningScreenState();
}

class _MorningScreenState extends State<MorningScreen> {
  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    final authController = context.read<AuthController>();
    final morningController = context.read<MorningController>();
    final characterController = context.read<CharacterController>();

    final userId = authController.currentUser?.uid;
    if (userId != null) {
      // 1. 먼저 일기 확인
      await morningController.checkTodayDiary(userId);

      // 2. 일기가 있으면 캐릭터를 깨움
      if (morningController.hasDiaryToday) {
        characterController.setAwake(true);
      }

      // 3. 나머지 유저 데이터 로드
      await characterController.loadUserData(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<MorningController, CharacterController>(
        builder: (context, morningController, characterController, child) {
          if (morningController.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final hasDiary = morningController.hasDiaryToday;
          final isAwake = characterController.isAwake || hasDiary;

          return NightSkyBackground(
            isDayTime: isAwake,
            child: SafeArea(
              child: Column(
                children: [
                  // 헤더
                  _buildHeader(context, isAwake),

                  const SizedBox(height: 16),

                  // 캐릭터 방
                  Expanded(
                    child: Center(
                      child: CharacterRoomWidget(
                        isAwake: isAwake,
                        characterState:
                            characterController.characterState.toString(),
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
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Consumer<CharacterController>(
                builder: (context, controller, child) {
                  return Text(
                    '${controller.currentUser?.consecutiveDays ?? 0}일 연속 기록 중 🔥',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  );
                },
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
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

  Widget _buildBottomSection(
    BuildContext context,
    MorningController controller,
    bool isAwake,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.6),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isAwake) ...[
            // 랜덤 질문 표시
            const RandomQuestionWidget(),
            const SizedBox(height: 20),

            // 작성 시작 버튼
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  await controller.fetchRandomQuestion();
                  if (context.mounted) {
                    context.push('/writing', extra: controller.currentQuestion);
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.success.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '오늘의 일기 작성 완료!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '내일 아침에 다시 만나요 😊',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
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
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
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
