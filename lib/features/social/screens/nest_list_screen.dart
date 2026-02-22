import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
    final TextEditingController nameController = TextEditingController();

    AppDialog.show(
      context: context,
      key: AppDialogKey.createNest,
      content: PopupTextField(
        controller: nameController,
        hintText: '둥지 이름을 입력하세요',
        maxLength: 10,
      ),
      actions: [
        AppDialogAction(
          label: '취소',
          onPressed: (ctx) => Navigator.of(ctx).pop(),
        ),
        AppDialogAction(
          label: '만들기',
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
                await nestController.createNest(name, userId);
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  MemoNotification.show(context, '둥지가 생성되었습니다!');
                }
              } catch (e) {
                if (ctx.mounted) {
                  MemoNotification.show(context, e.toString());
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
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Title
                Container(
                  width: 200,
                  height: 50,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/SubTitle_Area.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/icons/Nest_Icon.png',
                          width: 32, height: 32),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)?.get('nestList') ??
                            'Nest List',
                        style: const TextStyle(
                          color: Color(0xFF4E342E),
                          fontWeight: FontWeight.bold,
                          fontFamily: 'BMJUA',
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

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
                            const Text(
                              '새로운 둥지 초대',
                              style: TextStyle(
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
                                      await nestController.acceptNestInvite(
                                          inviteId,
                                          nestId,
                                          authCtrl.currentUser!.uid);
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

                const SizedBox(height: 12), // Participating Nests Section
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
                      GestureDetector(
                        onTap: () {
                          _showCreateNestDialog();
                        },
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
                                '+ Create Nest',
                            style: const TextStyle(
                              color: Color(0xFF4E342E),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'BMJUA',
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Participating Nests List
                Container(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height * 0.28,
                  ),
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
                      return const Padding(
                        padding: EdgeInsets.only(top: 32.0),
                        child: Text(
                          '참여 중인 둥지가 없습니다.',
                          style: TextStyle(
                              color: Color(0xFF7A6B5D), fontFamily: 'BMJUA'),
                        ),
                      );
                    }

                    return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
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

                const SizedBox(height: 16),

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
                const SizedBox(height: 12),

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
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        '내가 만든 둥지가 없습니다.',
                        style: TextStyle(
                            color: Color(0xFF7A6B5D), fontFamily: 'BMJUA'),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                const SizedBox(height: 80), // Padding for bottom
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
    final int maxPeople = 20; // Default or configured per level
    final String desc = '우리의 둥지 이야기'; // placeholder for now or field of nest

    String activityTime = '방금 전 활동';
    final diff = DateTime.now().difference(nest.lastActivityAt);
    if (diff.inDays > 0) {
      activityTime = '${diff.inDays}일 전 활동';
    } else if (diff.inHours > 0) {
      activityTime = '${diff.inHours}시간 전 활동';
    } else if (diff.inMinutes > 0) {
      activityTime = '${diff.inMinutes}분 전 활동';
    }
    final Widget nestIcon = Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFEFE5D8),
            borderRadius: BorderRadius.circular(40),
            image: const DecorationImage(
              image: AssetImage('assets/icons/Nest_Icon.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: -8,
          left: -8,
          child: Container(
            width: 40,
            height: 20,
            alignment: Alignment.center,
            child: Text(
              AppLocalizations.of(context)
                      ?.getFormat('nestLevel', {'level': level.toString()}) ??
                  'Lv.$level',
              style: const TextStyle(
                color: Color(
                    0xFF4E342E), // Changed to dark brown because white would be invisible
                fontFamily: 'BMJUA',
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

    return GestureDetector(
      onTap: () {
        context.push('/nest_room', extra: nest);
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/Item_Background.png'),
            fit: BoxFit.fill,
          ),
        ),
        child: isMyNest
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  nestIcon,
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Color(0xFF4E342E),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'BMJUA',
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  peopleCountWidget,
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
