import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/morning_controller.dart';
import '../../character/controllers/character_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../widgets/progress_indicator_widget.dart';

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
  bool _enableBlur = true;
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
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => _showExitConfirmation(context),
        ),
        title: const Text(
          '모닝 페이지 작성',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _enableBlur ? Icons.visibility_off : Icons.visibility,
              color: Colors.white70,
            ),
            onPressed: () {
              setState(() {
                _enableBlur = !_enableBlur;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<MorningController>(
          builder: (context, controller, child) {
            return Column(
              children: [
                // 진행률 표시
                ProgressIndicatorWidget(
                  progress: controller.getProgress(),
                  title:
                      '${controller.charCount}자 / ${_formatDuration(controller.writingDuration)}',
                ),

                const SizedBox(height: 16),

                // 질문 표시
                if (widget.initialQuestion != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.initialQuestion!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // 작성 영역
                Expanded(
                  child: _buildWritingArea(),
                ),

                // 하단 액션 버튼
                _buildBottomActions(context, controller),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildWritingArea() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          TextField(
            controller: _textController,
            focusNode: _focusNode,
            maxLines: null,
            autofocus: true,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.5,
            ),
            decoration: const InputDecoration(
              hintText: '오늘의 생각을 자유롭게 적어보세요...',
              hintStyle: TextStyle(color: Colors.white30),
              border: InputBorder.none,
            ),
          ),

          // 블러 효과
          if (_enableBlur && _textController.text.isNotEmpty)
            Positioned.fill(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: Container(
                    color: Colors.black.withOpacity(0.1),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(
      BuildContext context, MorningController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 기분 선택
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMoodButton('😊', '😊'),
              _buildMoodButton('😐', '😐'),
              _buildMoodButton('😢', '😢'),
              _buildMoodButton('🤩', '🤩'),
            ],
          ),

          const SizedBox(height: 16),

          // 완료 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: controller.isGoalReached()
                  ? () => _completeDiary(context, controller)
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
              ),
              child: Text(
                controller.isGoalReached() ? '작성 완료' : '목표를 달성해주세요',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodButton(String emoji, String mood) {
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
              ? AppColors.primary.withOpacity(0.3)
              : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white30,
            width: 2,
          ),
        ),
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 28),
        ),
      ),
    );
  }

  Future<void> _completeDiary(
      BuildContext context, MorningController controller) async {
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
      // 캐릭터 깨우기
      await characterController.wakeUpCharacter(userId);

      // 완료 다이얼로그 표시
      await _showCompletionDialog(context);

      // 메인 화면으로 이동
      if (context.mounted) {
        context.go('/morning');
      }
    }
  }

  Future<void> _showCompletionDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text(
          '🎉 작성 완료!',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 80,
            ),
            const SizedBox(height: 16),
            const Text(
              '캐릭터가 깨어났어요!',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Consumer<CharacterController>(
              builder: (context, controller, child) {
                return Text(
                  '+${10 + (controller.currentUser?.consecutiveDays ?? 0) * 2} 포인트 획득',
                  style: const TextStyle(
                    color: AppColors.pointStar,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _showExitConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text(
          '작성을 중단하시겠어요?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '작성 중인 내용은 저장되지 않습니다.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('계속 작성'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('중단'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.pop();
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
