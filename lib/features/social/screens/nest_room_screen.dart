import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../models/nest_model.dart';
import '../../../data/models/user_model.dart';
import '../../../services/nest_service.dart';
import '../../../services/user_service.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/memo_notification.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/nest_controller.dart';
import '../controllers/social_controller.dart';
import '../../character/widgets/character_display.dart';
import '../../common/widgets/custom_bottom_navigation_bar.dart';
import '../../../core/constants/room_assets.dart';
import '../../../core/widgets/network_or_asset_image.dart';

class NestRoomScreen extends StatefulWidget {
  final NestModel nest;

  const NestRoomScreen({super.key, required this.nest});

  @override
  State<NestRoomScreen> createState() => _NestRoomScreenState();
}

class _NestRoomScreenState extends State<NestRoomScreen> {
  // 미리 정해진 둥지 내 캐릭터 배치 위치 (상대적 좌표: dx, dy (0.0 ~ 1.0))
  final List<Offset> _fixedPositions = const [
    Offset(0.2, 0.4), // 1
    Offset(0.8, 0.4), // 2
    Offset(0.5, 0.5), // 3 (Center)
    Offset(0.3, 0.65), // 4
    Offset(0.7, 0.65), // 5
    Offset(0.2, 0.8), // 6
    Offset(0.8, 0.8), // 7
    Offset(0.5, 0.3), // 8
    Offset(0.5, 0.85), // 9
    Offset(0.2, 0.2), // 10
  ];

  late Stream<List<UserModel>> _membersStream;
  late Stream<NestModel?> _nestStream;

  @override
  void initState() {
    super.initState();
    final nestService = Provider.of<NestService>(context, listen: false);
    _membersStream = nestService.getNestMembersStream(widget.nest.id);
    _nestStream = nestService.getNestStream(widget.nest.id);
  }

