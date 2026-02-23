import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';

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
  final Set<String> _jumpingMemberIds = {};

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
        hintText: AppLocalizations.of(context)?.get('nestInvitePlaceholder') ??
            '초대할 친구의 닉네임을 입력하세요',
        maxLength: 10,
      ),
      actions: [
        AppDialogAction(
          label: AppLocalizations.of(context)?.get('cancel') ?? '취소',
          onPressed: (ctx) => Navigator.of(ctx).pop(),
        ),
        AppDialogAction(
          label: AppLocalizations.of(context)?.get('invite') ?? '초대하기',
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
              AppDialog.show(
                context: context,
                key: AppDialogKey.inviteToNest,
                content: Text(
                  AppLocalizations.of(context)?.get('nestSelfInviteError') ??
                      '자신을 초대할 수 없습니다.',
                  style: const TextStyle(fontFamily: 'BMJUA', fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                actions: [
                  AppDialogAction(
                    label: AppLocalizations.of(context)?.get('confirm') ?? '확인',
                    onPressed: (c) => Navigator.pop(c),
                  ),
                ],
              );
              return;
            }

            try {
              final targetUser = await userService.getUserByNickname(nickname);

              if (!ctx.mounted) return;

              if (targetUser == null) {
                AppDialog.show(
                  context: context,
                  key: AppDialogKey.inviteToNest,
                  content: Text(
                    AppLocalizations.of(context)
                            ?.get('nestUserNotFoundError') ??
                        '존재하지 않는 닉네임입니다.',
                    style: const TextStyle(fontFamily: 'BMJUA', fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  actions: [
                    AppDialogAction(
                      label:
                          AppLocalizations.of(context)?.get('confirm') ?? '확인',
                      onPressed: (c) => Navigator.pop(c),
                    ),
                  ],
                );
                return;
              }

              if (widget.nest.memberIds.contains(targetUser.uid)) {
                AppDialog.show(
                  context: context,
                  key: AppDialogKey.inviteToNest,
                  content: Text(
                    AppLocalizations.of(context)
                            ?.get('nestAlreadyMemberError') ??
                        '이미 둥지에 있는 사용자입니다.',
                    style: const TextStyle(fontFamily: 'BMJUA', fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  actions: [
                    AppDialogAction(
                      label:
                          AppLocalizations.of(context)?.get('confirm') ?? '확인',
                      onPressed: (c) => Navigator.pop(c),
                    ),
                  ],
                );
                return;
              }

              await nestController.inviteToNest(
                widget.nest.id,
                widget.nest.name,
                currentUser.uid,
                targetUser.uid,
              );

              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();

              if (!mounted) return;
              MemoNotification.show(
                  context,
                  AppLocalizations.of(context)?.getFormat(
                          'nestInviteSent', {'nickname': nickname}) ??
                      '$nickname님에게 초대 요청을 보냈습니다.');
            } catch (e) {
              if (ctx.mounted) {
                MemoNotification.show(ctx, '초대 실패: ${e.toString()}');
              }
            }
          },
        ),
      ],
    );
  }

  void _showCollectDialog(int currentNestGaji) {
    final TextEditingController amountController = TextEditingController();

    final authController = Provider.of<AuthController>(context, listen: false);
    final userGaji = authController.userModel?.points ?? 0;

    AppDialog.show(
      context: context,
      key: AppDialogKey.collectGaji,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/branch.png', width: 24, height: 24),
              const SizedBox(width: 8),
              Text(
                '$userGaji',
                style: const TextStyle(
                  fontFamily: 'BMJUA',
                  fontSize: 20,
                  color: Color(0xFF4E342E),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PopupTextField(
            controller: amountController,
            hintText: AppLocalizations.of(context)?.get('nestCollectHint') ??
                '모을 수량을 입력하세요',
            keyboardType: TextInputType.number,
            maxLength: 5,
          ),
        ],
      ),
      actions: [
        AppDialogAction(
          label: AppLocalizations.of(context)?.get('cancel') ?? '취소',
          onPressed: (ctx) => Navigator.pop(ctx),
        ),
        AppDialogAction(
          label:
              AppLocalizations.of(context)?.get('nestCollectButton') ?? '모으기',
          isPrimary: true,
          onPressed: (ctx) async {
            final amountStr = amountController.text.trim();
            final amount = int.tryParse(amountStr);

            if (amount == null || amount <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(AppLocalizations.of(context)
                            ?.get('nestInvalidAmount') ??
                        '올바른 숫자를 입력해주세요.')),
              );
              return;
            }

            if (amount > userGaji) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(AppLocalizations.of(context)
                            ?.get('nestNotEnoughGaji') ??
                        '보유한 가지보다 많이 모을 수 없습니다.')),
              );
              return;
            }

            final nestController =
                Provider.of<NestController>(context, listen: false);
            try {
              await nestController.donateGaji(
                widget.nest.id,
                authController.currentUser!.uid,
                authController.userModel?.nickname ??
                    (AppLocalizations.of(context)?.get('unknown') ?? '알 수 없음'),
                widget.nest.name,
                amount,
                userGaji,
              );

              if (!ctx.mounted) return;
              Navigator.pop(ctx); // 입력 다이얼로그만 확실히 닫기

              if (!mounted) return;
              // 성공 팝업 표시
              await AppDialog.show(
                context: context,
                key: AppDialogKey.nestCollectSuccess,
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    Image.asset(
                      'assets/images/branch.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)?.getFormat(
                              'nestCollectSuccessDesc',
                              {'amount': amount.toString()}) ??
                          '가지 $amount개 모으기 성공!',
                      style: const TextStyle(
                        fontFamily: 'BMJUA',
                        fontSize: 18,
                        color: Color(0xFF4E342E),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            } catch (e) {
              if (ctx.mounted) {
                MemoNotification.show(ctx, e.toString());
              }
            }
          },
        ),
      ],
    );
  }

  void _showEditNestDialog(NestModel nest) {
    final nameController = TextEditingController(text: nest.name);
    final descController = TextEditingController(text: nest.description);

    AppDialog.show(
      context: context,
      key: AppDialogKey.createNest,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.of(context)?.get('nestEditTitle') ?? '둥지 수정',
            style: const TextStyle(
              fontFamily: 'BMJUA',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4E342E),
            ),
          ),
          const SizedBox(height: 16),
          PopupTextField(
            controller: nameController,
            hintText: AppLocalizations.of(context)?.get('nestNameHint') ??
                '둥지 이름을 입력하세요',
            maxLength: 10,
          ),
          const SizedBox(height: 12),
          PopupTextField(
            controller: descController,
            hintText: AppLocalizations.of(context)?.get('nestDescHint') ??
                '둥지 설명을 입력하세요 (최대 15자)',
            maxLength: 15,
          ),
        ],
      ),
      actions: [
        AppDialogAction(
          label: AppLocalizations.of(context)?.get('cancel') ?? '취소',
          onPressed: (ctx) => Navigator.pop(ctx),
        ),
        AppDialogAction(
          label: AppLocalizations.of(context)?.get('edit') ?? '수정하기',
          isPrimary: true,
          onPressed: (ctx) async {
            final name = nameController.text.trim();
            final desc = descController.text.trim();
            if (name.isEmpty) return;

            final nestController =
                Provider.of<NestController>(context, listen: false);
            try {
              await nestController.updateNest(nest.id, name, desc);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              MemoNotification.show(
                  context,
                  AppLocalizations.of(context)?.get('nestUpdateSuccess') ??
                      '둥지 정보를 수정했습니다!');
            } catch (e) {
              if (ctx.mounted) {
                MemoNotification.show(ctx, e.toString());
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
          context,
          AppLocalizations.of(context)?.getFormat('nestMyStreak',
                  {'days': member.displayConsecutiveDays.toString()}) ??
              '나의 연속 기록: ${member.displayConsecutiveDays}일! 찌를 수 없습니다.');
      return;
    }

    final socialController =
        Provider.of<SocialController>(context, listen: false);

    if (!socialController.canSendWakeUp(member.uid)) {
      final remaining =
          socialController.wakeUpCooldownRemaining(member.uid).inSeconds;
      MemoNotification.show(
          context,
          AppLocalizations.of(context)?.getFormat(
                  'nestPokeCooldown', {'seconds': remaining.toString()}) ??
              '앗! ${remaining}초 뒤에 다시 찌를 수 있어요!');
      return;
    }

    MemoNotification.show(
        context,
        AppLocalizations.of(context)
                ?.getFormat('nestPokeSuccess', {'nickname': member.nickname}) ??
            '${member.nickname}님을 찔렀어요!');

    setState(() {
      _jumpingMemberIds.add(member.uid);
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _jumpingMemberIds.remove(member.uid);
        });
      }
    });

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
        title: StreamBuilder<NestModel?>(
          stream: _nestStream,
          builder: (context, snapshot) {
            final nestData = snapshot.data ?? widget.nest;
            final isCreator =
                Provider.of<AuthController>(context, listen: false)
                        .currentUser
                        ?.uid ==
                    nestData.creatorId;

            return Container(
              width: 260,
              height: 64,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/NestTitle_Area.png'),
                  fit: BoxFit.contain,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      nestData.name,
                      style: const TextStyle(
                        color: Color(0xFF4E342E),
                        fontFamily: 'BMJUA',
                        fontSize: 20,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (isCreator)
                    Positioned(
                      right: 25,
                      child: IconButton(
                        icon: const Icon(Icons.edit,
                            color: Color(0xFF4E342E), size: 20),
                        onPressed: () => _showEditNestDialog(nestData),
                      ),
                    ),
                ],
              ),
            );
          },
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
      floatingActionButton: Transform.translate(
        offset: const Offset(0, -10),
        child: _ScaleTapButton(
          onTap: _showInviteDialog,
          child: Container(
            width: 140,
            height: 48,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/icons/AddFriend_Button.png'),
                fit: BoxFit.contain,
              ),
            ),
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(top: 5), // 시각적 중앙 보정 (텍스트 아래로)
              child: Text(
                AppLocalizations.of(context)?.get('nestInviteButton') ??
                    '+  둥지 초대',
                style: const TextStyle(
                  color: Color(0xFF4E342E),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'BMJUA',
                  fontSize: 15,
                ),
              ),
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
                            width: 100,
                            height: 44,
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image:
                                    AssetImage('assets/images/Circle_Area.png'),
                                fit: BoxFit.fill,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
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
                          // 가지 모으기 버튼
                          _ScaleTapButton(
                            onTap: () => _showCollectDialog(nestData.totalGaji),
                            child: Container(
                              width: 75,
                              height: 32,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage(
                                      'assets/images/Add_Button.png'),
                                  fit: BoxFit.fill,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                AppLocalizations.of(context)
                                        ?.get('nestCollectButton') ??
                                    '+ 모으기',
                                style: const TextStyle(
                                  color: Color(0xFF4E342E),
                                  fontFamily: 'BMJUA',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
                      return Center(
                          child: Text(AppLocalizations.of(context)
                                  ?.get('errorOccurred') ??
                              '오류가 발생했습니다.'));
                    }
                    final members = snapshot.data ?? [];

                    if (members.isEmpty) {
                      return Center(
                          child: Text(
                              AppLocalizations.of(context)
                                      ?.get('nestNoMembers') ??
                                  '아직 멤버가 없습니다.',
                              style: const TextStyle(fontFamily: 'BMJUA')));
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
                                MemoNotification.show(
                                    context,
                                    AppLocalizations.of(context)?.getFormat(
                                            'nestPokeDescription', {
                                          'nickname': member.nickname,
                                          'days': member.displayConsecutiveDays
                                              .toString()
                                        }) ??
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
                                                  Colors.white.withOpacity(0.4),
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
                                                  '${member.displayConsecutiveDays}${AppLocalizations.of(context)?.get('dayUnit') ?? '일'}',
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
                                            child: Stack(
                                              alignment: Alignment.center,
                                              clipBehavior: Clip.none,
                                              children: [
                                                // 캐릭터 그림자 (바닥에 고정)
                                                Positioned(
                                                  bottom: -3,
                                                  child: AnimatedOpacity(
                                                    duration: const Duration(
                                                        milliseconds: 200),
                                                    opacity: _jumpingMemberIds
                                                            .contains(
                                                                member.uid)
                                                        ? 0.15
                                                        : 0.25,
                                                    child: Container(
                                                      width: 44,
                                                      height: 12,
                                                      decoration: BoxDecoration(
                                                        color: Colors.black,
                                                        borderRadius:
                                                            const BorderRadius
                                                                .all(Radius
                                                                    .elliptical(
                                                                        44,
                                                                        12)),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                // 점프하는 캐릭터만 AnimatedContainer로 감쌈
                                                AnimatedContainer(
                                                  duration: const Duration(
                                                      milliseconds: 200),
                                                  curve: Curves.easeInOut,
                                                  transform:
                                                      Matrix4.translationValues(
                                                          0,
                                                          _jumpingMemberIds
                                                                  .contains(
                                                                      member
                                                                          .uid)
                                                              ? -25
                                                              : 0,
                                                          0),
                                                  child: CharacterDisplay(
                                                    isAwake: isAwake,
                                                    characterLevel:
                                                        member.characterLevel,
                                                    size: 60.0,
                                                    equippedItems: member
                                                        .equippedCharacterItems,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.4),
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
                                          top: 0,
                                          right: -34,
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

/// 눌렸을 때 스케일 축소 애니메이션을 제공하는 탭 버튼 래퍼
class _ScaleTapButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _ScaleTapButton({required this.child, required this.onTap});

  @override
  State<_ScaleTapButton> createState() => _ScaleTapButtonState();
}

class _ScaleTapButtonState extends State<_ScaleTapButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _controller.forward();
  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}
