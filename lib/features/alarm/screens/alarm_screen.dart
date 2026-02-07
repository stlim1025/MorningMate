import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:alarm/alarm.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../services/alarm_service.dart';
import '../screens/alarm_ring_screen.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  AlarmSettings? _activeAlarm;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSingleAlarm();
  }

  // 1. 기존 알람 로드 및 없으면 바로 선택창 띄우기
  Future<void> _loadSingleAlarm() async {
    final alarms = await AlarmService.getAlarms();
    setState(() {
      _activeAlarm = alarms.isNotEmpty ? alarms.first : null;
      _isLoading = false;
    });

    // 설정된 알람이 없으면 페이지 진입 시 바로 시간 선택창 오픈
    if (_activeAlarm == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _selectAndScheduleAlarm();
      });
    }
  }

  // 2. 시간 선택 및 알람 등록 로직
  Future<void> _selectAndScheduleAlarm() async {
    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: _activeAlarm != null
          ? TimeOfDay.fromDateTime(_activeAlarm!.dateTime)
          : TimeOfDay.now(),
      helpText: '알람 시간 선택',
      confirmText: '확인',
      cancelText: '취소',
      hourLabelText: '시',
      minuteLabelText: '분',
    );

    if (selectedTime != null) {
      final now = DateTime.now();
      var alarmDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      // 이미 지난 시간이라면 내일로 설정
      if (alarmDateTime.isBefore(now)) {
        alarmDateTime = alarmDateTime.add(const Duration(days: 1));
      }

      // 기존 알람이 있다면 삭제 (하나만 유지)
      if (_activeAlarm != null) {
        await AlarmService.stopAlarm(_activeAlarm!.id);
      }

      // 새 알람 등록 (단일 관리를 위해 ID를 고정하거나 간단하게 생성)
      const int singleAlarmId = 888;
      await AlarmService.scheduleAlarm(time: alarmDateTime, id: singleAlarmId);

      _loadSingleAlarm(); // 상태 새로고침
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('알람 설정',
            style: TextStyle(
                color: colorScheme.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.iconPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // 테스트용 더미 알람 데이터 생성
              final dummySettings = AlarmSettings(
                id: 999, // 테스트용 ID
                dateTime: DateTime.now(),
                assetAudioPath: 'assets/audio/alarm.mp3',
                notificationSettings: const NotificationSettings(
                  title: '기상 시간이에요!',
                  body: '캐릭터가 당신을 기다리고 있어요 🐥',
                ),
              );

              // 알람 해제 화면으로 강제 이동
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AlarmRingScreen(alarmSettings: dummySettings),
                ),
              );
            },
            child: const Text(
              'Ring Test',
              style: TextStyle(
                  color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _activeAlarm == null
                    ? _buildEmptyState(colorScheme)
                    : _buildSingleAlarmCard(
                        context, _activeAlarm!, colorScheme),
              ),
            ),
    );
  }

  // 단일 알람 카드 UI
  Widget _buildSingleAlarmCard(BuildContext context, AlarmSettings settings,
      AppColorScheme colorScheme) {
    final timeText = DateFormat.jm().format(settings.dateTime);
    final dayText = DateFormat('M월 d일 (E)').format(settings.dateTime);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _selectAndScheduleAlarm, // 누르면 시간 수정
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadowColor.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(Icons.alarm, color: colorScheme.primaryButton, size: 48),
                const SizedBox(height: 16),
                Text(
                  dayText,
                  style:
                      TextStyle(color: colorScheme.textSecondary, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  timeText,
                  style: TextStyle(
                    color: colorScheme.textPrimary,
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'BMJUA',
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '터치하여 시간 수정',
                  style: TextStyle(color: colorScheme.textHint, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
        // 알람 삭제(해제) 버튼
        TextButton.icon(
          onPressed: () async {
            await AlarmService.stopAlarm(settings.id);
            _loadSingleAlarm();
          },
          icon: Icon(Icons.delete_outline, color: colorScheme.error),
          label: Text('알람 해제하기',
              style: TextStyle(color: colorScheme.error, fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildEmptyState(AppColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.alarm_off,
            size: 80, color: colorScheme.textHint.withOpacity(0.3)),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _selectAndScheduleAlarm,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primaryButton,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text('알람 추가하기',
              style: TextStyle(fontSize: 18, color: Colors.white)),
        ),
      ],
    );
  }
}
