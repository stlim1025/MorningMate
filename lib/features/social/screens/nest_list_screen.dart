import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;

import '../../../core/localization/app_localizations.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/widgets/memo_notification.dart';
import '../controllers/nest_controller.dart';
import '../../../models/nest_model.dart';
import '../../../data/models/user_model.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../character/widgets/character_display.dart';
import '../controllers/social_controller.dart';

class NestListScreen extends StatefulWidget {
  const NestListScreen({super.key});

  @override
  State<NestListScreen> createState() => _NestListScreenState();
}

class _NestListScreenState extends State<NestListScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(
        const AssetImage('assets/images/Nest_Background.png'), context);
  }

  void _showCreateNestDialog() {
    final nestController = Provider.of<NestController>(context, listen: false);
    final authController = Provider.of<AuthController>(context, listen: false);
    final userId = authController.currentUser?.uid;

    if (userId != null) {
      final createdNestsCount = nestController.myNests
          .where((nest) => nest.creatorId == userId)
          .length;
      if (createdNestsCount >= 2) {
        MemoNotification.show(
            context,
            AppLocalizations.of(context)?.get('nestMaxCountError') ??
                '둥지는 최대 2개까지만 생성할 수 있습니다.');
        return;
      }
    }

    final TextEditingController nameController = TextEditingController();

    AppDialog.show(
      context: context,
      key: AppDialogKey.createNest,
      content: PopupTextField(
        controller: nameController,
        hintText: AppLocalizations.of(context)?.get('nestNameHint') ??
            '둥지 이름을 입력하세요 (최대 15자)',
        maxLength: 15,
        fontFamily: 'KyoboHandwriting2024psw',
      ),
      actions: [
        AppDialogAction(
          label: AppLocalizations.of(context)?.get('cancel') ?? '취소',
          onPressed: (ctx) => Navigator.of(ctx).pop(),
        ),
        AppDialogAction(
          label: AppLocalizations.of(context)?.get('create') ?? '만들기',
          isPrimary: true,
          onPressed: (ctx) async {
            final name = nameController.text.trim();
            if (name.isEmpty) return;

            final authController =
                Provider.of<AuthController>(context, listen: false);
            final nestController =
                Provider.of<NestController>(context, listen: false);
            final userId = authController.currentUser?.uid;

            if (userId != null) {
              try {
                final nestId = await nestController.createNest(name, userId);

                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();

                if (!mounted) return;

                // 생성된 둥지로 바로 이동
                context.push('/nest_room/$nestId');

                MemoNotification.show(
                    context,
                    AppLocalizations.of(context)?.get('nestCreateSuccess') ??
                        '둥지가 생성되었습니다! ✨');
              } catch (e) {
                if (ctx.mounted) {
                  MemoNotification.show(ctx, e.toString());
                }
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: ResizeImage(AssetImage('assets/images/Nest_Background.png'),
                width: 1080),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          bottom: false, // Let content handle bottom padding for edge-to-edge
          child: Padding(
            padding: EdgeInsets.only(
                bottom: (Platform.isIOS ? 50.0 : 60.0) +
                    MediaQuery.of(context).viewPadding.bottom),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                SizedBox(height: Platform.isIOS ? 8 : 16),
                // Title
                Container(
                  width: Platform.isIOS ? 220 : 260,
                  height: Platform.isIOS ? 54 : 64,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/NestTitle_Area.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/icons/Nest_Icon.png',
                          width: Platform.isIOS ? 28 : 32,
                          height: Platform.isIOS ? 28 : 32),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)?.get('nestList') ??
                            'Nest List',
                        style: TextStyle(
                          color: const Color(0xFF4E342E),
                          fontWeight: FontWeight.bold,
                          fontFamily: 'BMJUA',
                          fontSize: Platform.isIOS ? 18 : 20,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: Platform.isIOS ? 12 : 20),

                // Nest Invites Section
                Consumer<NestController>(
                    builder: (context, nestController, child) {
                  if (nestController.nestRequests.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(
                            'assets/images/FriendRequest_Background.png'),
                        fit: BoxFit.fill,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.mail_outline,
                                color: Color(0xFF4E342E), size: 24),
                            const SizedBox(width: 12),
                            Text(
                              AppLocalizations.of(context)
                                      ?.get('nestInviteTitle') ??
                                  '새로운 둥지 초대',
                              style: const TextStyle(
                                color: Color(0xFF4E342E),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'BMJUA',
                              ),
                            ),
                            const Spacer(),
                            Transform.translate(
                              offset: const Offset(0, -2),
                              child: Text(
                                '${nestController.nestRequests.length}',
                                style: const TextStyle(
                                  color: Color(0xFF8B7355),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  fontFamily: 'BMJUA',
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...nestController.nestRequests.map((req) {
                          final inviteId = req['inviteId'] as String;
                          final nestId = req['nestId'] as String;
                          final nestName = req['nestName'] as String;
                          final sender = req['sender'] as UserModel;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4E342E)
                                        .withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Center(
                                    child: CharacterDisplay(
                                      characterLevel: sender.characterLevel,
                                      equippedItems:
                                          sender.equippedCharacterItems,
                                      size: 44,
                                      enableAnimation: false,
                                      isAwake: context
                                          .read<SocialController>()
                                          .isFriendAwake(sender),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sender.nickname,
                                        style: const TextStyle(
                                          color: Color(0xFF4E342E),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          fontFamily: 'BMJUA',
                                        ),
                                      ),
                                      Text(
                                        AppLocalizations.of(context)?.getFormat(
                                                'nestLabel',
                                                {'name': nestName}) ??
                                            '둥지: $nestName',
                                        style: const TextStyle(
                                          color: Color(0xFF8B7355),
                                          fontSize: 11,
                                          fontFamily: 'BMJUA',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // 거절 버튼
                                GestureDetector(
                                  onTap: () async {
                                    await nestController
                                        .rejectNestInvite(inviteId);
                                  },
                                  child: Container(
                                    width: 50,
                                    height: 32,
                                    decoration: const BoxDecoration(
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
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'BMJUA',
                                          color: Color(0xFF8B7355),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // 수락 버튼
                                GestureDetector(
                                  onTap: () async {
                                    final authCtrl =
                                        Provider.of<AuthController>(context,
                                            listen: false);
                                    if (authCtrl.currentUser != null) {
                                      try {
                                        await nestController.acceptNestInvite(
                                            inviteId,
                                            nestId,
                                            authCtrl.currentUser!.uid);
                                      } catch (e) {
                                        if (context.mounted &&
                                            e
                                                .toString()
                                                .contains('nestFullError')) {
                                          AppDialog.show(
                                            context: context,
                                            key: AppDialogKey.inviteToNest,
                                            content: Text(
                                              AppLocalizations.of(context)
                                                      ?.get('nestFullError') ??
                                                  '10명이 꽉차서 더 이상 입장할 수 없습니다.',
                                              style: const TextStyle(
                                                  fontFamily: 'BMJUA',
                                                  fontSize: 16),
                                              textAlign: TextAlign.center,
                                            ),
                                            actions: [
                                              AppDialogAction(
                                                label:
                                                    AppLocalizations.of(context)
                                                            ?.get('confirm') ??
                                                        '확인',
                                                onPressed: (c) =>
                                                    Navigator.pop(c),
                                              ),
                                            ],
                                          );
                                        }
                                      }
                                    }
                                  },
                                  child: Container(
                                    width: 50,
                                    height: 32,
                                    decoration: const BoxDecoration(
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
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'BMJUA',
                                          color: Color(0xFF4E342E),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  );
                }),

                SizedBox(
                    height:
                        Platform.isIOS ? 8 : 12), // Participating Nests Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 200,
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image:
                                AssetImage('assets/images/SubTitle_Area.png'),
                            fit: BoxFit.fill,
                          ),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          AppLocalizations.of(context)
                                  ?.get('participatingNests') ??
                              'Participating Nests',
                          style: const TextStyle(
                            color: Color(0xFF4E342E),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'BMJUA',
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -5), // 조금 위로 이동
                        child: _ScaleTapButton(
                          onTap: _showCreateNestDialog,
                          child: Container(
                            width: 120,
                            height: 44,
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(
                                    'assets/icons/AddFriend_Button.png'),
                                fit: BoxFit.contain,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              AppLocalizations.of(context)?.get('createNest') ??
                                  'Create Nest',
                              style: const TextStyle(
                                color: Color(0xFF4E342E),
                                fontWeight: FontWeight.bold,
                                fontFamily: 'BMJUA',
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: Platform.isIOS ? 8 : 12),

                Container(
                  alignment: Alignment.topCenter,
                  child: Consumer<NestController>(
                      builder: (context, nestController, child) {
                    final currUser =
                        Provider.of<AuthController>(context, listen: false)
                            .currentUser;
                    final participatingNests = nestController.myNests
                        .where((n) => n.creatorId != currUser?.uid)
                        .toList();

                    if (participatingNests.isEmpty) {
                      return Container(
                        width: double.infinity,
                        height: 100,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/NoNest_Area.png'),
                            fit: BoxFit.fill,
                          ),
                        ),
                        child: Row(
                          children: [
                            Spacer(flex: 3),
                            Text(
                              AppLocalizations.of(context)
                                      ?.get('nestNoParticipating') ??
                                  '참여중인 둥지가 없어요',
                              style: const TextStyle(
                                color: Color(0xFF4E342E),
                                fontFamily: 'BMJUA',
                                fontSize: 16,
                              ),
                            ),
                            Spacer(flex: 1),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: participatingNests.length,
                        itemBuilder: (context, index) {
                          final nest = participatingNests[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _buildNestCard(
                              nest: nest,
                              isMyNest: false,
                            ),
                          );
                        });
                  }),
                ),

                SizedBox(height: Platform.isIOS ? 8 : 16),

                // My Nests Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 200,
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image:
                                AssetImage('assets/images/SubTitle_Area.png'),
                            fit: BoxFit.fill,
                          ),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          AppLocalizations.of(context)?.get('myNests') ??
                              'My Nests',
                          style: const TextStyle(
                            color: Color(0xFF4E342E),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'BMJUA',
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: Platform.isIOS ? 8 : 12),

                // My Nests List (GridView for side-by-side like the image)
                Consumer<NestController>(
                    builder: (context, nestController, child) {
                  final currUser =
                      Provider.of<AuthController>(context, listen: false)
                          .currentUser;
                  final myNestsList = nestController.myNests
                      .where((n) => n.creatorId == currUser?.uid)
                      .toList();

                  if (myNestsList.isEmpty) {
                    return GestureDetector(
                      onTap: _showCreateNestDialog,
                      child: Container(
                        height: 220,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.fromLTRB(0, 95, 0, 0),
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image:
                                AssetImage('assets/images/NoMyNest_Area.png'),
                            fit: BoxFit.fill,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)
                                      ?.get('nestNoMyNests') ??
                                  '내가 만든 둥지가 없어요',
                              style: const TextStyle(
                                color: Color(0xFF4E342E),
                                fontFamily: 'BMJUA',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppLocalizations.of(context)
                                      ?.get('nestCreateNew') ??
                                  '새로운 둥지를 만들어 보세요!',
                              style: const TextStyle(
                                color: Color(0xFF8B7355),
                                fontFamily: 'BMJUA',
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 19),
                            Padding(
                              padding: const EdgeInsets.only(right: 15),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add,
                                      color: Color(0xFF4E342E), size: 20),
                                  SizedBox(width: 4),
                                  Text(
                                    AppLocalizations.of(context)
                                            ?.get('createNestTitle') ??
                                        '둥지 만들기',
                                    style: const TextStyle(
                                      color: Color(0xFF4E342E),
                                      fontFamily: 'BMJUA',
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(2, (index) {
                        final isLast = index == 1;
                        if (index < myNestsList.length) {
                          return Expanded(
                            child: Padding(
                              padding:
                                  EdgeInsets.only(right: isLast ? 0 : 12.0),
                              child: _buildNestCard(
                                nest: myNestsList[index],
                                isMyNest: true,
                              ),
                            ),
                          );
                        } else {
                          return Expanded(
                            child: Padding(
                              padding:
                                  EdgeInsets.only(right: isLast ? 0 : 12.0),
                            ),
                          );
                        }
                      }),
                    ),
                  );
                }),
                SizedBox(height: (Platform.isIOS ? 40 : 60)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNestCard({
    required NestModel nest,
    required bool isMyNest,
  }) {
    final String name = nest.name;
    final int level = nest.level;
    final int currentPeople = nest.memberIds.length;
    final int maxPeople =
        nest.level == 1 ? 10 : 15; // Level 1 is 10, others are 15
    final String desc = nest.description.isNotEmpty
        ? nest.description
        : (AppLocalizations.of(context)?.get('nestPlaceholderDesc') ??
            '우리의 둥지 이야기');

    String activityTime =
        AppLocalizations.of(context)?.get('nestActivityJustNow') ?? '방금 전 활동';
    final diff = DateTime.now().difference(nest.lastActivityAt);
    if (diff.inDays > 0) {
      activityTime = AppLocalizations.of(context)?.getFormat(
              'nestActivityDaysAgo', {'days': diff.inDays.toString()}) ??
          '${diff.inDays}일 전 활동';
    } else if (diff.inHours > 0) {
      activityTime = AppLocalizations.of(context)?.getFormat(
              'nestActivityHoursAgo', {'hours': diff.inHours.toString()}) ??
          '${diff.inHours}시간 전 활동';
    } else if (diff.inMinutes > 0) {
      activityTime = AppLocalizations.of(context)?.getFormat(
              'nestActivityMinutesAgo',
              {'minutes': diff.inMinutes.toString()}) ??
          '${diff.inMinutes}분 전 활동';
    }
    final Widget nestIcon = Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Image.asset(
            'assets/icons/Nest_Icon.png',
            fit: BoxFit.contain,
          ),
        ),
        Positioned(
          top: -8,
          left: 0,
          child: Container(
            width: 40,
            height: 20,
            alignment: Alignment.center,
            child: Text(
              AppLocalizations.of(context)
                      ?.getFormat('nestLevel', {'level': level.toString()}) ??
                  'Lv.$level',
              style: const TextStyle(
                color: Color(0xFF4E342E),
                fontFamily: 'KyoboHandwriting2024psw',
                fontSize: 12,
                height: 1.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );

    final Widget peopleCountWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFEFE5D8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        AppLocalizations.of(context)?.getFormat('nestPeopleCount', {
              'current': currentPeople.toString(),
              'max': maxPeople.toString()
            }) ??
            '$currentPeople/$maxPeople',
        style: const TextStyle(
          color: Color(0xFF4E342E),
          fontFamily: 'BMJUA',
          fontSize: 12,
        ),
      ),
    );

    // 내 둥지용 작은 아이콘 생성
    final Widget myNestIcon = Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: Image.asset(
            'assets/icons/Nest_Icon.png',
            fit: BoxFit.contain,
          ),
        ),
        Positioned(
          top: -26,
          left: 2,
          child: Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/Circle_Area.png'),
                fit: BoxFit.contain,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                AppLocalizations.of(context)
                        ?.getFormat('nestLevel', {'level': level.toString()}) ??
                    'Lv.$level',
                style: const TextStyle(
                  color: Color(0xFF4E342E),
                  fontFamily: 'KyoboHandwriting2024psw',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );

    return GestureDetector(
      onTap: () {
        context.push('/nest_room/${nest.id}', extra: nest);
      },
      child: Container(
        height: isMyNest ? 180 : null,
        padding: isMyNest
            ? const EdgeInsets.fromLTRB(12, 12, 12, 12)
            : const EdgeInsets.fromLTRB(16, 20, 16, 20),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(isMyNest
                ? 'assets/icons/MyNest_Area.png'
                : 'assets/icons/NestList_Area.png'),
            fit: BoxFit.fill,
          ),
        ),
        child: isMyNest
            ? Column(
                children: [
                  const SizedBox(height: 32),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 좌측 둥지 아이콘
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: myNestIcon,
                      ),
                      const SizedBox(width: 8),
                      // 우측 정보 (이름, 참여인원)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: Color(0xFF4E342E),
                                fontWeight: FontWeight.bold,
                                fontFamily: 'BMJUA',
                                fontSize: 13,
                                height: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.visible,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.person,
                                    size: 14, color: Color(0xFF7A6B5D)),
                                const SizedBox(width: 4),
                                Text(
                                  '$currentPeople/$maxPeople',
                                  style: const TextStyle(
                                    color: Color(0xFF7A6B5D),
                                    fontFamily: 'BMJUA',
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.access_time,
                                    size: 14, color: Color(0xFF7A6B5D)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    activityTime,
                                    style: const TextStyle(
                                      color: Color(0xFF7A6B5D),
                                      fontFamily: 'BMJUA',
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      desc,
                      style: const TextStyle(
                        color: Color(0xFF7A6B5D),
                        fontFamily: 'BMJUA',
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  // 하단 입장하기 버튼
                  Container(
                    width: double.infinity,
                    height: 32,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.center,
                    child: Text(
                      AppLocalizations.of(context)?.get('nestEnter') ??
                          '입장하기 >',
                      style: const TextStyle(
                        fontFamily: 'BMJUA',
                        fontSize: 14,
                        color: Color(0xFF4E342E),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  nestIcon,
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  color: Color(0xFF4E342E),
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'BMJUA',
                                  fontSize: 18,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            peopleCountWidget,
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          desc,
                          style: const TextStyle(
                            color: Color(0xFF7A6B5D),
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.access_time,
                                size: 14, color: Color(0xFFA18B75)),
                            const SizedBox(width: 4),
                            Text(
                              activityTime,
                              style: const TextStyle(
                                color: Color(0xFFA18B75),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
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
