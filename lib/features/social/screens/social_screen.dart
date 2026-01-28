import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/social_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../data/models/user_model.dart';
import '../../../services/user_service.dart';

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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.backgroundDark, Color(0xFF1A2332)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 헤더
              _buildHeader(context),

              // 친구 목록 (그리드)
              Expanded(
                child: Consumer<SocialController>(
                  builder: (context, controller, child) {
                    if (controller.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (controller.friends.isEmpty) {
                      return _buildEmptyState();
                    }

                    return RefreshIndicator(
                      onRefresh: _loadFriends,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // 가로 2개
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: controller.friends.length,
                        itemBuilder: (context, index) {
                          return _buildFriendCard(
                            context,
                            controller.friends[index],
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
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFriendDialog(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add),
        label: const Text('친구 추가'),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '친구',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Consumer<SocialController>(
            builder: (context, controller, child) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${controller.friends.length}명',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 100,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            '아직 친구가 없습니다',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '친구 추가 버튼을 눌러\n친구를 추가해보세요',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendCard(BuildContext context, UserModel friend) {
    return FutureBuilder<bool>(
      future:
          context.read<SocialController>().hasFriendWrittenToday(friend.uid),
      builder: (context, snapshot) {
        final hasWritten = snapshot.data ?? false;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: hasWritten
                  ? [
                      AppColors.friendActive.withOpacity(0.2),
                      AppColors.friendActive.withOpacity(0.1),
                    ]
                  : [
                      AppColors.cardDark,
                      AppColors.cardDark.withOpacity(0.8),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasWritten
                  ? AppColors.friendActive.withOpacity(0.5)
                  : Colors.white.withOpacity(0.1),
              width: 2,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                context.push('/friend/${friend.uid}');
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 친구 캐릭터
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: hasWritten
                            ? AppColors.friendActive.withOpacity(0.3)
                            : AppColors.friendSleep.withOpacity(0.3),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: hasWritten
                                ? AppColors.friendActive.withOpacity(0.3)
                                : Colors.transparent,
                            blurRadius: 15,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: Icon(
                        hasWritten ? Icons.wb_sunny : Icons.bedtime,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 친구 닉네임
                    Text(
                      friend.nickname,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 4),

                    // 상태
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: hasWritten
                            ? AppColors.friendActive.withOpacity(0.2)
                            : AppColors.friendSleep.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        hasWritten ? '기상 완료' : '수면 중',
                        style: TextStyle(
                          color: hasWritten
                              ? AppColors.friendActive
                              : AppColors.friendSleep,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 깨우기 버튼
                    if (!hasWritten)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _wakeUpFriend(context, friend),
                          icon: const Icon(Icons.alarm, size: 18),
                          label: const Text(
                            '깨우기',
                            style: TextStyle(fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.warning,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.check_circle,
                                color: AppColors.success,
                                size: 18,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '작성 완료',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 2,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/morning');
            break;
          case 1:
            context.go('/character');
            break;
          case 2:
            // 현재 화면
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

  Future<void> _wakeUpFriend(BuildContext context, UserModel friend) async {
    final authController = context.read<AuthController>();
    final socialController = context.read<SocialController>();
    final currentUser = authController.userModel;

    if (currentUser == null) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: const [
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
        friend.uid,
        currentUser.nickname,
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
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: const [
            Icon(Icons.person_add, color: AppColors.primary),
            SizedBox(width: 12),
            Text(
              '친구 추가',
              style: TextStyle(color: Colors.white),
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
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'friend@example.com',
                  hintStyle: const TextStyle(color: Colors.white30),
                  prefixIcon: const Icon(Icons.email, color: Colors.white70),
                  filled: true,
                  fillColor: AppColors.backgroundDark,
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
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('추가'),
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

    // 자기 자신은 추가할 수 없음
    if (email == currentUser.email) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('자기 자신은 친구로 추가할 수 없습니다'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      // 이메일로 사용자 찾기
      final friendUser = await userService.getUserByEmail(email);

      if (friendUser == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('해당 이메일의 사용자를 찾을 수 없습니다'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // 이미 친구인지 확인
      final isFriend = await socialController.checkIfAlreadyFriend(
        currentUser.uid,
        friendUser.uid,
      );

      if (isFriend) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('이미 친구로 등록된 사용자입니다'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }

      // 친구 추가
      await socialController.addFriend(currentUser.uid, friendUser.uid);

      // 친구 목록 새로고침
      await _loadFriends();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${friendUser.nickname}님을 친구로 추가했습니다! 🎉'),
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
          ),
        );
      }
    }
  }
}
