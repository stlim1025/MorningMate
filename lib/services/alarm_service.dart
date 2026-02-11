import 'dart:io';
import 'package:alarm/alarm.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';

class AlarmService {
  static AlarmSettings? _ringingAlarm;
  static AlarmSettings? get ringingAlarm => _ringingAlarm;
  static void Function(AlarmSettings)? _externalListener;

  static Future<void> init() async {
    await Alarm.init();

    Alarm.ringStream.stream.listen((settings) {
      _ringingAlarm = settings; // 현재 울리는 알람 캐싱

      if (_externalListener != null) {
        _externalListener!(settings);
      }
    });
  }

  static void setAlarmListener(void Function(AlarmSettings) onRing) {
    // UI에서 넘겨준 함수를 변수에 담아둡니다.
    _externalListener = onRing;

    // 💡 레이스 컨디션 해결: 리스너가 등록되는 시점에 이미 알람이 울리고 있다면 즉시 호출
    if (_ringingAlarm != null) {
      onRing(_ringingAlarm!);
    }
  }

  static Future<bool> checkPermissions() async {
    if (Platform.isIOS) {
      // iOS는 알림 권한만 체크
      return await Permission.notification.isGranted;
    } else {
      // Android 전용 권한들
      return await Permission.notification.isGranted &&
          await Permission.systemAlertWindow.isGranted &&
          await Permission.scheduleExactAlarm.isGranted;
    }
  }

  static Future<void> scheduleAlarm({
    required int id,
    required DateTime time,
    String? label,
  }) async {
    DateTime alarmTime = time;
    if (alarmTime.isBefore(DateTime.now())) {
      alarmTime = alarmTime.add(const Duration(days: 1));
    }

    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: alarmTime,
      assetAudioPath: 'assets/sounds/alarm.mp3',
      loopAudio: true,
      vibrate: true,
      volume: 0.8,
      // 💡 잠금화면 돌파를 위한 필수 옵션
      androidFullScreenIntent: true,
      notificationSettings: NotificationSettings(
        title: '모닝 메이트',
        body: '오늘의 일기를 작성해볼까요?',
        stopButton: '알람 끄기',
      ),
    );

    await Alarm.set(alarmSettings: alarmSettings);
  }

  static Future<List<AlarmSettings>> getAlarms() async {
    final rawAlarms = await Alarm.getAlarms();
    final List<AlarmSettings> alarms = List.from(rawAlarms);
    alarms.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return alarms;
  }

  static Future<void> stopAlarm(int id) async {
    if (_ringingAlarm?.id == id) {
      _ringingAlarm = null;
    }
    await Alarm.stop(id);
  }
}
