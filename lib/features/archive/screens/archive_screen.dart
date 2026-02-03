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
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
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
            '아카이브',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.cardAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '총 ${_diaries.length}개',
              style: TextStyle(
                color: colorScheme.cardAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
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
            color: colorScheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          weekendTextStyle: TextStyle(
            color: colorScheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          outsideTextStyle: TextStyle(
            color: colorScheme.textHint.withOpacity(0.5),
          ),
          selectedDecoration: BoxDecoration(
            color: colorScheme.calendarSelected,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colorScheme.calendarSelected.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          todayDecoration: BoxDecoration(
            color: colorScheme.calendarToday.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: colorScheme.calendarToday, width: 1.5),
          ),
          markerDecoration: BoxDecoration(
            color: colorScheme.accent,
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            color: colorScheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          leftChevronIcon:
              Icon(Icons.chevron_left, color: colorScheme.iconPrimary),
          rightChevronIcon:
              Icon(Icons.chevron_right, color: colorScheme.iconPrimary),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: colorScheme.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          weekendStyle: TextStyle(
            color: colorScheme.secondary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        // 일기가 있는 날 표시
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            final diary = _getDiaryForDay(day);
            if (diary != null) {
              return _buildDayWithEmoji(day, diary.mood);
            }
            return null;
          },
          selectedBuilder: (context, day, focusedDay) {
            final diary = _getDiaryForDay(day);
            return Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorScheme.calendarSelected.withOpacity(0.2),
                shape: BoxShape.circle,
                border:
                    Border.all(color: colorScheme.calendarSelected, width: 2),
              ),
              child: Center(
                child: Text(
                  diary != null
                      ? _getMoodEmoji(diary.mood ?? '')
                      : '${day.day}',
                  style: TextStyle(
                    color:
                        diary != null ? Colors.white : colorScheme.textPrimary,
                    fontSize: diary != null ? 24 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
          todayBuilder: (context, day, focusedDay) {
            final diary = _getDiaryForDay(day);
            return Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorScheme.calendarToday.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.calendarToday.withOpacity(0.5),
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
              ),
              child: Center(
                child: Text(
                  diary != null
                      ? _getMoodEmoji(diary.mood ?? '')
                      : '${day.day}',
                  style: TextStyle(
                    color:
                        diary != null ? Colors.white : colorScheme.textPrimary,
                    fontSize: diary != null ? 24 : 16,
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
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;
    final diary = _getDiaryForDay(_selectedDay!);

    if (diary == null) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
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
        child: Column(
          children: [
            Icon(
              Icons.event_busy,
              size: 48,
              color: colorScheme.textHint.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              DateFormat('M월 d일').format(_selectedDay!),
              style: TextStyle(
                color: colorScheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '이 날은 일기를 작성하지 않았습니다',
              style: TextStyle(
                color: colorScheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _getMoodEmoji(diary.mood ?? ''),
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          DateFormat('M월 d일 (E)', 'ko_KR')
                              .format(diary.dateOnly),
                          style: TextStyle(
                            color: colorScheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('HH:mm').format(diary.createdAt),
                          style: TextStyle(
                            color: colorScheme.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${diary.wordCount}자 • ${_formatDuration(diary.writingDuration)}',
                      style: TextStyle(
                        color: colorScheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (diary.promptQuestion != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryButton.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: colorScheme.accent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      diary.promptQuestion!,
                      style: TextStyle(
                        color: colorScheme.accent,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _viewDiaryContent(diary),
              icon: const Icon(Icons.visibility),
              label: const Text('일기 내용 보기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primaryButton,
                foregroundColor: colorScheme.primaryButtonForeground,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 3,
      selectedItemColor: colorScheme.tabSelected,
      unselectedItemColor: colorScheme.tabUnselected,
      backgroundColor:
          Theme.of(context).bottomNavigationBarTheme.backgroundColor,
      elevation: 8,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/morning');
            break;
          case 1:
            context.go('/character');
            break;
          case 2:
            context.go('/social');
            break;
          case 3:
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
        BottomNavigationBarItem(icon: Icon(Icons.pets), label: '캐릭터'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: '친구'),
        BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today), label: '아카이브'),
      ],
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

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}분 ${secs}초';
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
      child: ElevatedButton.icon(
        onPressed: _showMyMemosBottomSheet,
        icon: const Icon(Icons.note_alt_outlined),
        label: const Text('내 메모 모아보기'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.amber.shade100,
          foregroundColor: Colors.brown,
          elevation: 0,
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
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      '내 메모',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                    ),
                  ),
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
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF9C4),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
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
                                      const Icon(Icons.favorite,
                                          color: Colors.red, size: 20),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$heartCount',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.red,
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
