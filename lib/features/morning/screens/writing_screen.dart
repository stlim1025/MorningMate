import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../character/widgets/character_display.dart';
import '../controllers/morning_controller.dart';
import '../../character/controllers/character_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/constants/room_assets.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/memo_notification.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/models/question_model.dart';
import '../../../data/models/diary_model.dart';
import '../../../core/widgets/network_or_asset_image.dart';
import '../../common/widgets/tutorial_overlay.dart';

class WritingScreen extends StatefulWidget {
  final QuestionModel? initialQuestion;
  final bool isEditing;
  final DiaryModel? existingDiary;
  final String? existingContent;

  const WritingScreen({
    super.key,
    this.initialQuestion,
    this.isEditing = false,
    this.existingDiary,
    this.existingContent,
  });

  @override
  State<WritingScreen> createState() => _WritingScreenState();
}

class _WritingScreenState extends State<WritingScreen> {
  late final _BlurTextEditingController _textController;
  final FocusNode _focusNode = FocusNode();
  bool _enableBlur = false;
  bool _didLoadSettings = false;
  final List<String> _selectedMoods = [];
  final PageController _pageController = PageController();
  int _currentMoodPage = 0;

  final GlobalKey _blurKey = GlobalKey();
  final GlobalKey _draftKey = GlobalKey();
  final GlobalKey _moodKey = GlobalKey();
  final GlobalKey _saveKey = GlobalKey();
  bool _showWritingTutorial = false;

