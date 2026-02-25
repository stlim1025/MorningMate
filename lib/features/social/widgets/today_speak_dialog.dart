import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../controllers/nest_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/widgets/memo_notification.dart';
import '../../../services/nest_service.dart';
import '../../../data/models/user_model.dart';
import '../../character/widgets/character_display.dart';
import '../controllers/social_controller.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/app_dialog.dart';

class TodaySpeakDialog extends StatefulWidget {
  final String nestId;
  final String nestName;

  const TodaySpeakDialog({
    Key? key,
    required this.nestId,
    required this.nestName,
  }) : super(key: key);

  @override
  State<TodaySpeakDialog> createState() => _TodaySpeakDialogState();
}

class _TodaySpeakDialogState extends State<TodaySpeakDialog> {
  DateTime _currentDate = DateTime.now();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSubmitting = false;

  late Stream<List<UserModel>> _membersStream;
  late Stream<List<Map<String, dynamic>>> _messagesStream;

  @override
  void initState() {
    super.initState();
    _membersStream = NestService().getNestMembersStream(widget.nestId);
    _updateMessagesStream();
  }

  void _updateMessagesStream() {
    _messagesStream = Provider.of<NestController>(context, listen: false)
        .getNestMessagesStream(widget.nestId, _currentDate);
  }

  void _previousDay() {
    setState(() {
      _currentDate = _currentDate.subtract(const Duration(days: 1));
      _updateMessagesStream();
    });
  }

  void _nextDay() {
    setState(() {
      if (_currentDate
          .isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
        _currentDate = _currentDate.add(const Duration(days: 1));
      } else {
        _currentDate = DateTime.now();
      }
      _updateMessagesStream();
    });
  }

