import 'dart:async';
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

class WritingScreen extends StatefulWidget {
  final String? initialQuestion;

  const WritingScreen({
    super.key,
    this.initialQuestion,
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

  @override
  void initState() {
    super.initState();
    final morningController = context.read<MorningController>();
    morningController.startWriting();

    _textController = _BlurTextEditingController(
      blurEnabled: _enableBlur,
      colorScheme: AppColorScheme.light,
    );

    _textController.addListener(() {
      morningController.updateCharCount(_textController.text);
    });

    final characterController = context.read<CharacterController>();
    final activeIds = characterController.currentUser?.activeEmoticonIds ?? [];
    if (activeIds.isNotEmpty) {
      _selectedMoods.add(activeIds.first);
    } else {
      _selectedMoods.add('normal');
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
    // Use LayoutBuilder to get the full height constraint initially or use MediaQuery

    return Stack(
      children: [
        // 1. Static Background Image
        Positioned.fill(
          child: Image.asset(
            'assets/images/Diary_Background.png',
            fit: BoxFit.cover,
          ),
        ),
        // 2. Scaffold with transparent background and resizing enabled
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

              // Estimate middle row height based on contentWidth
              // (contentWidth - 48 (padding) - 12 (gap)) * (4/7)
              final availableRowWidth = contentWidth - 60;
              final middleRowHeight = (availableRowWidth * 4 / 7);

              // Header ~ 100, Min Writing Area ~ 260
              final minContentHeight = 100 + middleRowHeight + 260;

              final scrollHeight = minContentHeight > screenHeight
                  ? minContentHeight
                  : screenHeight;

              return SafeArea(
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
                          // Fixed Header
                          SizedBox(
                            width: contentWidth,
                            child:
                                _buildHeader(context, colorScheme, controller),
                          ),
                          // Scrollable Content
                          Expanded(
                            child: SingleChildScrollView(
                              child: Center(
                                child: SizedBox(
                                  width: contentWidth,
                                  height:
                                      scrollHeight - 140, // Header approx 140
                                  child: Column(
                                    children: [
                                      // Reduced spacing
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
                                                  colorScheme),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              flex: 9,
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    top:
                                                        12), // Slightly increased top padding
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
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, AppColorScheme colorScheme,
      MorningController controller) {
    final now = DateTime.now();
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[now.weekday - 1];

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(8, 16, 8, 4), // Reduced horizontal padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back Button
              GestureDetector(
                onTap: () async {
                  final confirmed = await _showExitConfirmation(context);
                  if (confirmed == true && context.mounted) {
                    context.go('/morning');
                  }
                },
                child: SizedBox(
                  width: 44, // 고정된 레이아웃 영역 (터치 영역)
                  height: 44, // 아래 콘텐츠를 밀어내지 않음
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none, // 이미지가 영역을 벗어나도 잘리지 않게 설정
                    children: [
                      Image.asset(
                        'assets/icons/X_Button.png',
                        width: 55, // 시각적으로 더 크게 표시
                        height: 55,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),
              ),
              // Action Buttons (Blur & Save)
              Row(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 0), // Align with save button
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _enableBlur = !_enableBlur;
                          _textController.blurEnabled = _enableBlur;
                        });
                      },
                      child: Image.asset(
                        _enableBlur
                            ? 'assets/icons/Blur_ToggleOn.png'
                            : 'assets/icons/Blur_ToggleOff.png',
                        width: 80,
                        height: 38,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 0),
                    child: GestureDetector(
                      onTap: controller.isGoalReached()
                          ? () =>
                              _completeDiary(context, controller, colorScheme)
                          : () {
                              MemoNotification.show(
                                  context, '조금만 더 작성해주세요! ✍️');
                            },
                      child: Opacity(
                        opacity: controller.isGoalReached() ? 1.0 : 0.5,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              'assets/images/Confirm_Button.png',
                              width: 110,
                              height: 44,
                              fit: BoxFit.fill,
                            ),
                            const Text(
                              '저장하기',
                              style: TextStyle(
                                fontFamily: 'BMJUA',
                                color: Color(0xFF5D4037), // Brown color
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12), // Spacing between back button and date
          // Date Icon with Text Overlay
          Stack(
            alignment: Alignment.center,
            children: [
              Image.asset('assets/images/Date_Icon.png',
                  width: 190, height: 50, fit: BoxFit.fill),
              Positioned(
                left: 20,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: colorScheme.textPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')} ($weekday)',
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

  Widget _buildQuestionCard(AppColorScheme colorScheme) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        // Reduced padding to align content better
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
                  widget.initialQuestion ?? '...',
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
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 1.0,
          child: PageView.builder(
            controller: _pageController,
            clipBehavior:
                Clip.hardEdge, // Prevent transition bleed into other areas
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
                padding: const EdgeInsets.all(
                    12.0), // Padding to safely contain pins within the clipped PageView
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
                  child: Image.asset(assetPath, fit: BoxFit.contain),
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
      padding:
          const EdgeInsets.fromLTRB(28, 20, 28, 40), // Added bottom padding
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        maxLines: null,
        style: TextStyle(
          fontFamily: 'KyoboHandwriting2024psw',
          color: colorScheme.textPrimary,
          fontSize: 20, // Slightly larger for handwriting font readability
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
          hintText: '지금 머릿속에 떠오르는 생각을 자유롭게 적어보세요.',
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
    final characterController = context.read<CharacterController>();
    final userId = authController.currentUser?.uid;

    if (userId == null) return;

    final success = await controller.saveDiary(
      userId: userId,
      content: _textController.text,
      moods: _selectedMoods,
    );

    if (success && context.mounted) {
      unawaited(characterController.wakeUpCharacter(userId));
      await _showCompletionDialog(context, colorScheme);
      if (context.mounted) {
        context.go('/morning');
      }
    }
  }

  Future<void> _showCompletionDialog(
      BuildContext context, AppColorScheme colorScheme) async {
    final characterController = context.read<CharacterController>();
    final level = characterController.currentUser?.characterLevel ?? 1;

    return AppDialog.show(
      context: context,
      key: AppDialogKey.diaryCompletion,
      content: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center, // Center align content
          children: [
            _WakeUpAnimationWidget(characterLevel: level),
            const SizedBox(height: 4),
            Text(
              '캐릭터가 깨어났어요!',
              style: TextStyle(
                fontFamily: 'BMJUA',
                color: colorScheme.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Consumer<CharacterController>(
              builder: (context, controller, child) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/Item_Background.png'),
                      fit: BoxFit.fill,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/branch.png',
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '+${10 + (controller.currentUser?.consecutiveDays ?? 0) * 2} 가지 획득',
                        style: TextStyle(
                          fontFamily: 'BMJUA',
                          color: colorScheme.twig,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        AppDialogAction(
          label: '확인',
          isPrimary: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Future<bool?> _showExitConfirmation(BuildContext context) async {
    return AppDialog.show<bool>(
      context: context,
      key: AppDialogKey.exitWriting,
      content: const Text(
        '작성 중인 내용은 저장되지 않습니다.',
        style: TextStyle(fontFamily: 'BMJUA'),
      ),
      actions: [
        AppDialogAction(
          label: '계속 작성',
          onPressed: (context) => Navigator.of(context).pop(false),
        ),
        AppDialogAction(
          label: '중단',
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
        if (beforePart.isNotEmpty)
          TextSpan(
            text: beforePart,
            style: blurStyle,
          ),
        if (currentPart.isNotEmpty)
          TextSpan(
            text: currentPart,
            style: style,
          ),
        if (afterPart.isNotEmpty)
          TextSpan(
            text: afterPart,
            style: blurStyle,
          ),
      ],
    );
  }
}

class _WakeUpAnimationWidget extends StatefulWidget {
  final int characterLevel;
  const _WakeUpAnimationWidget({required this.characterLevel});

  @override
  State<_WakeUpAnimationWidget> createState() => _WakeUpAnimationWidgetState();
}

class _WakeUpAnimationWidgetState extends State<_WakeUpAnimationWidget> {
  bool _isAwake = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _isAwake = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      width: 150,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: _isAwake
            ? CharacterDisplay(
                key: const ValueKey('awake'),
                isAwake: true,
                characterLevel: widget.characterLevel,
                size: 150,
                enableAnimation: true,
              )
            : CharacterDisplay(
                key: const ValueKey('asleep'),
                isAwake: false,
                characterLevel: widget.characterLevel,
                size: 150,
                enableAnimation: true,
              ),
      ),
    );
  }
}
