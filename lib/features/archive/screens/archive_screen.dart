import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../services/diary_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../character/controllers/character_controller.dart'; // Import CharacterController
import '../../../data/models/diary_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../character/widgets/character_display.dart';
import '../../../core/constants/room_assets.dart';
import '../../../core/widgets/memo_notification.dart';
import '../../morning/controllers/morning_controller.dart';
import '../../../core/localization/app_localizations.dart';
import '../../admin/controllers/admin_controller.dart';
import '../../../core/widgets/network_or_asset_image.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  List<DiaryModel> _diaries = [];
  bool _isLoading = true;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.twoWeeks;
  bool _isSettingsPressed = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadDiaries();
  }

  Future<void> _loadDiaries({bool silent = false}) async {
    final authController = context.read<AuthController>();
    final diaryService = context.read<DiaryService>();
    final userId = authController.currentUser?.uid;

    if (userId == null) return;

    if (!silent) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final diaries = await diaryService.getUserDiaries(userId);
      if (mounted) {
        setState(() {
          // 완료된 일기만 표시 (임시저장 제외)
          _diaries = diaries.where((d) => d.isCompleted).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('일기 로드 오류: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 오늘 일기가 리스트에 있는지 확인
  bool _hasTodayDiaryInList() {
    return _diaries
        .any((d) => d.dateKey == DiaryModel.buildDateKey(DateTime.now()));
  }

  // 특정 날짜에 일기가 있는지 확인
  DiaryModel? _getDiaryForDay(DateTime day) {
    try {
      // 이미 리스트 자체가 완료된 일기만 담고 있지만, 이중 확인
      return _diaries.firstWhere(
        (diary) =>
            diary.dateKey == DiaryModel.buildDateKey(day) && diary.isCompleted,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;

    return Consumer<MorningController>(
      builder: (context, morningController, child) {
        // 오늘 일기가 완료되었는데 리스트에 없다면 자동 새로고침 (작성 후 이동 시 대응)
        if (morningController.hasDiaryToday &&
            !_hasTodayDiaryInList() &&
            !_isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadDiaries(silent: true);
          });
        }

        return Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: ResizeImage(AssetImage('assets/images/Ceiling.png'),
                  width: 1080),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            bottom: false, // Allow background/content to extend lower
            child: Column(
              children: [
                // 헤더 (마이페이지 + 설정 버튼)
                _buildHeader(context, colorScheme),

                // 메인 컨텐츠
                if (_isLoading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // 프로필 섹션 (유저 정보 + 포인트)
                          _buildProfileSection(context, colorScheme),
                          const SizedBox(height: 20),

                          // 일기 작성 정보 (캘린더)
                          _buildCalendarSection(context, colorScheme),
                          const SizedBox(height: 100), // Adjusted for PageView
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AppColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppLocalizations.of(context)?.get('myPage') ?? 'My Page',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF4E342E), // Dark brown color
                  fontWeight: FontWeight.bold,
                  fontFamily: 'BMJUA',
                  fontSize: 24,
                ),
          ),
          GestureDetector(
            onTapDown: (_) => setState(() => _isSettingsPressed = true),
            onTapUp: (_) {
              setState(() => _isSettingsPressed = false);
              context.push('/settings');
            },
            onTapCancel: () => setState(() => _isSettingsPressed = false),
            child: Transform.scale(
              scale: _isSettingsPressed ? 0.95 : 1.0,
              child: Image.asset(
                'assets/icons/Setting_button.png',
                width: 40, // 50 -> 40 축소
                height: 40,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(
      BuildContext context, AppColorScheme colorScheme) {
    return Consumer<AuthController>(
      builder: (context, authController, child) {
        final user = authController.userModel;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 16), // Reduced vertical padding
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/Archive_Background.png'),
              fit: BoxFit.fill,
            ),
            // borderRadius, boxShadow 제거 (이미지 자체 형태 유지)
          ),
          child: Stack(
            children: [
              // Main Content (Character + Info)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Character Display
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CharacterDisplay(
                      isAwake: true,
                      characterLevel: user?.characterLevel ?? 1,
                      size: 80,
                      enableAnimation: true,
                      equippedItems: user?.equippedCharacterItems ?? {},
                    ),
                  ),
                  const SizedBox(width: 16),

                  // User Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nickname (avoid overlapping with point box)
                        Padding(
                          padding: const EdgeInsets.only(right: 125),
                          child: Text(
                            user?.nickname ?? '사용자',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'BMJUA',
                              color: Color(0xFF4E342E),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Level Tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Lv. ${user?.characterLevel ?? 1}',
                            style: const TextStyle(
                              color: Color(0xFF8D6E63),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'BMJUA',
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Experience Bar (Full Width)
                        if (user != null)
                          Container(
                            width: double.infinity,
                            height: 24,
                            child: Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                // 배경 틀
                                Image.asset(
                                  'assets/images/Challenge_ProgressBar_Empty.png',
                                  width: double.infinity,
                                  height: 24,
                                  fit: BoxFit.fill,
                                ),
                                // 경험치 게이지
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 5),
                                  child: ClipRect(
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: user.expProgress * 0.94,
                                      child: Image.asset(
                                        'assets/images/Challenge_ProgressBar.png',
                                        width: double.infinity,
                                        height: 14,
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                  ),
                                ),
                                // 경험치 텍스트
                                Center(
                                  child: Text(
                                    user.characterLevel >= 6
                                        ? (AppLocalizations.of(context)
                                                ?.get('maxLevel') ??
                                            'Max Level')
                                        : '${user.experience} / ${user.requiredExpForNextLevel}',
                                    style: const TextStyle(
                                      fontFamily: 'BMJUA',
                                      fontSize: 10,
                                      color: Color(0xFF5D4037),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              // Point Info Box (Positioned Top-Right)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 120,
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/TextBox_Background.png'),
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/branch.png',
                          width: 18,
                          height: 18,
                          cacheWidth: 72,
                          filterQuality: FilterQuality.medium,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${user?.points ?? 0}',
                          style: const TextStyle(
                            color: Color(0xFF5D4037),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'BMJUA',
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppLocalizations.of(context)?.get('branch') ??
                              'Branch',
                          style: TextStyle(
                            color: Color(0xFF8D6E63),
                            fontFamily: 'BMJUA',
                            fontSize: 12,
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
        );
      },
    );
  }

  Widget _buildCharacterSection(
      BuildContext context, AppColorScheme colorScheme) {
    return Consumer<CharacterController>(
      builder: (context, controller, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadowColor.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppLocalizations.of(context)?.get('characterInfo') ??
                      'Character Info',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'BMJUA',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 캐릭터 아이콘
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryButton.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getCharacterIcon(controller.characterState),
                      size: 48,
                      color: colorScheme.primaryButton,
                    ),
                  ),
                  const SizedBox(width: 24),

                  // 캐릭터 상태 텍스트
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStateName(controller.characterState),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        controller.currentAnimation,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCalendarSection(
      BuildContext context, AppColorScheme colorScheme) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          alignment: Alignment.centerLeft,
          child: Text(
            AppLocalizations.of(context)?.get('diaryWritingInfo') ??
                'Diary Writing Info',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'BMJUA',
              color: colorScheme.textPrimary,
            ),
          ),
        ),

        // 기존 캘린더
        _buildCalendar(),
        const SizedBox(height: 16),

        // 선택된 날짜 정보
        if (_selectedDay != null) _buildSelectedDayInfo(),

        const SizedBox(height: 24),
        _buildMyMemosButton(),
      ],
    );
  }

  // --- 기존 캘린더 및 관련 위젯 메서드 재사용 ---

  Widget _buildCalendar() {
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: ResizeImage(
              AssetImage('assets/images/Calander_Background.png'),
              width: 800),
          fit: BoxFit.fill,
        ),
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        locale: Localizations.localeOf(context).languageCode,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: _calendarFormat,
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        // 스타일링
        calendarStyle: CalendarStyle(
          defaultTextStyle: TextStyle(
            fontFamily: 'NanumPenScript-Regular',
            fontSize: 20,
            color: colorScheme.textPrimary,
          ),
          weekendTextStyle: TextStyle(
            fontFamily: 'NanumPenScript-Regular',
            fontSize: 20,
            color: colorScheme.secondary,
          ),
          outsideTextStyle: TextStyle(
            fontFamily: 'NanumPenScript-Regular',
            fontSize: 20,
            color: colorScheme.textHint.withOpacity(0.5),
          ),
          todayDecoration: const BoxDecoration(), // Builder에서 처리
          selectedDecoration: const BoxDecoration(), // Builder에서 처리
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontFamily: 'NanumPenScript-Regular',
            color: colorScheme.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          leftChevronIcon:
              Icon(Icons.chevron_left, color: colorScheme.iconPrimary),
          rightChevronIcon:
              Icon(Icons.chevron_right, color: colorScheme.iconPrimary),
        ),
        daysOfWeekHeight: 28, // 요일 라벨 높이 상향
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            fontFamily: 'NanumPenScript-Regular',
            color: colorScheme.textSecondary,
            fontSize: 18,
            height: 1.2, // 줄 높이 설정으로 잘림 방지
          ),
          weekendStyle: TextStyle(
            fontFamily: 'NanumPenScript-Regular',
            color: colorScheme.secondary,
            fontSize: 18,
            height: 1.2, // 줄 높이 설정으로 잘림 방지
          ),
        ),
        // 커스텀 빌더
        calendarBuilders: CalendarBuilders(
          // 1. 기본 날짜 (일기 없음)
          defaultBuilder: (context, day, focusedDay) {
            final diary = _getDiaryForDay(day);
            if (diary != null) {
              return _buildDayWithEmoji(
                  day, diary.moods.isNotEmpty ? diary.moods.first : null);
            }
            return Center(
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontFamily: 'NanumPenScript-Regular',
                  fontSize: 20,
                  color: colorScheme.textPrimary,
                ),
              ),
            );
          },
          // 2. 선택된 날짜
          selectedBuilder: (context, day, focusedDay) {
            final diary = _getDiaryForDay(day);
            return Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF8D6E63),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: diary != null
                    ? _buildMoodWidget(
                        diary.moods.isNotEmpty ? diary.moods.first : '', 40)
                    : Text(
                        '${day.day}',
                        style: TextStyle(
                          fontFamily: 'NanumPenScript-Regular',
                          color: const Color(0xFF4E342E),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            );
          },
          // 3. 오늘 날짜
          todayBuilder: (context, day, focusedDay) {
            final diary = _getDiaryForDay(day);
            // 선택된 날짜와 같으면 selectedBuilder가 우선하므로 여기선 선택 안 된 오늘만 처리
            return Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                border: Border.all(
                  color: colorScheme.primaryButton.withOpacity(0.5),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(20), // 비정형 느낌을 위해 약간 둥글게
              ),
              child: Center(
                child: diary != null
                    ? _buildMoodWidget(
                        diary.moods.isNotEmpty ? diary.moods.first : '', 40)
                    : Text(
                        '${day.day}',
                        style: TextStyle(
                          fontFamily: 'NanumPenScript-Regular',
                          color: colorScheme.textPrimary, // Fixed color
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDayWithEmoji(DateTime day, String? mood) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: _buildMoodWidget(mood ?? '', 40),
      ),
    );
  }

  Widget _buildSelectedDayInfo() {
    final diary = _getDiaryForDay(_selectedDay!);

    if (diary == null) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/Archive_Background.png',
                fit: BoxFit.fill,
                cacheWidth: 400,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Column(
                children: [
                  const Icon(
                    Icons.event_busy,
                    size: 48,
                    color: Color(0xFF8D6E63),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)?.getFormat('monthDayFormat', {
                          'month': _selectedDay!.month.toString(),
                          'day': _selectedDay!.day.toString(),
                        }) ??
                        DateFormat('M월 d일').format(_selectedDay!),
                    style: const TextStyle(
                      fontFamily: 'BMJUA',
                      color: Color(0xFF4E342E),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)?.get('noDiaryForDay') ??
                        '이 날은 일기를 작성하지 않았습니다',
                    style: const TextStyle(
                      fontFamily: 'BMJUA',
                      color: Color(0xFF8D6E63),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return _AnimatedDiaryCard(
      diary: diary,
      onTap: () => _viewDiaryContent(diary),
      dateText: AppLocalizations.of(context)?.getFormat('diaryRecordForDay', {
            'date': AppLocalizations.of(context)?.getFormat('monthDayFormat', {
                  'month': diary.dateOnly.month.toString(),
                  'day': diary.dateOnly.day.toString(),
                }) ??
                DateFormat('M월 d일').format(diary.dateOnly)
          }) ??
          DateFormat('M월 d일 기록').format(diary.dateOnly),
      moodWidget: _buildMoodWidget(
          diary.moods.isNotEmpty ? diary.moods.first : '',
          64), // Increased size from 48 to 64
    );
  }

  Future<void> _viewDiaryContent(DiaryModel diary) async {
    final authController = context.read<AuthController>();
    final userId = authController.currentUser?.uid;
    if (userId == null) return;

    final userModel = authController.userModel;
    if (userModel?.biometricEnabled == true) {
      final authenticated = await authController.authenticateWithBiometric(
        localizedReason: AppLocalizations.of(context)
                ?.get('biometricAuthReasonPastRecords') ??
            '과거 기록을 확인하기 위해 인증이 필요합니다',
      );
      if (!authenticated) {
        if (mounted) {
          MemoNotification.show(
              context,
              AppLocalizations.of(context)?.get('biometricAuthFailed') ??
                  '생체 인증에 실패했습니다. 🔒');
        }
        return;
      }
    }

    if (mounted) {
      await context.push('/diary-detail', extra: {
        'diaries': _diaries,
        'initialDate': _selectedDay ?? DateTime.now(),
      });
      if (mounted) {
        _loadDiaries(silent: true);
      }
    }
  }

  Widget _buildMoodWidget(String mood, double size) {
    if (mood.isEmpty) {
      return Text('📝', style: TextStyle(fontSize: size * 0.8));
    }

    try {
      final emoticon = RoomAssets.emoticons.firstWhere(
        (e) => e.id == mood,
        orElse: () => RoomAssets.emoticons[1], // Default to normal
      );

      if (emoticon.imagePath != null) {
        return NetworkOrAssetImage(
          imagePath: emoticon.imagePath!,
          width: size,
          height: size,
          fit: BoxFit.contain,
        );
      }
    } catch (_) {}

    return Text(mood, style: TextStyle(fontSize: size * 0.8));
  }

  Widget _buildMyMemosButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: _AnimatedImageButton(
        onTap: _showMyMemosBottomSheet,
        imagePath: 'assets/images/MemoView_Button.png',
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(context)?.get('collectMyMemos') ??
                    'Collect My Memos',
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'KyoboHandwriting2024psw',
                  color: Color(0xFF4E342E),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFF4E342E),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMyMemosBottomSheet() {
    final authController = context.read<AuthController>();
    final userId = authController.currentUser?.uid;

    if (userId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // Fixed Background Image
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/MyNote_Background.png',
                      fit: BoxFit.fill,
                      cacheWidth: 800,
                    ),
                  ),
                  // Scrollable Content
                  Positioned.fill(
                    top:
                        45, // Add top padding to keep content inside the paper area
                    child: CustomScrollView(
                      controller: scrollController,
                      slivers: [
                        // Header Section
                        SliverToBoxAdapter(
                          child: Column(
                            children: [
                              const SizedBox(
                                  height:
                                      10), // Reduced since Positioned adds 45
                              Text(
                                AppLocalizations.of(context)?.get('myMemos') ??
                                    '내 메모',
                                style: const TextStyle(
                                  fontFamily: 'BMJUA',
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4E342E),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 40),
                                child: CustomPaint(
                                  size: const Size(double.infinity, 1),
                                  painter: _DottedLinePainter(),
                                ),
                              ),
                              const SizedBox(height: 15),
                            ],
                          ),
                        ),
                        // Memo List or Empty State
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .collection('memos')
                              .orderBy('createdAt', descending: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.only(top: 50),
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                ),
                              );
                            }

                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 100),
                                  child: Column(
                                    children: [
                                      Icon(Icons.note_alt_outlined,
                                          size: 48,
                                          color: Colors.grey.shade300),
                                      const SizedBox(height: 16),
                                      Text(
                                        AppLocalizations.of(context)
                                                ?.get('noMemos') ??
                                            '작성한 메모가 없습니다',
                                        style: TextStyle(
                                            color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final memos = snapshot.data!.docs;

                            return SliverPadding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final data = memos[index].data()
                                        as Map<String, dynamic>;
                                    final content =
                                        data['content'] as String? ?? '';
                                    final heartCount =
                                        data['heartCount'] as int? ?? 0;
                                    final createdAt =
                                        data['createdAt'] as String? ?? '';

                                    DateTime? date;
                                    try {
                                      date = DateTime.parse(createdAt);
                                    } catch (_) {}

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(24),
                                      decoration: const BoxDecoration(
                                        image: DecorationImage(
                                          image: ResizeImage(
                                              AssetImage(
                                                  'assets/images/Memo.png'),
                                              width: 800),
                                          fit: BoxFit.fill,
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  content,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    height: 1.4,
                                                    color: Colors.black87,
                                                    fontFamily:
                                                        'NanumPenScript-Regular',
                                                  ),
                                                ),
                                                if (date != null) ...[
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    DateFormat('yyyy.MM.dd')
                                                        .format(date),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.black45,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            children: [
                                              Image.asset(
                                                'assets/images/Pink_Heart.png',
                                                width: 20,
                                                height: 20,
                                                cacheWidth: 100, // Optimized
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '$heartCount',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: Color(0xFFFF8EAB),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  childCount: memos.length,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  IconData _getCharacterIcon(CharacterState state) {
    switch (state) {
      case CharacterState.egg:
        return Icons.egg;
      case CharacterState.cracking:
        return Icons.egg_alt;
      case CharacterState.hatching:
        return Icons.cruelty_free;
      case CharacterState.baby:
        return Icons.pets;
      case CharacterState.young:
        return Icons.flutter_dash;
      case CharacterState.adult:
        return Icons.flight;
      case CharacterState.sleeping:
        return Icons.bedtime;
    }
  }

  String _getStateName(CharacterState state) {
    switch (state) {
      case CharacterState.egg:
        return AppLocalizations.of(context)?.get('state_egg') ?? '알 🥚';
      case CharacterState.cracking:
        return AppLocalizations.of(context)?.get('state_cracking') ??
            '금이 간 알 🥚✨';
      case CharacterState.hatching:
        return AppLocalizations.of(context)?.get('state_hatching') ?? '부화 중 🐣';
      case CharacterState.baby:
        return AppLocalizations.of(context)?.get('state_baby') ?? '새끼 새 🐥';
      case CharacterState.young:
        return AppLocalizations.of(context)?.get('state_young') ?? '아기 새 🐦';
      case CharacterState.adult:
        return AppLocalizations.of(context)?.get('state_adult') ?? '귀여운 새 🕊️';
      case CharacterState.sleeping:
        return AppLocalizations.of(context)?.get('state_sleeping') ?? '수면 중 💤';
    }
  }
}

class _AnimatedImageButton extends StatefulWidget {
  final VoidCallback onTap;
  final String imagePath;
  final Widget? child;

  const _AnimatedImageButton({
    required this.onTap,
    required this.imagePath,
    this.child,
  });

  @override
  State<_AnimatedImageButton> createState() => _AnimatedImageButtonState();
}

class _AnimatedImageButtonState extends State<_AnimatedImageButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              widget.imagePath,
              width: double.infinity,
              height: 60,
              fit: BoxFit.fill,
              cacheWidth: 800, // Optimized
            ),
            if (widget.child != null) widget.child!,
          ],
        ),
      ),
    );
  }
}

class _AnimatedDiaryCard extends StatefulWidget {
  final DiaryModel diary;
  final VoidCallback onTap;
  final String dateText;
  final Widget moodWidget;

  const _AnimatedDiaryCard({
    required this.diary,
    required this.onTap,
    required this.dateText,
    required this.moodWidget,
  });

  @override
  State<_AnimatedDiaryCard> createState() => _AnimatedDiaryCardState();
}

class _AnimatedDiaryCardState extends State<_AnimatedDiaryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: Image.asset(
                  'assets/images/Archive_Background.png',
                  fit: BoxFit.fill,
                  cacheWidth: 400, // Optimized
                ),
              ),
              // Content
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top: Emoji + Date
                    Row(
                      children: [
                        widget.moodWidget,
                        const SizedBox(width: 12),
                        Text(
                          widget.dateText,
                          style: const TextStyle(
                            fontFamily: 'BMJUA',
                            fontSize: 20,
                            color: Color(0xFF4E342E),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Divider 1
                    CustomPaint(
                      size: const Size(double.infinity, 1),
                      painter: _DottedLinePainter(),
                    ),
                    const SizedBox(height: 16),
                    // Question
                    if (widget.diary.promptQuestion != null) ...[
                      Builder(builder: (context) {
                        String displayQuestion = widget.diary.promptQuestion!;

                        // 영어 모드일 경우 번역 시도
                        if (Localizations.localeOf(context).languageCode ==
                            'en') {
                          // 정규화 함수 (공백, 문장부호 제거)
                          String normalize(String text) {
                            return text.replaceAll(RegExp(r'[\s\?\!.,]'), '');
                          }

                          final String normalizedOriginal =
                              normalize(displayQuestion);

                          // 번역 맵에서 검색
                          for (var entry in AdminController
                              .questionTranslationMap.entries) {
                            if (normalize(entry.key) == normalizedOriginal) {
                              displayQuestion = entry.value;
                              break;
                            }
                          }
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.lightbulb_outline,
                                color: Color(0xFF8D6E63),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                displayQuestion,
                                style: const TextStyle(
                                  fontFamily: 'BMJUA',
                                  fontSize: 16,
                                  color: Color(0xFF4E342E),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 16),
                    ],
                    // Divider 2
                    CustomPaint(
                      size: const Size(double.infinity, 1),
                      painter: _DottedLinePainter(),
                    ),
                    const SizedBox(height: 16),
                    // Bottom: View Content
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Color(0xFF4E342E),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            padding: const EdgeInsets.only(bottom: 1),
                            child: Text(
                              AppLocalizations.of(context)
                                      ?.get('viewDiaryContent') ??
                                  '일기 내용 보기',
                              style: const TextStyle(
                                fontFamily: 'BMJUA',
                                fontSize: 18,
                                color: Color(0xFF4E342E),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 20,
                            color: Color(0xFF4E342E),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8D6E63).withOpacity(0.5)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