  Future<void> _submitMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final authController = Provider.of<AuthController>(context, listen: false);
    final user = authController.currentUser;
    final userModel = authController.userModel;
    if (user == null || userModel == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final nestController =
          Provider.of<NestController>(context, listen: false);
      final earnedReward = await nestController.postNestMessage(
        widget.nestId,
        user.uid,
        userModel.nickname,
        widget.nestName,
        message,
      );
      _messageController.clear();
      _focusNode.unfocus();

      setState(() {
        _currentDate = DateTime.now();
        _updateMessagesStream();
      });

      if (earnedReward && mounted) {
        await AppDialog.show(
          context: context,
          key: AppDialogKey.todaySpeakReward,
        );
      }
    } catch (e) {
      if (mounted) {
        MemoNotification.show(
            context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateString = DateFormat('yyyy.MM.dd').format(_currentDate);
    final isToday = DateFormat('yyyy-MM-dd').format(_currentDate) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    final authController = Provider.of<AuthController>(context, listen: false);
    final currentUserId = authController.currentUser?.uid;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/TodaySpeak_Background.png'),
                fit: BoxFit.fill,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Image.asset('assets/icons/X_Button.png',
                        width: 32, height: 32),
                  ),
                ),
                Column(
                  children: [
                    SizedBox(
                      height: 120, // Enough height for the header elements
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 오늘의 한마디 (더 아래로)
                          Positioned(
                            top: 50, // 조금 더 위로
                            child: Text(
                              AppLocalizations.of(context)
                                      ?.get('todaySpeakTitle') ??
                                  '오늘의 한마디',
                              style: TextStyle(
                                fontFamily: 'KyoboHandwriting2024psw',
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4E342E),
                              ),
                            ),
                          ),
                          // 날짜 (지금 위치 그대로)
                          Positioned(
                            top: 82, // Keep same relative visual position
                            child: Text(
                              dateString,
                              style: const TextStyle(
                                fontFamily: 'BMJUA',
                                fontSize: 14,
                                color: Color(0xFF4E342E),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // 이전날 버튼 (조금 더 키우고, 중앙으로, 위로)
                          Positioned(
                            top: 60, // Shift up
                            left: 45, // 양끝단으로 더 이동
                            child: GestureDetector(
                              onTap: _previousDay,
                              child: Container(
                                width: 60, // 조금 더 줄이기
                                height: 34,
                                decoration: const BoxDecoration(
                                  image: DecorationImage(
                                    image: AssetImage(
                                        'assets/images/Circle_Area.png'),
                                    fit: BoxFit.fill,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  AppLocalizations.of(context)
                                          ?.get('previousDayBtn') ??
                                      '< 이전날',
                                  style: TextStyle(
                                    fontFamily: 'BMJUA',
                                    fontSize: 13,
                                    color: Color(0xFF4E342E),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // 다음날 버튼
                          Positioned(
                            top: 60, // Shift up
                            right: 45, // 양끝단으로 더 이동
                            child: GestureDetector(
                              onTap: isToday ? null : _nextDay,
                              child: Opacity(
                                opacity:
                                    isToday ? 0.4 : 1.0, // 불투명 적용 (회색 필터 제거)
                                child: Container(
                                  width: 60, // 조금 더 줄이기
                                  height: 34,
                                  decoration: const BoxDecoration(
                                    image: DecorationImage(
                                      image: AssetImage(
                                          'assets/images/Circle_Area.png'),
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    AppLocalizations.of(context)
                                            ?.get('nextDayBtn') ??
                                        '다음날 >',
                                    style: TextStyle(
                                      fontFamily: 'BMJUA',
                                      fontSize: 13,
                                      color: Color(0xFF4E342E),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Message list + Input area wrapped in StreamBuilders
                    Expanded(
                      child: StreamBuilder<List<UserModel>>(
                        stream: _membersStream,
                        builder: (context, membersSnapshot) {
                          final members = membersSnapshot.data ?? [];

                          return Consumer<NestController>(
                            builder: (context, nestController, child) {
                              return StreamBuilder<List<Map<String, dynamic>>>(
                                stream: _messagesStream,
                                builder: (context, snapshot) {
                                  final messages = snapshot.data ?? [];
                                  final alreadyPosted = messages
                                      .any((m) => m['userId'] == currentUserId);

                                  if (snapshot.connectionState ==
                                          ConnectionState.waiting &&
                                      messages.isEmpty) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  }
                                  if (snapshot.hasError && messages.isEmpty) {
                                    return Center(
                                        child: Text(
                                            '오류가 발생했습니다: ${snapshot.error}'));
                                  }

                                  return Column(
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                              left: 24.0,
                                              right: 24.0,
                                              bottom:
                                                  Platform.isIOS ? 25.0 : 0.0),
                                          child: messages.isEmpty
                                              ? Center(
                                                  child: Text(
                                                    AppLocalizations.of(context)
                                                            ?.get(
                                                                'noTodaySpeakRecords') ??
                                                        '작성된 한마디가 없습니다.',
                                                    style: TextStyle(
                                                      fontFamily: 'BMJUA',
                                                      fontSize: 18,
                                                      color: Colors.black54,
                                                    ),
                                                  ),
                                                )
                                              : ListView.separated(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 30),
                                                  physics:
                                                      const BouncingScrollPhysics(),
                                                  itemCount: messages.length,
                                                  separatorBuilder:
                                                      (context, index) =>
                                                          const SizedBox(
                                                              height: 16),
                                                  itemBuilder:
                                                      (context, index) {
                                                    final msg = messages[index];
                                                    final userId =
                                                        msg['userId'];

                                                    UserModel? authorModel;
                                                    try {
                                                      authorModel = members
                                                          .firstWhere((m) =>
                                                              m.uid == userId);
                                                    } catch (e) {
                                                      authorModel = null;
                                                    }

                                                    return Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 25.0),
                                                      child: Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Column(
                                                            children: [
                                                              if (authorModel !=
                                                                  null)
                                                                SizedBox(
                                                                  width: 50,
                                                                  height: 50,
                                                                  child:
                                                                      CharacterDisplay(
                                                                    isAwake: Provider.of<SocialController>(
                                                                            context,
                                                                            listen:
                                                                                false)
                                                                        .isFriendAwake(
                                                                            authorModel),
                                                                    characterLevel:
                                                                        authorModel
                                                                            .characterLevel,
                                                                    size: 50.0,
                                                                    equippedItems:
                                                                        authorModel
                                                                            .equippedCharacterItems,
                                                                  ),
                                                                )
                                                              else
                                                                const SizedBox(
                                                                  width: 50,
                                                                  height: 50,
                                                                  child: Icon(
                                                                      Icons
                                                                          .person,
                                                                      size: 40,
                                                                      color: Colors
                                                                          .grey),
                                                                ),
                                                              const SizedBox(
                                                                  height: 4),
                                                              Text(
                                                                msg['nickname'] ??
                                                                    AppLocalizations.of(
                                                                            context)
                                                                        ?.get(
                                                                            'unknownUser') ??
                                                                    '알 수 없음',
                                                                style:
                                                                    const TextStyle(
                                                                  fontFamily:
                                                                      'BMJUA',
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Color(
                                                                      0xFF8B5A2B),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                              width: 10),
                                                          Expanded(
                                                            child: Container(
                                                              margin:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      top: 8),
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          16,
                                                                      vertical:
                                                                          12),
                                                              decoration:
                                                                  const BoxDecoration(
                                                                image:
                                                                    DecorationImage(
                                                                  image: AssetImage(
                                                                      'assets/images/TodaySpeak_TextBox.png'),
                                                                  fit: BoxFit
                                                                      .fill,
                                                                ),
                                                              ),
                                                              child: Stack(
                                                                clipBehavior:
                                                                    Clip.none,
                                                                children: [
                                                                  Padding(
                                                                    padding: const EdgeInsets
                                                                        .only(
                                                                        right:
                                                                            20),
                                                                    child: Text(
                                                                      msg['message'] ??
                                                                          '',
                                                                      style:
                                                                          const TextStyle(
                                                                        fontFamily:
                                                                            'KyoboHandwriting2024psw',
                                                                        fontSize:
                                                                            16,
                                                                        color: Color(
                                                                            0xFF4E342E),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  if (userId ==
                                                                      currentUserId)
                                                                    Positioned(
                                                                      top: -15,
                                                                      right:
                                                                          -15,
                                                                      child:
                                                                          GestureDetector(
                                                                        onTap:
                                                                            () async {
                                                                          final confirm =
                                                                              await AppDialog.show<bool>(
                                                                            context:
                                                                                context,
                                                                            key:
                                                                                AppDialogKey.deleteTodaySpeak,
                                                                            actions: [
                                                                              AppDialogAction(
                                                                                label: AppLocalizations.of(context)?.get('cancel') ?? '취소',
                                                                                onPressed: (context) => Navigator.pop(context, false),
                                                                              ),
                                                                              AppDialogAction(
                                                                                label: AppLocalizations.of(context)?.get('delete') ?? '삭제',
                                                                                isPrimary: true,
                                                                                onPressed: (context) => Navigator.pop(context, true),
                                                                              ),
                                                                            ],
                                                                          );
                                                                          if (confirm ==
                                                                              true) {
                                                                            await nestController.deleteNestMessage(
                                                                                widget.nestId,
                                                                                _currentDate,
                                                                                msg['id']);
                                                                          }
                                                                        },
                                                                        child:
                                                                            Container(
                                                                          padding: const EdgeInsets
                                                                              .all(
                                                                              8),
                                                                          color:
                                                                              Colors.transparent,
                                                                          child:
                                                                              Image.asset(
                                                                            'assets/icons/X_Button.png',
                                                                            width:
                                                                                24,
                                                                            height:
                                                                                24,
                                                                          ),
                                                                        ),
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
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      if (isToday && !alreadyPosted)
                                        Padding(
                                          padding: EdgeInsets.fromLTRB(55, 0,
                                              50, Platform.isIOS ? 70 : 75),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.transparent,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: TextField(
                                                    controller:
                                                        _messageController,
                                                    focusNode: _focusNode,
                                                    maxLength: 25,
                                                    maxLines: 1,
                                                    scrollPadding:
                                                        const EdgeInsets.only(
                                                            bottom: 120),
                                                    style: const TextStyle(
                                                      fontFamily:
                                                          'KyoboHandwriting2024psw',
                                                      color: Color(0xFF4E342E),
                                                    ),
                                                    decoration: InputDecoration(
                                                      filled: false,
                                                      counterText: '',
                                                      hintText: AppLocalizations
                                                                  .of(context)
                                                              ?.get(
                                                                  'todaySpeakHint') ??
                                                          '오늘의 한마디를 남겨보세요..',
                                                      hintStyle:
                                                          const TextStyle(
                                                        fontFamily:
                                                            'KyoboHandwriting2024psw',
                                                        color: Colors.black54,
                                                      ),
                                                      contentPadding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                              horizontal: 16,
                                                              vertical: 12),
                                                      border: InputBorder.none,
                                                    ),
                                                    onSubmitted: (_) =>
                                                        _submitMessage(),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              GestureDetector(
                                                onTap: _isSubmitting
                                                    ? null
                                                    : _submitMessage,
                                                child: Container(
                                                  width: 52,
                                                  height: 32,
                                                  decoration:
                                                      const BoxDecoration(
                                                    image: DecorationImage(
                                                      image: AssetImage(
                                                          'assets/images/Cancel_Button.png'),
                                                      fit: BoxFit.fill,
                                                    ),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: _isSubmitting
                                                      ? const SizedBox(
                                                          width: 16,
                                                          height: 16,
                                                          child:
                                                              CircularProgressIndicator(
                                                                  color: Color(
                                                                      0xFF4E342E),
                                                                  strokeWidth:
                                                                      2),
                                                        )
                                                      : Text(
                                                          AppLocalizations.of(
                                                                      context)
                                                                  ?.get(
                                                                      'todaySpeakWrite') ??
                                                              '작성',
                                                          style:
                                                              const TextStyle(
                                                            fontFamily: 'BMJUA',
                                                            color: Color(
                                                                0xFF4E342E),
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      else if (isToday && alreadyPosted)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 88),
                                          child: Text(
                                            AppLocalizations.of(context)?.get(
                                                    'alreadyPostedTodaySpeak') ??
                                                '이미 오늘의 한마디를 작성했습니다.',
                                            style: const TextStyle(
                                              fontFamily: 'BMJUA',
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                          ),
                                        )
                                      else
                                        const SizedBox(height: 80),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
