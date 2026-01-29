import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/morning_controller.dart';
import '../../character/controllers/character_controller.dart';
import '../../auth/controllers/auth_controller.dart';

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
  bool _enableBlur = false; // 기본값을 false로 변경
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
    return Scaffold(
      backgroundColor: const Color(0xFFFAF3E0), // 따뜻한 베이지색 배경
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8E7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF8B7355)),
          onPressed: () => _showExitConfirmation(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.edit_note, color: Color(0xFFD4A574), size: 28),
            SizedBox(width: 8),
            Text(
              '오늘의 일기',
              style: TextStyle(
                color: Color(0xFF5D4E37),
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
              color: const Color(0xFF8B7355),
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
              const Color(0xFFFFF8E7),
              const Color(0xFFFAF3E0),
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<MorningController>(
            builder: (context, controller, child) {
              return Column(
                children: [
                  const SizedBox(height: 8),

                  // 날짜와 진행률을 함께 표시
                  _buildDateAndProgress(controller),

                  const SizedBox(height: 16),

                  // 질문 표시 (다이어리 스티커 느낌)
                  if (widget.initialQuestion != null) _buildQuestionCard(),

                  const SizedBox(height: 16),

                  // 작성 영역 (노트북 스타일)
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
      ),
    );
  }

  Widget _buildDateAndProgress(MorningController controller) {
    final now = DateTime.now();
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[now.weekday - 1];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4A574).withOpacity(0.15),
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
                      color: const Color(0xFFFFF8E7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_today,
                      color: Color(0xFFD4A574),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${now.year}년 ${now.month}월 ${now.day}일',
                        style: const TextStyle(
                          color: Color(0xFF5D4E37),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$weekday요일',
                        style: TextStyle(
                          color: const Color(0xFF8B7355).withOpacity(0.7),
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
                  color: const Color(0xFFFFE4B5).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${controller.charCount}자 • ${_formatDuration(controller.writingDuration)}',
                  style: const TextStyle(
                    color: Color(0xFF8B7355),
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
              backgroundColor: const Color(0xFFFFF8E7),
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProgressColor(controller.getProgress()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.3) {
      return const Color(0xFFFFB6B9); // 연한 핑크
    } else if (progress < 0.7) {
      return const Color(0xFFFFE66D); // 따뜻한 노랑
    } else {
      return const Color(0xFF95E1D3); // 민트
    }
  }

  Widget _buildQuestionCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFE4E1),
            const Color(0xFFFFF0F0),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFB6C1).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB6C1).withOpacity(0.2),
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
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb,
              color: Color(0xFFFFD700),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '오늘의 질문',
                  style: TextStyle(
                    color: Color(0xFFFF69B4),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.initialQuestion!,
                  style: const TextStyle(
                    color: Color(0xFF8B4C6B),
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

  Widget _buildWritingArea() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4A574).withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 노트북 줄 무늬 배경
            CustomPaint(
              painter: LinedPaperPainter(),
              size: Size.infinite,
            ),

            // 텍스트 입력 영역
            Padding(
              padding: const EdgeInsets.all(20),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                maxLines: null,
                autofocus: true,
                style: const TextStyle(
                  color: Color(0xFF3E2723), // 다크 브라운 텍스트
                  fontSize: 17,
                  height: 1.8,
                  letterSpacing: 0.3,
                ),
                cursorColor: const Color(0xFFD4A574), // 커서 색상도 골드로
                decoration: InputDecoration(
                  hintText: '오늘의 생각을 자유롭게 적어보세요...',
                  hintStyle: TextStyle(
                    color: const Color(0xFF8B7355).withOpacity(0.4),
                    fontSize: 17,
                  ),
                  border: InputBorder.none,
                  filled: false, // 배경 채우기 비활성화
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),

            // 블러 효과
            if (_enableBlur && _textController.text.isNotEmpty)
              Positioned.fill(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                    child: Container(
                      color: const Color(0xFFFFF8E7)
                          .withOpacity(0.7), // 밝은 베이지색으로 변경
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.visibility_off,
                              color: const Color(0xFFD4A574).withOpacity(0.8),
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '글 가리기 활성화됨',
                              style: TextStyle(
                                color: const Color(0xFF8B7355).withOpacity(0.9),
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
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(
      BuildContext context, MorningController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4A574).withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 기분 선택
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.sentiment_satisfied_alt,
                      color: Color(0xFFD4A574),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '오늘의 기분',
                      style: TextStyle(
                        color: Color(0xFF8B7355),
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
                    _buildMoodButton('😊', 'happy'),
                    _buildMoodButton('😐', 'neutral'),
                    _buildMoodButton('😢', 'sad'),
                    _buildMoodButton('🤩', 'excited'),
                  ],
                ),
              ],
            ),
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
                backgroundColor: const Color(0xFFD4A574),
                disabledBackgroundColor: const Color(0xFFE8DCC0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: controller.isGoalReached() ? 4 : 0,
                shadowColor: const Color(0xFFD4A574).withOpacity(0.4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    controller.isGoalReached()
                        ? Icons.check_circle
                        : Icons.edit,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    controller.isGoalReached() ? '작성 완료' : '조금만 더 작성해주세요',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
          color: isSelected ? const Color(0xFFFFE4B5) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color:
                isSelected ? const Color(0xFFD4A574) : const Color(0xFFE8DCC0),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFD4A574).withOpacity(0.3),
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
      unawaited(characterController.wakeUpCharacter(userId));

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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          '🎉 작성 완료!',
          style: TextStyle(
            color: Color(0xFF5D4E37),
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
                color: const Color(0xFFFFF8E7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF95E1D3),
                size: 80,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '캐릭터가 깨어났어요!',
              style: TextStyle(
                color: Color(0xFF8B7355),
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
                    color: const Color(0xFFFFE4B5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+${10 + (controller.currentUser?.consecutiveDays ?? 0) * 2} 포인트 획득',
                    style: const TextStyle(
                      color: Color(0xFFD4A574),
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
                backgroundColor: const Color(0xFFD4A574),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '확인',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showExitConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          '작성을 중단하시겠어요?',
          style: TextStyle(
            color: Color(0xFF5D4E37),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          '작성 중인 내용은 저장되지 않습니다.',
          style: TextStyle(
            color: Color(0xFF8B7355),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              '계속 작성',
              style: TextStyle(
                color: Color(0xFFD4A574),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              '중단',
              style: TextStyle(
                color: Color(0xFFFFB6B9),
                fontWeight: FontWeight.w600,
              ),
            ),
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

// 노트북 줄 무늬를 그리는 커스텀 페인터
class LinedPaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE8DCC0).withOpacity(0.3)
      ..strokeWidth = 1;

    final lineSpacing = 32.0; // 줄 간격 (1.8 line height * 17px font size ≈ 30.6)
    final topPadding = 20.0; // 상단 패딩과 일치

    for (double y = topPadding + lineSpacing;
        y < size.height;
        y += lineSpacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // 왼쪽 마진 라인 (옵션)
    final marginPaint = Paint()
      ..color = const Color(0xFFFFB6C1).withOpacity(0.2)
      ..strokeWidth = 2;
    canvas.drawLine(
      const Offset(60, 0),
      Offset(60, size.height),
      marginPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
