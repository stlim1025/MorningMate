import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../social/controllers/social_controller.dart';
import '../../social/controllers/nest_controller.dart';
import '../controllers/notification_controller.dart';
import '../../../data/models/notification_model.dart';
import '../../social/widgets/reply_dialog.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/app_dialog.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  Stream<List<NotificationModel>>? _notificationStream;
  String? _initializedUserId;
  int _limit = 10;
  List<NotificationModel> _cachedNotifications = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_cachedNotifications.length >= _limit) {
        setState(() {
          _limit += 10;
        });
        _initStream(forceReload: true);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initStream();
  }

  void _initStream({bool forceReload = false}) {
    final userId = context.read<AuthController>().currentUser?.uid;
    if (userId != null && (userId != _initializedUserId || forceReload)) {
      _initializedUserId = userId;
      _notificationStream = context
          .read<NotificationController>()
          .getNotificationsStream(userId, limit: _limit);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.get('notifications') ?? 'Notifications',
          style: TextStyle(
            fontFamily: AppLocalizations.of(context)?.mainFontFamily,
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
                  margin: EdgeInsets.only(right: 16, top: 8, bottom: 8),
                  padding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    image: const DecorationImage(
                      image: AssetImage('assets/images/Cancel_Button.png'),
                      fit: BoxFit.fill,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)?.get('markAllAsRead') ??
                          'Mark all as read',
                      style: TextStyle(
                        fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA',
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
              'assets/images/Diary_Background.png',
              fit: BoxFit.cover,
            ),
          ),
          Consumer<AuthController>(
            builder: (context, authController, child) {
              final userId = authController.currentUser?.uid;
              if (userId == null) {
                return const Center(child: CircularProgressIndicator());
              }

              _initStream();

              if (_notificationStream == null) {
                return const Center(child: CircularProgressIndicator());
              }

              final notificationController =
                  context.read<NotificationController>();
              final socialController = context.read<SocialController>();
              final nestController = context.read<NestController>();

              return StreamBuilder<List<NotificationModel>>(
                stream: _notificationStream,
                initialData: _cachedNotifications,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    _cachedNotifications = snapshot.data!;
                  }

                  if (snapshot.connectionState == ConnectionState.waiting &&
                      _cachedNotifications.isEmpty) {
                    return _buildEmptyState(
                      context,
                      colorScheme,
                      title: AppLocalizations.of(context)
                              ?.get('loadingNotifications') ??
                          'Loading notifications...',
                      subtitle:
                          AppLocalizations.of(context)?.get('pleaseWait') ??
                              'Please wait',
                    );
                  }
                  if (snapshot.hasError) {
                    return _buildEmptyState(
                      context,
                      colorScheme,
                      title: AppLocalizations.of(context)
                              ?.get('errorLoadingNotifications') ??
                          'Error loading notifications',
                      subtitle:
                          AppLocalizations.of(context)?.get('tryAgainLater') ??
                              'Please try again later',
                    );
                  }

                  final notifications = _cachedNotifications;

                  if (notifications.isEmpty) {
                    return _buildEmptyState(
                      context,
                      colorScheme,
                      title: AppLocalizations.of(context)
                              ?.get('noNotifications') ??
                          'No notifications',
                      subtitle: AppLocalizations.of(context)
                              ?.get('noNotificationsDesc') ??
                          'We will notify you when there is news',
                    );
                  }

                  return ListView.separated(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(
                      16,
                      MediaQuery.of(context).padding.top,
                      16,
                      16 + MediaQuery.of(context).viewPadding.bottom,
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
                      final isNestInvite =
                          notification.type == NotificationType.nestInvite &&
                              notification.data?['inviteId'] != null;
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
                            padding: EdgeInsets.symmetric(
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
                                      notification, colorScheme),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Opacity(
                                    opacity: notification.isRead ? 0.7 : 1.0,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          notification.type == NotificationType.cheerMessage
                                              ? (notification.data?['isReply'] == true
                                                  ? (AppLocalizations.of(context)?.getFormat('replyFrom', {'username': notification.senderNickname}) ??
                                                      '${notification.senderNickname}\'s reply')
                                                  : (AppLocalizations.of(context)?.getFormat('cheerFrom', {'username': notification.senderNickname}) ??
                                                      '${notification.senderNickname}\'s cheer'))
                                              : (notification.type ==
                                                      NotificationType.wakeUp
                                                  ? (AppLocalizations.of(context)?.get('wakeUpAlert') ??
                                                      'Wake up alert')
                                                  : (notification.type == NotificationType.friendRequest
                                                      ? (AppLocalizations.of(context)?.get('friendRequest') ??
                                                          'Friend Request')
                                                      : (notification.type == NotificationType.nestInvite
                                                          ? (AppLocalizations.of(context)?.get('nestInvite') ??
                                                              '둥지 초대')
                                                          : (notification.type == NotificationType.nestPoke
                                                              ? (AppLocalizations.of(context)?.get('nestPokeAlert') ??
                                                                  '찌르기 알림')
                                                              : (notification.type == NotificationType.nestDonation
                                                                  ? (AppLocalizations.of(context)?.get('nestDonation') ??
                                                                      '둥지 기부')
                                                                  : (notification.type == NotificationType.referralReward
                                                                      ? (AppLocalizations.of(context)?.get('referralReward') ?? '추천인 보상')
                                                                      : (AppLocalizations.of(context)?.get('notifications') ?? 'Notifications'))))))),
                                          style: TextStyle(
                                            fontFamily: AppLocalizations.of(context)?.mainFontFamily,
                                            color: colorScheme.textSecondary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          notification
                                              .getLocalizedMessage(context),
                                          style: TextStyle(
                                            fontFamily: AppLocalizations.of(context)?.mainFontFamily,
                                            color: colorScheme.textPrimary,
                                            fontSize: 14,
                                            fontWeight: notification.isRead
                                                ? FontWeight.normal
                                                : FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          DateFormat('MM/dd HH:mm')
                                              .format(notification.createdAt),
                                          style: TextStyle(
                                            fontFamily: AppLocalizations.of(context)?.mainFontFamily,
                                            color: colorScheme.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isFriendRequest) ...[
                                  SizedBox(width: 16),
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
                                                  (AppLocalizations.of(context)?.get('unknown') ?? 'Unknown'),
                                              notification.senderId,
                                              notification.senderNickname,
                                            );
                                          },
                                          child: Container(
                                            width: 70,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              image: DecorationImage(
                                                image: AssetImage(
                                                    'assets/images/Confirm_Button.png'),
                                                fit: BoxFit.fill,
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                AppLocalizations.of(context)
                                                        ?.get('accept') ??
                                                    'Accept',
                                                style: TextStyle(
                                                  fontFamily: AppLocalizations.of(context)?.mainFontFamily,
                                                  fontSize: 12,
                                                  color: const Color(0xFF4E342E),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        GestureDetector(
                                          onTap: () async {
                                            final userNickname = authController
                                                    .userModel?.nickname ??
                                                (AppLocalizations.of(context)?.get('unknown') ?? 'Unknown');
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
                                            decoration: BoxDecoration(
                                              image: DecorationImage(
                                                image: AssetImage(
                                                    'assets/images/Cancel_Button.png'),
                                                fit: BoxFit.fill,
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                AppLocalizations.of(context)
                                                        ?.get('reject') ??
                                                    'Reject',
                                                style: TextStyle(
                                                  fontFamily: AppLocalizations.of(context)?.mainFontFamily,
                                                  fontSize: 12,
                                                  color: const Color(0xFF4E342E),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else if (isNestInvite) ...[
                                  const SizedBox(width: 16),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      GestureDetector(
                                        onTap: () async {
                                          final inviteId = notification
                                              .data!['inviteId']
                                              .toString();
                                          final nestId = notification
                                              .data!['nestId']
                                              .toString();
                                          try {
                                            await nestController
                                                .acceptNestInvite(
                                              inviteId,
                                              nestId,
                                              userId,
                                            );
                                            // 알림 업데이트 (읽음 처리)
                                            await notificationController
                                                .markAsRead(notification.id);
                                          } catch (e) {
                                            if (context.mounted &&
                                                e.toString().contains(
                                                    'nestFullError')) {
                                              AppDialog.show(
                                                context: context,
                                                key: AppDialogKey.inviteToNest,
                                                content: Text(
                                                  AppLocalizations.of(context)
                                                          ?.get(
                                                              'nestFullError') ??
                                                      '10명이 꽉차서 더 이상 입장할 수 없습니다.',
                                                  style: TextStyle(
                                                      fontFamily: AppLocalizations.of(context)?.mainFontFamily,
                                                      fontSize: 16),
                                                  textAlign: TextAlign.center,
                                                ),
                                                actions: [
                                                  AppDialogAction(
                                                    label: AppLocalizations.of(
                                                                context)
                                                            ?.get('confirm') ??
                                                        '확인',
                                                    onPressed: (c) =>
                                                        Navigator.pop(c),
                                                  ),
                                                ],
                                              );
                                            }
                                          }
                                        },
                                        child: Container(
                                          width: 70,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            image: DecorationImage(
                                              image: AssetImage(
                                                  'assets/images/Confirm_Button.png'),
                                              fit: BoxFit.fill,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              AppLocalizations.of(context)
                                                      ?.get('accept') ??
                                                  'Accept',
                                              style: TextStyle(
                                                fontFamily: AppLocalizations.of(context)?.mainFontFamily,
                                                fontSize: 12,
                                                color: const Color(0xFF4E342E),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      GestureDetector(
                                        onTap: () async {
                                          final inviteId = notification
                                              .data!['inviteId']
                                              .toString();
                                          await nestController
                                              .rejectNestInvite(inviteId);
                                          // 알림 업데이트 (읽음 처리)
                                          await notificationController
                                              .markAsRead(notification.id);
                                        },
                                        child: Container(
                                          width: 70,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            image: DecorationImage(
                                              image: AssetImage(
                                                  'assets/images/Cancel_Button.png'),
                                              fit: BoxFit.fill,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              AppLocalizations.of(context)
                                                      ?.get('reject') ??
                                                  'Reject',
                                              style: TextStyle(
                                                fontFamily: AppLocalizations.of(context)?.mainFontFamily,
                                                fontSize: 12,
                                                color: const Color(0xFF4E342E),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else if (notification.type ==
                                    NotificationType.cheerMessage)
                                  Padding(
                                    padding: EdgeInsets.only(left: 12),
                                    child: notification.isReplied
                                        ? Opacity(
                                            opacity: 0.3,
                                            child: Container(
                                              width: 70,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                image: DecorationImage(
                                                  image: AssetImage(
                                                      'assets/images/Cancel_Button.png'),
                                                  fit: BoxFit.fill,
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  AppLocalizations.of(context)
                                                          ?.get(
                                                              'replyCompleted') ??
                                                      'Replied',
                                                  style: TextStyle(
                                                    fontFamily: AppLocalizations.of(context)?.mainFontFamily,
                                                    fontSize: 11,
                                                    color: const Color(0xFF4E342E),
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
                                              decoration: BoxDecoration(
                                                image: DecorationImage(
                                                  image: AssetImage(
                                                      'assets/images/Cancel_Button.png'),
                                                  fit: BoxFit.fill,
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  AppLocalizations.of(context)
                                                          ?.get('reply') ??
                                                      'Reply',
                                                  style: TextStyle(
                                                    fontFamily: AppLocalizations.of(context)?.mainFontFamily,
                                                    fontSize: 12,
                                                    color: const Color(0xFF4E342E),
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
      NotificationModel notification, AppColorScheme colorScheme) {
    String iconPath;

    // 둥지 관련 알림인지 확인 (type이 둥지 타입이거나 data에 nestId가 있는 경우)
    final isNestNotification =
        notification.type == NotificationType.nestInvite ||
            notification.type == NotificationType.nestDonation ||
            notification.type == NotificationType.nestPoke ||
            (notification.data != null && notification.data!['nestId'] != null);

    if (isNestNotification) {
      iconPath = 'assets/icons/Nest_Notification_Icon.png';
    } else {
      switch (notification.type) {
        case NotificationType.wakeUp:
          iconPath = 'assets/icons/Clock_Icon.png';
          break;
        case NotificationType.cheerMessage:
          iconPath = 'assets/icons/Heart_Icon.png';
          break;
        case NotificationType.friendRequest:
          iconPath = 'assets/icons/Friend_NotiIcon.png';
          break;
        case NotificationType.referralReward:
          iconPath = 'assets/icons/Gift_Icon.png';
          break;
        default:
          iconPath = 'assets/icons/Bell_Icon.png';
          break;
      }
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
          SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontFamily: AppLocalizations.of(context)?.mainFontFamily,
              color: colorScheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: AppLocalizations.of(context)?.mainFontFamily,
              color: colorScheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