  void _showInviteDialog() {
    final TextEditingController nicknameController = TextEditingController();

    AppDialog.show(
      context: context,
      key: AppDialogKey.inviteToNest,
      content: PopupTextField(
        controller: nicknameController,
        hintText: '초대할 친구의 닉네임을 입력하세요',
        maxLength: 10,
      ),
      actions: [
        AppDialogAction(
          label: '취소',
          onPressed: (ctx) => Navigator.of(ctx).pop(),
        ),
        AppDialogAction(
          label: '초대하기',
          isPrimary: true,
          onPressed: (ctx) async {
            final nickname = nicknameController.text.trim();
            if (nickname.isEmpty) return;

            final userService =
                Provider.of<UserService>(context, listen: false);
            final nestController =
                Provider.of<NestController>(context, listen: false);
            final authController =
                Provider.of<AuthController>(context, listen: false);

            final currentUser = authController.currentUser;
            if (currentUser == null) return;

            if (nickname == authController.userModel?.nickname) {
              MemoNotification.show(context, '자신을 초대할 수 없습니다.');
              Navigator.of(ctx).pop();
              return;
            }

            try {
              final targetUser = await userService.getUserByNickname(nickname);

              if (targetUser == null) {
                if (ctx.mounted) {
                  MemoNotification.show(context, '해당 닉네임의 사용자를 찾을 수 없습니다.');
                }
                return;
              }

              if (widget.nest.memberIds.contains(targetUser.uid)) {
                if (ctx.mounted) {
                  MemoNotification.show(context, '이미 둥지에 있는 사용자입니다.');
                }
                return;
              }

              await nestController.inviteToNest(
                widget.nest.id,
                widget.nest.name,
                currentUser.uid,
                targetUser.uid,
              );

              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                MemoNotification.show(context, '$nickname님에게 초대 요청을 보냈습니다.');
              }
            } catch (e) {
              if (ctx.mounted) {
                MemoNotification.show(context, '초대 실패: ${e.toString()}');
              }
            }
          },
        ),
      ],
    );
  }

  void _showDonateDialog(int currentNestGaji) {
    final TextEditingController amountController = TextEditingController();

    final authController = Provider.of<AuthController>(context, listen: false);
    final userGaji = authController.userModel?.points ?? 0;

    AppDialog.show(
      context: context,
      key: AppDialogKey.donateGaji,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '내 보유 가지: $userGaji',
            style: const TextStyle(fontFamily: 'BMJUA', fontSize: 16),
          ),
          const SizedBox(height: 12),
          PopupTextField(
            controller: amountController,
            hintText: '기부할 수량을 입력하세요',
            keyboardType: TextInputType.number,
            maxLength: 5,
          ),
        ],
      ),
      actions: [
        AppDialogAction(
          label: '취소',
          onPressed: (ctx) => Navigator.of(ctx).pop(),
        ),
        AppDialogAction(
          label: '기부하기',
          isPrimary: true,
          onPressed: (ctx) async {
            final amountStr = amountController.text.trim();
            final amount = int.tryParse(amountStr);

            if (amount == null || amount <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('올바른 숫자를 입력해주세요.')),
              );
              return;
            }

            if (amount > userGaji) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('보유한 가지보다 많이 기부할 수 없습니다.')),
              );
              return;
            }

            final nestController =
                Provider.of<NestController>(context, listen: false);
            try {
              await nestController.donateGaji(
                widget.nest.id,
                authController.currentUser!.uid,
                authController.userModel?.nickname ?? '알 수 없음',
                widget.nest.name,
                amount,
                userGaji,
              );
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                MemoNotification.show(context, '가지 $amount개를 기부했습니다!');
              }
            } catch (e) {
              if (ctx.mounted) {
                MemoNotification.show(context, e.toString());
              }
            }
          },
        ),
      ],
    );
  }

  void _handlePoke(UserModel member) {
    // 본인 제외인지 체크?
    final currUserId =
        Provider.of<AuthController>(context, listen: false).currentUser?.uid;
    if (member.uid == currUserId) {
      MemoNotification.show(
          context, '나의 연속 기록: ${member.displayConsecutiveDays}일! 찌를 수 없습니다.');
      return;
    }

    final socialController =
        Provider.of<SocialController>(context, listen: false);

    if (!socialController.canSendWakeUp(member.uid)) {
      final remaining =
          socialController.wakeUpCooldownRemaining(member.uid).inSeconds;
      MemoNotification.show(context, '앗! ${remaining}초 뒤에 다시 찌를 수 있어요!');
      return;
    }

    MemoNotification.show(context,
        '${member.nickname}님을 찔렀어요! (연속 일기: ${member.displayConsecutiveDays}일)');

    socialController.startWakeUpCooldown(member.uid);

    final reqUser =
        Provider.of<AuthController>(context, listen: false).userModel;
    if (reqUser != null) {
      socialController.pokeNestMember(
        reqUser.uid,
        reqUser.nickname,
        member.uid,
        member.nickname,
        widget.nest.name,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        title: Text(
          widget.nest.name,
          style: const TextStyle(
            color: Color(0xFF4E342E),
            fontFamily: 'BMJUA',
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          iconSize: 32,
          icon: Image.asset('assets/icons/X_Button.png', width: 32, height: 32),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: GestureDetector(
        onTap: () => _showInviteDialog(),
        child: Container(
          width: 120,
          height: 44,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/icons/AddFriend_Button.png'),
              fit: BoxFit.contain,
            ),
          ),
          alignment: Alignment.center,
          child: const Text(
            '+  둥지 초대',
            style: TextStyle(
              color: Color(0xFF4E342E),
              fontWeight: FontWeight.bold,
              fontFamily: 'BMJUA',
              fontSize: 14,
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 3,
        onTap: (_) {},
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: ResizeImage(
                AssetImage(widget.nest.level == 1
                    ? 'assets/images/Nest_Level1.png'
                    : 'assets/images/Nest_Background.png'),
                width: 1080),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 둥지 상단: 공통 가지 수량 및 기부 버튼
              StreamBuilder<NestModel?>(
                  stream: _nestStream,
                  builder: (context, snapshot) {
                    final nestData = snapshot.data ?? widget.nest;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBF4EB),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: const Color(0xFFDCD2C6), width: 2),
                            ),
                            child: Row(
                              children: [
                                Image.asset('assets/images/branch.png',
                                    width: 24, height: 24),
                                const SizedBox(width: 8),
                                Text(
                                  '${nestData.totalGaji}',
                                  style: const TextStyle(
                                    color: Color(0xFF4E342E),
                                    fontFamily: 'BMJUA',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _showDonateDialog(nestData.totalGaji),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFBF4EB),
                              ),
                              child: const Icon(Icons.add,
                                  color: Color(0xFF4E342E)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              Expanded(
                child: StreamBuilder<List<UserModel>>(
                  stream: _membersStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(child: Text('오류가 발생했습니다.'));
                    }
                    final members = snapshot.data ?? [];

                    if (members.isEmpty) {
                      return const Center(
                          child: Text('아직 멤버가 없습니다.',
                              style: TextStyle(fontFamily: 'BMJUA')));
                    }

                    return LayoutBuilder(builder: (context, constraints) {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: members.asMap().entries.map((entry) {
                          final index = entry.key;
                          final member = entry.value;
                          // 위치 초과시 랜덤? 혹은 안전한 위치로
                          final posOffset = index < _fixedPositions.length
                              ? _fixedPositions[index]
                              : Offset(0.5, 0.5);

                          final left = constraints.maxWidth * posOffset.dx -
                              50; // 캐릭터 절반 사이즈 보정
                          final top = constraints.maxHeight * posOffset.dy - 50;

                          return Positioned(
                            left: left,
                            top: top,
                            child: GestureDetector(
                              onDoubleTap: () => _handlePoke(member),
                              onTap: () {
                                MemoNotification.show(context,
                                    '${member.nickname}: 연속 ${member.displayConsecutiveDays}일! (더블탭해서 찌르기)');
                              },
                              child: Builder(
                                builder: (context) {
                                  final socialController =
                                      Provider.of<SocialController>(context,
                                          listen: false);
                                  final isAwake =
                                      socialController.isFriendAwake(member);
                                  final friendMood =
                                      socialController.getFriendMood(member);

                                  String? moodAsset;
                                  if (isAwake && friendMood != null) {
                                    final asset = RoomAssets.emoticons
                                        .cast<RoomAsset?>()
                                        .firstWhere(
                                          (e) => e?.id == friendMood,
                                          orElse: () => null,
                                        );
                                    if (asset?.imagePath != null) {
                                      moodAsset = asset!.imagePath;
                                    } else {
                                      switch (friendMood) {
                                        case 'happy':
                                          moodAsset =
                                              'assets/imoticon/Imoticon_Happy.png';
                                          break;
                                        case 'normal':
                                          moodAsset =
                                              'assets/imoticon/Imoticon_Normal.png';
                                          break;
                                        case 'sad':
                                          moodAsset =
                                              'assets/imoticon/Imoticon_Sad.png';
                                          break;
                                        case 'angry':
                                          moodAsset =
                                              'assets/imoticon/Imoticon_Angry.png';
                                          break;
                                      }
                                    }
                                  }

                                  return Stack(
                                    alignment: Alignment.center,
                                    clipBehavior: Clip.none,
                                    children: [
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.8),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Text('🔥',
                                                    style: TextStyle(
                                                        fontSize: 12)),
                                                const SizedBox(width: 2),
                                                Text(
                                                  '${member.displayConsecutiveDays}일',
                                                  style: const TextStyle(
                                                    fontFamily: 'BMJUA',
                                                    color: Color(0xFF4E342E),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          SizedBox(
                                            width: 60,
                                            height: 60,
                                            child: CharacterDisplay(
                                              isAwake: isAwake,
                                              characterLevel:
                                                  member.characterLevel,
                                              size: 60.0,
                                              equippedItems:
                                                  member.equippedCharacterItems,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.8),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              member.nickname,
                                              style: const TextStyle(
                                                fontFamily: 'BMJUA',
                                                fontSize: 12,
                                                color: Color(0xFF4E342E),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (moodAsset != null)
                                        Positioned(
                                          top: -20,
                                          right: -28,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Image.asset(
                                                'assets/icons/Bubble_Icon.png',
                                                width: 44,
                                                height: 44,
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 6),
                                                child: NetworkOrAssetImage(
                                                  imagePath: moodAsset,
                                                  width: 26,
                                                  height: 26,
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
