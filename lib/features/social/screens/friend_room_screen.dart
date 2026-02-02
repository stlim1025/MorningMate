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
import '../../morning/widgets/room_background_widget.dart';
import '../../../data/models/room_decoration_model.dart';
import '../controllers/social_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../notification/controllers/notification_controller.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/app_dialog.dart';

class FriendRoomScreen extends StatefulWidget {
  final String friendId;

  const FriendRoomScreen({
    super.key,
    required this.friendId,
  });

  @override
  State<FriendRoomScreen> createState() => _FriendRoomScreenState();
}

class _FriendRoomScreenState extends State<FriendRoomScreen> {
  UserModel? _friend;
  bool _isLoading = true;
  bool? _friendAwakeStatus;

  @override
  void initState() {
    super.initState();
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

          return Stack(
            children: [
              // 1. Global Background
              Positioned.fill(
                child: RoomBackgroundWidget(
                  decoration: _friend?.roomDecoration ?? RoomDecorationModel(),
                  isAwake: isAwake,
                  isDarkMode: isDarkMode,
                  colorScheme: colorScheme,
                ),
              ),

              // 2. Main Content
              SafeArea(
                bottom: false,
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                            color: isAwake
                                ? colorScheme.progressBar
                                : Colors.white))
                    : _friend == null
                        ? _buildErrorState()
                        : _buildFriendRoom(isAwake, colorScheme, isDarkMode),
              ),
            ],
          );
        },
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

  Widget _buildFriendRoom(
      bool isAwake, AppColorScheme colorScheme, bool isDarkMode) {
    final textColor =
        (isAwake && !isDarkMode) ? const Color(0xFF2C3E50) : Colors.white;

    return Column(
      children: [
        // 헤더
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: textColor),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_friend!.nickname}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_friend!.consecutiveDays}일 연속 기록 중 🔥',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: textColor.withOpacity(0.8),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 캐릭터 영역 (방 모양)
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 50), // 상단 여백 추가 (달/해 가려짐 방지)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: EnhancedCharacterRoomWidget(
                    isAwake: isAwake,
                    characterLevel: _friend!.characterLevel,
                    consecutiveDays: _friend!.consecutiveDays,
                    roomDecoration: _friend!.roomDecoration,
                    showBorder: true,
                  ),
                ),
                const SizedBox(height: 16),
                _buildFriendStats(isAwake, colorScheme),
              ],
            ),
          ),
        ),

        // 방명록 영역
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadowColor.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.mode_comment_rounded,
                          color: colorScheme.primaryButton,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '친구에게 한마디',
                          style: TextStyle(
                            color: colorScheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () => _showSentMessagesDialog(colorScheme),
                      icon: Icon(
                        Icons.history_rounded,
                        color: colorScheme.primaryButton,
                        size: 16,
                      ),
                      label: Text(
                        '보낸 기록',
                        style: TextStyle(
                          color: colorScheme.primaryButton,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor:
                            colorScheme.primaryButton.withOpacity(0.08),
                        side: BorderSide(
                          color: colorScheme.primaryButton.withOpacity(0.15),
                          width: 1,
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Consumer<SocialController>(
                  builder: (context, socialController, child) {
                    final remaining = _friend != null
                        ? socialController.cheerCooldownRemaining(_friend!.uid)
                        : Duration.zero;
                    final seconds = (remaining.inMilliseconds / 1000).ceil();
                    final isCooldown = seconds > 0;

                    return Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: isCooldown
                              ? [
                                  colorScheme.textHint.withOpacity(0.3),
                                  colorScheme.textHint.withOpacity(0.2),
                                ]
                              : [
                                  colorScheme.primaryButton,
                                  colorScheme.primaryButton.withOpacity(0.85),
                                ],
                        ),
                        boxShadow: [
                          if (!isCooldown)
                            BoxShadow(
                              color: colorScheme.primaryButton.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: isCooldown
                            ? null
                            : () => _showGuestbookDialog(colorScheme),
                        icon: Icon(
                          isCooldown
                              ? Icons.timer_outlined
                              : Icons.send_rounded,
                          size: 20,
                        ),
                        label: Text(
                          isCooldown
                              ? '$seconds초 후에 다시 보낼 수 있어요'
                              : '친구에게 응원 메시지 보내기',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: isCooldown
                              ? colorScheme.textSecondary
                              : colorScheme.primaryButtonForeground,
                          disabledForegroundColor: colorScheme.textSecondary,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFriendStats(bool isAwake, AppColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isAwake
            ? Colors.white.withOpacity(0.95) // More opaque
            : Colors.black.withOpacity(0.25), // Darker for night
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAwake
              ? colorScheme.primaryButton.withOpacity(0.15)
              : Colors.white.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isAwake ? 0.08 : 0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatChip(
            label: '레벨',
            value: 'Lv.${_friend!.characterLevel}',
            isAwake: isAwake,
            colorScheme: colorScheme,
          ),
          _buildStatChip(
            label: '연속 기록',
            value: '${_friend!.consecutiveDays}일',
            isAwake: isAwake,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required String value,
    required bool isAwake,
    required AppColorScheme colorScheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isAwake
                ? colorScheme.textPrimary.withOpacity(0.6)
                : Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isAwake
                ? colorScheme.primaryButton.withOpacity(0.08)
                : Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: isAwake ? colorScheme.primaryButton : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
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
}
