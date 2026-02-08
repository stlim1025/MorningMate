import 'package:flutter/material.dart';

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
    // Normalize to date only (00:00:00)
    _currentDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    _loadCurrentDiary();
  }

  // ... (previous methods)

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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextDate = _currentDate.add(const Duration(days: 1));

    // Normalize comparison
    final nextDateOnly = DateTime(nextDate.year, nextDate.month, nextDate.day);

    if (!nextDateOnly.isAfter(today)) {
      setState(() {
        _currentDate = nextDateOnly;
      });
      _loadCurrentDiary();
    }
  }

  void _navigateToPrevious() {
    setState(() {
      _currentDate = _currentDate.subtract(const Duration(days: 1));
      // Normalize just in case, though subtract returns same time
      _currentDate =
          DateTime(_currentDate.year, _currentDate.month, _currentDate.day);
    });
    _loadCurrentDiary();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current =
        DateTime(_currentDate.year, _currentDate.month, _currentDate.day);
    final hasNext = current.isBefore(today);

    return Stack(
      children: [
        // 1. Static Background Image
        Positioned.fill(
          child: Image.asset(
            'assets/images/Diary_Background.png',
            fit: BoxFit.cover,
          ),
        ),
        // 2. Scaffold with transparent background
        Scaffold(
          backgroundColor: Colors.transparent,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final screenHeight = MediaQuery.of(context).size.height;
              const maxWidth = 600.0;
              final contentWidth = constraints.maxWidth > maxWidth
                  ? maxWidth
                  : constraints.maxWidth;

              // Estimate middle row height based on contentWidth
              final availableRowWidth = contentWidth - 60;
              final middleRowHeight = (availableRowWidth * 4 / 7);
              final minContentHeight = 100 + middleRowHeight + 260;
              final scrollHeight = minContentHeight > screenHeight
                  ? minContentHeight
                  : screenHeight;

              return SingleChildScrollView(
                child: Center(
                  child: SizedBox(
                    width: contentWidth,
                    height: scrollHeight,
                    child: SafeArea(
                      child: Column(
                        children: [
                          _buildHeader(context, colorScheme),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: _buildQuestionCard(colorScheme),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 3,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 30),
                                    child: _buildMoodSelection(colorScheme),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _buildWritingArea(context, colorScheme),
                          ),
                          // Bottom Navigation Buttons
                          const SizedBox(height: 14),
                          _buildBottomNavigation(hasNext, colorScheme),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, AppColorScheme colorScheme) {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[_currentDate.weekday - 1];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
                        '${_currentDate.year}.${_currentDate.month.toString().padLeft(2, '0')}.${_currentDate.day.toString().padLeft(2, '0')} ($weekday)',
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
          // Close Button
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/images/Cancel_Button.png',
                    width: 80,
                    height: 38,
                    fit: BoxFit.fill,
                  ),
                  const Text(
                    '닫기',
                    style: TextStyle(
                      fontFamily: 'BMJUA',
                      color: Color(0xFF5D4037),
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
    );
  }

  Widget _buildQuestionCard(AppColorScheme colorScheme) {
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
                  _currentDiary?.promptQuestion ?? '질문이 없습니다.',
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
    final selectedMood = _currentDiary?.mood;
    if (selectedMood == null) return const SizedBox.shrink();

    String assetPath;
    switch (selectedMood) {
      case 'happy':
        assetPath = 'assets/imoticon/Imoticon_Happy.png';
        break;
      case 'neutral':
        assetPath = 'assets/imoticon/Imoticon_Normal.png';
        break;
      case 'sad':
        assetPath = 'assets/imoticon/Imoticon_Sad.png';
        break;
      case 'excited':
        assetPath = 'assets/imoticon/Imoticon_Love.png';
        break;
      default:
        assetPath = 'assets/imoticon/Imoticon_Normal.png';
    }

    return Center(
      child: SizedBox(
        width: 140, // Increased size for background
        height: 140,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Image.asset(
              'assets/images/Popup_Background.png',
              fit: BoxFit.fill,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: -8,
              right: -8,
              child: Image.asset(
                'assets/images/Red_Pin.png',
                width: 40,
                height: 40,
              ),
            ),
          ],
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
      padding: const EdgeInsets.fromLTRB(55, 40, 28, 20),
      child: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: colorScheme.primaryButton,
              ),
            )
          : _currentDiary == null
              ? Center(
                  child: Text(
                    '작성된 일기가 없습니다.',
                    style: TextStyle(
                      fontFamily: 'BMJUA',
                      color: colorScheme.textHint,
                      fontSize: 18,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Text(
                    _decryptedContent,
                    style: TextStyle(
                      fontFamily: 'KyoboHandwriting2024psw',
                      color: colorScheme.textPrimary,
                      fontSize: 20,
                      height: 1.6,
                    ),
                  ),
                ),
    );
  }

  Widget _buildBottomNavigation(bool hasNext, AppColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavButton(
            onPressed: _navigateToPrevious,
            label: '이전',
            icon: Icons.arrow_back_ios_new,
            enabled: true,
          ),
          _buildNavButton(
            onPressed: hasNext ? _navigateToNext : null,
            label: '다음',
            icon: Icons.arrow_forward_ios,
            enabled: hasNext,
            isRight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required VoidCallback? onPressed,
    required String label,
    required IconData icon,
    required bool enabled,
    bool isRight = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
          width: 80,
          height: 40,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/Item_Background.png'),
              fit: BoxFit.fill,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: isRight
                ? [
                    Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'BMJUA',
                        color: Color(0xFF5D4037),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(icon, size: 14, color: const Color(0xFF5D4037)),
                  ]
                : [
                    Icon(icon, size: 14, color: const Color(0xFF5D4037)),
                    const SizedBox(width: 4),
                    Text(
                      label,
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
      ),
    );
  }
}
