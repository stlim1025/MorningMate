import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../services/diary_service.dart';
import '../../auth/controllers/auth_controller.dart';
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

  @override
  Widget build(BuildContext context) {
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
              // 헤더
              _buildHeader(context),

              // 달력
              if (_isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildCalendar(),
                        const SizedBox(height: 16),
                        if (_selectedDay != null) _buildSelectedDayInfo(),
                        const SizedBox(height: 24),
                        _buildMyMemosButton(),
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

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '기록',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'BMJUA',
                ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                'assets/images/Cancel_Button.png',
                width: 50,
                height: 30,
                fit: BoxFit.fill,
                cacheWidth: 150, // Optimized
              ),
              Text(
                '${_diaries.where((d) => d.dateOnly.year == _focusedDay.year && d.dateOnly.month == _focusedDay.month).length}개',
                style: const TextStyle(
                  color: Color(0xFF4E342E),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'BMJUA',
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF8D6E63),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  diary != null
                      ? _getMoodEmoji(diary.mood ?? '')
                      : '${day.day}',
                  style: TextStyle(
                    fontFamily: 'NanumPenScript-Regular',
                    color:
                        diary != null ? Colors.white : const Color(0xFF4E342E),
                    fontSize: diary != null ? 24 : 22,
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
                child: Text(
                  diary != null
                      ? _getMoodEmoji(diary.mood ?? '')
                      : '${day.day}',
                  style: TextStyle(
                    fontFamily: 'NanumPenScript-Regular',
                    color: colorScheme.textPrimary,
                    fontSize: diary != null ? 24 : 20,
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
        child: Text(
          _getMoodEmoji(mood ?? ''),
          style: const TextStyle(fontSize: 24),
        ),
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
      moodEmoji: _getMoodEmoji(diary.mood ?? ''),
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

  String _getMoodEmoji(String mood) {
    if (mood.isEmpty) return '📝';
    final emojiRegex = RegExp(
        r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F700}-\u{1F77F}\u{1F780}-\u{1F7FF}\u{1F800}-\u{1F8FF}\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}\u{1FA70}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
        unicode: true);
    if (emojiRegex.hasMatch(mood)) return mood;
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
        return '📝';
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
  final String moodEmoji;

  const _AnimatedDiaryCard({
    required this.diary,
    required this.onTap,
    required this.dateText,
    required this.moodEmoji,
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
                  cacheWidth: 800, // Optimized
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
                        Text(
                          widget.moodEmoji,
                          style: const TextStyle(fontSize: 24),
                        ),
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
                                fontFamily: 'BMJUA',
                                fontSize: 16,
                                color: Color(0xFF4E342E),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
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
                            child: const Text(
                              '일기 내용 보기',
                              style: TextStyle(
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
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const dashWidth = 5.0;
    const dashSpace = 5.0;
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
