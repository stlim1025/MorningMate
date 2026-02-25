import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import '../widgets/today_speak_dialog.dart';

class NestRoomScreen extends StatefulWidget {
  final NestModel nest;

  const NestRoomScreen({super.key, required this.nest});

  @override
  State<NestRoomScreen> createState() => _NestRoomScreenState();
}

class _NestRoomScreenState extends State<NestRoomScreen> {
  // 레벨 1 둥지 내 캐릭터 배치 위치
  final List<Offset> _level1Positions = const [
    Offset(0.85, 0.38), // 침대 위
    Offset(0.50, 0.48), // 러그 중앙 상단
    Offset(0.32, 0.55), // 러그 왼쪽
    Offset(0.68, 0.55), // 러그 오른쪽
    Offset(0.16, 0.45), // 왼쪽 장식장 부근
    Offset(0.20, 0.68), // 테이블 위
    Offset(0.40, 0.78), // 테이블 근처 아래 바닥
    Offset(0.78, 0.70), // 바닥 오른쪽 (Y축 위로 조정)
    Offset(0.88, 0.50), // 중앙 오른쪽 끝 (Y축 위로 조정)
    Offset(0.55, 0.88), // 바닥 하단
  ];

  // 레벨 2 둥지 내 캐릭터 배치 위치 (15명용)
  final List<Offset> _level2Positions = const [
    Offset(0.30, 0.42), // 중앙 소파 1
    Offset(0.45, 0.40), // 중앙 소파 2
    Offset(0.60, 0.40), // 중앙 소파 3
    Offset(0.72, 0.42), // 중앙 소파 4
    Offset(0.15, 0.35), // 왼쪽 위 소파/침대
    Offset(0.85, 0.3), // 오른쪽 위 소파/침대
    Offset(0.15, 0.76), // 왼쪽 아래 소파/침대
    Offset(0.85, 0.76), // 오른쪽 아래 소파/침대
    Offset(0.50, 0.64), // 책상 아래 (러그 위)
    Offset(0.20, 0.65), // 러그 왼쪽
    Offset(0.80, 0.65), // 러그 오른쪽
    Offset(0.18, 0.32), // 계단 부근
    Offset(0.35, 0.82), // 하단 왼쪽 바닥
    Offset(0.65, 0.82), // 하단 오른쪽 바닥
    Offset(0.50, 0.15), // 발코니 중앙 (한 명 추가하여 15명 유지)
  ];

  late Stream<List<UserModel>> _membersStream;
  late Stream<NestModel?> _nestStream;
  final Set<String> _jumpingMemberIds = {};
  DateTime? _lastViewedTodaySpeak;

  @override
  void initState() {
    super.initState();
    final nestService = Provider.of<NestService>(context, listen: false);
    _membersStream = nestService.getNestMembersStream(widget.nest.id);
    _nestStream = nestService.getNestStream(widget.nest.id);
    _loadLastViewed();
  }

  Future<void> _loadLastViewed() async {
    final authController = Provider.of<AuthController>(context, listen: false);
    final userId = authController.currentUser?.uid;
    if (userId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt('lastViewedTodaySpeak_${userId}_${widget.nest.id}');
    if (ts != null) {
      if (mounted) {
        setState(() {
          _lastViewedTodaySpeak = DateTime.fromMillisecondsSinceEpoch(ts);
        });
      }
    }
  }

  Future<void> _saveLastViewed() async {
    final authController = Provider.of<AuthController>(context, listen: false);
    final userId = authController.currentUser?.uid;
    if (userId == null) return;

    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastViewedTodaySpeak_${userId}_${widget.nest.id}',
        now.millisecondsSinceEpoch);
    if (mounted) {
      setState(() {
        _lastViewedTodaySpeak = now;
      });
    }
  }

