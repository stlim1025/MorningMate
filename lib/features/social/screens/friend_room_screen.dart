import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../services/user_service.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/notification_model.dart';
import '../../morning/widgets/enhanced_character_room_widget.dart';

import '../../../data/models/room_decoration_model.dart';
import '../controllers/social_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../notification/controllers/notification_controller.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../common/widgets/custom_bottom_navigation_bar.dart';
import '../../common/widgets/room_action_button.dart';

class FriendRoomScreen extends StatefulWidget {
  final String friendId;

  const FriendRoomScreen({
    super.key,
    required this.friendId,
  });

  @override
  State<FriendRoomScreen> createState() => _FriendRoomScreenState();
}

class _FriendRoomScreenState extends State<FriendRoomScreen>
    with TickerProviderStateMixin {
  UserModel? _friend;
  bool _isLoading = true;
  bool? _friendAwakeStatus;
  late AnimationController _buttonController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
    _loadFriendData();
  }

  Future<void> _loadFriendData() async {
    final userService = context.read<UserService>();
    final socialController = context.read<SocialController>();

    try {
      final friend = await userService.getUser(widget.friendId);
      if (!mounted) return;

      if (friend == null) {
        setState(() {
          _friend = null;
          _isLoading = false;
        });
        return;
      }

      final isAwake =
          await socialController.refreshFriendAwakeStatus(friend.uid);
      if (!mounted) return;

      setState(() {
        _friend = friend;
        _friendAwakeStatus = isAwake;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('친구 데이터 로드 오류: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;
    final isDarkMode = Provider.of<ThemeController>(context).isDarkMode;

    return Scaffold(
      body: Consumer<SocialController>(
        builder: (context, socialController, child) {
          final isAwake = _friendAwakeStatus ??
              (_friend != null
                  ? socialController.isFriendAwake(_friend!.uid)
                  : false);

          final textColor =
              (isAwake && !isDarkMode) ? const Color(0xFF2C3E50) : Colors.white;

          return Stack(
            children: [
              // 1. Full Screen Room Background
              if (_friend != null && !_isLoading)
                Positioned.fill(
                  child: EnhancedCharacterRoomWidget(
                    isAwake: isAwake,
                    characterLevel: _friend!.characterLevel,
                    consecutiveDays: _friend!.consecutiveDays,
                    roomDecoration: _friend!.roomDecoration,
                    showBorder: false,
                    currentAnimation: 'idle',
                    onPropTap: (prop) => _showFriendMemoDialog(prop),
                    colorScheme: colorScheme,
                    isDarkMode: isDarkMode,
                  ),
                ),

              // 2. UI Overlay
              SafeArea(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                            color: isAwake
                                ? colorScheme.progressBar
                                : Colors.white))
                    : _friend == null
                        ? _buildErrorState()
                        : Column(
                            children: [
                              // Header
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.arrow_back,
                                          color: textColor),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${_friend!.nickname}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                  color: textColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${_friend!.consecutiveDays}일 연속 기록 중 🔥',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: textColor
                                                      .withOpacity(0.8),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // 레벨 표시 버튼
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/images/Button_Background.png',
                                          width: 100,
                                          height: 60,
                                          fit: BoxFit.fill,
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 2),
                                          child: Text(
                                            'Lv.${_friend!.characterLevel}',
                                            style: const TextStyle(
                                              fontFamily: 'BMJUA',
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF4E342E),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const Spacer(),
                            ],
                          ),
              ),

              // Floating Buttons (메인화면 스타일)
              if (_friend != null && !_isLoading)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 15,
                  child: SafeArea(
                    child: Consumer<SocialController>(
                      builder: (context, socialController, child) {
                        final remaining = socialController
                            .cheerCooldownRemaining(_friend!.uid);
                        final seconds =
                            (remaining.inMilliseconds / 1000).ceil();
                        final isCooldown = seconds > 0;

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // 응원 메시지 보내기 버튼 (왼쪽)
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(left: 20, right: 10),
                                child: GestureDetector(
                                  onTapDown: isCooldown
                                      ? null
                                      : (_) => _buttonController.forward(),
                                  onTapUp: isCooldown
                                      ? null
                                      : (_) {
                                          _buttonController.reverse();
                                          _showGuestbookDialog(colorScheme);
                                        },
                                  onTapCancel: isCooldown
                                      ? null
                                      : () => _buttonController.reverse(),
                                  child: ScaleTransition(
                                    scale: _scaleAnimation,
                                    child: Opacity(
                                      opacity: isCooldown ? 0.6 : 1.0,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Image.asset(
                                            'assets/images/Button_Background2.png',
                                            width: double.infinity,
                                            height: 90,
                                            fit: BoxFit.fill,
                                          ),
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 6),
                                            child: Text(
                                              isCooldown
                                                  ? '$seconds초 후 재전송'
                                                  : '응원메시지 보내기',
                                              style: TextStyle(
                                                fontFamily: 'BMJUA',
                                                fontSize: 23,
                                                fontWeight: FontWeight.bold,
                                                color: isCooldown
                                                    ? const Color(0xFF4E342E)
                                                        .withOpacity(0.5)
                                                    : const Color(0xFF4E342E),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // 보낸 기록 버튼 (오른쪽)
                            Padding(
                              padding: const EdgeInsets.only(right: 20),
                              child: RoomActionButton(
                                iconPath: 'assets/icons/SendRecord_Icon.png',
                                label: '보낸기록',
                                size: 90,
                                onTap: () {
                                  _showSentMessagesDialog(colorScheme);
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 2,
        onTap: (_) {}, // Navigation is handled internally
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.white54,
          ),
          const SizedBox(height: 16),
          const Text(
            '친구를 찾을 수 없습니다',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('돌아가기'),
          ),
        ],
      ),
    );
  }

  Future<void> _showGuestbookDialog(AppColorScheme colorScheme) async {
    final parentContext = context;
    final messageController = TextEditingController();
    final errorNotifier = ValueNotifier<String?>(null);

    return AppDialog.show(
      context: context,
      key: AppDialogKey.guestbook,
      content: ValueListenableBuilder<String?>(
        valueListenable: errorNotifier,
        builder: (context, errorText, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: messageController,
                maxLines: 3,
                style: TextStyle(color: colorScheme.textPrimary),
                decoration: InputDecoration(
                  hintText: '친구에게 응원의 메시지를 남겨주세요',
                  hintStyle: TextStyle(color: colorScheme.textHint),
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  errorText: errorText,
                ),
                onChanged: (_) {
                  if (errorNotifier.value != null) {
                    errorNotifier.value = null;
                  }
                },
              ),
            ],
          );
        },
      ),
      actions: [
        AppDialogAction(
          label: '취소',
          onPressed: () => Navigator.pop(context),
        ),
        AppDialogAction(
          label: '남기기',
          isPrimary: true,
          onPressed: () async {
            final message = messageController.text.trim();
            if (message.isEmpty) return;

            final socialController = parentContext.read<SocialController>();
            final notificationController =
                parentContext.read<NotificationController>();
            final authController = parentContext.read<AuthController>();
            final userModel = authController.userModel;

            if (userModel == null) return;

            // 1. 쿨다운 체크
            if (!socialController.canSendCheer(_friend!.uid)) {
              return;
            }

            // 다이얼로그 닫기
            Navigator.pop(context);

            // 2. 즉시 UI 피드백 (쿨다운 시작 및 스낵바)
            socialController.startCheerCooldown(_friend!.uid);

            final friendId = _friend!.uid;
            final messenger = ScaffoldMessenger.of(parentContext);
            messenger.showSnackBar(
              SnackBar(
                content: const Text('응원 메시지를 보냈습니다! 💌'),
                backgroundColor: colorScheme.success,
              ),
            );

            // 3. 실제 전송은 백그라운드에서 진행
            unawaited(() async {
              try {
                // FCM 알림 (클라우드 함수)
                final callable = FirebaseFunctions.instance
                    .httpsCallable('sendCheerMessage');

                try {
                  await callable.call({
                    'userId': userModel.uid,
                    'friendId': friendId,
                    'message': message,
                    'senderNickname': userModel.nickname,
                  });
                } catch (e) {
                  debugPrint('응원 메시지 FCM 전송 오류: $e');
                }

                // Firestore 알림 데이터 생성 (fcmSent를 false로 설정)
                await notificationController.sendCheerMessage(
                  userModel.uid,
                  userModel.nickname,
                  friendId,
                  message,
                  fcmSent: false,
                );
              } catch (e) {
                debugPrint('응원 메시지 전송 오류: $e');
                if (parentContext.mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: const Text('응원 메시지 전송에 실패했습니다.'),
                      backgroundColor: colorScheme.error,
                    ),
                  );
                }
              }
            }());
          },
        ),
      ],
    );
  }

  Future<void> _showSentMessagesDialog(AppColorScheme colorScheme) async {
    final authController = context.read<AuthController>();
    final notificationController = context.read<NotificationController>();
    final myId = authController.currentUser?.uid;

    if (myId == null) return;

    return AppDialog.show(
      context: context,
      key: AppDialogKey.sentMessages,
      content: SizedBox(
        width: double.maxFinite,
        height: 350,
        child: StreamBuilder<List<NotificationModel>>(
          stream: notificationController.getSentMessagesStream(
              myId, widget.friendId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final messages = snapshot.data ?? [];
            if (messages.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_outline,
                        size: 48, color: colorScheme.textHint.withOpacity(0.5)),
                    const SizedBox(height: 12),
                    Text(
                      '아직 보낸 메시지가 없어요',
                      style: TextStyle(color: colorScheme.textSecondary),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: messages.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final msg = messages[index];
                final actualMessage = msg.message.contains('\n')
                    ? msg.message.split('\n').last
                    : msg.message;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: msg.isRead
                        ? colorScheme.secondary.withOpacity(0.08)
                        : colorScheme.primaryButton.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: msg.isRead
                          ? colorScheme.secondary.withOpacity(0.2)
                          : colorScheme.primaryButton.withOpacity(0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              actualMessage,
                              style: TextStyle(
                                color: colorScheme.textPrimary,
                                fontSize: 15,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (msg.isRead) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: colorScheme.success.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: colorScheme.success,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(Icons.access_time,
                              size: 12, color: colorScheme.textHint),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('yyyy.MM.dd HH:mm')
                                .format(msg.createdAt),
                            style: TextStyle(
                              color: colorScheme.textHint,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        AppDialogAction(
          label: '닫기',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  void _showFriendMemoDialog(RoomPropModel prop) {
    if (prop.type != 'sticky_note' || prop.metadata == null) return;
    if (_friend == null) return;

    final content = prop.metadata!['content'] ?? '';
    int heartCount = prop.metadata!['heartCount'] ?? 0;
    List<dynamic> likedBy = prop.metadata!['likedBy'] ?? [];

    final authController = context.read<AuthController>();
    final userModel = authController.userModel;
    if (userModel == null) return;

    bool isLiked = likedBy.contains(userModel.uid);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                    // 3. 하트 (왼쪽 아래) - 상호작용 가능
                    Positioned(
                      bottom: 30,
                      left: 35,
                      child: GestureDetector(
                        onTap: () async {
                          if (isLiked) return; // 이미 좋아요 함

                          // UI Optimistic Update
                          setState(() {
                            isLiked = true;
                            heartCount++;
                          });

                          // Call Controller
                          try {
                            await context
                                .read<SocialController>()
                                .likeStickyNote(
                                  userModel.uid,
                                  userModel.nickname,
                                  _friend!.uid,
                                  prop.id,
                                );
                          } catch (e) {
                            // Revert on error (optional)
                          }
                        },
                        child: Row(
                          children: [
                            Image.asset(
                              isLiked
                                  ? 'assets/images/Pink_Heart.png'
                                  : 'assets/images/Pink_Heart_Empty.png',
                              width: 24,
                              height: 24,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$heartCount',
                              style: const TextStyle(
                                fontFamily: 'NanumPenScript-Regular',
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
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
      },
    );
  }
}
