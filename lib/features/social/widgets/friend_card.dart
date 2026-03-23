import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/user_model.dart';
import '../../../core/constants/room_assets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../controllers/social_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../character/widgets/character_display.dart';
import '../../../core/widgets/memo_notification.dart';
import '../../../services/user_service.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/network_or_asset_image.dart';

class FriendCard extends StatefulWidget {
  final UserModel friend;
  final AppColorScheme colorScheme;

  const FriendCard({
    super.key,
    required this.friend,
    required this.colorScheme,
  });

  @override
  State<FriendCard> createState() => _FriendCardState();
}

class _FriendCardState extends State<FriendCard> {
  late Stream<UserModel?> _userStream;

  @override
  void initState() {
    super.initState();
    _userStream = context.read<UserService>().getUserStream(widget.friend.uid);
  }

  @override
  void didUpdateWidget(FriendCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.friend.uid != widget.friend.uid) {
      _userStream =
          context.read<UserService>().getUserStream(widget.friend.uid);
    }
  }

  Future<void> _wakeUpFriend(BuildContext context, UserModel friend,
      SocialController controller) async {
    final authController = context.read<AuthController>();

    // 1. 쿨다운 체크
    if (!controller.canSendWakeUp(friend.uid)) return;

    // 2. 즉시 UI 피드백 (쿨다운 시작 및 스낵바)
    controller.startWakeUpCooldown(friend.uid);

    final friendId = friend.uid;
    final friendNickname = friend.nickname;
    MemoNotification.show(
      context,
      AppLocalizations.of(context)
              ?.getFormat('wakeUpSuccess', {'nickname': friendNickname}) ??
          '$friendNickname님을 깨웠습니다! ⏰',
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
        if (context.mounted) {
          MemoNotification.show(context,
              AppLocalizations.of(context)?.get('wakeUpFailed') ?? '깨우기 요청 실패');
        }
      }
    }());
  }

  Widget _buildWakeUpButton(
    BuildContext context,
    UserModel friend,
    SocialController controller,
    double width,
    double height,
    double fontSize,
  ) {
    final remaining = controller.wakeUpCooldownRemaining(friend.uid);
    final seconds = (remaining.inMilliseconds / 1000).ceil();
    final isCooldown = seconds > 0;
    final VoidCallback? onTap =
        isCooldown ? null : () => _wakeUpFriend(context, friend, controller);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // 1. Expanded Touch Area (Behind visual button)
        Positioned(
          top: -12,
          bottom: -12,
          left: -12,
          right: -12,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onTap,
            child: Container(color: Colors.transparent),
          ),
        ),
        // 2. Visual Button
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: const AssetImage('assets/icons/WakeUp_Button.png'),
              colorFilter: null,
              opacity: isCooldown ? 0.5 : 1.0,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Center(
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 200),
                  child: Text(
                    isCooldown
                        ? AppLocalizations.of(context)?.getFormat(
                                'secondsUnit', {'seconds': '$seconds'}) ??
                            '${seconds}s'
                        : AppLocalizations.of(context)?.get('wakeUp') ?? '깨우기',
                    key: ValueKey(isCooldown ? seconds : -1),
                    style: TextStyle(
                      fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA',
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: isCooldown ? Colors.grey : Colors.brown,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: _userStream,
      initialData: widget.friend,
      builder: (context, snapshot) {
        final currentFriend = snapshot.data ?? widget.friend;

        return Consumer<SocialController>(
          builder: (context, controller, child) {
            final isAwakeRequested = controller.isFriendAwake(currentFriend);
            final friendMood = controller.getFriendMood(currentFriend);
            String? moodAsset;
            if (isAwakeRequested && friendMood != null) {
              final asset = RoomAssets.emoticons.cast<RoomAsset?>().firstWhere(
                    (e) => e?.id == friendMood,
                    orElse: () => null,
                  );
              moodAsset =
                  asset?.imagePath ?? 'assets/imoticon/Imoticon_Happy.png';
            }

            final cardIndex = (currentFriend.uid.hashCode % 5) + 1;
            final backgroundImage = 'assets/icons/Friend_Card$cardIndex.png';

            return LayoutBuilder(
              builder: (context, constraints) {
                final double cardWidth = constraints.maxWidth;
                final double cardHeight = constraints.maxHeight;

                // Define responsive sizes
                final double avatarRadius = cardWidth * 0.22;
                final double fontSizeLarge = cardWidth * 0.22;
                final double moodIconSize =
                    cardWidth * 0.45; // Increased size for emoticon
                final double fontSizeMedium = cardWidth * 0.12;
                final double fontSizeSmall = cardWidth * 0.09;
                final double fontSizeTiny = cardWidth * 0.08;
                final double iconSize = cardWidth * 0.09;
                final double statusIconSize = cardWidth * 0.1;
                final double wakeUpButtonWidth =
                    cardWidth * 0.80; // Adjusted width
                final double wakeUpButtonHeight =
                    cardHeight * 0.15; // Approx 23px relative to typical height

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    image: DecorationImage(
                      image: AssetImage(backgroundImage),
                      fit: BoxFit.fill,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.push('/friend/${currentFriend.uid}'),
                      child: Padding(
                        padding: EdgeInsets.only(
                            left: 4,
                            right: 4,
                            top: cardHeight * 0.12,
                            bottom: 6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // 기상/취침 상태에 따른 아바타 배경색 변화
                                CircleAvatar(
                                  radius: avatarRadius,
                                  backgroundColor: Colors.transparent,
                                  child: !isAwakeRequested
                                      ? CharacterDisplay(
                                          isAwake: false,
                                          characterLevel:
                                              currentFriend.characterLevel,
                                          size: avatarRadius * 1.6,
                                          enableAnimation: false,
                                          equippedItems: currentFriend
                                              .equippedCharacterItems,
                                        )
                                      : moodAsset != null
                                          ? NetworkOrAssetImage(
                                              imagePath: moodAsset,
                                              width: moodIconSize,
                                              height: moodIconSize,
                                              fit: BoxFit.contain,
                                            )
                                          : Text(
                                              currentFriend.nickname[0],
                                              style: TextStyle(
                                                fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA',
                                                color: Colors.brown,
                                                fontSize: fontSizeLarge * 0.7,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isAwakeRequested
                                            ? widget.colorScheme.success
                                                .withOpacity(0.2)
                                            : Colors.white,
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 2,
                                        )
                                      ],
                                    ),
                                    child: Icon(
                                      isAwakeRequested
                                          ? Icons.wb_sunny
                                          : Icons.bedtime,
                                      size: statusIconSize,
                                      color: isAwakeRequested
                                          ? widget.colorScheme.pointStar
                                          : widget.colorScheme.textHint,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: cardHeight * 0.01),
                            Text(
                              currentFriend.nickname,
                              style: TextStyle(
                                fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA',
                                color: Colors.brown,
                                fontSize: fontSizeMedium,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: cardHeight * 0.01),
                            // 연속 일수 뱃지 스타일
                            Container(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('🔥',
                                      style:
                                          TextStyle(fontSize: fontSizeSmall)),
                                  SizedBox(width: 2),
                                  Text(
                                    '${currentFriend.displayConsecutiveDays}${AppLocalizations.of(context)?.get('days') ?? '일'}',
                                    style: TextStyle(
                                      fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA',
                                      color: Colors.brown,
                                      fontSize: fontSizeSmall,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Spacer(),
                            if (isAwakeRequested)
                              Container(
                                width: double.infinity,
                                padding:
                                    EdgeInsets.only(top: 4, bottom: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.brown, size: iconSize),
                                    SizedBox(width: 2),
                                    Text(
                                      AppLocalizations.of(context)
                                              ?.get('written') ??
                                          '작성 완료',
                                      style: TextStyle(
                                        fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA',
                                        color: Colors.brown,
                                        fontSize: fontSizeTiny,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.only(bottom: 5.0),
                                child: Center(
                                  child: _buildWakeUpButton(
                                      context,
                                      currentFriend,
                                      controller,
                                      wakeUpButtonWidth,
                                      wakeUpButtonHeight,
                                      fontSizeSmall),
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
          },
        );
      },
    );
  }
}
