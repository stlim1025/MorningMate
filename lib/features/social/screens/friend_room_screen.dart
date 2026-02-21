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
import '../../../core/widgets/memo_notification.dart';
import '../../../core/localization/app_localizations.dart';

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

      final isAwake = socialController.isFriendAwake(friend);
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
      extendBody: true,
      body: Consumer<SocialController>(
        builder: (context, socialController, child) {
          final isAwake = _friendAwakeStatus ??
              (_friend != null
                  ? socialController.isFriendAwake(_friend!)
                  : false);

          final textColor =
              (isAwake && !isDarkMode) ? const Color(0xFF2C3E50) : Colors.white;

          final todaysMood =
              _friend != null ? socialController.getFriendMood(_friend!) : null;

          final currentUser = context.read<AuthController>().userModel;

          return Stack(
            children: [
              // 1. Full Screen Room Background
              if (_friend != null && !_isLoading)
                Positioned.fill(
                  child: EnhancedCharacterRoomWidget(
                    isAwake: isAwake,
                    characterLevel: _friend!.characterLevel,
                    consecutiveDays: _friend!.displayConsecutiveDays,
                    roomDecoration: _friend!.roomDecoration,
                    showBorder: false,
                    currentAnimation: 'idle',
                    onPropTap: (prop) => _showFriendMemoDialog(prop),
                    colorScheme: colorScheme,
                    isDarkMode: isDarkMode,
                    todaysMood: todaysMood,
                    bottomPadding: 45 + MediaQuery.of(context).padding.bottom,
                    equippedCharacterItems: _friend!.equippedCharacterItems,
                    visitorCharacterLevel: currentUser?.characterLevel,
                    visitorEquippedItems: currentUser?.equippedCharacterItems,
                  ),
                ),

              // 1.5. 밤 모드 전체 오버레이 (친구가 자고 있을 때 방 전체를 어둡게)
              // 이제 EnhancedCharacterRoomWidget 내부에서 광원 효과와 함께 처리됩니다.

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
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isSmallScreen =
                                        constraints.maxWidth < 350;
                                    return Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () => Navigator.pop(context),
                                          child: Image.asset(
                                            'assets/icons/X_Button.png',
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
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
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontFamily: 'BMJUA',
                                                    ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (!isSmallScreen) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  AppLocalizations.of(context)!
                                                      .getFormat(
                                                          'consecutiveDays', {
                                                    'days': _friend!
                                                        .displayConsecutiveDays
                                                        .toString()
                                                  }),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        color: textColor
                                                            .withOpacity(0.8),
                                                        fontFamily: 'BMJUA',
                                                      ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // 레벨 표시 버튼
                                        Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Image.asset(
                                              'assets/images/Item_Background.png',
                                              width: 70,
                                              height: 42,
                                              fit: BoxFit.fill,
                                              cacheWidth: 140,
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 2),
                                              child: Text(
                                                'Lv.${_friend!.characterLevel}',
                                                style: const TextStyle(
                                                  fontFamily: 'BMJUA',
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF4E342E),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Menu Button
                                        const SizedBox(width: 8),
                                        PopupMenuButton<void>(
                                          padding: EdgeInsets.zero,
                                          elevation: 0,
                                          color: Colors.transparent,
                                          offset: const Offset(0, 40),
                                          icon: Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 5),
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Image.asset(
                                                  'assets/icons/AddFriend_Button.png',
                                                  width: 50,
                                                  height: 46,
                                                  fit: BoxFit.fill,
                                                ),
                                                const Icon(Icons.more_horiz,
                                                    color: Color(0xFF4E342E),
                                                    size: 32),
                                              ],
                                            ),
                                          ),
                                          onSelected: (_) {},
                                          itemBuilder: (context) => [
                                            PopupMenuItem<void>(
                                              enabled:
                                                  false, // Disable outer touch to prevent double handling, opacity handled by providing non-null text style if needed, but 'enabled:false' fades content.
                                              // Actually, enabled:false fades content. We need enabled:true but handle taps inside.
                                              // Better approach: enabled: false, but wrap content in a widget that ignores the opacity or re-applies opacity?
                                              // No, simple workaround: enabled: true, but consuming taps.
                                              padding: EdgeInsets.zero,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 12,
                                                        horizontal: 12),
                                                decoration: const BoxDecoration(
                                                  image: DecorationImage(
                                                    image: AssetImage(
                                                        'assets/images/Popup_Background.png'),
                                                    fit: BoxFit.fill,
                                                  ),
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    GestureDetector(
                                                      behavior: HitTestBehavior
                                                          .opaque,
                                                      onTap: () {
                                                        Navigator.pop(context);
                                                        _showReportDialog(
                                                            _friend!.uid,
                                                            AppLocalizations.of(
                                                                    context)!
                                                                .get(
                                                                    'userReport'),
                                                            'user');
                                                      },
                                                      child: Row(
                                                        children: [
                                                          Image.asset(
                                                            'assets/icons/Warning_Icon.png',
                                                            width: 24,
                                                            height: 24,
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          Text(
                                                              AppLocalizations.of(
                                                                      context)!
                                                                  .get(
                                                                      'report'),
                                                              style:
                                                                  const TextStyle(
                                                                fontFamily:
                                                                    'BMJUA',
                                                                color: Colors
                                                                    .redAccent,
                                                              )),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    GestureDetector(
                                                      behavior: HitTestBehavior
                                                          .opaque,
                                                      onTap: () {
                                                        Navigator.pop(context);
                                                        _showDeleteFriendDialog();
                                                      },
                                                      child: Row(
                                                        children: [
                                                          Image.asset(
                                                            'assets/icons/FriendDelete_Icon.png',
                                                            width: 24,
                                                            height: 24,
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          Text(
                                                              AppLocalizations.of(
                                                                      context)!
                                                                  .get(
                                                                      'deleteFriendTitle'),
                                                              style:
                                                                  const TextStyle(
                                                                fontFamily:
                                                                    'BMJUA',
                                                                color:
                                                                    Colors.red,
                                                              )),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
              ),

              // Floating Buttons (메인화면 스타일)
              if (_friend != null && !_isLoading)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
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
                                  padding: const EdgeInsets.only(
                                      left: 20, right: 10),
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
                                              'assets/images/Message_Button.png',
                                              width: double.infinity,
                                              height: 90,
                                              fit: BoxFit.fill,
                                              cacheWidth: 300,
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 6),
                                              child: Text(
                                                isCooldown
                                                    ? AppLocalizations.of(
                                                            context)!
                                                        .getFormat(
                                                            'resendAfterSeconds',
                                                            {
                                                            'seconds': seconds
                                                                .toString()
                                                          })
                                                    : AppLocalizations.of(
                                                            context)!
                                                        .get(
                                                            'sendCheerMessage'),
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
                                  label: AppLocalizations.of(context)!
                                      .get('sentHistory'),
                                  backgroundImagePath:
                                      'assets/images/SendHistory_Button.png',
                                  size: 90,
                                  iconSize: 45, // 아이콘 크기 살짝 줄임 (기존 54)
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
              PopupTextField(
                controller: messageController,
                maxLines: 3,
                hintText: AppLocalizations.of(context)!.get('cheerMessageHint'),
                fontFamily: 'KyoboHandwriting2024psw',
                errorText: errorText,
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
          label: AppLocalizations.of(context)!.get('cancel'),
          onPressed: () => Navigator.pop(context),
        ),
        AppDialogAction(
          label: AppLocalizations.of(context)!.get('leave'),
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
            MemoNotification.show(parentContext,
                AppLocalizations.of(parentContext)!.get('cheerMessageSent'));

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
                  MemoNotification.show(
                      parentContext,
                      AppLocalizations.of(parentContext)!
                          .get('cheerMessageSendFailed'));
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
                      AppLocalizations.of(context)!.get('noSentMessages'),
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

                return Stack(
                  children: [
                    // 배경 이미지
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/Item_Background.png',
                        fit: BoxFit.fill,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  actualMessage,
                                  style: const TextStyle(
                                    color: Color(0xFF4E342E),
                                    fontSize: 17,
                                    height: 1.4,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'KyoboHandwriting2024psw',
                                  ),
                                ),
                              ),
                              if (msg.isRead) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4E342E)
                                        .withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    size: 14,
                                    color: Color(0xFF4E342E),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(Icons.access_time,
                                  size: 12,
                                  color:
                                      const Color(0xFF4E342E).withOpacity(0.6)),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('yyyy.MM.dd HH:mm')
                                    .format(msg.createdAt),
                                style: TextStyle(
                                  color:
                                      const Color(0xFF4E342E).withOpacity(0.6),
                                  fontSize: 12,
                                  fontFamily: 'BMJUA',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      actions: [
        AppDialogAction(
          label: AppLocalizations.of(context)!.get('close'),
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
                        cacheWidth: 320,
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
                              cacheWidth: 48,
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
                    // 5. 신고 버튼 (오른쪽 아래)
                    Positioned(
                      bottom: 30,
                      right: 35,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context); // Close memo dialog first
                          _showReportDialog(prop.id, content, 'sticky_note');
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          child: const Icon(Icons.report_problem_outlined,
                              color: Colors.redAccent, size: 20),
                        ),
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

  void _showReportDialog(String targetId, String content, String type) {
    String? selectedReason;
    final reasons = [
      AppLocalizations.of(context)!.get('reportReasonInappropriate'),
      AppLocalizations.of(context)!.get('reportReasonAbusive'),
      AppLocalizations.of(context)!.get('reportReasonSpam'),
      AppLocalizations.of(context)!.get('reportReasonOther'),
    ];

    AppDialog.show(
      context: context,
      key: AppDialogKey.report,
      content: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: reasons.map((reason) {
              final isSelected = selectedReason == reason;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedReason = reason;
                  });
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 4.0),
                  child: Row(
                    children: [
                      // Custom Radio/Check UI
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: isSelected
                            ? Image.asset('assets/images/Check_Icon.png',
                                fit: BoxFit.contain)
                            : Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(
                                        0xFFD7CCC8), // Light brown border for unselected
                                    width: 2,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        reason,
                        style: const TextStyle(
                          fontFamily: 'BMJUA',
                          fontSize: 16,
                          color: Color(0xFF4E342E),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
      actions: [
        AppDialogAction(
          label: AppLocalizations.of(context)!.get('cancel'),
          onPressed: () => Navigator.pop(context),
        ),
        AppDialogAction(
          label: AppLocalizations.of(context)!.get('report'),
          isPrimary: true,
          onPressed: () async {
            if (selectedReason == null) {
              MemoNotification.show(context,
                  AppLocalizations.of(context)!.get('reportReasonSelect'));
              return;
            }

            final authController = context.read<AuthController>();
            final socialController = context.read<SocialController>();
            final user = authController.userModel!;

            try {
              // 다이얼로그 닫기
              Navigator.pop(context);

              await socialController.submitReport(
                reporterId: user.uid,
                reporterName: user.nickname,
                targetUserId: _friend!.uid,
                targetUserName: _friend!.nickname,
                targetContent: content,
                targetId: targetId,
                reason: selectedReason!,
              );

              if (mounted) {
                MemoNotification.show(context,
                    AppLocalizations.of(context)!.get('reportSubmitted'));
              }
            } catch (e) {
              if (mounted) {
                MemoNotification.show(
                    context, AppLocalizations.of(context)!.get('reportError'));
              }
            }
          },
        ),
      ],
    );
  }

  Future<void> _showDeleteFriendDialog() async {
    final confirmed = await AppDialog.show<bool>(
      context: context,
      key: AppDialogKey.deleteFriend,
      content: SizedBox(
        width: double.maxFinite,
        child: Text(
          AppLocalizations.of(context)!.getFormat('deleteFriendConfirm', {
            'nickname':
                _friend?.nickname ?? AppLocalizations.of(context)!.get('friend')
          }),
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontFamily: 'BMJUA',
          ),
          textAlign: TextAlign.center,
        ),
      ),
      actions: [
        AppDialogAction(
          label: AppLocalizations.of(context)!.get('cancel'),
          onPressed: () => Navigator.pop(context, false),
        ),
        AppDialogAction(
          label: AppLocalizations.of(context)!.get('delete'),
          isPrimary: true,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );

    if (confirmed == true) {
      if (!mounted) return;
      final socialController = context.read<SocialController>();
      final authController = context.read<AuthController>();
      final myId = authController.currentUser?.uid;

      if (myId != null && _friend != null) {
        try {
          await socialController.deleteFriend(myId, _friend!.uid);
          if (mounted) {
            MemoNotification.show(
                context, AppLocalizations.of(context)!.get('friendDeleted'));
            Navigator.pop(context); // Close screen
          }
        } catch (e) {
          if (mounted) {
            MemoNotification.show(context,
                AppLocalizations.of(context)!.get('friendDeleteError'));
          }
        }
      }
    }
  }
}
