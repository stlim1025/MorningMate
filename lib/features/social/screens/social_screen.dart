import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../controllers/social_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../data/models/user_model.dart';
import '../../../services/user_service.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../common/widgets/custom_bottom_navigation_bar.dart';

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
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;
    final authController = context.read<AuthController>();
    final socialController = context.read<SocialController>();
    final userId = authController.currentUser?.uid;
    final friendsStream =
        userId == null ? null : socialController.getFriendsStream(userId);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people, color: colorScheme.iconPrimary, size: 28),
            const SizedBox(width: 8),
            Text(
              '친구',
              style: TextStyle(
                color: colorScheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontFamily: 'BMJUA',
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
                    color: colorScheme.cardAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count명',
                    style: TextStyle(
                      color: colorScheme.cardAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: ResizeImage(AssetImage('assets/images/Ceiling.png'),
                width: 1080),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              Consumer<SocialController>(
                builder: (context, controller, child) {
                  if (controller.friendRequests.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: colorScheme.accent.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.accent.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.accent.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.person_add_rounded,
                                  color: colorScheme.accent, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '새로운 친구 요청',
                              style: TextStyle(
                                color: colorScheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: colorScheme.accent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${controller.friendRequests.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...controller.friendRequests
                            .map((req) => _buildRequestItem(req, colorScheme)),
                      ],
                    ),
                  );
                },
              ),
              Expanded(
                child: StreamBuilder<List<UserModel>>(
                  stream: friendsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                size: 80, color: colorScheme.textHint),
                            const SizedBox(height: 16),
                            Text(
                              '아직 친구가 없어요',
                              style: TextStyle(
                                color: colorScheme.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final friends = snapshot.data!;
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: friends.length,
                      itemBuilder: (context, index) {
                        return _buildFriendCard(friends[index], colorScheme);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFriendDialog(context, colorScheme),
        backgroundColor: colorScheme.primaryButton,
        foregroundColor: colorScheme.primaryButtonForeground,
        icon: const Icon(Icons.add),
        label: const Text('친구 추가'),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildRequestItem(
      Map<String, dynamic> req, AppColorScheme colorScheme) {
    final user = req['user'] as UserModel;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: colorScheme.secondary.withOpacity(0.2),
            child: Text(
              user.nickname[0],
              style: TextStyle(
                color: colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              user.nickname,
              style: TextStyle(
                color: colorScheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 거절 버튼
          SizedBox(
            height: 32,
            child: TextButton(
              onPressed: () =>
                  _rejectRequest(req['requestId'], user.uid, user.nickname),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                foregroundColor: colorScheme.textSecondary,
                backgroundColor: colorScheme.textHint.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '거절',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 수락 버튼
          SizedBox(
            height: 32,
            child: ElevatedButton(
              onPressed: () =>
                  _acceptRequest(req['requestId'], user.uid, user.nickname),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor: colorScheme.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '수락',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptRequest(
      String requestId, String friendId, String friendNickname) async {
    final socialController = context.read<SocialController>();
    final authController = context.read<AuthController>();
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;

    try {
      await socialController.acceptFriendRequest(
        requestId,
        authController.currentUser!.uid,
        authController.userModel!.nickname,
        friendId,
        friendNickname,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$friendNickname님과 친구가 되었습니다!'),
            backgroundColor: colorScheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _rejectRequest(
      String requestId, String friendId, String friendNickname) async {
    final socialController = context.read<SocialController>();
    final authController = context.read<AuthController>();
    try {
      await socialController.rejectFriendRequest(
        requestId,
        authController.currentUser!.uid,
        friendId,
        authController.userModel!.nickname,
        friendNickname,
      );
    } catch (e) {
      if (mounted) {
        final colorScheme = Theme.of(context).extension<AppColorScheme>()!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    }
  }

  Widget _buildFriendCard(UserModel friend, AppColorScheme colorScheme) {
    return Consumer<SocialController>(
      builder: (context, controller, child) {
        final isAwakeRequested =
            controller.isFriendAwake(friend.uid, friend.lastDiaryDate);

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isAwakeRequested
                  ? colorScheme.success // 불투명하게 변경하여 더 뚜렷하게
                  : colorScheme.shadowColor.withOpacity(0.1),
              width: isAwakeRequested ? 3.5 : 1.5,
            ),
            boxShadow: [
              if (isAwakeRequested)
                BoxShadow(
                  color: colorScheme.success.withOpacity(0.3), // 그림자 농도 강화
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                )
              else
                BoxShadow(
                  color: colorScheme.shadowColor.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Stack(
            children: [
              // 작성 완료 상태 시 구석에 큼직한 체크 아이콘 배경
              if (isAwakeRequested)
                Positioned(
                  right: -10,
                  top: -10,
                  child: Icon(
                    Icons.check_circle,
                    size: 85,
                    color: colorScheme.success.withOpacity(0.15), // 약간 더 선명하게
                  ),
                ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => context.push('/friend/${friend.uid}'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // 기상/취침 상태에 따른 아바타 배경색 변화
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: isAwakeRequested
                                  ? colorScheme.success.withOpacity(0.2)
                                  : colorScheme.primaryButton.withOpacity(0.1),
                              child: Text(
                                friend.nickname[0],
                                style: TextStyle(
                                  color: isAwakeRequested
                                      ? colorScheme.success
                                      : colorScheme.primaryButton,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isAwakeRequested
                                        ? colorScheme.success.withOpacity(0.2)
                                        : Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                    )
                                  ],
                                ),
                                child: Icon(
                                  isAwakeRequested
                                      ? Icons.wb_sunny
                                      : Icons.bedtime,
                                  size: 16,
                                  color: isAwakeRequested
                                      ? colorScheme.pointStar
                                      : colorScheme.textHint,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          friend.nickname,
                          style: TextStyle(
                            color: colorScheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // 연속 일수 뱃지 스타일
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.local_fire_department,
                                  color: colorScheme.accent, size: 14),
                              const SizedBox(width: 2),
                              Text(
                                '${friend.consecutiveDays}일',
                                style: TextStyle(
                                  color: colorScheme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (isAwakeRequested)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: colorScheme.success.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.success.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle,
                                    color: colorScheme.success, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '작성 완료',
                                  style: TextStyle(
                                    color: colorScheme.success,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          _buildWakeUpButton(friend, controller, colorScheme),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWakeUpButton(UserModel friend, SocialController controller,
      AppColorScheme colorScheme) {
    final remaining = controller.wakeUpCooldownRemaining(friend.uid);
    final seconds = (remaining.inMilliseconds / 1000).ceil();
    final isCooldown = seconds > 0;

    return SizedBox(
      width: double.infinity,
      height: 36,
      child: ElevatedButton(
        onPressed: isCooldown
            ? null
            : () => _wakeUpFriend(friend, controller, colorScheme),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primaryButton,
          foregroundColor: colorScheme.primaryButtonForeground,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          disabledBackgroundColor: colorScheme.textHint.withOpacity(0.2),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            isCooldown ? '${seconds}초' : '깨우기',
            key: ValueKey(isCooldown ? seconds : -1),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isCooldown
                  ? colorScheme.textSecondary
                  : colorScheme.primaryButtonForeground,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _wakeUpFriend(UserModel friend, SocialController controller,
      AppColorScheme colorScheme) async {
    final authController = context.read<AuthController>();

    // 1. 쿨다운 체크
    if (!controller.canSendWakeUp(friend.uid)) return;

    // 2. 즉시 UI 피드백 (쿨다운 시작 및 스낵바)
    controller.startWakeUpCooldown(friend.uid);

    final friendId = friend.uid;
    final friendNickname = friend.nickname;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text('$friendNickname님을 깨웠습니다! ⏰'),
        backgroundColor: colorScheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // 3. 실제 전송은 백그라운드에서 진행
    unawaited(() async {
      try {
        await controller.wakeUpFriend(
          authController.currentUser!.uid,
          authController.userModel!.nickname,
          friendId,
          friendNickname,
        );
      } catch (e) {
        debugPrint('깨우기 요청 실패: $e');
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: const Text('깨우기 요청 실패'),
              backgroundColor: colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }());
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return CustomBottomNavigationBar(
      currentIndex: 2,
      onTap: (index) {},
    );
  }

  Future<void> _showAddFriendDialog(
      BuildContext context, AppColorScheme colorScheme) async {
    final controller = TextEditingController();
    final socialController = context.read<SocialController>();
    final authController = context.read<AuthController>();

    return AppDialog.show(
      context: context,
      key: AppDialogKey.addFriend,
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextField(
          controller: controller,
          style: TextStyle(color: colorScheme.textPrimary),
          decoration: InputDecoration(
            hintText: '친구 닉네임 입력',
            hintStyle: TextStyle(color: colorScheme.textHint),
            filled: true,
            fillColor: Colors.black.withOpacity(0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: colorScheme.textHint.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: colorScheme.textHint.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: colorScheme.primaryButton, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
      actions: [
        AppDialogAction(
          label: '취소',
          onPressed: () => Navigator.pop(context),
        ),
        AppDialogAction(
          label: '요청',
          isPrimary: true,
          onPressed: (BuildContext context) async {
            final nickname = controller.text.trim();
            if (nickname.isEmpty) return;

            final myId = authController.currentUser?.uid;
            final myNickname = authController.userModel?.nickname;
            if (myId == null || myNickname == null) return;

            final userService = context.read<UserService>();
            try {
              final user = await userService.getUserByNickname(nickname);
              if (user == null) {
                if (context.mounted) {
                  AppDialog.showError(context, '해당 닉네임의 사용자를 찾을 수 없습니다.');
                }
                return;
              }

              if (user.uid == myId) {
                if (context.mounted) {
                  AppDialog.showError(context, '자신에게는 친구 요청을 보낼 수 없습니다.');
                }
                return;
              }

              await socialController.sendFriendRequest(
                myId,
                myNickname,
                user.uid,
              );

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${user.nickname}님께 친구 요청을 보냈습니다!'),
                    backgroundColor: colorScheme.success,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                AppDialog.showError(context, e.toString());
              }
            }
          },
        ),
      ],
    );
  }
}
