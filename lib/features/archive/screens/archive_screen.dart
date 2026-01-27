import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/firestore_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../data/models/diary_model.dart';
import '../../morning/controllers/morning_controller.dart';

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
    _loadDiaries();
  }

  Future<void> _loadDiaries() async {
    final authController = context.read<AuthController>();
    final firestoreService = context.read<FirestoreService>();
    final userId = authController.currentUser?.uid;

    if (userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final diaries = await firestoreService.getUserDiaries(userId);
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
        (diary) =>
            diary.date.year == day.year &&
            diary.date.month == day.month &&
            diary.date.day == day.day,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.backgroundDark, Color(0xFF0F1419)],
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '아카이브',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '총 ${_diaries.length}개',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
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
          defaultTextStyle: const TextStyle(color: Colors.white),
          weekendTextStyle: const TextStyle(color: Colors.white70),
          outsideTextStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          selectedDecoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white),
          rightChevronIcon:
              const Icon(Icons.chevron_right, color: Colors.white),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: const TextStyle(color: Colors.white70),
          weekendStyle: const TextStyle(color: Colors.white70),
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
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  diary != null
                      ? _getMoodEmoji(diary.mood ?? '')
                      : '${day.day}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: diary != null ? 24 : 16,
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
                color: AppColors.primary.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  diary != null
                      ? _getMoodEmoji(diary.mood ?? '')
                      : '${day.day}',
                  style: TextStyle(
                    color: Colors.white,
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
    final diary = _getDiaryForDay(_selectedDay!);

    if (diary == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_busy,
              size: 48,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              DateFormat('M월 d일').format(_selectedDay!),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '이 날은 일기를 작성하지 않았습니다',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
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
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
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
                    Text(
                      DateFormat('M월 d일 (E)', 'ko_KR').format(diary.date),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${diary.wordCount}자 • ${_formatDuration(diary.writingDuration)}',
                      style: const TextStyle(
                        color: Colors.white54,
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
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.accent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      diary.promptQuestion!,
                      style: const TextStyle(
                        color: AppColors.accent,
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
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 3,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
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
            // 현재 화면
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: '홈',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.pets),
          label: '캐릭터',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: '친구',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: '아카이브',
        ),
      ],
    );
  }

  Future<void> _viewDiaryContent(DiaryModel diary) async {
    // 복호화
    setState(() {
      _isLoading = true;
    });

    try {
      final morningController = context.read<MorningController>();
      final decryptedContent = await morningController.loadDiaryContent(
        userId: diary.userId,
        date: diary.date,
        encryptedContent: diary.encryptedContent,
      );

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.cardDark,
            title: Text(
              DateFormat('M월 d일').format(diary.date),
              style: const TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (diary.promptQuestion != null) ...[
                    Text(
                      '질문: ${diary.promptQuestion}',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    decryptedContent,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('닫기'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('복호화 오류: $e')),
        );
      }
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}분 ${secs}초';
  }

  String _getMoodEmoji(String mood) {
    if (mood.isEmpty) return '📝';

    // 만약 mood 자체가 이모지라면 그대로 반환
    final emojiRegex = RegExp(
        r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F700}-\u{1F77F}\u{1F780}-\u{1F7FF}\u{1F800}-\u{1F8FF}\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}\u{1FA70}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
        unicode: true);
    if (emojiRegex.hasMatch(mood)) {
      return mood;
    }

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
}