  @override
  void initState() {
    super.initState();
    final morningController = context.read<MorningController>();
    morningController.startWriting();

    _textController = _BlurTextEditingController(
      blurEnabled: _enableBlur,
      colorScheme: AppColorScheme.light,
    );

    // 편집 모드 초기화
    if (widget.isEditing && widget.existingDiary != null) {
      _textController.text = widget.existingContent ?? '';
      _selectedMoods.clear();
      _selectedMoods.addAll(widget.existingDiary!.moods);

      morningController.updateCharCount(_textController.text);
    } else {
      final characterController = context.read<CharacterController>();
      final activeIds =
          characterController.currentUser?.activeEmoticonIds ?? [];
      if (activeIds.isNotEmpty) {
        _selectedMoods.add(activeIds.first);
      } else {
        _selectedMoods.add('normal');
      }

      _loadDraft();
    }

    _textController.addListener(() {
      morningController.updateCharCount(_textController.text);
    });

    // 튜토리얼 체크
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authController = context.read<AuthController>();
        if (authController.userModel != null &&
            !authController.userModel!.hasSeenWritingTutorial) {
          // 레이아웃이 완전히 자리를 잡을 수 있도록 지연 시간을 둡니다.
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() {
                _showWritingTutorial = true;
              });
            }
          });
        }
      }
    });
  }

  Future<void> _loadDraft() async {
    final morningController = context.read<MorningController>();
    final authController = context.read<AuthController>();
    final userId = authController.currentUser?.uid;

    if (userId == null) return;

    if (morningController.todayDiary != null &&
        !morningController.todayDiary!.isCompleted) {
      try {
        final content = await morningController.loadDiaryContent(
          userId: userId,
          date: morningController.todayDiary!.date,
          encryptedContent: morningController.todayDiary!.encryptedContent,
        );

        if (mounted) {
          setState(() {
            _textController.text = content;
            if (morningController.todayDiary!.moods.isNotEmpty) {
              _selectedMoods.clear();
              _selectedMoods.addAll(morningController.todayDiary!.moods);
            }
          });
          morningController.updateCharCount(content);
        }
      } catch (e) {
        debugPrint('드래프트 로드 실패: $e');
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoadSettings) {
      final authController = Provider.of<AuthController>(context);
      final userBlurEnabled = authController.userModel?.writingBlurEnabled;
      if (userBlurEnabled != null) {
        _enableBlur = userBlurEnabled;
        _textController.blurEnabled = _enableBlur;
        _textController.colorScheme =
            Theme.of(context).extension<AppColorScheme>()!;
        _didLoadSettings = true;
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/Diary_Background.png',
            fit: BoxFit.cover,
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: true,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final screenHeight = MediaQuery.of(context).size.height;
              const maxWidth = 600.0;
              final contentWidth = constraints.maxWidth > maxWidth
                  ? maxWidth
                  : constraints.maxWidth;

              final availableRowWidth = contentWidth - 60;
              final middleRowHeight = (availableRowWidth * 4 / 7);

              final minContentHeight = 100 + middleRowHeight + 260;

              final scrollHeight = minContentHeight > screenHeight
                  ? minContentHeight
                  : screenHeight;

              return GestureDetector(
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                child: SafeArea(
                  child: PopScope(
                    canPop: false,
                    onPopInvokedWithResult: (didPop, result) async {
                      if (didPop) return;
                      final confirmed = await _showExitConfirmation(context);
                      if (confirmed == true && context.mounted) {
                        context.go('/morning');
                      }
                    },
                    child: Consumer<MorningController>(
                      builder: (context, controller, child) {
                        return Column(
                          children: [
                            SizedBox(
                              width: contentWidth,
                              child: _buildHeader(
                                  context, colorScheme, controller),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Center(
                                  child: SizedBox(
                                    width: contentWidth,
                                    height: scrollHeight - 140,
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 24),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                flex: 10,
                                                child: _buildQuestionCard(
                                                    colorScheme, controller),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                flex: 9,
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .only(top: 12),
                                                  child: _buildMoodSelection(
                                                      colorScheme),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildWritingArea(
                                              context, colorScheme),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_showWritingTutorial)
          Positioned.fill(
            child: InteractiveTutorialOverlay(
              steps: [
                TutorialStep(
                  targetKey: _blurKey,
                  title: AppLocalizations.of(context)
                          ?.get('write_tutorial_blur_title') ??
                      "비밀 유지 모드 🤫",
                  text: AppLocalizations.of(context)
                          ?.get('write_tutorial_blur_text') ??
                      "상단 버튼으로 내용을 뿌옇게 가릴 수 있어! 누구에게도 보이고 싶지 않은 비밀 이야기를 쓸 때 유용해.",
                ),
                TutorialStep(
                  targetKey: _draftKey,
                  title: AppLocalizations.of(context)
                          ?.get('write_tutorial_draft_title') ??
                      "잠시 멈춰도 괜찮아 📝",
                  text: AppLocalizations.of(context)
                          ?.get('write_tutorial_draft_text') ??
                      "작성하던 내용을 임시저장할 수 있어. 바쁠 때는 일단 저장해두고 나중에 다시 써도 돼!",
                ),
                TutorialStep(
                  targetKey: _moodKey,
                  title: AppLocalizations.of(context)
                          ?.get('write_tutorial_mood_title') ??
                      "오늘의 기분은? ✨",
                  text: AppLocalizations.of(context)
                          ?.get('write_tutorial_mood_text') ??
                      "오늘의 기분을 골라봐! 방꾸미기 - 이모티콘에서 선택한 이모티콘들을 여기서 사용할 수 있어.",
                ),
                TutorialStep(
                  title: AppLocalizations.of(context)
                          ?.get('write_tutorial_free_title') ??
                      "나의 이야기 적기 ✍️",
                  text: AppLocalizations.of(context)
                          ?.get('write_tutorial_free_text') ??
                      "이제 여기에 너의 소중한 이야기들을 자유롭게 적어봐!\n(튜토리얼 일기는 실제로 저장되지 않아 안심해도 돼! ✨)\n\n아 참! 내용은 10글자 이상 적어야 저장할 수 있어~ ✨",
                ),
                TutorialStep(
                  targetKey: _saveKey,
                  title: AppLocalizations.of(context)
                          ?.get('write_tutorial_save_title') ??
                      "일기 저장하기 💾",
                  text: AppLocalizations.of(context)
                          ?.get('write_tutorial_save_text') ??
                      "이야기를 다 적었다면 이 버튼을 눌러서 완료해줘!\n너를 위한 특별한 선물이 기다리고 있을지도 몰라! 🎁",
                  showNextButton: false,
                ),
              ],
              onComplete: () {
                context.read<AuthController>().completeWritingTutorial();
                setState(() {
                  _showWritingTutorial = false;
                });
              },
              onSkip: () {
                context.read<AuthController>().skipAllTutorials();
                setState(() {
                  _showWritingTutorial = false;
                });
              },
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, AppColorScheme colorScheme,
      MorningController controller) {
    final weekdayKeys = [
      'weekday_mon',
      'weekday_tue',
      'weekday_wed',
      'weekday_thu',
      'weekday_fri',
      'weekday_sat',
      'weekday_sun'
    ];
    final displayDate = widget.isEditing && widget.existingDiary != null
        ? widget.existingDiary!.date
        : DateTime.now();
    final weekday = AppLocalizations.of(context)
            ?.get(weekdayKeys[displayDate.weekday - 1]) ??
        '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () async {
                  final confirmed = await _showExitConfirmation(context);
                  if (confirmed == true && context.mounted) {
                    context.go('/morning');
                  }
                },
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Image.asset(
                        'assets/icons/X_Button.png',
                        width: 55,
                        height: 55,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                        cacheWidth: 150,
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _enableBlur = !_enableBlur;
                        _textController.blurEnabled = _enableBlur;
                      });
                    },
                    child: Container(
                      key: _blurKey,
                      child: Image.asset(
                        _enableBlur
                            ? 'assets/icons/Blur_ToggleOn.png'
                            : 'assets/icons/Blur_ToggleOff.png',
                        width: 80,
                        height: 38,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                        cacheHeight: 120,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _saveDraft(context, controller),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset(
                          key: _draftKey,
                          'assets/images/Cancel_Button.png',
                          width: 80,
                          height: 38,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                          cacheHeight: 120,
                        ),
                        Text(
                          AppLocalizations.of(context)?.get('tempSave') ??
                              'Draft',
                          style: const TextStyle(
                            fontFamily: 'BMJUA',
                            color: Color(0xFF5D4037),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Consumer<AuthController>(
                    builder: (context, auth, _) {
                      final isTutorial = auth.userModel?.hasSeenTutorial == false &&
                          (auth.userModel?.mainTutorialStep == 'diary' ||
                              auth.userModel?.mainTutorialStep == null);
                      final isGoalReached = controller.isGoalReached();
                      final isEnabled = isTutorial || isGoalReached;

                      return GestureDetector(
                        onTap: isEnabled
                            ? () => _completeDiary(context, controller, colorScheme)
                            : () {
                                MemoNotification.show(
                                    context,
                                    AppLocalizations.of(context)
                                            ?.get('moreWriting') ??
                                        'Please write a bit more! ✍️');
                              },
                        child: Opacity(
                          opacity: isEnabled ? 1.0 : 0.5,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset(
                                key: _saveKey,
                                'assets/images/Confirm_Button.png',
                                width: 110,
                                height: 44,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.medium,
                                cacheHeight: 150,
                              ),
                              Text(
                                AppLocalizations.of(context)?.get('save') ?? 'Save',
                                style: const TextStyle(
                                  fontFamily: 'BMJUA',
                                  color: Color(0xFF5D4037),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            alignment: Alignment.center,
            children: [
              Image.asset('assets/images/Date_Icon.png',
                  width: 200, height: 50, fit: BoxFit.fill),
              Positioned(
                left: 20,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 16, color: colorScheme.textPrimary),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)
                                ?.getFormat('fullDateFormat', {
                              'year': displayDate.year.toString(),
                              'month': displayDate.month.toString(),
                              'day': displayDate.day.toString(),
                              'weekday': weekday
                            }) ??
                            '${displayDate.year}.${displayDate.month}.${displayDate.day} ($weekday)',
                        style: TextStyle(
                          fontFamily: 'BMJUA',
                          color: colorScheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(
      AppColorScheme colorScheme, MorningController controller) {
    // widget.initialQuestion이 없으면 컨트롤러의 현재 질문을 사용합니다.
    final displayQuestion = widget.initialQuestion ?? controller.currentQuestion;

    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/Today_Question.png'),
            fit: BoxFit.contain,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context)?.get('todayQuestion') ??
                      '오늘의 질문',
                  style: TextStyle(
                    fontFamily: 'BMJUA',
                    color: colorScheme.textSecondary.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (displayQuestion?.getLocalizedText(
                              Localizations.localeOf(context).languageCode) ??
                          controller.currentQuestion?.getLocalizedText(
                              Localizations.localeOf(context).languageCode)) ??
                      '...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'BMJUA',
                    color: colorScheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodSelection(AppColorScheme colorScheme) {
    final characterController = context.read<CharacterController>();
    final user = characterController.currentUser;
    if (user == null) return const SizedBox();

    final activeIds = user.activeEmoticonIds;
    final activeEmoticons = activeIds.map((id) {
      return RoomAssets.emoticons.firstWhere(
        (e) => e.id == id,
        orElse: () => RoomAssets.emoticons[0],
      );
    }).toList();

    if (activeEmoticons.isEmpty) return const SizedBox();

    final int pageCount = (activeEmoticons.length / 4).ceil();

    return Column(
      key: _moodKey,
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 1.0,
          child: PageView.builder(
            controller: _pageController,
            clipBehavior: Clip.hardEdge,
            onPageChanged: (index) {
              setState(() {
                _currentMoodPage = index;
              });
            },
            itemCount: pageCount,
            itemBuilder: (context, pageIndex) {
              final start = pageIndex * 4;
              final end = (start + 4 > activeEmoticons.length)
                  ? activeEmoticons.length
                  : start + 4;
              final pageEmoticons = activeEmoticons.sublist(start, end);

              return Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMoodButton(pageEmoticons[0].imagePath!,
                              pageEmoticons[0].id, colorScheme),
                          const SizedBox(width: 8),
                          if (pageEmoticons.length > 1)
                            _buildMoodButton(pageEmoticons[1].imagePath!,
                                pageEmoticons[1].id, colorScheme)
                          else
                            const Expanded(child: SizedBox()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (pageEmoticons.length > 2)
                            _buildMoodButton(pageEmoticons[2].imagePath!,
                                pageEmoticons[2].id, colorScheme)
                          else
                            const Expanded(child: SizedBox()),
                          const SizedBox(width: 8),
                          if (pageEmoticons.length > 3)
                            _buildMoodButton(pageEmoticons[3].imagePath!,
                                pageEmoticons[3].id, colorScheme)
                          else
                            const Expanded(child: SizedBox()),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (pageCount > 1)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pageCount, (index) {
                return Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentMoodPage == index
                        ? const Color(0xFF5D4037)
                        : const Color(0xFF5D4037).withOpacity(0.3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildMoodButton(
      String assetPath, String moodId, AppColorScheme colorScheme) {
    final isSelected = _selectedMoods.contains(moodId);
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedMoods.clear();
            _selectedMoods.add(moodId);
          });
        },
        child: Opacity(
          opacity: isSelected ? 1.0 : 0.6,
          child: AspectRatio(
            aspectRatio: 1.0,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Image.asset(
                  'assets/images/Popup_Background.png',
                  fit: BoxFit.fill,
                ),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: NetworkOrAssetImage(
                      imagePath: assetPath, fit: BoxFit.contain),
                ),
                if (isSelected)
                  Positioned(
                    top: -8,
                    right: -8,
                    child: Image.asset(
                      'assets/images/Red_Pin.png',
                      width: 30,
                      height: 30,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWritingArea(BuildContext context, AppColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/Note_Background.png'),
          fit: BoxFit.fill,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        maxLines: null,
        style: TextStyle(
          fontFamily: 'KyoboHandwriting2024psw',
          color: colorScheme.textPrimary,
          fontSize: 20,
          height: 1.6,
        ),
        cursorColor: colorScheme.primaryButton,
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          filled: false,
          fillColor: Colors.transparent,
          hintText: AppLocalizations.of(context)?.get('writingHint') ??
              '어떤 생각이라도 좋으니 자유롭게 적어보세요.',
          hintStyle: TextStyle(
            fontFamily: 'KyoboHandwriting2024psw',
            color: colorScheme.textHint.withOpacity(0.6),
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  Future<void> _completeDiary(BuildContext context,
      MorningController controller, AppColorScheme colorScheme) async {
    final authController = context.read<AuthController>();

    if (authController.userModel?.biometricEnabled == true) {
      final authenticated = await authController.authenticateWithBiometric();
      if (!authenticated) return;
    }

    final characterController = context.read<CharacterController>();
    final userId = authController.currentUser?.uid;

    if (userId == null) return;

    // 튜토리얼 모드 확인
    final isTutorial = authController.userModel?.hasSeenTutorial == false &&
        (authController.userModel?.mainTutorialStep == 'diary' ||
            authController.userModel?.mainTutorialStep == null);

    if (isTutorial) {
      // 1. 선물 지급 (실제로 일기는 저장하지 않음)
      final gift = await characterController.grantTutorialGift(userId);
      // 2. 글쓰기 튜토리얼 완료 처리
      await authController.completeWritingTutorial();
      // 3. 메인 튜토리얼 다음 단계로
      await authController.setMainTutorialStep('decoration');

      if (context.mounted && gift != null) {
        await _showTutorialGiftDialog(context, gift, colorScheme);
        if (context.mounted) {
          context.go('/morning');
        }
      }
      return;
    }

    final success = await controller.saveDiary(
      userId: userId,
      content: _textController.text,
      moods: _selectedMoods,
      customDate: widget.isEditing ? widget.existingDiary?.date : null,
      existingId: widget.isEditing ? widget.existingDiary?.id : null,
    );

    if (success && context.mounted) {
      if (widget.isEditing) {
        context.pop();
      } else {
        unawaited(characterController.wakeUpCharacter(userId));
        await _showCompletionDialog(context, colorScheme);
        if (context.mounted) {
          final adShown =
              await _tryShowBonusAdOffer(context, characterController, userId);
          if (!adShown && context.mounted) {
            context.go('/morning');
          }
        }
      }
    }
  }

  Future<bool> _tryShowBonusAdOffer(
    BuildContext context,
    CharacterController characterController,
    String userId,
  ) async {
    if (!characterController.isBonusAdReady) return false;
    if (Random().nextInt(10) >= 3) return false;
    if (!context.mounted) return false;

    final watchAd = await AppDialog.show<bool>(
      context: context,
      key: AppDialogKey.bonusAdOffer,
      barrierDismissible: false,
    );

    if (watchAd != true || !context.mounted) return false;

    characterController.showBonusRewardedAd(context, () async {
      await characterController.watchBonusAdAndGetPoints(userId);
      if (context.mounted) {
        await AppDialog.show(context: context, key: AppDialogKey.adReward);
        if (context.mounted) context.go('/morning');
      }
    });

    return true;
  }

  Future<void> _saveDraft(
      BuildContext context, MorningController controller) async {
    final authController = context.read<AuthController>();
    final userId = authController.currentUser?.uid;
    if (userId == null) return;

    final success = await controller.saveDraft(
      userId: userId,
      content: _textController.text,
      moods: _selectedMoods,
    );

    if (success && context.mounted) {
      MemoNotification.show(context, AppLocalizations.of(context)?.get('saveDraftSuccess') ?? 'Draft saved. 📝');
    }
  }

  Future<void> _showCompletionDialog(
      BuildContext context, AppColorScheme colorScheme) async {
    final characterController = context.read<CharacterController>();
    final level = characterController.currentUser?.characterLevel ?? 1;

    return AppDialog.show(
      context: context,
      key: AppDialogKey.diaryCompletion,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _WakeUpAnimationWidget(
            characterLevel: level,
            equippedItems:
                characterController.currentUser?.equippedCharacterItems ?? {},
          ),
          const SizedBox(height: 8),
          Consumer<CharacterController>(
            builder: (context, controller, child) {
              return Text(
                '+${context.read<MorningController>().lastEarnedPoints} ${AppLocalizations.of(context)?.get('branchEarned') ?? 'Branch Earned'}',
                style: TextStyle(
                    fontFamily: 'BMJUA', color: colorScheme.twig, fontSize: 16),
              );
            },
          ),
        ],
      ),
      actions: [
        AppDialogAction(
          label: AppLocalizations.of(context)?.get('confirm') ?? 'Confirm',
          isPrimary: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Future<void> _showTutorialGiftDialog(
      BuildContext context, RoomAsset gift, AppColorScheme colorScheme) async {
    final l10n = AppLocalizations.of(context);
    return AppDialog.show(
      context: context,
      key: AppDialogKey.diaryCompletion,
      title: l10n?.get('gift_popup_title') ?? "특별한 선물 🎁",
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n?.get('gift_popup_welcome') ?? "첫 방문을 축하합니다! 🎉",
            style: const TextStyle(
              fontFamily: 'BMJUA',
              fontSize: 18,
              color: Color(0xFF4E342E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.get('gift_popup_desc') ?? "특별한 선물이 도착했어요.",
            style: const TextStyle(
              fontFamily: 'BMJUA',
              fontSize: 14,
              color: Colors.brown,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.brown.shade100),
            ),
            child: NetworkOrAssetImage(
              imagePath: gift.imagePath ?? '',
              width: 100,
              height: 100,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            gift.getLocalizedName(context),
            style: const TextStyle(
              fontFamily: 'BMJUA',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4E342E),
            ),
          ),
        ],
      ),
      actions: [
        AppDialogAction(
          label: l10n?.get('receive') ?? "받기",
          isPrimary: true,
          onPressed: (context) => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Future<bool?> _showExitConfirmation(BuildContext context) async {
    return AppDialog.show<bool>(
      context: context,
      key: AppDialogKey.exitWriting,
      content: Text(
        AppLocalizations.of(context)?.get('exitWritingDesc') ??
            '지금 중단하면 작성 중인 내용은 저장되지 않아요. (임시저장을 활용해 보세요!)',
        textAlign: TextAlign.center,
        style: const TextStyle(fontFamily: 'BMJUA'),
      ),
      actions: [
        AppDialogAction(
          label: AppLocalizations.of(context)?.get('keepWriting') ?? '계속 작성',
          onPressed: (context) => Navigator.of(context).pop(false),
        ),
        AppDialogAction(
          label: AppLocalizations.of(context)?.get('stop') ?? '중단',
          isPrimary: true,
          onPressed: (context) => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}

class _BlurTextEditingController extends TextEditingController {
  bool blurEnabled;
  AppColorScheme colorScheme;

  _BlurTextEditingController({
    required this.blurEnabled,
    required this.colorScheme,
    String? text,
  }) : super(text: text);

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (!blurEnabled || text.isEmpty) {
      return super.buildTextSpan(
          context: context, style: style, withComposing: withComposing);
    }

    int start = 0;
    int end = text.length;

    if (selection.isValid) {
      final beforeCursor = text.substring(0, selection.baseOffset);
      final lastBreak = beforeCursor.lastIndexOf('\n');
      start = lastBreak != -1 ? lastBreak + 1 : 0;
      final afterCursor = text.substring(selection.baseOffset);
      final nextBreak = afterCursor.indexOf('\n');
      end = nextBreak != -1 ? selection.baseOffset + nextBreak : text.length;
    }

    final beforePart = text.substring(0, start);
    final currentPart = text.substring(start, end);
    final afterPart = text.substring(end);

    final blurStyle = style?.copyWith(
      color: null,
      foreground: Paint()
        ..style = PaintingStyle.fill
        ..color = (style?.color ?? colorScheme.textPrimary).withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0),
    );

    return TextSpan(
      style: style,
      children: [
        if (beforePart.isNotEmpty) TextSpan(text: beforePart, style: blurStyle),
        if (currentPart.isNotEmpty) TextSpan(text: currentPart, style: style),
        if (afterPart.isNotEmpty) TextSpan(text: afterPart, style: blurStyle),
      ],
    );
  }
}

class _WakeUpAnimationWidget extends StatefulWidget {
  final int characterLevel;
  final Map<String, dynamic> equippedItems;
  const _WakeUpAnimationWidget({
    required this.characterLevel,
    required this.equippedItems,
  });

  @override
  State<_WakeUpAnimationWidget> createState() => _WakeUpAnimationWidgetState();
}

class _WakeUpAnimationWidgetState extends State<_WakeUpAnimationWidget> {
  bool _isAwake = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _isAwake = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      width: 150,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _isAwake
            ? CharacterDisplay(
                key: const ValueKey('awake'),
                isAwake: true,
                characterLevel: widget.characterLevel,
                size: 150,
                equippedItems: widget.equippedItems,
              )
            : CharacterDisplay(
                key: const ValueKey('asleep'),
                isAwake: false,
                characterLevel: widget.characterLevel,
                size: 150,
                equippedItems: widget.equippedItems,
              ),
      ),
    );
  }
}
