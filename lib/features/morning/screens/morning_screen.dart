import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/morning_controller.dart';
import '../../character/controllers/character_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../services/user_service.dart';
import '../../notification/controllers/notification_controller.dart';
import '../../../data/models/notification_model.dart';
import '../widgets/enhanced_character_room_widget.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../data/models/room_decoration_model.dart';
import '../../../core/services/asset_precache_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/store_button.dart';
import '../widgets/diary_button.dart';
import '../widgets/decoration_button.dart';
import '../widgets/header_image_button.dart';
import '../widgets/character_decoration_button.dart';
import '../../../core/localization/app_localizations.dart';

class MorningScreen extends StatefulWidget {
  const MorningScreen({super.key});

  @override
  State<MorningScreen> createState() => _MorningScreenState();
}

class _MorningScreenState extends State<MorningScreen>
    with SingleTickerProviderStateMixin {
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
                    cacheWidth: 400,
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
                            cacheWidth: 100,
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
                    onTap: () => context.pop(),
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
          // 닉네임 체크: 닉네임이 숫자로만 구성된 경우 (카카오 ID) 또는 '사용자'인 경우 변경 팝업 표시
          final userModel = authController.userModel;
          if (userModel != null) {
            final nickname = userModel.nickname;
            // 숫자로만 구성되어 있는지 확인 (카카오 ID) 또는 기본값 '사용자'인지 확인
            final isNumeric = RegExp(r'^[0-9]+$').hasMatch(nickname);
            final isDefault = nickname == '사용자';

            if (isNumeric || isDefault) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showNicknameChangeDialog(nickname);
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error initializing morning screen: $e');
    }

    // 프리캐싱 시작 (화면 렌더링에 방해되지 않게 마지막에 실행)
    if (mounted) {
      AssetPrecacheService().precacheAllRoomAssets(context);
    }
  }

  Future<void> _showNicknameChangeDialog(String currentNickname) async {
    final controller = TextEditingController(text: ''); // 빈 칸으로 시작 유도
    final isCheckingNotifier = ValueNotifier<bool>(false);

    // 사용자가 닉네임을 입력하도록 유도하기 위해 빈 칸으로 시작하거나,
    // 현재 닉네임(숫자)을 보여줄지 결정. 숫자는 보기 싫으니 빈 칸이 나을 수도 있음.
    // 하지만 힌트를 주기 위해 placeholder에 "닉네임을 입력해주세요" 등을 넣음.

    await AppDialog.show(
      context: context,
      barrierDismissible: false, // 필수 입력 유도
      key: AppDialogKey.changeNickname,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)?.get('nicknameIntro') ??
                'Nice to meet you! Please enter your nickname.',
            style: const TextStyle(
              fontFamily: 'BMJUA',
              fontSize: 16,
              color: Color(0xFF4E342E),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PopupTextField(
              controller: controller,
              hintText:
                  AppLocalizations.of(context)?.get('nicknamePlaceholder') ??
                      'Enter nickname (2-10 chars)',
              maxLength: 10,
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: isCheckingNotifier,
            builder: (context, isChecking, child) {
              if (!isChecking) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      actions: [
        // 취소 버튼 없음 (필수 설정 유도)
        AppDialogAction(
          label: AppLocalizations.of(context)?.get('start') ?? 'Start',
          isPrimary: true,
          onPressed: (BuildContext context) async {
            final newNickname = controller.text.trim();
            AppDialog.showError(context, null);

            if (newNickname.isEmpty || newNickname.length < 2) {
              AppDialog.showError(
                  context,
                  AppLocalizations.of(context)?.get('nicknameLengthError') ??
                      'Nickname must be at least 2 characters');
              return;
            }

            final authController = context.read<AuthController>();
            final userService = context.read<UserService>();
            final userId = authController.currentUser?.uid;

            if (userId != null) {
              try {
                isCheckingNotifier.value = true;
                final isAvailable =
                    await userService.isNicknameAvailable(newNickname);
                isCheckingNotifier.value = false;

                if (!isAvailable) {
                  AppDialog.showError(
                      context,
                      AppLocalizations.of(context)?.get('nicknameTakenError') ??
                          'Nickname is already taken');
                  return;
                }

                await context
                    .read<AuthController>()
                    .updateNickname(newNickname);

                if (context.mounted) {
                  Navigator.pop(context);
                  // 환영 메시지 등 표시 가능
                }
              } catch (e) {
                if (context.mounted) {
                  isCheckingNotifier.value = false;
                  AppDialog.showError(context,
                      '${AppLocalizations.of(context)?.get('error') ?? 'Error'}: $e');
                }
              }
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;
    final isDarkMode = Provider.of<ThemeController>(context).isDarkMode;

    return Consumer<MorningController>(
      builder: (context, morningController, child) {
        // 데이터가 로드되지 않았을 때는(초기 상태) 깨어있는 것으로 간주하여 "뿌연" 오버레이 방지
        final isAwake = !morningController.hasInitialized ||
            morningController.hasDiaryToday;
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
                morningController,
              ),
            ),

            // 1.5. 밤 모드 전체 오버레이 (잠들어있을 때 방 전체를 어둡게)
            // 이제 EnhancedCharacterRoomWidget 내부에서 광원 효과와 함께 처리됩니다.

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
              bottom: 0,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                      bottom: isAwake
                          ? 30
                          : 105), // Increased significantly to avoid overlap
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
            ),

            // 3.5 캐릭터 꾸미기 버튼 (오른쪽)
            Positioned(
              right: 20,
              bottom: 0,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: isAwake ? 20 : 95, // 잘 때 일기 작성 버튼 위로 올라가도록
                  ),
                  child: const CharacterDecorationButton(),
                ),
              ),
            ),

            // 4. 일기작성하기 버튼 (중앙 하단)
            if (!isAwake)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(
                        bottom: 10, // Match side button height
                        left: 20,
                        right: 20),
                    child: Center(
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

            // 5. Header (Top)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: _buildHeader(context, isAwake, colorScheme, isDarkMode),
              ),
            ),

            // 6. Optional Bottom Section Overlay (if needed for other UI)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                top: false,
                child: _buildBottomSection(
                  context,
                  morningController,
                  isAwake,
                  colorScheme,
                  isDarkMode,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 생체 인증 로직은 SplashScreen으로 이동됨

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
                    fontFamily: 'BMJUA',
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
                  AppLocalizations.of(context)?.getFormat(
                        'consecutiveDays',
                        {
                          'days':
                              '${characterController.currentUser?.displayConsecutiveDays ?? 0}'
                        },
                      ) ??
                      '${characterController.currentUser?.displayConsecutiveDays ?? 0} days consecutive streak 🔥',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textColor.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                    fontFamily: 'BMJUA',
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
              const SizedBox(width: 8),
              // 알림 버튼
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
                  return HeaderImageButton(
                    imagePath: hasUnread
                        ? 'assets/icons/Alerm_Red.png'
                        : 'assets/icons/Alerm_Button.png',
                    onTap: () {
                      context.pushNamed('notification');
                    },
                  );
                },
              ),
              const SizedBox(width: 8),
              // 설정 버튼
              HeaderImageButton(
                imagePath: 'assets/icons/Setting_button.png',
                onTap: () {
                  context.push('/settings');
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
    MorningController morningController,
  ) {
    final isDarkMode =
        Provider.of<ThemeController>(context, listen: false).isDarkMode;
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;

    final bottomPadding = 30 + MediaQuery.of(context).padding.bottom;

    return EnhancedCharacterRoomWidget(
      key: const ValueKey('main_character_room'),
      isAwake: isAwake,
      isDarkMode: isDarkMode,
      colorScheme: colorScheme,
      characterLevel: characterController.currentUser?.characterLevel ?? 1,
      consecutiveDays:
          characterController.currentUser?.displayConsecutiveDays ?? 0,
      roomDecoration: characterController.currentUser?.roomDecoration,
      currentAnimation: characterController.currentAnimation,
      onPropTap: (prop) => _showMemoDialog(prop),
      todaysMood: (morningController.todayDiary?.moods.isNotEmpty ?? false)
          ? morningController.todayDiary?.moods.first
          : null,
      bottomPadding: bottomPadding,
      equippedCharacterItems:
          characterController.currentUser?.equippedCharacterItems,
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return AppLocalizations.of(context)?.get('greetingMorning') ??
          'Good morning!';
    }
    if (hour < 18) {
      return AppLocalizations.of(context)?.get('greetingAfternoon') ??
          'Good afternoon!';
    }
    return AppLocalizations.of(context)?.get('greetingEvening') ??
        'Good evening!';
  }
}
