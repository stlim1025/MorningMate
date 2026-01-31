import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../controllers/morning_controller.dart';
import '../../character/controllers/character_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/widgets/app_dialog.dart';

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
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _enableBlur = false;
  bool _didLoadSettings = false;
  String? _selectedMood;

  @override
  void initState() {
    super.initState();
    final morningController = context.read<MorningController>();
    morningController.startWriting();

    _textController.addListener(() {
      morningController.updateCharCount(_textController.text);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoadSettings) {
      final authController = Provider.of<AuthController>(context);
      final userBlurEnabled = authController.userModel?.writingBlurEnabled;
      if (userBlurEnabled != null) {
        _enableBlur = userBlurEnabled;
        _didLoadSettings = true;
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: colorScheme.iconPrimary),
          onPressed: () async {
            final confirmed = await _showExitConfirmation(context);
            if (confirmed == true && context.mounted) {
              context.pop();
            }
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_note, color: colorScheme.primaryButton, size: 28),
            const SizedBox(width: 8),
            Text(
              '오늘의 일기',
              style: TextStyle(
                color: colorScheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _enableBlur ? Icons.visibility_off : Icons.visibility,
              color: colorScheme.iconPrimary,
            ),
            onPressed: () {
              setState(() {
                _enableBlur = !_enableBlur;
              });
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.awakeGradientStart,
              colorScheme.awakeGradientMid,
              colorScheme.awakeGradientEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;
              final confirmed = await _showExitConfirmation(context);
              if (confirmed == true && context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Consumer<MorningController>(
              builder: (context, controller, child) {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _buildDateAndProgress(controller, colorScheme),
                      const SizedBox(height: 16),
                      if (widget.initialQuestion != null)
                        _buildQuestionCard(colorScheme),
                      const SizedBox(height: 16),
                      _buildWritingArea(context, colorScheme),
                      _buildBottomActions(context, controller, colorScheme),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateAndProgress(
      MorningController controller, AppColorScheme colorScheme) {
    final now = DateTime.now();
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[now.weekday - 1];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadowColor.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryButton.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      color: colorScheme.primaryButton,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${now.year}년 ${now.month}월 ${now.day}일',
                        style: TextStyle(
                          color: colorScheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$weekday요일',
                        style: TextStyle(
                          color: colorScheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.cardAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${controller.charCount}자 • ${_formatDuration(controller.writingDuration)}',
                  style: TextStyle(
                    color: colorScheme.cardAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: controller.getProgress(),
              minHeight: 6,
              backgroundColor: colorScheme.textHint.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProgressColor(controller.getProgress(), colorScheme),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double progress, AppColorScheme colorScheme) {
    if (progress < 0.3) {
      return colorScheme.error.withOpacity(0.7);
    } else if (progress < 0.7) {
      return colorScheme.warning;
    } else {
      return colorScheme.success;
    }
  }

  Widget _buildQuestionCard(AppColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.accent.withOpacity(0.15),
            colorScheme.accent.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.accent.withOpacity(0.25),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lightbulb,
              color: colorScheme.pointStar,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '오늘의 질문',
                  style: TextStyle(
                    color: colorScheme.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.initialQuestion!,
                  style: TextStyle(
                    color: colorScheme.textPrimary,
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWritingArea(BuildContext context, AppColorScheme colorScheme) {
    return Container(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.45,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadowColor.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: LinedPaperPainter(
                  lineColor: colorScheme.textHint.withOpacity(0.2),
                  marginColor: colorScheme.secondary.withOpacity(0.3),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 24, 20),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                maxLines: null,
                autofocus: true,
                style: TextStyle(
                  color: colorScheme.textPrimary,
                  fontSize: 17,
                  height: 1.8,
                  letterSpacing: 0.3,
                ),
                cursorColor: colorScheme.primaryButton,
                decoration: InputDecoration(
                  hintText: '오늘의 생각을 자유롭게 적어보세요...',
                  hintStyle: TextStyle(
                    color: colorScheme.textHint.withOpacity(0.6),
                    fontSize: 17,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
            if (_enableBlur && _textController.text.isNotEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                      child: Container(
                        color: Theme.of(context).cardColor.withOpacity(0.7),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.visibility_off,
                                color:
                                    colorScheme.primaryButton.withOpacity(0.8),
                                size: 48,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '글 가리기 활성화됨',
                                style: TextStyle(
                                  color: colorScheme.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, MorningController controller,
      AppColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadowColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.sentiment_satisfied_alt,
                      color: colorScheme.primaryButton,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '오늘의 기분',
                      style: TextStyle(
                        color: colorScheme.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMoodButton('😊', 'happy', colorScheme),
                    _buildMoodButton('😐', 'neutral', colorScheme),
                    _buildMoodButton('😢', 'sad', colorScheme),
                    _buildMoodButton('🤩', 'excited', colorScheme),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: controller.isGoalReached()
                  ? () => _completeDiary(context, controller, colorScheme)
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: colorScheme.primaryButton,
                disabledBackgroundColor: colorScheme.textHint.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: controller.isGoalReached() ? 4 : 0,
                shadowColor: colorScheme.primaryButton.withOpacity(0.4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    controller.isGoalReached()
                        ? Icons.check_circle
                        : Icons.edit,
                    color: colorScheme.primaryButtonForeground,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    controller.isGoalReached() ? '작성 완료' : '조금만 더 작성해주세요',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primaryButtonForeground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodButton(
      String emoji, String mood, AppColorScheme colorScheme) {
    final isSelected = _selectedMood == mood;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMood = mood;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryButton.withOpacity(0.2)
              : Theme.of(context).cardColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? colorScheme.primaryButton
                : colorScheme.textHint.withOpacity(0.2),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primaryButton.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 28),
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
      mood: _selectedMood,
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
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            '🎉 작성 완료!',
            style: TextStyle(
              color: colorScheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: colorScheme.success,
                  size: 80,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '캐릭터가 깨어났어요!',
                style: TextStyle(
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
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.cardAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '+${10 + (controller.currentUser?.consecutiveDays ?? 0) * 2} 포인트 획득',
                      style: TextStyle(
                        color: colorScheme.cardAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primaryButton,
                  foregroundColor: colorScheme.primaryButtonForeground,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  '확인',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showExitConfirmation(BuildContext context) async {
    return AppDialog.show<bool>(
      context: context,
      key: AppDialogKey.exitWriting,
      content: const Text('작성 중인 내용은 저장되지 않습니다.'),
      actions: [
        AppDialogAction(
          label: '계속 작성',
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AppDialogAction(
          label: '중단',
          isPrimary: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

class LinedPaperPainter extends CustomPainter {
  final Color lineColor;
  final Color marginColor;

  LinedPaperPainter({required this.lineColor, required this.marginColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    final lineSpacing = 32.0;
    final topPadding = 16.0;

    for (double y = topPadding + lineSpacing;
        y < size.height;
        y += lineSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final marginPaint = Paint()
      ..color = marginColor
      ..strokeWidth = 2;
    canvas.drawLine(const Offset(32, 0), Offset(32, size.height), marginPaint);
  }

  @override
  bool shouldRepaint(covariant LinedPaperPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor ||
      oldDelegate.marginColor != marginColor;
}
