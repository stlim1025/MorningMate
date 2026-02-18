import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../../../data/models/diary_model.dart';
import '../../morning/controllers/morning_controller.dart';
import '../../../core/constants/room_assets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../admin/controllers/admin_controller.dart'; // Import AdminController correctly

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
                              children: [
                                Expanded(
                                  child: _buildQuestionCard(colorScheme),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildMoodSelection(colorScheme),
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
    final weekdayKeys = [
      'weekday_mon',
      'weekday_tue',
      'weekday_wed',
      'weekday_thu',
      'weekday_fri',
      'weekday_sat',
      'weekday_sun'
    ];
    final weekday = AppLocalizations.of(context)
            ?.get(weekdayKeys[_currentDate.weekday - 1]) ??
        '';

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
                  width: 220, height: 50, fit: BoxFit.fill),
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
                        AppLocalizations.of(context)
                                ?.getFormat('fullDateFormat', {
                              'year': _currentDate.year.toString(),
                              'month': _currentDate.month.toString(),
                              'day': _currentDate.day.toString(),
                              'weekday': weekday
                            }) ??
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
                  Text(
                    AppLocalizations.of(context)?.get('close') ?? 'Close',
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
    // 1. 현재 질문 텍스트 가져오기
    String questionText = _currentDiary?.promptQuestion ??
        (AppLocalizations.of(context)?.get('noQuestion') ?? 'No Question');

    // 2. 언어 설정 확인 (영어 모드일 때만 번역 시도)
    if (Localizations.localeOf(context).languageCode == 'en' &&
        _currentDiary?.promptQuestion != null) {
      final String originalText = _currentDiary!.promptQuestion!;

      // 정규화 함수 (공백, 문장부호 제거)
      String normalize(String text) {
        return text.replaceAll(RegExp(r'[\s\?\!.,]'), '');
      }

      final String normalizedOriginal = normalize(originalText);

      // 번역 맵에서 검색
      for (var entry in AdminController.questionTranslationMap.entries) {
        if (normalize(entry.key) == normalizedOriginal) {
          questionText = entry.value;
          break;
        }
      }
    }

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
                      'Today\'s Question',
                  style: TextStyle(
                    fontFamily: 'BMJUA',
                    color: colorScheme.textSecondary.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // Padding 추가로 텍스트가 너무 가장자리에 붙지 않게 함
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    questionText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'BMJUA', // 한글 원문일 경우 BMJUA
                      // 영어일 경우 가독성을 위해 다른 폰트를 고려할 수도 있으나 통일성 유지
                      color: colorScheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
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
    final moods = _currentDiary?.moods ?? [];
    if (moods.isEmpty) return const SizedBox.shrink();

    return AspectRatio(
      aspectRatio: 1.0,
      child: Padding(
        padding: const EdgeInsets.all(20.0), // 외부 여백을 주어 배경 이미지 자체의 크기를 줄임
        child: moods.length == 1
            ? _buildSingleMood(moods.first)
            : _buildMultipleMoods(moods),
      ),
    );
  }

  Widget _buildSingleMood(String moodId) {
    final emoticon = RoomAssets.emoticons.firstWhere(
      (e) => e.id == moodId,
      orElse: () => RoomAssets.emoticons[1],
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        Image.asset(
          'assets/images/Popup_Background.png',
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.fill,
        ),
        Padding(
          padding: const EdgeInsets.all(12.0), // 배경이 작아졌으므로 내부 여백은 다시 줄임
          child: Image.asset(
            emoticon.imagePath!,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }

  Widget _buildMultipleMoods(List<String> moods) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/Popup_Background.png'),
          fit: BoxFit.fill,
        ),
      ),
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          spacing: 4,
          runSpacing: 4,
          children: moods.map((moodId) {
            final emoticon = RoomAssets.emoticons.firstWhere(
              (e) => e.id == moodId,
              orElse: () => RoomAssets.emoticons[1],
            );

            return SizedBox(
              width: moods.length <= 2 ? 60 : 45,
              height: moods.length <= 2 ? 60 : 45,
              child: Image.asset(emoticon.imagePath!, fit: BoxFit.contain),
            );
          }).toList(),
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
                    AppLocalizations.of(context)?.get('noDiaryContent') ??
                        'No content.',
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
            label: AppLocalizations.of(context)?.get('previous') ?? 'Previous',
            icon: Icons.arrow_back_ios_new,
            enabled: true,
          ),
          _buildNavButton(
            onPressed: hasNext ? _navigateToNext : null,
            label: AppLocalizations.of(context)?.get('next') ?? 'Next',
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
