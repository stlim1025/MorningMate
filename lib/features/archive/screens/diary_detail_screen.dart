import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../data/models/diary_model.dart';
import '../../morning/controllers/morning_controller.dart';
import '../../../core/theme/app_color_scheme.dart';

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
    try {
      _currentDiary = widget.diaries.firstWhere(
        (d) => d.dateKey == DiaryModel.buildDateKey(_currentDate),
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
        date: _currentDiary!.dateOnly,
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
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;
    final isTodayOrFuture = _currentDate.year >= DateTime.now().year &&
        _currentDate.month >= DateTime.now().month &&
        _currentDate.day >= DateTime.now().day;
    final hasNext = !isTodayOrFuture;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        iconTheme: Theme.of(context).iconTheme,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: colorScheme.iconPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book, color: colorScheme.primaryButton, size: 24),
            const SizedBox(width: 8),
            Text(
              '기록 보기',
              style: TextStyle(
                color: colorScheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildHeader(colorScheme),
            const SizedBox(height: 16),
            if (_currentDiary?.promptQuestion != null)
              _buildQuestionCard(colorScheme),
            const SizedBox(height: 16),
            Expanded(
              child: _buildDiaryContentArea(colorScheme),
            ),
            _buildBottomSection(hasNext, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppColorScheme colorScheme) {
    final weekday = DateFormat('E', 'ko_KR').format(_currentDate);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
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
                  Row(
                    children: [
                      Text(
                        DateFormat('yyyy년 M월 d일').format(_currentDate),
                        style: TextStyle(
                          color: colorScheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_currentDiary != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('HH:mm').format(_currentDiary!.createdAt),
                          style: TextStyle(
                            color: colorScheme.textSecondary,
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
                      color: colorScheme.textSecondary,
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
                  _currentDiary?.promptQuestion ?? '',
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

  Widget _buildDiaryContentArea(AppColorScheme colorScheme) {
    return Container(
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
            CustomPaint(
              painter: LinedPaperPainter(
                lineColor: colorScheme.textHint.withOpacity(0.2),
                marginColor: colorScheme.secondary.withOpacity(0.3),
              ),
              size: Size.infinite,
            ),
            if (_isLoading)
              Center(
                  child: CircularProgressIndicator(
                      color: colorScheme.primaryButton))
            else if (_currentDiary == null)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 64,
                      color: colorScheme.textHint.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '이 날은 일기를 작성하지 않았습니다',
                      style: TextStyle(
                        color: colorScheme.textSecondary,
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
                    style: TextStyle(
                      color: colorScheme.textPrimary,
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

  Widget _buildBottomSection(bool hasNext, AppColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_currentDiary != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildInfoChip(Icons.text_fields,
                    '${_currentDiary?.wordCount}자', colorScheme),
                const SizedBox(width: 12),
                _buildInfoChip(
                    Icons.timer,
                    '${_currentDiary!.writingDuration ~/ 60}분 ${_currentDiary!.writingDuration % 60}초',
                    colorScheme),
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
                colorScheme: colorScheme,
              ),
              _buildNavButton(
                onPressed: hasNext ? _navigateToNext : null,
                icon: Icons.arrow_forward_ios,
                label: '다음 날짜',
                enabled: hasNext,
                isRight: true,
                colorScheme: colorScheme,
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
    required AppColorScheme colorScheme,
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
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadowColor.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: isRight
                ? [
                    Text(
                      label,
                      style: TextStyle(
                        color: colorScheme.primaryButton,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(icon, size: 16, color: colorScheme.primaryButton),
                  ]
                : [
                    Icon(icon, size: 16, color: colorScheme.primaryButton),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        color: colorScheme.primaryButton,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(
      IconData icon, String label, AppColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primaryButton.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colorScheme.primaryButton),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: colorScheme.primaryButton,
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
  final Color lineColor;
  final Color marginColor;

  LinedPaperPainter({required this.lineColor, required this.marginColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    final lineSpacing = 32.0;
    final topPadding = 24.0;

    for (double y = topPadding + lineSpacing;
        y < size.height;
        y += lineSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final marginPaint = Paint()
      ..color = marginColor
      ..strokeWidth = 2;
    canvas.drawLine(const Offset(40, 0), Offset(40, size.height), marginPaint);
  }

  @override
  bool shouldRepaint(covariant LinedPaperPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor ||
      oldDelegate.marginColor != marginColor;
}
