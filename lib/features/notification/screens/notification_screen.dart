import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../social/controllers/social_controller.dart';
import '../controllers/notification_controller.dart';
import '../../../data/models/notification_model.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '알림',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
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
                child: const Text(
                  '모두 읽음',
                  style: TextStyle(
                    color: AppColors.primary,
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
                  title: '알림을 불러오는 중이에요',
                  subtitle: '잠시만 기다려주세요',
                );
              }
              if (snapshot.hasError) {
                return _buildEmptyState(
                  context,
                  title: '알림을 불러오는 중 오류가 발생했습니다',
                  subtitle: '잠시 후 다시 시도해주세요',
                );
              }

              final notifications = snapshot.data ?? [];

              if (notifications.isEmpty) {
                return _buildEmptyState(
                  context,
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
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        if (!notification.isRead) {
                          notificationController.markAsRead(notification.id);
                        }
                        // TODO: 알림 유형에 따른 이동 처리 (친구 요청이면 소셜 탭 등)
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: notification.isRead
                              ? Theme.of(context).cardColor
                              : (Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.primary.withOpacity(0.15)
                                  : const Color(0xFFFFF9C4)),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: notification.isRead
                              ? null
                              : Border.all(
                                  color:
                                      const Color(0xFFFFD700).withOpacity(0.5),
                                  width: 1.5,
                                ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildNotificationIcon(notification.type),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notification.message,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color,
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
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isFriendRequest)
                              Column(
                                children: [
                                  SizedBox(
                                    width: 64,
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
                                        backgroundColor: AppColors.primary,
                                        foregroundColor:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? const Color(0xFF5D4E37)
                                                : Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 6),
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
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    width: 64,
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
                                            vertical: 6),
                                        side: BorderSide(
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.white24
                                                    : AppColors.error),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        '거절',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white54
                                              : AppColors.error,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
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

  Widget _buildNotificationIcon(NotificationType type) {
    IconData iconData;
    Color color;

    switch (type) {
      case NotificationType.wakeUp:
        iconData = Icons.alarm;
        color = Colors.orange;
        break;
      case NotificationType.friendRequest:
        iconData = Icons.person_add;
        color = Colors.blue;
        break;
      case NotificationType.cheerMessage:
        iconData = Icons.favorite;
        color = Colors.pink;
        break;
      case NotificationType.system:
        iconData = Icons.notifications;
        color = Colors.grey;
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
    BuildContext context, {
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
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 64,
              color: AppColors.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).textTheme.titleLarge?.color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
