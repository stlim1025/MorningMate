import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../social/controllers/social_controller.dart';
import '../controllers/notification_controller.dart';
import '../../../data/models/notification_model.dart';
import '../../social/widgets/reply_dialog.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          '알림',
          style: TextStyle(
            fontFamily: 'BMJUA',
            color: colorScheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
                return;
              }
              context.go('/morning');
            },
            child: Image.asset(
              'assets/icons/X_Button.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
          ),
        ),
        actions: [
          Consumer<AuthController>(
            builder: (context, authController, child) {
              final userId = authController.currentUser?.uid;
              if (userId == null) {
                return const SizedBox.shrink();
              }
              return GestureDetector(
                onTap: () async {
                  final notificationController =
                      context.read<NotificationController>();
                  await notificationController.markAllAsRead(userId);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    image: const DecorationImage(
                      image: AssetImage('assets/images/Cancel_Button.png'),
                      fit: BoxFit.fill,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      '모두 읽음',
                      style: TextStyle(
                        fontFamily: 'BMJUA',
                        color: Color(0xFF4E342E),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 배경 이미지
          Positioned.fill(
            child: Image.asset(
              'assets/images/Noti_BackGround.png',
              fit: BoxFit.cover,
            ),
          ),
          Consumer<AuthController>(
            builder: (context, authController, child) {
              final userId = authController.currentUser?.uid;
              if (userId == null) {
                return const Center(child: CircularProgressIndicator());
              }

              final notificationController =
                  context.read<NotificationController>();
              final socialController = context.read<SocialController>();

              return StreamBuilder<List<NotificationModel>>(
                stream: notificationController.getNotificationsStream(userId),
                initialData: const [],
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return _buildEmptyState(
                      context,
                      colorScheme,
                      title: '알림을 불러오는 중이에요',
                      subtitle: '잠시만 기다려주세요',
                    );
                  }
                  if (snapshot.hasError) {
                    return _buildEmptyState(
                      context,
                      colorScheme,
                      title: '알림을 불러오는 중 오류가 발생했습니다',
                      subtitle: '잠시 후 다시 시도해주세요',
                    );
                  }

                  final notifications = snapshot.data ?? [];

                  if (notifications.isEmpty) {
                    return _buildEmptyState(
                      context,
                      colorScheme,
                      title: '알림이 없습니다',
                      subtitle: '새로운 소식이 생기면 이곳에 알려드릴게요',
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      MediaQuery.of(context).padding.top + kToolbarHeight + 16,
                      16,
                      16,
                    ),
                    itemCount: notifications.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      final requestId =
                          notification.data?['requestId']?.toString();
                      final isFriendRequest =
                          notification.type == NotificationType.friendRequest &&
                              requestId != null &&
                              requestId.isNotEmpty;
                      return Dismissible(
                        key: Key(notification.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          notificationController
                              .deleteNotification(notification.id);
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: colorScheme.error,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            if (!notification.isRead) {
                              notificationController
                                  .markAsRead(notification.id);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 20),
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: const AssetImage(
                                    'assets/images/Noti_List.png'),
                                fit: BoxFit.fill,
                                opacity: notification.isRead ? 0.7 : 1.0,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Opacity(
                                  opacity: notification.isRead ? 0.7 : 1.0,
                                  child: _buildNotificationIcon(
                                      notification.type, colorScheme),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Opacity(
                                    opacity: notification.isRead ? 0.7 : 1.0,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          notification.type ==
                                                  NotificationType.cheerMessage
                                              ? (notification
                                                          .data?['isReply'] ==
                                                      true
                                                  ? '${notification.senderNickname}님의 답장'
                                                  : '${notification.senderNickname}님의 응원')
                                              : (notification.type ==
                                                      NotificationType.wakeUp
                                                  ? '깨우기 알림'
                                                  : (notification.type ==
                                                          NotificationType
                                                              .friendRequest
                                                      ? '친구 요청'
                                                      : '알림')),
                                          style: TextStyle(
                                            fontFamily: 'BMJUA',
                                            color: colorScheme.textSecondary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          notification.message,
                                          style: TextStyle(
                                            fontFamily: 'BMJUA',
                                            color: colorScheme.textPrimary,
                                            fontSize: 14,
                                            fontWeight: notification.isRead
                                                ? FontWeight.normal
                                                : FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          DateFormat('MM/dd HH:mm')
                                              .format(notification.createdAt),
                                          style: TextStyle(
                                            fontFamily: 'BMJUA',
                                            color: colorScheme.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isFriendRequest) ...[
                                  const SizedBox(width: 16),
                                  Opacity(
                                    opacity: notification.isRead ? 0.9 : 1.0,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        GestureDetector(
                                          onTap: () async {
                                            await socialController
                                                .acceptFriendRequest(
                                              requestId,
                                              userId,
                                              authController
                                                      .userModel?.nickname ??
                                                  '알 수 없음',
                                              notification.senderId,
                                              notification.senderNickname,
                                            );
                                          },
                                          child: Container(
                                            width: 70,
                                            height: 36,
                                            decoration: const BoxDecoration(
                                              image: DecorationImage(
                                                image: AssetImage(
                                                    'assets/images/Confirm_Button.png'),
                                                fit: BoxFit.fill,
                                              ),
                                            ),
                                            child: const Center(
                                              child: Text(
                                                '수락',
                                                style: TextStyle(
                                                  fontFamily: 'BMJUA',
                                                  fontSize: 12,
                                                  color: Color(0xFF4E342E),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        GestureDetector(
                                          onTap: () async {
                                            final userNickname = authController
                                                    .userModel?.nickname ??
                                                '알 수 없음';
                                            await socialController
                                                .rejectFriendRequest(
                                              requestId,
                                              userId,
                                              notification.senderId,
                                              userNickname,
                                              notification.senderNickname,
                                            );
                                          },
                                          child: Container(
                                            width: 70,
                                            height: 36,
                                            decoration: const BoxDecoration(
                                              image: DecorationImage(
                                                image: AssetImage(
                                                    'assets/images/Cancel_Button.png'),
                                                fit: BoxFit.fill,
                                              ),
                                            ),
                                            child: const Center(
                                              child: Text(
                                                '거절',
                                                style: TextStyle(
                                                  fontFamily: 'BMJUA',
                                                  fontSize: 12,
                                                  color: Color(0xFF4E342E),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else if (notification.type ==
                                    NotificationType.cheerMessage)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: notification.isReplied
                                        ? Opacity(
                                            opacity: 0.3,
                                            child: Container(
                                              width: 70,
                                              height: 36,
                                              decoration: const BoxDecoration(
                                                image: DecorationImage(
                                                  image: AssetImage(
                                                      'assets/images/Cancel_Button.png'),
                                                  fit: BoxFit.fill,
                                                ),
                                              ),
                                              child: const Center(
                                                child: Text(
                                                  '답장 완료',
                                                  style: TextStyle(
                                                    fontFamily: 'BMJUA',
                                                    fontSize: 11,
                                                    color: Color(0xFF4E342E),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )
                                        : GestureDetector(
                                            onTap: () => ReplyDialog.show(
                                              context,
                                              receiverId: notification.senderId,
                                              receiverNickname:
                                                  notification.senderNickname,
                                              notificationId: notification.id,
                                            ),
                                            child: Container(
                                              width: 70,
                                              height: 36,
                                              decoration: const BoxDecoration(
                                                image: DecorationImage(
                                                  image: AssetImage(
                                                      'assets/images/Cancel_Button.png'),
                                                  fit: BoxFit.fill,
                                                ),
                                              ),
                                              child: const Center(
                                                child: Text(
                                                  '답장',
                                                  style: TextStyle(
                                                    fontFamily: 'BMJUA',
                                                    fontSize: 12,
                                                    color: Color(0xFF4E342E),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                  )
                                else if (!notification.isRead)
                                  Container(
                                    margin: const EdgeInsets.only(left: 12),
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryButton,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon(
      NotificationType type, AppColorScheme colorScheme) {
    String iconPath;

    switch (type) {
      case NotificationType.wakeUp:
        iconPath = 'assets/icons/Clock_Icon.png';
        break;
      case NotificationType.cheerMessage:
        iconPath = 'assets/icons/Heart_Icon.png';
        break;
      case NotificationType.friendRequest:
        iconPath = 'assets/icons/Friend_NotiIcon.png';
        break;
      default:
        iconPath = 'assets/icons/Bell_Icon.png';
        break;
    }

    return Image.asset(
      iconPath,
      width: 36,
      height: 36,
      fit: BoxFit.contain,
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppColorScheme colorScheme, {
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primaryButton.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 64,
              color: colorScheme.primaryButton.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'BMJUA',
              color: colorScheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'BMJUA',
              color: colorScheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
