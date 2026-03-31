import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/diary_model.dart';
import '../../../data/models/question_model.dart';
import '../../morning/controllers/morning_controller.dart';
import '../../../core/constants/room_assets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../admin/controllers/admin_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../services/diary_service.dart';
import '../../../core/widgets/network_or_asset_image.dart';
import '../../character/widgets/character_display.dart';

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
  late List<DiaryModel> _localDiaries;

  @override
  void initState() {
    super.initState();
    _localDiaries = List<DiaryModel>.from(widget.diaries);
    // Normalize to date only (00:00:00)
    _currentDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    _loadCurrentDiary();
  }

  // ... (previous methods)

  Future<void> _loadCurrentDiaryByDate() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authController = context.read<AuthController>();
      final diaryService = context.read<DiaryService>();
      final userId = authController.currentUser?.uid;

      if (userId != null) {
        final diary = await diaryService.getDiaryByDate(userId, _currentDate);
        if (mounted) {
          setState(() {
            _currentDiary = diary;
            if (_currentDiary != null) {
              // Update local list with fresh data
              final index = _localDiaries
                  .indexWhere((d) => d.dateKey == _currentDiary!.dateKey);
              if (index != -1) {
                _localDiaries[index] = _currentDiary!;
              } else {
                _localDiaries.add(_currentDiary!);
              }
            } else {
              _isLoading = false;
              _decryptedContent = '';
            }
          });
          if (_currentDiary != null) {
            await _fetchDecryptedContent();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _loadCurrentDiary() {
    try {
      _currentDiary = _localDiaries.firstWhere(
        (d) => d.dateKey == DiaryModel.buildDateKey(_currentDate),
      );
    } catch (_) {
      _currentDiary = null;
    }

    if (_currentDiary != null) {
      _fetchDecryptedContent();
    } else {
      _loadCurrentDiaryByDate(); // Fallback to DB if not in list
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
                                  child: _buildPhotoArea(colorScheme),
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
      padding: EdgeInsets.fromLTRB(8, 16, 8, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Date Icon with Text Overlay
          Stack(
            alignment: Alignment.center,
            children: [
              Image.asset('assets/images/Date_Icon.png',
                  width: 170,
                  height: 44,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.medium),
              Positioned(
                left: 10,
                child: Padding(
                  padding: EdgeInsets.only(top: 2.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: colorScheme.textPrimary,
                      ),
                      SizedBox(width: 8),
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
                          fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA',
                          color: colorScheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Action Buttons (Edit & Close)
          Row(
            children: [
              // Edit Button
              if (_currentDiary != null)
                Padding(
                  padding: const EdgeInsets.only(top: 5, right: 4),
                  child: GestureDetector(
                    onTap: () async {
                      await context.push('/writing', extra: {
                        'isEditing': true,
                        'existingDiary': _currentDiary,
                        'existingContent': _decryptedContent,
                        'initialQuestion': QuestionModel(
                          id: 'existing',
                          text: _currentDiary!.promptQuestion ?? '',
                          engText: _currentDiary!.promptQuestionEng,
                          category: 'default',
                        ),
                      });
                      if (context.mounted) {
                        _loadCurrentDiaryByDate();
                      }
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset(
                          'assets/images/Confirm_Button.png',
                          width: 90,
                          height: 43,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                          cacheHeight: 120,
                        ),
                        Text(
                          AppLocalizations.of(context)?.get('edit') ?? 'Edit',
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
                ),
              // Close Button
              Padding(
                padding: EdgeInsets.only(top: 5),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'assets/images/Cancel_Button.png',
                        width: 90,
                        height: 43,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                        cacheHeight: 120,
                      ),
                      Text(
                        AppLocalizations.of(context)?.get('close') ?? 'Close',
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(AppColorScheme colorScheme) {
    // 1. 현재 질문 텍스트 가져오기
    String questionText = _currentDiary?.promptQuestion ??
        (AppLocalizations.of(context)?.get('noQuestion') ?? 'No Question');

    // 2. 언어 설정 확인 (다국어 번역 시도: 영어, 일본어)
    final langCode = Localizations.localeOf(context).languageCode;
    if ((langCode == 'en' || langCode == 'ja') &&
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
          final translated = entry.value[langCode];
          if (translated != null && translated.isNotEmpty) {
            questionText = translated;
          }
          break;
        }
      }
    }

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
                      'Today\'s Question',
                  style: TextStyle(
                    fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA',
                    color: colorScheme.textSecondary.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                // Padding 추가로 텍스트가 너무 가장자리에 붙지 않게 함
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    questionText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA', // 한글 원문일 경우 BMJUA
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

  void _showEnlargedPhoto(BuildContext context, String imageUrl) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // 중앙 확대 이미지
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: NetworkOrAssetImage(
                      imagePath: imageUrl,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              // 우측 상단 X 버튼
              Positioned(
                top: MediaQuery.of(context).padding.top + 20,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Image.asset(
                    'assets/icons/X_Button.png',
                    width: 50,
                    height: 50,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhotoArea(AppColorScheme colorScheme) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/Popup_Background.png'),
            fit: BoxFit.fill,
          ),
        ),
        child: _currentDiary?.photoUrl != null
            ? GestureDetector(
                onTap: () => _showEnlargedPhoto(context, _currentDiary!.photoUrl!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: NetworkOrAssetImage(
                    imagePath: _currentDiary!.photoUrl!,
                    fit: BoxFit.contain,
                  ),
                ),
              )
            : Center(
                child: _currentDiary?.moods.isNotEmpty == true
                    ? NetworkOrAssetImage(
                        imagePath: RoomAssets.emoticons
                                .firstWhere(
                                  (e) => e.id == _currentDiary!.moods.first,
                                  orElse: () => RoomAssets.emoticons[0],
                                )
                                .imagePath ??
                            '',
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                      )
                    : CharacterDisplay(
                        key: ValueKey(
                            'detail_fallback_${_currentDiary?.id ?? _currentDate.millisecondsSinceEpoch}'),
                        characterLevel: _currentDiary?.characterLevel ?? 1,
                        equippedItems:
                            _currentDiary?.equippedCharacterItems ?? {},
                        size: 150,
                        isAwake: true,
                        enableAnimation: false,
                      ),
              ),
      ),
    );
  }

  // Removed _buildMoodSelection, _buildSingleMood, _buildMultipleMoods as they are no longer used.

  Widget _buildWritingArea(BuildContext context, AppColorScheme colorScheme) {
    final langCode = Localizations.localeOf(context).languageCode;

    // 날씨 텍스트 다국어 처리 (에셋 이미지로 대체됨)

    // 기분 이모티콘
    final moodId = _currentDiary?.moods.isNotEmpty == true
        ? _currentDiary!.moods.first
        : null;
    final moodEmoticon = moodId != null
        ? RoomAssets.emoticons.firstWhere(
            (e) => e.id == moodId,
            orElse: () => RoomAssets.emoticons[0],
          )
        : null;

    // 날씨 레이블 (다국어)
    final weatherTitle = {
      'ko': '날씨',
      'en': 'Weather',
      'ja': '天気',
    }[langCode] ?? '날씨';

    final Map<String, String> weatherIcons = {
      'sunny': 'assets/icons/Diary_Sun.png',
      'partlyCloudy': 'assets/icons/DIary_SunCloud.png',
      'cloudy': 'assets/icons/Diary_Cloud.png',
      'rainy': 'assets/icons/Diray_Rain.png',
      'snowy': 'assets/icons/Diary_Snow.png',
    };
    final weatherIconPath = weatherIcons[_currentDiary?.weather] ?? 'assets/icons/Diary_Sun.png';

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
      padding: EdgeInsets.fromLTRB(48, 20, 28, 20),
      child: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: colorScheme.primaryButton,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 날씨 & 기분 표시 행 (Wrap으로 overflow 방지)
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 0,
                    runSpacing: 4,
                    children: [
                      // 날씨
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$weatherTitle: ',
                              style: TextStyle(
                                fontFamily: 'BMJUA',
                                fontSize: 22,
                                color: colorScheme.textPrimary,
                              ),
                            ),
                            Image.asset(
                              weatherIconPath,
                              width: 32,
                              height: 32,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text(
                          '/',
                          style: TextStyle(
                            fontFamily: 'BMJUA',
                            fontSize: 22,
                            color: colorScheme.textHint,
                          ),
                        ),
                      ),
                      // 기분
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$moodTitle: ',
                              style: TextStyle(
                                fontFamily: 'BMJUA',
                                fontSize: 22,
                                color: colorScheme.textPrimary,
                              ),
                            ),
                            if (moodEmoticon != null)
                              NetworkOrAssetImage(
                                imagePath: moodEmoticon.imagePath ?? '',
                                width: 40,
                                height: 40,
                                fit: BoxFit.contain,
                              )
                            else
                              Text(
                                '❓',
                                style: TextStyle(fontSize: 18),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _currentDiary == null
                      ? Center(
                          child: Text(
                            AppLocalizations.of(context)?.get('noDiaryContent') ??
                                'No content.',
                            style: TextStyle(
                              fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA',
                              color: colorScheme.textHint,
                              fontSize: 18,
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          child: SizedBox(
                            width: double.infinity,
                            child: Text(
                              _decryptedContent,
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontFamily: 'KyoboHandwriting2024psw',
                                color: colorScheme.textPrimary,
                                fontSize: 20,
                                height: 1.6,
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildBottomNavigation(bool hasNext, AppColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 14),
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
          decoration: BoxDecoration(
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
                      style: TextStyle(
                        fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA',
                        color: Color(0xFF5D4037),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(icon, size: 14, color: Color(0xFF5D4037)),
                  ]
                : [
                    Icon(icon, size: 14, color: Color(0xFF5D4037)),
                    SizedBox(width: 4),
                    Text(
                      label,
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
      ),
    );
  }
}
