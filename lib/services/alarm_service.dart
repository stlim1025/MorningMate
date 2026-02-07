import 'package:alarm/alarm.dart';
import 'dart:async';

class AlarmService {
  static StreamSubscription<AlarmSettings>? _ringSubscription;
  static bool _isNavigating = false; // 💡 화면 이동 중복 방지 플래그

  static Future<void> init() async {
    await Alarm.init();
  }

  static void setAlarmListener(Function(AlarmSettings) onRing) {
    _ringSubscription?.cancel();
    _ringSubscription = null;

    _ringSubscription = Alarm.ringStream.stream.listen((settings) {
      onRing(settings);
    });
  }

  // 앱 종료 시 호출하거나 초기화할 때 사용
  static void dispose() {
    _ringSubscription?.cancel();
    _ringSubscription = null;
  }

  // 알람 예약
  static Future<void> scheduleAlarm({
    required int id,
    required DateTime time,
    String? label,
  }) async {
    // 💡 중요: 설정하려는 시간이 과거라면 내일로 변경
    DateTime alarmTime = time;
    if (alarmTime.isBefore(DateTime.now())) {
      alarmTime = alarmTime.add(const Duration(days: 1));
    }

    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: alarmTime,
      assetAudioPath: 'assets/sounds/alarm.mp3', // 실제 파일 경로 확인 필수
      loopAudio: true,
      vibrate: true,
      volume: 0.8,
      notificationSettings: NotificationSettings(
        title: '모닝 메이트',
        body:
            '${alarmTime.hour}:${alarmTime.minute.toString().padLeft(2, '0')} 오늘의 일기를 작성해볼까요?',
        stopButton: '알람 끄기',
      ),
    );

    await Alarm.set(alarmSettings: alarmSettings);
  }

  // 모든 알람 목록 가져오기
  static Future<List<AlarmSettings>> getAlarms() async {
    final rawAlarms = await Alarm.getAlarms();

    final List<AlarmSettings> alarms = List.from(rawAlarms);

    alarms.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return alarms;
  }

  static Future<void> stopAlarm(int id) async {
    await Alarm.stop(id);
  }
}
