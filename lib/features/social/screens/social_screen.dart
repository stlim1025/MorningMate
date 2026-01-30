import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/social_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../data/models/user_model.dart';
import '../../../services/user_service.dart';
import '../../../core/theme/theme_controller.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    final authController = context.read<AuthController>();
    final socialController = context.read<SocialController>();
    final userId = authController.currentUser?.uid;

    if (userId != null) {
      await socialController.loadFriends(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.read<AuthController>();
    final socialController = context.read<SocialController>();
    final userId = authController.currentUser?.uid;
    final friendsStream =
        userId == null ? null : socialController.getFriendsStream(userId);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people, color: AppColors.primary, size: 28),
            SizedBox(width: 8),
            Text(
              '친구',
              style: TextStyle(
                color: Theme.of(context).textTheme.titleLarge?.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          if (friendsStream != null)
            StreamBuilder<List<UserModel>>(
              stream: friendsStream,
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;
                return Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count명',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),

            // 친구 요청 목록 (있을 경우에만 표시)
            Consumer<SocialController>(
              builder: (context, controller, child) {
                if (controller.friendRequests.isEmpty) {
                  return const SizedBox.shrink();
                }
                return _buildFriendRequestSection(context, controller);
              },
            ),

            // 친구 목록
            Expanded(
              child: friendsStream == null
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : StreamBuilder<List<UserModel>>(
                      stream: friendsStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          );
                        }

                        final friends = snapshot.data ?? [];
                        if (friends.isEmpty) {
                          return _buildEmptyState();
                        }

                        return RefreshIndicator(
                          onRefresh: _loadFriends,
                          color: AppColors.primary,
                          child: GridView.builder(
                            padding: const EdgeInsets.all(20),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.68,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: friends.length,
                            itemBuilder: (context, index) {
                              return Builder(
                                builder: (context) {
                                  final friend = friends[index];
                                  final isAwake =
                                      context.select<SocialController, bool>(
                                          (controller) =>
                                              controller.isFriendAwake(
                                                friend.uid,
                                                friend.lastDiaryDate,
                                              ));
                                  return _buildFriendCard(
                                    context,
                                    friend,
                                    isAwake: isAwake,
                                  );
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFriendDialog(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          '친구 추가',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 4,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline,
              size: 80,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '아직 친구가 없습니다',
            style: TextStyle(
              color: Theme.of(context).textTheme.titleLarge?.color,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '친구 추가 버튼을 눌러\n친구를 추가해보세요',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.7),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendRequestSection(
      BuildContext context, SocialController controller) {
    final isDarkMode = Provider.of<ThemeController>(context).isDarkMode;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '친구 요청',
                style: TextStyle(
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDarkMode ? AppColors.primary : AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${controller.friendRequests.length}',
                  style: TextStyle(
                    color: isDarkMode ? const Color(0xFF5D4E37) : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.friendRequests.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final request = controller.friendRequests[index];
              final user = request['user'] as UserModel;
              final requestId = request['requestId'] as String;

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.smallCardShadow,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      child: Text(
                        user.nickname[0],
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.nickname,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          Text(
                            'Lv.${user.characterLevel}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        SizedBox(
                          width: 64,
                          child: ElevatedButton(
                            onPressed: () {
                              final myId = context
                                  .read<AuthController>()
                                  .currentUser
                                  ?.uid;
                              final myNickname = context
                                  .read<AuthController>()
                                  .userModel
                                  ?.nickname;
                              if (myId != null && myNickname != null) {
                                controller.acceptFriendRequest(
                                    requestId, myId, myNickname, user.uid);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: isDarkMode
                                  ? const Color(0xFF5D4E37)
                                  : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              '수락',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 64,
                          child: OutlinedButton(
                            onPressed: () {
                              final myId = context
                                  .read<AuthController>()
                                  .currentUser
                                  ?.uid;
                              final myNickname = context
                                  .read<AuthController>()
                                  .userModel
                                  ?.nickname;
                              if (myId != null) {
                                controller.rejectFriendRequest(
                                  requestId,
                                  myId,
                                  user.uid,
                                  myNickname ?? '알 수 없음',
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              side: BorderSide(
                                color: isDarkMode
                                    ? Colors.white24
                                    : AppColors.error,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              '거절',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode
                                    ? Colors.white54
                                    : AppColors.error,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _buildFriendCard(
    BuildContext context,
    UserModel friend, {
    required bool isAwake,
  }) {
    final hasWritten = isAwake;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasWritten
              ? AppColors.success.withOpacity(0.5)
              : AppColors.textHint.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            context.push('/friend/${friend.uid}');
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 친구 캐릭터
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: hasWritten
                          ? [
                              AppColors.success.withOpacity(0.3),
                              AppColors.accent.withOpacity(0.3),
                            ]
                          : [
                              AppColors.textHint.withOpacity(0.2),
                              Colors.grey[300]!,
                            ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: hasWritten
                        ? [
                            BoxShadow(
                              color: AppColors.success.withOpacity(0.3),
                              blurRadius: 15,
                              spreadRadius: 3,
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    hasWritten ? Icons.wb_sunny : Icons.bedtime,
                    color:
                        hasWritten ? AppColors.awakeMode : AppColors.sleepMode,
                    size: 45,
                  ),
                ),

                const SizedBox(height: 16),

                // 친구 닉네임
                Text(
                  friend.nickname,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 6),

                // 상태
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: hasWritten
                        ? AppColors.success.withOpacity(0.15)
                        : AppColors.friendSleep.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    hasWritten ? '기상 완료' : '수면 중',
                    style: TextStyle(
                      color: hasWritten
                          ? AppColors.success
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 깨우기 버튼
                if (!hasWritten)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _wakeUpFriend(context, friend),
                      icon: const Icon(Icons.alarm, size: 18),
                      label: const Text(
                        '깨우기',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        side: BorderSide(
                          color: AppColors.textPrimary.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text(
                          '작성 완료',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: AppColors.textHint.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 2,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Provider.of<ThemeController>(context).isDarkMode
            ? const Color(0xFF3E3224) // 훨씬 어두운 브라운
            : Colors.grey,
        backgroundColor: Colors.transparent,
        elevation: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/morning');
              break;
            case 1:
              context.go('/character');
              break;
            case 2:
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
      ),
    );
  }

  Future<void> _wakeUpFriend(BuildContext context, UserModel friend) async {
    final authController = context.read<AuthController>();
    final socialController = context.read<SocialController>();
    final currentUser = authController.userModel;

    if (currentUser == null) return;

    final messenger = ScaffoldMessenger.of(context);
    if (!socialController.canSendWakeUp(friend.uid)) {
      final remaining = socialController.wakeUpCooldownRemaining(friend.uid);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '너무 많은 요청을 보냈어요. ${remaining.inSeconds}초 후에 다시 시도해주세요.',
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Expanded(child: Text('깨우는 중입니다...')),
          ],
        ),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    try {
      await socialController.wakeUpFriend(
        currentUser.uid,
        currentUser.nickname,
        friend.uid,
        friend.nickname,
      );

      if (mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.alarm, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('${friend.nickname}님을 깨웠습니다! ⏰'),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      if (e.code == 'resource-exhausted') {
        messenger.showSnackBar(
          SnackBar(
            content: const Text('너무 많은 요청을 보냈어요. 잠시 후 다시 시도해주세요.'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: const Text('깨우기 실패: 잠시 후 다시 시도해주세요.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    } catch (_) {
      if (mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: const Text('깨우기 실패: 잠시 후 다시 시도해주세요.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _showAddFriendDialog(BuildContext context) async {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Icon(Icons.person_add, color: AppColors.primary),
            SizedBox(width: 12),
            Text(
              '친구 추가',
              style: TextStyle(
                color: Theme.of(context).textTheme.titleLarge?.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '친구의 이메일 주소를 입력하세요',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: 'friend@example.com',
                  hintStyle: TextStyle(color: AppColors.textHint),
                  prefixIcon: const Icon(
                    Icons.email,
                    color: AppColors.primary,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor ??
                      AppColors.backgroundLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이메일을 입력해주세요';
                  }
                  if (!value.contains('@')) {
                    return '올바른 이메일 형식이 아닙니다';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  Provider.of<ThemeController>(context, listen: false)
                          .isDarkMode
                      ? Colors.grey[800]
                      : Colors.grey[200],
              foregroundColor:
                  Provider.of<ThemeController>(context, listen: false)
                          .isDarkMode
                      ? Colors.white70
                      : Colors.black87,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final email = emailController.text.trim();
              Navigator.pop(dialogContext);

              await _addFriendByEmail(context, email);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor:
                  Provider.of<ThemeController>(context, listen: false)
                          .isDarkMode
                      ? const Color(0xFF5D4E37)
                      : Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '추가',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addFriendByEmail(BuildContext context, String email) async {
    final authController = context.read<AuthController>();
    final socialController = context.read<SocialController>();
    final userService = context.read<UserService>();
    final currentUser = authController.currentUser;

    if (currentUser == null) return;

    if (email == currentUser.email) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('자기 자신은 친구로 추가할 수 없습니다'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    try {
      final friendUser = await userService.getUserByEmail(email);

      if (friendUser == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('해당 이메일의 사용자를 찾을 수 없습니다'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        return;
      }

      final isFriend = await socialController.checkIfAlreadyFriend(
        currentUser.uid,
        friendUser.uid,
      );

      if (isFriend) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('이미 친구로 등록된 사용자입니다'),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        return;
      }

      final currentUserModel = context.read<AuthController>().userModel;
      final nickname = currentUserModel?.nickname ?? '알 수 없음';

      await socialController.sendFriendRequest(
          currentUser.uid, nickname, friendUser.uid);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${friendUser.nickname}님에게 친구 요청을 보냈습니다! 📨'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('친구 추가 실패: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }
}
