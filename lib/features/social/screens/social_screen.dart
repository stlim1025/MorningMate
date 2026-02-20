import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../controllers/social_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../character/controllers/character_controller.dart';
import '../../../data/models/user_model.dart';
import '../../../services/user_service.dart';
import '../../../core/widgets/app_dialog.dart';

import '../widgets/friend_card.dart';
import '../../../core/widgets/memo_notification.dart';
import '../../../core/localization/app_localizations.dart';
import '../../character/widgets/character_display.dart';

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(
        const AssetImage('assets/images/Friend_Background.png'), context);
  }

  Future<void> _loadFriends() async {
    final authController = context.read<AuthController>();
    final socialController = context.read<SocialController>();
    final userId = authController.currentUser?.uid;

    if (userId != null) {
      // 빌드 완료 후 실행하여 setState 오류 방지
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 이미 데이터가 있으면 로딩 없이 백그라운드 갱신
        socialController.initialize(userId);
      });
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

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: ResizeImage(AssetImage('assets/images/Friend_Background.png'),
              width: 1080),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        bottom: true, // Handle system bottom padding
        child: Stack(
          children: [
            Positioned.fill(
              child: Column(
                children: [
                  // Custom AppBar replacement
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: StreamBuilder<List<UserModel>>(
                      stream: friendsStream,
                      initialData: socialController.friends,
                      builder: (context, snapshot) {
                        final isLoading = context
                            .select<SocialController, bool>((c) => c.isLoading);
                        final friends = snapshot.data ?? [];
                        final count = friends.length;
                        final displayCount =
                            (isLoading && friends.isEmpty) ? '...' : '$count';

                        return Container(
                          width: 150,
                          height: 40,
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(
                                  'assets/icons/TopFriend_Label.png'),
                              fit: BoxFit.fill,
                            ),
                          ),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.only(top: 4, left: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppLocalizations.of(context)
                                        ?.get('friendsTitle') ??
                                    'Friends',
                                style: TextStyle(
                                  color: colorScheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'BMJUA',
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context)?.getFormat(
                                        'friendsCount',
                                        {'count': displayCount}) ??
                                    displayCount,
                                style: TextStyle(
                                  color: colorScheme.textPrimary,
                                  fontWeight: FontWeight.normal,
                                  fontFamily: 'BMJUA',
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: Selector<SocialController, bool>(
                      selector: (context, controller) => controller.isLoading,
                      builder: (context, isLoading, child) {
                        return StreamBuilder<List<UserModel>>(
                          stream: friendsStream,
                          initialData: socialController.friends,
                          builder: (context, snapshot) {
                            final friends = snapshot.data ?? [];
                            final hasFriends = friends.isNotEmpty;

                            // 로딩 중이고 보여줄 데이터가 없는 경우 로딩 인디케이터 표시
                            if ((isLoading && !hasFriends) ||
                                (snapshot.connectionState ==
                                        ConnectionState.waiting &&
                                    !snapshot.hasData)) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.brown,
                                ),
                              );
                            }

                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                // Background Layer (Fixed Position)
                                if (!hasFriends)
                                  Positioned.fill(
                                    child: Center(
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Image.asset(
                                            'assets/images/Nofriend_Charactor.png',
                                            width: 250,
                                          ),
                                          Positioned(
                                            top: 125,
                                            child: Text(
                                              AppLocalizations.of(context)
                                                      ?.get('addFriendEmpty') ??
                                                  'Add a friend',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: Colors.brown,
                                                fontSize: 18,
                                                fontFamily: 'BMJUA',
                                                height: 1.2,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                // Content Layer
                                Column(
                                  children: [
                                    const SizedBox(height: 8),
                                    // Friend Requests
                                    Consumer<SocialController>(
                                      builder: (context, controller, child) {
                                        if (controller.friendRequests.isEmpty) {
                                          return const SizedBox.shrink();
                                        }
                                        return Container(
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          padding: const EdgeInsets.all(20),
                                          decoration: const BoxDecoration(
                                            image: DecorationImage(
                                              image: AssetImage(
                                                  'assets/images/FriendRequest_Background.png'),
                                              fit: BoxFit.fill,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(Icons.person_add_rounded,
                                                      color: Colors.brown,
                                                      size: 24),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    AppLocalizations.of(context)
                                                            ?.get(
                                                                'newFriendRequests') ??
                                                        'New friend requests',
                                                    style: TextStyle(
                                                      color: colorScheme
                                                          .textPrimary,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontFamily: 'BMJUA',
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Text(
                                                    '${controller.friendRequests.length}',
                                                    style: const TextStyle(
                                                      color: Colors.brown,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18,
                                                      fontFamily: 'BMJUA',
                                                    ),
                                                  ),
                                                  const SizedBox(width: 20),
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                              ...controller.friendRequests.map(
                                                  (req) => _buildRequestItem(
                                                      req, colorScheme)),
                                            ],
                                          ),
                                        );
                                      },
                                    ),

                                    // Friend List (GridView)
                                    if (hasFriends)
                                      Expanded(
                                        child: GridView.builder(
                                          padding: const EdgeInsets.fromLTRB(
                                              16, 16, 16, 100),
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 3,
                                            mainAxisSpacing: 10,
                                            crossAxisSpacing: 10,
                                            childAspectRatio: 0.82,
                                          ),
                                          itemCount: friends.length,
                                          itemBuilder: (context, index) {
                                            return FriendCard(
                                                friend: friends[index],
                                                colorScheme: colorScheme);
                                          },
                                        ),
                                      ),
                                    if (!hasFriends) const SizedBox(height: 80),
                                  ],
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 16,
              bottom: 30, // Increased to avoid bottom nav bar
              child: _AnimatedAddFriendButton(
                onPressed: () => _showAddFriendDialog(context, colorScheme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestItem(
      Map<String, dynamic> req, AppColorScheme colorScheme) {
    final user = req['user'] as UserModel;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      // Decoration removed as requested
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.secondary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias, // 동그라미 영역 밖으로 나가는 부분 자르기
            child: Center(
              child: CharacterDisplay(
                characterLevel: user.characterLevel,
                equippedItems: user.equippedCharacterItems,
                size: 48, // 컨테이너(48x48)에 딱 맞춰서 하단이 잘리지 않게 함
                enableAnimation: false,
                isAwake: context.read<SocialController>().isFriendAwake(user),
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
                fontFamily: 'BMJUA',
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 거절 버튼
          GestureDetector(
            onTap: () =>
                _rejectRequest(req['requestId'], user.uid, user.nickname),
            child: Container(
              width: 50,
              height: 32,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/Cancel_Button.png'),
                  fit: BoxFit.fill,
                ),
              ),
              child: Center(
                child: Text(
                  AppLocalizations.of(context)?.get('reject') ?? 'Reject',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'BMJUA',
                    color: colorScheme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 수락 버튼
          GestureDetector(
            onTap: () =>
                _acceptRequest(req['requestId'], user.uid, user.nickname),
            child: Container(
              width: 50,
              height: 32,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/Confirm_Button.png'),
                  fit: BoxFit.fill,
                ),
              ),
              child: Center(
                child: Text(
                  AppLocalizations.of(context)?.get('accept') ?? 'Accept',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'BMJUA',
                    color: Colors.brown,
                  ),
                ),
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

    try {
      await socialController.acceptFriendRequest(
        requestId,
        authController.currentUser!.uid,
        authController.userModel!.nickname,
        friendId,
        friendNickname,
      );
      if (mounted) {
        // 친구 관련 도전과제 체크
        final characterController = context.read<CharacterController>();
        await characterController.checkAchievements(context);

        MemoNotification.show(
          context,
          AppLocalizations.of(context)?.getFormat(
                  'youBecameFriends', {'nickname': friendNickname}) ??
              'You became friends with $friendNickname! ✨',
        );
      }
    } catch (e) {
      if (mounted) {
        MemoNotification.show(context, e.toString());
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
        MemoNotification.show(context, e.toString());
      }
    }
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
        child: PopupTextField(
          controller: controller,
          hintText: AppLocalizations.of(context)?.get('enterFriendNickname') ??
              'Enter friend nickname',
        ),
      ),
      actions: [
        AppDialogAction(
          label: AppLocalizations.of(context)?.get('cancel') ?? 'Cancel',
          onPressed: () => context.pop(),
        ),
        AppDialogAction(
          label: AppLocalizations.of(context)?.get('request') ?? 'Request',
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
                  AppDialog.showError(
                      context,
                      AppLocalizations.of(context)?.get('userNotFound') ??
                          'User not found.');
                }
                return;
              }

              if (user.uid == myId) {
                if (context.mounted) {
                  AppDialog.showError(
                      context,
                      AppLocalizations.of(context)?.get('selfRequestError') ??
                          'You cannot send a request to yourself.');
                }
                return;
              }

              await socialController.sendFriendRequest(
                myId,
                myNickname,
                user.uid,
              );

              if (context.mounted) {
                Navigator.pop(context); // Close input dialog
                MemoNotification.show(
                  context,
                  AppLocalizations.of(context)?.getFormat(
                        'friendRequestSent',
                        {'nickname': user.nickname},
                      ) ??
                      'Friend request sent to ${user.nickname}!',
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

class _AnimatedAddFriendButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _AnimatedAddFriendButton({
    required this.onPressed,
  });

  @override
  State<_AnimatedAddFriendButton> createState() =>
      _AnimatedAddFriendButtonState();
}

class _AnimatedAddFriendButtonState extends State<_AnimatedAddFriendButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      // Slightly less aggressive scale
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              'assets/icons/AddFriend_Button.png',
              width: 150,
              height: 56,
              fit: BoxFit.contain,
            ),
            Positioned.fill(
              child: Align(
                alignment: const Alignment(0, 0.2),
                child: Text(
                  AppLocalizations.of(context)?.get('addFriendButton') ??
                      '+ Add Friend',
                  style: const TextStyle(
                    fontFamily: 'BMJUA',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4E342E),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
