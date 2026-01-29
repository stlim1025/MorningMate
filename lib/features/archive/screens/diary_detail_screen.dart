import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../data/models/diary_model.dart';
import '../../morning/controllers/morning_controller.dart';
import '../../../core/theme/app_colors.dart';

class DiaryDetailScreen extends StatefulWidget {
  final List<DiaryModel> diaries;
  final DateTime initialDate;

  const DiaryDetailScreen({
    super.key,
    required this.diaries,
    required this.initialDate,
  });

  @override
  State<DiaryDetailScreen> createState() => _DiaryDetailScreenState();
}

class _DiaryDetailScreenState extends State<DiaryDetailScreen> {
  late DateTime _currentDate;
  String _decryptedContent = '';
  bool _isLoading = true;
  DiaryModel? _currentDiary;

  @override
  void initState() {
    super.initState();
    _currentDate = widget.initialDate;
    _loadCurrentDiary();
  }

  void _loadCurrentDiary() {
    // 해당 날짜의 일기가 있는지 확인
    try {
      _currentDiary = widget.diaries.firstWhere(
        (d) =>
            d.date.year == _currentDate.year &&
            d.date.month == _currentDate.month &&
            d.date.day == _currentDate.day,
      );
    } catch (_) {
      _currentDiary = null;
    }

    if (_currentDiary != null) {
      _fetchDecryptedContent();
    } else {
      setState(() {
        _isLoading = false;
        _decryptedContent = '';
      });
    }
  }

  Future<void> _fetchDecryptedContent() async {
    if (_currentDiary == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final morningController = context.read<MorningController>();

      final content = await morningController.loadDiaryContent(
        userId: _currentDiary!.userId,
        date: _currentDiary!.date,
        encryptedContent: _currentDiary!.encryptedContent,
      );

      if (mounted) {
        setState(() {
          _decryptedContent = content;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _decryptedContent = '내용을 불러올 수 없습니다: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToNext() {
    final tomorrow = _currentDate.add(const Duration(days: 1));
    if (tomorrow.isBefore(DateTime.now().add(const Duration(seconds: 1)))) {
      setState(() {
        _currentDate = tomorrow;
      });
      _loadCurrentDiary();
    }
  }

  void _navigateToPrevious() {
    setState(() {
      _currentDate = _currentDate.subtract(const Duration(days: 1));
    });
    _loadCurrentDiary();
  }

  @override
  Widget build(BuildContext context) {
    final isTodayOrFuture = _currentDate.year >= DateTime.now().year &&
        _currentDate.month >= DateTime.now().month &&
        _currentDate.day >= DateTime.now().day;
    final hasNext = !isTodayOrFuture;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF3E0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8E7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF8B7355), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.menu_book, color: Color(0xFFD4A574), size: 24),
            SizedBox(width: 8),
            Text(
              '기록 보기',
              style: TextStyle(
                color: Color(0xFF5D4E37),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF8E7),
              Color(0xFFFAF3E0),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              _buildHeader(),
              const SizedBox(height: 16),
              if (_currentDiary?.promptQuestion != null) _buildQuestionCard(),
              const SizedBox(height: 16),
              Expanded(
                child: _buildDiaryContentArea(),
              ),
              _buildBottomSection(hasNext),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final weekday = DateFormat('E', 'ko_KR').format(_currentDate);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.smallCardShadow,
      ),
      child: Row(
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
                  Row(
                    children: [
                      Text(
                        DateFormat('yyyy년 M월 d일').format(_currentDate),
                        style: const TextStyle(
                          color: Color(0xFF5D4E37),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_currentDiary != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('HH:mm').format(_currentDiary!.createdAt),
                          style: TextStyle(
                            color: const Color(0xFF8B7355).withOpacity(0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
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
          if (_currentDiary?.mood != null)
            Text(
              _getMoodEmoji(_currentDiary!.mood!),
              style: const TextStyle(fontSize: 28),
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFE4E1),
            Color(0xFFFFF0F0),
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
            decoration: const BoxDecoration(
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
                  _currentDiary?.promptQuestion ?? '',
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

  Widget _buildDiaryContentArea() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            CustomPaint(
              painter: LinedPaperPainter(),
              size: Size.infinite,
            ),
            if (_isLoading)
              const Center(
                  child: CircularProgressIndicator(color: Color(0xFFD4A574)))
            else if (_currentDiary == null)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 64,
                      color: const Color(0xFFD4A574).withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '이 날은 일기를 작성하지 않았습니다',
                      style: TextStyle(
                        color: Color(0xFF8B7355),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: AnimatedOpacity(
                  opacity: _isLoading ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _decryptedContent,
                    style: const TextStyle(
                      color: Color(0xFF3E2723),
                      fontSize: 17,
                      height: 1.8,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection(bool hasNext) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_currentDiary != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildInfoChip(
                    Icons.text_fields, '${_currentDiary?.wordCount}자'),
                const SizedBox(width: 12),
                _buildInfoChip(Icons.timer,
                    '${_currentDiary!.writingDuration ~/ 60}분 ${_currentDiary!.writingDuration % 60}초'),
              ],
            )
          else
            const SizedBox(height: 38), // Space for alignment
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavButton(
                onPressed: _navigateToPrevious,
                icon: Icons.arrow_back_ios_new,
                label: '이전 날짜',
                enabled: true,
              ),
              _buildNavButton(
                onPressed: hasNext ? _navigateToNext : null,
                icon: Icons.arrow_forward_ios,
                label: '다음 날짜',
                enabled: hasNext,
                isRight: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required bool enabled,
    bool isRight = false,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.3,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppColors.smallCardShadow,
          ),
          child: Row(
            children: isRight
                ? [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFFD4A574),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(icon, size: 16, color: const Color(0xFFD4A574)),
                  ]
                : [
                    Icon(icon, size: 16, color: const Color(0xFFD4A574)),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFFD4A574),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8DCC0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFFD4A574)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8B7355),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getMoodEmoji(String mood) {
    switch (mood) {
      case 'happy':
        return '😊';
      case 'neutral':
        return '😐';
      case 'sad':
        return '😢';
      case 'excited':
        return '🤩';
      default:
        return mood;
    }
  }
}

class LinedPaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE8DCC0).withOpacity(0.3)
      ..strokeWidth = 1;

    final lineSpacing = 32.0;
    final topPadding = 24.0;

    for (double y = topPadding + lineSpacing;
        y < size.height;
        y += lineSpacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    final marginPaint = Paint()
      ..color = const Color(0xFFFFB6C1).withOpacity(0.2)
      ..strokeWidth = 2;
    canvas.drawLine(
      const Offset(40, 0),
      Offset(40, size.height),
      marginPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
