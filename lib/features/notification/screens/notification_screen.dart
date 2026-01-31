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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '알림',
          style: TextStyle(
            color: colorScheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.iconPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
              return;
            }
            context.go('/morning');
          },
        ),
        actions: [
          Consumer<AuthController>(
            builder: (context, authController, child) {
              final userId = authController.currentUser?.uid;
              if (userId == null) {
                return const SizedBox.shrink();
              }
              return TextButton(
                onPressed: () async {
                  final notificationController =
                      context.read<NotificationController>();
                  await notificationController.markAllAsRead(userId);
                },
                child: Text(
                  '모두 읽음',
                  style: TextStyle(
                    color: colorScheme.primaryButton,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<AuthController>(
        builder: (context, authController, child) {
          final userId = authController.currentUser?.uid;
          if (userId == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final notificationController = context.read<NotificationController>();
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
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  final requestId = notification.data?['requestId']?.toString();
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
                          notificationController.markAsRead(notification.id);
                        }
                        // 응원 메시지인 경우 탭했을 때 바로 답장 팝업 띄우기 (이미 답장한 경우는 제외)
                        if (notification.type ==
                                NotificationType.cheerMessage &&
                            !notification.isReplied) {
                          ReplyDialog.show(
                            context,
                            receiverId: notification.senderId,
                            receiverNickname: notification.senderNickname,
                            notificationId: notification.id,
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: notification.isRead
                              ? Theme.of(context).cardColor
                              : colorScheme.secondary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadowColor.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: notification.isRead
                              ? null
                              : Border.all(
                                  color:
                                      colorScheme.streakGold.withOpacity(0.5),
                                  width: 1.5,
                                ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildNotificationIcon(
                                notification.type, colorScheme),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notification.message,
                                    style: TextStyle(
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
                                      color: colorScheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isFriendRequest)
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 70,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        await socialController
                                            .acceptFriendRequest(
                                          requestId,
                                          userId,
                                          authController.userModel?.nickname ??
                                              '알 수 없음',
                                          notification.senderId,
                                        );
                                        await notificationController
                                            .deleteNotification(
                                                notification.id);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            colorScheme.primaryButton,
                                        foregroundColor:
                                            colorScheme.primaryButtonForeground,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
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
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: 70,
                                    child: OutlinedButton(
                                      onPressed: () async {
                                        final userNickname = authController
                                                .userModel?.nickname ??
                                            '알 수 없음';
                                        await socialController
                                            .rejectFriendRequest(
                                          requestId,
                                          userId,
                                          notification.senderId,
                                          userNickname,
                                        );
                                        await notificationController
                                            .deleteNotification(
                                                notification.id);
                                      },
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        side: BorderSide(
                                            color: colorScheme.error
                                                .withOpacity(0.5)),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        '거절',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colorScheme.error,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else if (notification.type ==
                                NotificationType.cheerMessage)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: notification.isReplied
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: colorScheme.textHint
                                              .withOpacity(0.08),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '답장 완료',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: colorScheme.textHint,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      )
                                    : ElevatedButton(
                                        onPressed: () => ReplyDialog.show(
                                          context,
                                          receiverId: notification.senderId,
                                          receiverNickname:
                                              notification.senderNickname,
                                          notificationId: notification.id,
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              colorScheme.primaryButton,
                                          foregroundColor: colorScheme
                                              .primaryButtonForeground,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          minimumSize: const Size(60, 36),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: const Text(
                                          '답장',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildNotificationIcon(
      NotificationType type, AppColorScheme colorScheme) {
    IconData iconData;
    Color color;

    switch (type) {
      case NotificationType.wakeUp:
        iconData = Icons.alarm;
        color = colorScheme.warning;
        break;
      case NotificationType.friendRequest:
        iconData = Icons.person_add;
        color = colorScheme.accent;
        break;
      case NotificationType.cheerMessage:
        iconData = Icons.favorite;
        color = colorScheme.secondary;
        break;
      case NotificationType.system:
        iconData = Icons.notifications;
        color = colorScheme.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color, size: 24),
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
              color: colorScheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: colorScheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
