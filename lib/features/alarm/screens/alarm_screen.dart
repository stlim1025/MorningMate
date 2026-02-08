import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:alarm/alarm.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../services/alarm_service.dart';
import '../screens/alarm_ring_screen.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> with WidgetsBindingObserver {
  AlarmSettings? _activeAlarm;
  bool _isLoading = true;
  bool _hasPermissions = false;

  @override
  void initState() {
    super.initState();
    // 💡 앱 상태 변화 감지 등록 (설정창에서 돌아오는 것 확인용)
    WidgetsBinding.instance.addObserver(this);
    _initializeScreen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 💡 사용자가 앱 설정에서 권한을 변경하고 돌아왔을 때 자동으로 재체크
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initializeScreen();
    }
  }

  // 초기화 로직: 권한 체크 -> 데이터 로드
  Future<void> _initializeScreen() async {
    setState(() => _isLoading = true);

    // 1. 권한 체크
    final isGranted = await AlarmService.checkPermissions();

    setState(() {
      _hasPermissions = isGranted;
    });

    // 2. 권한이 있을 때만 알람 데이터 로드
    if (isGranted) {
      await _loadSingleAlarm();
    } else {
      setState(() => _isLoading = false);
    }
  }

  // 기존 알람 로드 및 없으면 바로 선택창 띄우기
  Future<void> _loadSingleAlarm() async {
    final alarms = await AlarmService.getAlarms();
    setState(() {
      _activeAlarm = alarms.isNotEmpty ? alarms.first : null;
      _isLoading = false;
    });

    if (_activeAlarm == null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _selectAndScheduleAlarm();
      });
    }
  }

  // 시간 선택 및 알람 등록 로직
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

      if (alarmDateTime.isBefore(now)) {
        alarmDateTime = alarmDateTime.add(const Duration(days: 1));
      }

      if (_activeAlarm != null) {
        await AlarmService.stopAlarm(_activeAlarm!.id);
      }

      const int singleAlarmId = 888;
      // 💡 androidFullScreenIntent 옵션은 AlarmService.scheduleAlarm 내부에서
      // true로 설정되어 있는지 반드시 확인하세요.
      await AlarmService.scheduleAlarm(time: alarmDateTime, id: singleAlarmId);

      _loadSingleAlarm();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;

    // 1. 로딩 중 UI
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 2. 💡 권한 미부여 시 봉쇄 UI
    if (!_hasPermissions) {
      return _buildPermissionLockState(colorScheme);
    }

    // 3. 권한 부여 시 정상 UI
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
              final dummySettings = AlarmSettings(
                id: 999,
                dateTime: DateTime.now(),
                assetAudioPath: 'assets/sounds/alarm.mp3',
                androidFullScreenIntent: true, // 잠금화면 테스트용
                notificationSettings: const NotificationSettings(
                  title: '기상 시간이에요!',
                  body: '캐릭터가 당신을 기다리고 있어요 🐥',
                ),
              );
              context.push('/alarm-ring', extra: dummySettings);
            },
            child: const Text('Ring Test',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _activeAlarm == null
              ? _buildEmptyState(colorScheme)
              : _buildSingleAlarmCard(context, _activeAlarm!, colorScheme),
        ),
      ),
    );
  }

  // 💡 권한 잠금 화면 UI
  Widget _buildPermissionLockState(AppColorScheme colorScheme) {
    return Scaffold(
      appBar: AppBar(title: const Text('접근 권한 필요')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_person_outlined,
                size: 80, color: colorScheme.error),
            const SizedBox(height: 24),
            Text(
              '알람을 사용하려면 권한이 필요합니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18,
                  color: colorScheme.textPrimary,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              '알림, 다른 앱 위에 표시, 정확한 알람 설정 권한이 모두 허용되어야 알람 기능을 이용할 수 있습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => openAppSettings(),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primaryButton,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('시스템 설정창 열기',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleAlarmCard(BuildContext context, AlarmSettings settings,
      AppColorScheme colorScheme) {
    final timeText = DateFormat.jm().format(settings.dateTime);
    final dayText = DateFormat('M월 d일 (E)').format(settings.dateTime);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _selectAndScheduleAlarm,
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
                Text(dayText,
                    style: TextStyle(
                        color: colorScheme.textSecondary, fontSize: 16)),
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
                Text('터치하여 시간 수정',
                    style:
                        TextStyle(color: colorScheme.textHint, fontSize: 14)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
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
