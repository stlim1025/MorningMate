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
import '../../common/widgets/custom_bottom_navigation_bar.dart';

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
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadDiaries();
  }

  Future<void> _loadDiaries() async {
    final authController = context.read<AuthController>();
    final diaryService = context.read<DiaryService>();
    final userId = authController.currentUser?.uid;

    if (userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final diaries = await diaryService.getUserDiaries(userId);
      setState(() {
        _diaries = diaries;
        _isLoading = false;
      });
    } catch (e) {
      print('일기 로드 오류: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 특정 날짜에 일기가 있는지 확인
  DiaryModel? _getDiaryForDay(DateTime day) {
    try {
      return _diaries.firstWhere(
        (diary) => diary.dateKey == DiaryModel.buildDateKey(day),
      );
    } catch (_) {
      return null;
    }
  }

  bool _hasWrittenToday() {
    return _getDiaryForDay(DateTime.now()) != null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: ResizeImage(AssetImage('assets/images/Ceiling.png'),
                width: 1080),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
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
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildHeader(BuildContext context, AppColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '마이페이지',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'BMJUA',
                  fontSize: 24,
                ),
          ),
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: Icon(
              Icons.settings,
              color: colorScheme.iconPrimary,
              size: 28,
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
        final hasWritten = _hasWrittenToday();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
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
              Row(
                children: [
                  // 프로필 이미지 (이니셜)
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.cardAccent.withOpacity(0.8),
                          colorScheme.secondaryButton.withOpacity(0.8),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.cardAccent.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        user?.nickname?.substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // 유저 정보 텍스트
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.nickname ?? '사용자',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.cardAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Lv. ${user?.characterLevel ?? 1}',
                            style: TextStyle(
                              color: colorScheme.cardAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // 작성 여부 배지
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: hasWritten
                                ? colorScheme.success.withOpacity(0.15)
                                : colorScheme.textHint.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            hasWritten ? '오늘 작성 완료 ✨' : '오늘 미작성 ✍️',
                            style: TextStyle(
                              color: hasWritten
                                  ? colorScheme.success
                                  : colorScheme.textHint,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 포인트 정보 박스
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.twig.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.twig.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/branch.png',
                          width: 24,
                          height: 24,
                          cacheWidth: 100,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${user?.points ?? 0}',
                          style: TextStyle(
                            color: colorScheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '가지',
                          style: TextStyle(
                            color: colorScheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '캐릭터 정보',
                  style: TextStyle(
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
            '일기 작성 정보',
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
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            fontFamily: 'NanumPenScript-Regular',
            color: colorScheme.textSecondary,
            fontSize: 18,
          ),
          weekendStyle: TextStyle(
            fontFamily: 'NanumPenScript-Regular',
            color: colorScheme.secondary,
            fontSize: 18,
          ),
        ),
        // 커스텀 빌더
        calendarBuilders: CalendarBuilders(
          // 1. 기본 날짜 (일기 없음)
          defaultBuilder: (context, day, focusedDay) {
            final diary = _getDiaryForDay(day);
            if (diary != null) {
              return _buildDayWithEmoji(day, diary.mood);
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
                    ? _buildMoodWidget(diary.mood ?? '', 40)
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
                    ? _buildMoodWidget(diary.mood ?? '', 40)
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
                    DateFormat('M월 d일').format(_selectedDay!),
                    style: const TextStyle(
                      fontFamily: 'BMJUA',
                      color: Color(0xFF4E342E),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '이 날은 일기를 작성하지 않았습니다',
                    style: TextStyle(
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
      dateText: DateFormat('M월 d일 기록').format(diary.dateOnly),
      moodWidget: _buildMoodWidget(diary.mood ?? '', 48), // Increased size
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return CustomBottomNavigationBar(
      currentIndex: 3,
      onTap: (index) {},
    );
  }

  Future<void> _viewDiaryContent(DiaryModel diary) async {
    final authController = context.read<AuthController>();
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;
    final userId = authController.currentUser?.uid;
    if (userId == null) return;

    final userModel = authController.userModel;
    if (userModel?.biometricEnabled == true) {
      final authenticated = await authController.authenticateWithBiometric();
      if (!authenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('생체 인증에 실패했습니다'),
              backgroundColor: colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        return;
      }
    }

    if (mounted) {
      context.push('/diary-detail', extra: {
        'diaries': _diaries,
        'initialDate': _selectedDay ?? DateTime.now(),
      });
    }
  }

  Widget _buildMoodWidget(String mood, double size) {
    if (mood.isEmpty) {
      return Text('📝', style: TextStyle(fontSize: size));
    }
    switch (mood) {
      case 'happy':
        return Image.asset('assets/imoticon/Imoticon_Happy.png',
            width: size, height: size);
      case 'neutral':
        return Image.asset('assets/imoticon/Imoticon_Normal.png',
            width: size, height: size);
      case 'sad':
        return Image.asset('assets/imoticon/Imoticon_Sad.png',
            width: size, height: size);
      case 'excited':
        return Image.asset('assets/imoticon/Imoticon_Love.png',
            width: size, height: size);
      default:
        // Check for emoji or just display text
        return Text(mood, style: TextStyle(fontSize: size));
    }
  }

  Widget _buildMyMemosButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: _AnimatedImageButton(
        onTap: _showMyMemosBottomSheet,
        imagePath: 'assets/images/MemoView_Button.png',
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
                image: DecorationImage(
                  image: ResizeImage(
                      AssetImage('assets/images/MyNote_Background.png'),
                      width: 800),
                  fit: BoxFit.fill,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 80),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .collection('memos')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.note_alt_outlined,
                                    size: 48, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  '작성한 메모가 없습니다',
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          );
                        }

                        final memos = snapshot.data!.docs;

                        return ListView.builder(
                          controller: scrollController,
                          itemCount: memos.length,
                          padding: const EdgeInsets.all(20),
                          itemBuilder: (context, index) {
                            final data =
                                memos[index].data() as Map<String, dynamic>;
                            final content = data['content'] as String? ?? '';
                            final heartCount = data['heartCount'] as int? ?? 0;
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
                                      AssetImage('assets/images/Memo.png'),
                                      width: 800),
                                  fit: BoxFit.fill,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                        );
                      },
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
        return '알 🥚';
      case CharacterState.cracking:
        return '금이 간 알 🥚✨';
      case CharacterState.hatching:
        return '부화 중 🐣';
      case CharacterState.baby:
        return '새끼 새 🐥';
      case CharacterState.young:
        return '아기 새 🐦';
      case CharacterState.adult:
        return '귀여운 새 🕊️';
      case CharacterState.sleeping:
        return '수면 중 💤';
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
                      Row(
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
                              widget.diary.promptQuestion!,
                              style: const TextStyle(
                                fontFamily: 'NanumPenScript-Regular',
                                fontSize: 18,
                                color: Color(0xFF5D4037),
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Divider 2
                      CustomPaint(
                        size: const Size(double.infinity, 1),
                        painter: _DottedLinePainter(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Content Preview
                    const Text(
                      '터치하여 내용을 확인하세요',
                      style: TextStyle(
                        fontFamily: 'NanumPenScript-Regular',
                        fontSize: 18,
                        color: Color(0xFF3E2723),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
