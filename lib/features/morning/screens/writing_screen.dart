import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  File? _selectedImage;
  String? _existingPhotoUrl;
  String _selectedWeather = 'sunny';
  final GlobalKey _blurKey = GlobalKey();
  final GlobalKey _draftKey = GlobalKey();
  final GlobalKey _photoKey = GlobalKey();
  final GlobalKey _saveKey = GlobalKey();
  final GlobalKey _weatherMoodKey = GlobalKey();
  bool _showWritingTutorial = false;
  bool _isSaving = false;

  // 인라인 다이얼 Overlay
  final GlobalKey _weatherDialKey = GlobalKey();
  final GlobalKey _moodDialKey = GlobalKey();
  OverlayEntry? _weatherOverlay;
  OverlayEntry? _moodOverlay;
  FixedExtentScrollController? _weatherDialController;
  FixedExtentScrollController? _moodDialController;

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
      _selectedWeather = widget.existingDiary!.weather ?? 'sunny';
      _existingPhotoUrl = widget.existingDiary!.photoUrl;

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
      _selectedWeather = 'sunny';

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
            _selectedWeather = morningController.todayDiary!.weather ?? 'sunny';
            _existingPhotoUrl = morningController.todayDiary!.photoUrl;
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
    if (_weatherOverlay != null) {
      _weatherOverlay!.remove();
      _weatherOverlay = null;
    }
    if (_moodOverlay != null) {
      _moodOverlay!.remove();
      _moodOverlay = null;
    }
    _weatherDialController?.dispose();
    _moodDialController?.dispose();
    _textController.dispose();
    _focusNode.dispose();
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
                                                  child: _buildPhotoSelection(
                                                      context, colorScheme),
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
                  targetKey: _photoKey,
                  title: AppLocalizations.of(context)
                          ?.get('write_tutorial_photo_title') ??
                      "오늘의 순간 간직하기 📸",
                  text: AppLocalizations.of(context)
                          ?.get('write_tutorial_photo_text') ??
                      "오늘의 특별한 순간을 사진으로 남겨봐! 사진을 추가하면 일기가 더 다채로워질 거야.",
                ),
                TutorialStep(
                  targetKey: _weatherMoodKey,
                  title: AppLocalizations.of(context)
                          ?.get('write_tutorial_mood_title') ??
                      "오늘의 날씨와 기분 ✨",
                  text: AppLocalizations.of(context)
                          ?.get('write_tutorial_mood_text') ??
                      "오늘의 날씨와 기분을 자유롭게 골라봐! 선택한 아이콘들이 일기에 예쁘게 기록될 거야.",
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
                  SizedBox(width: 8),
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
                          style: TextStyle(
                            fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA',
                            color: Color(0xFF5D4037),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
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
                                style: TextStyle(
                                  fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA',
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
          SizedBox(height: 12),
          Stack(
            alignment: Alignment.center,
            children: [
              Image.asset('assets/images/Date_Icon.png',
                  width: AppLocalizations.of(context)?.locale.languageCode == 'ja' ? 260 : 210, 
                  height: 50, 
                  fit: BoxFit.fill),
              Positioned(
                left: 20,
                child: Padding(
                  padding: EdgeInsets.only(top: 4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 16, color: colorScheme.textPrimary),
                      SizedBox(width: 8),
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
                          fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA',
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
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
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
                    fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA',
                    color: colorScheme.textSecondary.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  (displayQuestion?.getLocalizedText(
                              Localizations.localeOf(context).languageCode) ??
                          controller.currentQuestion?.getLocalizedText(
                              Localizations.localeOf(context).languageCode)) ??
                      '...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA',
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

  Widget _buildPhotoSelection(BuildContext context, AppColorScheme colorScheme) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: GestureDetector(
        onTap: () async {
          final picker = ImagePicker();
          final pickedFile = await picker.pickImage(source: ImageSource.gallery);
          if (pickedFile != null) {
            setState(() {
              _selectedImage = File(pickedFile.path);
              _existingPhotoUrl = null;
            });
          }
        },
        child: Container(
          key: _photoKey,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/Popup_Background.png'),
              fit: BoxFit.fill,
            ),
          ),
          child: _selectedImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(_selectedImage!, fit: BoxFit.contain),
                )
              : _existingPhotoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: NetworkOrAssetImage(
                        imagePath: _existingPhotoUrl!,
                        fit: BoxFit.contain,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate,
                            size: 40, color: colorScheme.textHint),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)?.get('addPhoto') ?? '사진 추가',
                          style: TextStyle(
                            fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA',
                            color: colorScheme.textHint,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  // GlobalKey 위젯의 화면 상 절대 위치(Rect)를 반환
  Rect? _getWidgetRect(GlobalKey key) {
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;
    final offset = renderBox.localToGlobal(Offset.zero);
    return offset & renderBox.size;
  }

  void _closeAllDials() {
    if (_weatherOverlay != null) {
      _weatherOverlay!.remove();
      _weatherOverlay = null;
    }
    if (_moodOverlay != null) {
      _moodOverlay!.remove();
      _moodOverlay = null;
    }
    _weatherDialController?.dispose();
    _weatherDialController = null;
    _moodDialController?.dispose();
    _moodDialController = null;
  }

  void _showWeatherDial(BuildContext context, AppColorScheme colorScheme) {
    // 기분 다이얼이 열려 있으면 닫기
    _moodOverlay?.remove();
    _moodOverlay = null;
    _moodDialController?.dispose();
    _moodDialController = null;

    // 이미 날씨 다이얼이 열려 있으면 닫기
    if (_weatherOverlay != null) {
      _weatherOverlay!.remove();
      _weatherOverlay = null;
      _weatherDialController?.dispose();
      _weatherDialController = null;
      return;
    }

    final rect = _getWidgetRect(_weatherDialKey);
    if (rect == null) return;

    final weathers = ['sunny', 'partlyCloudy', 'cloudy', 'rainy', 'snowy'];
    final initialIndex = weathers.indexOf(_selectedWeather).clamp(0, weathers.length - 1);
    _weatherDialController = FixedExtentScrollController(initialItem: initialIndex);

    final overlayState = Overlay.of(context);
    const dialHeight = 170.0;
    const dialWidth = 170.0;
    final screenSize = MediaQuery.of(context).size;

    // 위젯 중앙 기준 x 위치 계산 (화면 밖으로 나가지 않게 clamp)
    double left = rect.center.dx - dialWidth / 2;
    left = left.clamp(8.0, screenSize.width - dialWidth - 8);

    // 기본적으로 위젯 위에 표시, 위 공간이 부족하면 아래에 표시
    double top = rect.top - dialHeight - 6;
    if (top < 60) top = rect.bottom + 6;

    _weatherOverlay = OverlayEntry(
      builder: (ctx) {
        final Map<String, String> weatherNames = {
          'sunny': '☀️',
          'partlyCloudy': '🌤',
          'cloudy': '☁️',
          'rainy': '🌧',
          'snowy': '❄️',
        };
        return Stack(
          children: [
            // 투명 배경 - 탭하면 닫힘
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeAllDials,
                behavior: HitTestBehavior.translucent,
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              width: dialWidth,
              height: dialHeight,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/Popup_Background.png'),
                      fit: BoxFit.fill,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 가운데 하이라이트 바
                        Center(
                          child: Container(
                            height: 55,
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryButton.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        StatefulBuilder(
                          builder: (ctx2, setInnerState) {
                            return ListWheelScrollView.useDelegate(
                              controller: _weatherDialController,
                              itemExtent: 55,
                              perspective: 0.003,
                              diameterRatio: 1.5,
                              physics: const FixedExtentScrollPhysics(),
                              onSelectedItemChanged: (index) {
                                setState(() {
                                  _selectedWeather = weathers[index];
                                });
                                setInnerState(() {});
                                // Overlay 자체도 리빌드
                                _weatherOverlay?.markNeedsBuild();
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount: weathers.length,
                                builder: (context, index) {
                                  final isSelected = weathers[index] == _selectedWeather;
                                  return Center(
                                    child: Text(
                                      weatherNames[weathers[index]]!,
                                      style: TextStyle(
                                        fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA',
                                        fontSize: isSelected ? 30 : 20,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected
                                            ? colorScheme.textPrimary
                                            : colorScheme.textHint.withOpacity(0.4),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
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
    );
    overlayState.insert(_weatherOverlay!);
  }

  void _showMoodDial(BuildContext context, AppColorScheme colorScheme) {
    // 날씨 다이얼이 열려 있으면 닫기
    _weatherOverlay?.remove();
    _weatherOverlay = null;
    _weatherDialController?.dispose();
    _weatherDialController = null;

    // 이미 기분 다이얼이 열려 있으면 닫기
    if (_moodOverlay != null) {
      _moodOverlay!.remove();
      _moodOverlay = null;
      _moodDialController?.dispose();
      _moodDialController = null;
      return;
    }

    final characterController = context.read<CharacterController>();
    final activeIds = characterController.currentUser?.activeEmoticonIds ?? [];
    final activeEmoticons = activeIds.map((id) {
      return RoomAssets.emoticons.firstWhere(
        (e) => e.id == id,
        orElse: () => RoomAssets.emoticons[0],
      );
    }).toList();

    if (activeEmoticons.isEmpty) return;

    final currentMoodId = _selectedMoods.isNotEmpty ? _selectedMoods.first : '';
    final idx = activeEmoticons.indexWhere((e) => e.id == currentMoodId);
    final initialIndex = idx >= 0 ? idx : 0;
    _moodDialController = FixedExtentScrollController(initialItem: initialIndex);

    final rect = _getWidgetRect(_moodDialKey);
    if (rect == null) return;

    final overlayState = Overlay.of(context);
    const dialHeight = 170.0;
    const dialWidth = 170.0;
    final screenSize = MediaQuery.of(context).size;

    double left = rect.center.dx - dialWidth / 2;
    left = left.clamp(8.0, screenSize.width - dialWidth - 8);

    double top = rect.top - dialHeight - 6;
    if (top < 60) top = rect.bottom + 6;

    _moodOverlay = OverlayEntry(
      builder: (ctx) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeAllDials,
                behavior: HitTestBehavior.translucent,
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              width: dialWidth,
              height: dialHeight,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/Popup_Background.png'),
                      fit: BoxFit.fill,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 가운데 하이라이트 바
                        Center(
                          child: Container(
                            height: 70,
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryButton.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                        StatefulBuilder(
                          builder: (ctx2, setInnerState) {
                            return ListWheelScrollView.useDelegate(
                              controller: _moodDialController,
                              itemExtent: 75,
                              perspective: 0.003,
                              diameterRatio: 1.5,
                              physics: const FixedExtentScrollPhysics(),
                              onSelectedItemChanged: (index) {
                                if (activeEmoticons.isEmpty) return;
                                setState(() {
                                  _selectedMoods.clear();
                                  _selectedMoods.add(activeEmoticons[index].id);
                                });
                                setInnerState(() {});
                                _moodOverlay?.markNeedsBuild();
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount: activeEmoticons.length,
                                builder: (context, index) {
                                  final emoticon = activeEmoticons[index];
                                  final isSelected = _selectedMoods.contains(emoticon.id);
                                  return Center(
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      padding: EdgeInsets.all(isSelected ? 6 : 4),
                                      decoration: isSelected
                                          ? BoxDecoration(
                                              color: colorScheme.primaryButton.withOpacity(0.15),
                                              shape: BoxShape.circle,
                                            )
                                          : null,
                                      child: NetworkOrAssetImage(
                                        imagePath: emoticon.imagePath ?? '',
                                        width: isSelected ? 64 : 50,
                                        height: isSelected ? 64 : 50,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
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
    );
    overlayState.insert(_moodOverlay!);
  }

  Widget _buildWritingArea(BuildContext context, AppColorScheme colorScheme) {
    final langCode = Localizations.localeOf(context).languageCode;

    final Map<String, String> weatherEmojis = {
      'sunny': '☀️', 'partlyCloudy': '🌤', 'cloudy': '☁️', 'rainy': '🌧', 'snowy': '❄️',
    };
    final weatherEmoji = weatherEmojis[_selectedWeather] ?? '☀️';



    final activeMoodModel = RoomAssets.emoticons.firstWhere(
      (e) => _selectedMoods.isNotEmpty && e.id == _selectedMoods.first,
      orElse: () => RoomAssets.emoticons[0],
    );

    final weatherTitle = {
      'ko': '날씨',
      'en': 'Weather',
      'ja': '天気',
    }[langCode] ?? '날씨';

    final moodTitle = {
      'ko': '기분',
      'en': 'Mood',
      'ja': '気分',
    }[langCode] ?? '기분';


    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/Note_Background.png'),
          fit: BoxFit.fill,
        ),
      ),
      padding: EdgeInsets.fromLTRB(28, 20, 28, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            key: _weatherMoodKey,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 0,
            runSpacing: 4,
            children: [
              // 날씨 선택 버튼
              GestureDetector(
                key: _weatherDialKey,
                onTap: () => _showWeatherDial(context, colorScheme),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                  decoration: BoxDecoration(
                    color: _weatherOverlay != null
                        ? colorScheme.primaryButton.withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$weatherTitle: $weatherEmoji',
                        style: TextStyle(
                          fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA',
                          fontSize: 20,
                          color: colorScheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        _weatherOverlay != null ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        color: colorScheme.textPrimary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  '/',
                  style: TextStyle(
                    fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA',
                    fontSize: 20,
                    color: colorScheme.textHint,
                  ),
                ),
              ),
              // 기분 선택 버튼
              GestureDetector(
                key: _moodDialKey,
                onTap: () => _showMoodDial(context, colorScheme),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                  decoration: BoxDecoration(
                    color: _moodOverlay != null
                        ? colorScheme.primaryButton.withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$moodTitle: ',
                        style: TextStyle(
                          fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA',
                          fontSize: 20,
                          color: colorScheme.textPrimary,
                        ),
                      ),
                      NetworkOrAssetImage(
                        imagePath: activeMoodModel.imagePath ?? '',
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _moodOverlay != null ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        color: colorScheme.textPrimary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Expanded(
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
          ),
        ],
      ),
    );
  }





  Future<void> _completeDiary(BuildContext context,
      MorningController controller, AppColorScheme colorScheme) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
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

    // Removed _isUploadingPhoto updates

    String? photoUrl = _existingPhotoUrl;
    if (_selectedImage != null) {
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('diary_photos')
            .child(userId)
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(_selectedImage!);
        photoUrl = await ref.getDownloadURL();
      } catch (e) {
        debugPrint('Photo upload error: $e');
      }
    }

    // Removed _isUploadingPhoto updates

    final success = await controller.saveDiary(
      userId: userId,
      content: _textController.text,
      moods: _selectedMoods,
      weather: _selectedWeather,
      photoUrl: photoUrl,
      characterLevel: widget.isEditing ? widget.existingDiary?.characterLevel : characterController.currentUser?.characterLevel,
      equippedCharacterItems: widget.isEditing ? widget.existingDiary?.equippedCharacterItems : characterController.currentUser?.equippedCharacterItems,
      customDate: widget.isEditing ? widget.existingDiary?.date : null,
      existingId: widget.isEditing ? widget.existingDiary?.id : null,
      createdAt: widget.isEditing ? widget.existingDiary?.createdAt : (widget.existingDiary != null ? widget.existingDiary?.createdAt : null),
    );

      if (success && context.mounted) {
      // 1. 수정 모드이거나 이미 완료된 일기를 수정하는 경우 팝업 건너뜀
      final bool isActuallyEditing = widget.isEditing || (widget.existingDiary?.isCompleted == true);
      
      if (isActuallyEditing) {
        if (context.mounted && GoRouter.of(context).canPop()) {
          context.pop();
        }
      } else {
        // 2. 처음 완성하거나 미완성 드래프트를 완성하는 경우에만 팝업 표시
        unawaited(characterController.wakeUpCharacter(userId));
        await _showCompletionDialog(context, colorScheme);
        
        if (context.mounted) {
          // 임시 로그인 유저이면서 첫 일기 작성인 경우 소셜 로그인 유도
          final currentAuth = context.read<AuthController>();
          if (currentAuth.userModel != null && 
              currentAuth.userModel!.isAnonymous &&
              currentAuth.userModel!.diaryCount <= 1) {
            
            final provider = await AppDialog.show<String>(
              context: context,
              key: AppDialogKey.guestMigration,
              barrierDismissible: false,
            );

            if (provider != null && context.mounted) {
              try {
                await currentAuth.linkWithSocialProvider(provider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('성공적으로 계정이 연결되었습니다!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('계정 연결 실패: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }
          }
        }

        if (context.mounted) {
          final adShown =
              await _tryShowBonusAdOffer(context, characterController, userId);
          if (!adShown && context.mounted) {
            context.go('/morning');
          }
        }
      }
    }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
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
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final authController = context.read<AuthController>();
      final userId = authController.currentUser?.uid;
      if (userId == null) return;

    // Removed _isUploadingPhoto state updates

    String? photoUrl = _existingPhotoUrl;
    if (_selectedImage != null) {
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('diary_photos')
            .child(userId)
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(_selectedImage!);
        photoUrl = await ref.getDownloadURL();
      } catch (e) {
        debugPrint('Photo upload error: $e');
      }
    }

    // Removed _isUploadingPhoto state updates

    final success = await controller.saveDraft(
      userId: userId,
      content: _textController.text,
      moods: _selectedMoods,
      weather: _selectedWeather,
      photoUrl: photoUrl,
    );

      if (success && context.mounted) {
        MemoNotification.show(context, AppLocalizations.of(context)?.get('saveDraftSuccess') ?? 'Draft saved. 📝');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _showCompletionDialog(
      BuildContext context, AppColorScheme colorScheme) async {
    final characterController = context.read<CharacterController>();
    final level = characterController.currentUser?.characterLevel ?? 1;
    final morningController = context.read<MorningController>();

    return AppDialog.show(
      context: context,
      key: AppDialogKey.diaryCompletion,
      title: AppLocalizations.of(context)?.get('diaryCompletionTitle') ??
          'Character Woke Up!',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _WakeUpAnimationWidget(
            characterLevel: level,
            equippedItems:
                characterController.currentUser?.equippedCharacterItems ?? {},
          ),
          SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                'assets/images/TextBox_Background.png',
                width: 180,
                height: 44,
                fit: BoxFit.fill,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/branch.png',
                    width: 22,
                    height: 22,
                  ),
                  SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)?.getFormat('branchEarned', {
                          'amount':
                              morningController.lastEarnedPoints.toString()
                        }) ??
                        '+${morningController.lastEarnedPoints} Branch Earned',
                    style: TextStyle(
                      fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA',
                      color: Color(0xFF5D4037),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)?.get('diaryCompletionDesc') ??
                'Your character has started the day!',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
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
            style: TextStyle(
              fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA',
              fontSize: 18,
              color: Color(0xFF4E342E),
            ),
          ),
          SizedBox(height: 8),
          Text(
            l10n?.get('gift_popup_desc') ?? "특별한 선물이 도착했어요.",
            style: TextStyle(
              fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA',
              fontSize: 14,
              color: Colors.brown,
            ),
          ),
          SizedBox(height: 16),
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
          SizedBox(height: 12),
          Text(
            gift.getLocalizedName(context),
            style: TextStyle(
              fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA',
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
        style: TextStyle(fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA'),
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