  void _showInviteDialog() {
    if (widget.nest.level == 1 && widget.nest.memberIds.length >= 10) {
      AppDialog.show(
        context: context,
        key: AppDialogKey.inviteToNest,
        content: Text(
          AppLocalizations.of(context)?.get('nestFullError') ??
              '10명이 꽉차서 더 이상 입장할 수 없습니다.',
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
                if (e.toString().contains('nestFullError')) {
                  AppDialog.show(
                    context: ctx,
                    key: AppDialogKey.inviteToNest,
                    content: Text(
                      AppLocalizations.of(context)?.get('nestFullError') ??
                          '10명이 꽉차서 더 이상 입장할 수 없습니다.',
                      style: const TextStyle(fontFamily: 'BMJUA', fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    actions: [
                      AppDialogAction(
                        label: AppLocalizations.of(context)?.get('confirm') ??
                            '확인',
                        onPressed: (c) => Navigator.pop(c),
                      ),
                    ],
                  );
                } else {
                  MemoNotification.show(
                      ctx,
                      AppLocalizations.of(context)?.getFormat(
                              'nestInviteFailed', {'error': e.toString()}) ??
                          '초대 실패: ${e.toString()}');
                }
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
      key: AppDialogKey.editNest,
      trailing: GestureDetector(
        onTap: () {
          _showDeleteNestConfirmDialog(nest);
        },
        child: Image.asset(
          'assets/icons/Delete_Button.png',
          width: 26,
          height: 26,
          fit: BoxFit.contain,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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

  void _showDeleteNestConfirmDialog(NestModel nest) {
    AppDialog.show(
      context: context,
      key: AppDialogKey.deleteNest,
      content: Text(
        AppLocalizations.of(context)
                ?.getFormat('nestDeleteConfirm', {'name': nest.name}) ??
            '\'${nest.name}\' 둥지를 정말 삭제하시겠습니까?\n모든 멤버가 탈퇴 처리되며 복구할 수 없습니다.',
        textAlign: TextAlign.center,
        style: const TextStyle(fontFamily: 'BMJUA', fontSize: 16),
      ),
      actions: [
        AppDialogAction(
          label: AppLocalizations.of(context)?.get('cancel') ?? '취소',
          onPressed: (ctx) => Navigator.pop(ctx),
        ),
        AppDialogAction(
          label: AppLocalizations.of(context)?.get('delete') ?? '삭제',
          isPrimary: true,
          onPressed: (ctx) async {
            final nestController =
                Provider.of<NestController>(context, listen: false);
            // 둥지 삭제 시 현재 화면 캐시가 날아가 unmount 예외가 발생할 수 있으므로,
            // 팝업 닫기와 페이지 이동에 필요한 NavigatorState와 GoRouter를 미리 저장합니다.
            final rootNav = Navigator.of(context, rootNavigator: true);
            final router = GoRouter.of(context);

            try {
              await nestController.deleteNest(nest.id);

              // 1. 확인 팝업과 수정 팝업을 rootNav를 사용하여 동기적으로 바로 닫기
              rootNav.pop(); // '정말 삭제하시겠습니까?' 다이얼로그 닫기
              rootNav.pop(); // '둥지 수정' 다이얼로그 닫기

              // 2. 탭바가 포함된 둥지 목록(ShellRoute)으로 안전하게 전체 이동
              router.go('/nest_list');

              if (ctx.mounted) {
                MemoNotification.show(
                    ctx,
                    AppLocalizations.of(ctx)?.get('nestDeleteSuccess') ??
                        '둥지가 삭제되었습니다.');
              }
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

  void _showLeaveNestConfirmDialog(NestModel nest) {
    AppDialog.show(
      context: context,
      key: AppDialogKey.leaveNest,
      content: Text(
        AppLocalizations.of(context)
                ?.getFormat('nestLeaveConfirm', {'name': nest.name}) ??
            '\'${nest.name}\' 둥지에서 정말 나가시겠습니까?',
        textAlign: TextAlign.center,
        style: const TextStyle(fontFamily: 'BMJUA', fontSize: 16),
      ),
      actions: [
        AppDialogAction(
          label: AppLocalizations.of(context)?.get('cancel') ?? '취소',
          onPressed: (ctx) => Navigator.pop(ctx),
        ),
        AppDialogAction(
          label: AppLocalizations.of(context)?.get('nestWithdraw') ?? '나가기',
          isPrimary: true,
          onPressed: (ctx) async {
            final authController =
                Provider.of<AuthController>(context, listen: false);
            final userId = authController.currentUser?.uid;
            if (userId == null) return;

            final nestController =
                Provider.of<NestController>(context, listen: false);
            try {
              await nestController.leaveNest(nest.id, userId);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (!mounted) return;
              context.pop();
              MemoNotification.show(
                  context,
                  AppLocalizations.of(context)?.get('nestLeaveSuccess') ??
                      '둥지에서 퇴장했습니다.');
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
        widget.nest.id,
      );
    }
  }

  void _showUpgradeDialog(int totalGaji) {
    AppDialog.show(
      context: context,
      key: AppDialogKey.nestUpgrade,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Image.asset(
            'assets/images/Nest_Level2.png',
            width: 150,
            height: 150,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/branch.png', width: 24, height: 24),
              const SizedBox(width: 8),
              Text(
                '1000',
                style: TextStyle(
                  fontFamily: 'BMJUA',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: totalGaji >= 1000
                      ? const Color(0xFF4E342E)
                      : Colors.red.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)?.get('nestUpgradeConfirm') ??
                '둥지를 레벨 2로 업그레이드 하시겠습니까?\n배경이 바뀌고 정원이 15명으로 늘어납니다.\n(일기 작성 시 가지 +5% 버프 획득)',
            style: const TextStyle(
              fontFamily: 'BMJUA',
              fontSize: 16,
              color: Color(0xFF4E342E),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        AppDialogAction(
          label: AppLocalizations.of(context)?.get('cancel') ?? '취소',
          onPressed: (ctx) => Navigator.pop(ctx),
        ),
        AppDialogAction(
          label: AppLocalizations.of(context)?.get('upgrade') ?? '업그레이드',
          isPrimary: true,
          isEnabled: AlwaysStoppedAnimation(totalGaji >= 1000),
          onPressed: (ctx) async {
            final nestController =
                Provider.of<NestController>(context, listen: false);
            try {
              await nestController.upgradeNest(widget.nest.id);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (!mounted) return;
              AppDialog.show(
                context: context,
                key: AppDialogKey.nestUpgradeSuccess,
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    Image.asset(
                      'assets/images/Nest_Level2.png',
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)?.get('nestUpgradeSuccess') ??
                          '둥지가 레벨 2로 업그레이드 되었습니다!',
                      style: const TextStyle(
                        fontFamily: 'BMJUA',
                        fontSize: 16,
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
                clipBehavior: Clip.none,
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
                      right: 20,
                      child: IconButton(
                        icon: Image.asset(
                          'assets/icons/Edit_Button.png',
                          width: 18,
                          height: 18,
                          fit: BoxFit.contain,
                        ),
                        onPressed: () => _showEditNestDialog(nestData),
                      ),
                    )
                  else
                    Positioned(
                      right: 15,
                      child: IconButton(
                        icon: const Icon(Icons.logout,
                            color: Color(0xFF4E342E), size: 18),
                        onPressed: () => _showLeaveNestConfirmDialog(nestData),
                      ),
                    ),
                  Positioned(
                    right: -55, // Container 오른쪽 바깥으로 조금 더 이동
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/Circle_Area.png'),
                          fit: BoxFit.fill,
                          opacity: 0.7,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person,
                              size: 12, color: Color(0xFF4E342E)),
                          const SizedBox(width: 2),
                          Text(
                            AppLocalizations.of(context)
                                    ?.getFormat('nestPeopleCount', {
                                  'current':
                                      nestData.memberIds.length.toString(),
                                  'max': nestData.level == 1 ? '10' : '15'
                                }) ??
                                '${nestData.memberIds.length}/${nestData.level == 1 ? 10 : 15}',
                            style: const TextStyle(
                              color: Color(0xFF4E342E),
                              fontFamily: 'BMJUA',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(left: 32.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Transform.translate(
              offset: const Offset(0, 0), // -10 -> 0 (조금 아래로)
              child: _ScaleTapButton(
                onTap: () {
                  _saveLastViewed(); // 보았으므로 시간 저장
                  showDialog(
                    context: context,
                    builder: (context) => TodaySpeakDialog(
                      nestId: widget.nest.id,
                      nestName: widget.nest.name,
                    ),
                  );
                },
                child: Consumer<NestController>(
                  builder: (context, nestController, child) {
                    return StreamBuilder<List<Map<String, dynamic>>>(
                      stream: nestController.getNestMessagesStream(
                          widget.nest.id, DateTime.now()),
                      builder: (context, snapshot) {
                        final messages = snapshot.data ?? [];
                        final hasNew = messages.any((m) =>
                            (_lastViewedTodaySpeak == null ||
                                (m['createdAt'] as DateTime)
                                    .isAfter(_lastViewedTodaySpeak!)) &&
                            m['userId'] !=
                                Provider.of<AuthController>(context,
                                        listen: false)
                                    .currentUser
                                    ?.uid);

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Image.asset(
                              'assets/icons/TodaySpeak_Button.png',
                              width: 75,
                              height: 75,
                            ),
                            if (hasNew)
                              Positioned(
                                top: 5,
                                right: 5,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            Transform.translate(
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
                    padding:
                        const EdgeInsets.only(top: 5), // 시각적 중앙 보정 (텍스트 아래로)
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
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 3,
        onTap: (_) {},
      ),
      body: StreamBuilder<NestModel?>(
        stream: _nestStream,
        builder: (context, nestSnapshot) {
          if (nestSnapshot.hasError) {
            return const SizedBox.shrink(); // 삭제 후 에러 발생 시 공백 처리 (이미 화면 이동 중)
          }
          final nestData = nestSnapshot.data ?? widget.nest;

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: ResizeImage(
                    AssetImage(nestData.level == 1
                        ? 'assets/images/Nest_Level1.png'
                        : 'assets/images/Nest_Level2.png'),
                    width: 1080),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // 둥지 상단: 공통 가지 수량 및 기부 버튼
                  if (nestData.level >= 2)
                    Transform.translate(
                      offset: const Offset(0, -10),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image:
                                AssetImage('assets/images/Buff_Background.png'),
                            fit: BoxFit.fill,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('✨', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text(
                              AppLocalizations.of(context)?.getFormat(
                                      'nestBuffActive', {
                                    'bonus': nestData.level == 2 ? '5' : '10'
                                  }) ??
                                  '일기 작성 가지 +${nestData.level == 2 ? 5 : 10}% 버프 적용중!',
                              style: const TextStyle(
                                color: Color(0xFF4E342E),
                                fontFamily: 'BMJUA',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8.0,
                      runSpacing: 8.0,
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
                        // 가지 모으기 버튼
                        _ScaleTapButton(
                          onTap: () => _showCollectDialog(nestData.totalGaji),
                          child: Container(
                            width: 75,
                            height: 32,
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image:
                                    AssetImage('assets/images/Add_Button.png'),
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
                        // 업그레이드 버튼 (방장 && 레벨1)
                        if (Provider.of<AuthController>(context, listen: false)
                                    .currentUser
                                    ?.uid ==
                                nestData.creatorId &&
                            nestData.level == 1)
                          Opacity(
                            opacity: 1.0, // 항상 클릭 가능하므로 불투명도 제거 (또는 1.0 유지)
                            child: _ScaleTapButton(
                              onTap: () =>
                                  _showUpgradeDialog(nestData.totalGaji),
                              child: Container(
                                width: 90,
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
                                          ?.get('nestUpgrade') ??
                                      '업그레이드',
                                  style: const TextStyle(
                                    color: Color(0xFF4E342E),
                                    fontFamily: 'BMJUA',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<List<UserModel>>(
                      stream: _membersStream,
                      builder: (context, memberSnapshot) {
                        if (memberSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (memberSnapshot.hasError) {
                          return Center(
                              child: Text(AppLocalizations.of(context)
                                      ?.get('errorOccurred') ??
                                  '오류가 발생했습니다.'));
                        }
                        final members = memberSnapshot.data ?? [];

                        if (members.isEmpty) {
                          return Center(
                              child: Text(
                                  AppLocalizations.of(context)
                                          ?.get('nestNoMembers') ??
                                      '아직 멤버가 없습니다.',
                                  style: const TextStyle(fontFamily: 'BMJUA')));
                        }

                        return LayoutBuilder(builder: (context, constraints) {
                          final positions = nestData.level == 1
                              ? _level1Positions
                              : _level2Positions;

                          return Stack(
                            clipBehavior: Clip.none,
                            children: members.asMap().entries.map((entry) {
                              final index = entry.key;
                              final member = entry.value;

                              final posOffset = index < positions.length
                                  ? positions[index]
                                  : const Offset(0.5, 0.5);

                              final left =
                                  constraints.maxWidth * posOffset.dx - 50;
                              final top =
                                  constraints.maxHeight * posOffset.dy - 50;

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
                                              'days': member
                                                  .displayConsecutiveDays
                                                  .toString()
                                            }) ??
                                            '${member.nickname}: 연속 ${member.displayConsecutiveDays}일! (더블탭해서 찌르기)');
                                  },
                                  child: Builder(
                                    builder: (context) {
                                      final socialController =
                                          Provider.of<SocialController>(context,
                                              listen: false);
                                      final isAwake = socialController
                                          .isFriendAwake(member);
                                      final friendMood = socialController
                                          .getFriendMood(member);

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
                                              SizedBox(
                                                width: 60,
                                                height: 60,
                                                child: Stack(
                                                  alignment: Alignment.center,
                                                  clipBehavior: Clip.none,
                                                  children: [
                                                    // 캐릭터 그림자
                                                    Positioned(
                                                      bottom: -3,
                                                      child: AnimatedOpacity(
                                                        duration:
                                                            const Duration(
                                                                milliseconds:
                                                                    200),
                                                        opacity:
                                                            _jumpingMemberIds
                                                                    .contains(
                                                                        member
                                                                            .uid)
                                                                ? 0.15
                                                                : 0.25,
                                                        child: Container(
                                                          width: 44,
                                                          height: 12,
                                                          decoration:
                                                              BoxDecoration(
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
                                                    // 점프하는 캐릭터
                                                    AnimatedContainer(
                                                      duration: const Duration(
                                                          milliseconds: 200),
                                                      curve: Curves.easeInOut,
                                                      transform: Matrix4
                                                          .translationValues(
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
                                                        characterLevel: member
                                                            .characterLevel,
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
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4),
                                                decoration: const BoxDecoration(
                                                  image: DecorationImage(
                                                    image: AssetImage(
                                                        'assets/images/Circle_Area.png'),
                                                    fit: BoxFit.fill,
                                                    opacity: 0.4,
                                                  ),
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
                                              const SizedBox(height: 2),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                decoration: const BoxDecoration(
                                                  image: DecorationImage(
                                                    image: AssetImage(
                                                        'assets/images/Circle_Area.png'),
                                                    fit: BoxFit.fill,
                                                    opacity: 0.4,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Text('🔥',
                                                        style: TextStyle(
                                                            fontSize: 10)),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      '${member.displayConsecutiveDays}${AppLocalizations.of(context)?.get('dayUnit') ?? '일'}',
                                                      style: const TextStyle(
                                                        fontFamily: 'BMJUA',
                                                        color:
                                                            Color(0xFF4E342E),
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
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
                                                    padding:
                                                        const EdgeInsets.only(
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
          );
        },
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
