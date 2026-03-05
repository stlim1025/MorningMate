import 'package:flutter/foundation.dart';
import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/widgets/floating_notification.dart';
import '../router/app_router.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  FirebaseMessaging get _fcm {
    try {
      return FirebaseMessaging.instance;
    } catch (e) {
      debugPrint('NotificationService: FirebaseMessaging 인스턴스 획득 실패');
      rethrow;
    }
  }

  Future<void> Function(String token)? _onTokenRefresh;
  StreamSubscription<String>? _tokenRefreshSubscription;
  GlobalKey<ScaffoldMessengerState>? _scaffoldMessengerKey;
  GlobalKey<NavigatorState>? _navigatorKey;
  Timer? _foregroundBannerTimer;
  OverlayEntry? _currentOverlayEntry;
  final FlutterLocalNotificationsPlugin _localPlugin =
      FlutterLocalNotificationsPlugin();

  // FCM 토큰
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  void setScaffoldMessengerKey(GlobalKey<ScaffoldMessengerState> key) {
    _scaffoldMessengerKey = key;
  }

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  void setOnTokenRefreshHandler(Future<void> Function(String token)? handler) {
    _onTokenRefresh = handler;
  }

  // 알림 초기화
  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false);
    const InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsDarwin);
    await _localPlugin.initialize(settings: initializationSettings);

    // 알림 권한 요청
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: false, // iOS Critical Alert
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('알림 권한이 허용되었습니다.');

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        String? apnsToken = await _fcm.getAPNSToken();
        print('APNs 토큰: $apnsToken');
        if (apnsToken == null) {
          print('경고: APNs 토큰을 가져오지 못했습니다. iOS 기기에서 푸시 알림이 제대로 수신되지 않을 수 있습니다.');
          // 시뮬레이터이거나 권한, APNs 설정 문제일 수 있으나 일단 진행
        }
      }

      // FCM 토큰 가져오기
      _fcmToken = await _fcm.getToken();
      print('FCM 토큰: $_fcmToken');

      await setForegroundNotificationPresentationOptions();

      // 토큰 갱신 리스너
      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = _fcm.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        print('FCM 토큰 갱신: $newToken');
        if (_onTokenRefresh != null) {
          try {
            await _onTokenRefresh!(newToken);
          } catch (e) {
            print('FCM 토큰 갱신 처리 실패: $e');
          }
        }
      });

      // 포그라운드 메시지 리스너
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 백그라운드에서 알림 클릭 시
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // 앱이 종료된 상태에서 알림을 통해 열렸는지 확인
      RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    } else {
      print('알림 권한이 거부되었습니다.');
    }
  }

  // 포그라운드 메시지 처리
  void _handleForegroundMessage(RemoteMessage message) {
    print('포그라운드 메시지 수신: ${message.notification?.title}');

    // 앱이 실행 중일 때 메시지를 받으면 여기서 처리
    if (message.notification != null) {
      _showInAppNotification(
        title: message.notification!.title,
        body: message.notification!.body,
        data: message.data, // data를 함께 넘겨서 한 번만 처리
      );
    } else if (message.data.isNotEmpty) {
      // notification이 없고 data만 있는 경우
      _showInAppNotificationFromData(message.data);
      _handleDataMessage(message.data);
    }
  }

  Future<void> scheduleNightlyReminder() async {
    try {
      await _localPlugin.zonedSchedule(
        id: 1123,
        title: '오늘의 일기를 작성해주세요!',
        body: '아직 일기를 작성하지 않았어요. 작성하지 않으면 연속 기록이 날아가요!',
        scheduledDate: _nextInstanceOfElevenPM(),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'nightly_reminder_channel',
            '야간 일기 알림',
            channelDescription: '밤 11시 일기 미작성 시 알림',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      print('밤 11시 푸시 알림 스케줄링 완료');
    } catch (e) {
      print('밤 11시 알림 스케줄링 실패: $e');
    }
  }

  tz.TZDateTime _nextInstanceOfElevenPM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 23, 0);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> cancelNightlyReminder() async {
    try {
      await _localPlugin.cancel(id: 1123);
      print('밤 11시 푸시 알림 스케줄링 취소 완료');
    } catch (e) {
      print('밤 11시 푸시 알림 스케줄링 취소 실패: $e');
    }
  }

  Future<void> scheduleMorningReminder(String time) async {
    try {
      final parts = time.split(':');
      if (parts.length != 2) return;
      final hour = int.tryParse(parts[0]) ?? 8;
      final minute = int.tryParse(parts[1]) ?? 0;

      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduledDate =
          tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _localPlugin.zonedSchedule(
        id: 1124, // 아침 알림 고유 ID
        title: '굿모닝! 아침 일기를 작성할 시간이에요 ☀️',
        body: '상쾌한 하루를 시작하며 일기를 남겨보세요!',
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'morning_reminder_channel',
            '아침 일기 알림',
            channelDescription: '설정한 시간에 아침 일기 작성 알림',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      print('아침 알림 설정 완료: $time');
    } catch (e) {
      print('아침 알림 설정 실패: $e');
    }
  }

  Future<void> cancelMorningReminder() async {
    try {
      await _localPlugin.cancel(id: 1124);
      print('아침 알림 스케줄링 취소 완료');
    } catch (e) {
      print('아침 알림 취소 실패: $e');
    }
  }

  // 알림 탭 처리
  void _handleNotificationTap(RemoteMessage message) {
    print('알림 탭: ${message.notification?.title}');

    // 알림을 탭했을 때 특정 화면으로 이동
    if (message.data.isNotEmpty) {
      final String? type = message.data['type'];

      switch (type) {
        case 'wake_up':
          // 깨우기 알림 - 메인 화면으로 이동
          print('친구가 깨우기를 시도했습니다!');
          // TODO: Navigator를 사용해 특정 화면으로 이동
          break;
        case 'friend_request':
        case 'friendRequest':
          // 친구 요청 - 알림 화면으로 이동
          print('새로운 친구 요청이 있습니다.');
          AppRouter.navigatorKey.currentContext?.go('/notification');
          break;
        case 'friend_accept':
        case 'friendAccept':
        case 'friend_reject':
        case 'friendReject':
          AppRouter.navigatorKey.currentContext?.go('/notification');
          break;
        case 'morning_reminder':
          // 아침 알림 - 작성 화면으로 이동
          print('아침 일기를 작성할 시간입니다!');
          break;
        case 'cheer_message':
          print('친구가 응원 메시지를 보냈습니다!');
          break;
        case 'nestInvite':
        case 'nest_invite':
        case 'nestDonation':
        case 'nest_donation':
          AppRouter.navigatorKey.currentContext?.go('/notification');
          break;
      }
    }
  }

  // 데이터 메시지 처리
  void _handleDataMessage(Map<String, dynamic> data) {
    final String? type = data['type'];

    switch (type) {
      case 'wake_up':
        final String? friendName = data['friendName'];
        print('$friendName님이 당신을 깨우려고 합니다!');
        // TODO: 캐릭터 흔들림 애니메이션 트리거
        break;
      case 'character_evolved':
        print('축하합니다! 캐릭터가 진화했습니다!');
        // TODO: 진화 애니메이션 트리거
        break;
      case 'cheer_message':
        final String? cheerMessage = data['message'];
        print('응원 메시지 수신: $cheerMessage');
        break;
      case 'friend_request':
      case 'friendRequest':
        final String? friendName = data['friendName'] ?? data['senderNickname'];
        print('$friendName님이 친구 추가를 요청했습니다.');
        break;
      case 'friend_accept':
      case 'friendAccept':
        final String? friendName = data['senderNickname'];
        print('${friendName ?? '친구'}님이 친구 요청을 수락했습니다.');
        break;
      case 'friend_reject':
      case 'friendReject':
        final String? friendName = data['senderNickname'];
        print('${friendName ?? '친구'}님이 친구 요청을 거절했습니다.');
        break;
    }
  }

  void _showInAppNotificationFromData(Map<String, dynamic> data) {
    final String? type = data['type'];
    String? title;
    String? body;

    switch (type) {
      case 'wake_up':
        final String? friendName = data['friendName'];
        title = '깨우기 알림';
        body = friendName == null || friendName.isEmpty
            ? '친구가 당신을 깨우려고 합니다!'
            : '$friendName님이 당신을 깨우려고 합니다!';
        break;
      case 'character_evolved':
        title = '캐릭터 진화';
        body = '축하합니다! 캐릭터가 진화했습니다!';
        break;
      case 'cheer_message':
        final String? senderNickname = data['senderNickname'];
        title = senderNickname != null && senderNickname.isNotEmpty
            ? '$senderNickname님이 응원 메시지를 보냈어요.'
            : '친구가 응원 메시지를 보냈어요.';
        body = data['message']?.toString();
        break;
      case 'friend_request':
      case 'friendRequest':
        final String? friendName = data['friendName'] ?? data['senderNickname'];
        title = '친구 요청';
        body = friendName == null || friendName.isEmpty
            ? '친구 요청이 도착했어요.'
            : '$friendName 님이 친구 추가를 요청하였습니다.';
        break;
      case 'friend_accept':
      case 'friendAccept':
        final String? friendName = data['senderNickname'];
        title = '친구 요청 수락';
        body = friendName == null || friendName.isEmpty
            ? '친구 요청이 수락되었어요.'
            : '$friendName님이 친구 요청을 수락했어요.';
        break;
      case 'friend_reject':
      case 'friendReject':
        final String? friendName = data['senderNickname'];
        title = '친구 요청 거절';
        body = friendName == null || friendName.isEmpty
            ? '친구 요청이 거절되었어요.'
            : '$friendName님이 친구 요청을 거절했어요.';
        break;
      case 'nestInvite':
        title = '둥지 초대';
        body = data['message']?.toString();
        break;
      case 'nestDonation':
        title = '둥지 기부 알림';
        body = data['message']?.toString();
        break;
      default:
        title = '알림';
        body = data['message']?.toString();
        break;
    }

    _showInAppNotification(title: title, body: body, type: type, data: data);
  }

  void _showInAppNotification(
      {String? title, String? body, String? type, Map<String, dynamic>? data}) {
    final overlayState = _navigatorKey?.currentState?.overlay;
    if (overlayState == null) {
      _showFallbackNotification(title: title, body: body);
      return;
    }

    // 예전 알림이 남아있다면 제거
    if (_currentOverlayEntry != null) {
      try {
        if (_currentOverlayEntry!.mounted) {
          _currentOverlayEntry!.remove();
        }
      } catch (e) {
        print('알림 제거 중 오류: $e');
      }
      _currentOverlayEntry = null;
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: FloatingNotification(
          title: title ?? '알림',
          body: body,
          type: type,
          data: data,
          onTap: () {
            _handleNotificationTapFromData(data);
          },
          onDismiss: () {
            try {
              if (entry.mounted) {
                entry.remove();
              }
            } catch (e) {
              print('알림 해제 중 오류: $e');
            }
            if (_currentOverlayEntry == entry) {
              _currentOverlayEntry = null;
            }
          },
        ),
      ),
    );

    _currentOverlayEntry = entry;
    overlayState.insert(entry);
  }

  // 데이터 기반 탭 처리 (내부용)
  void _handleNotificationTapFromData(Map<String, dynamic>? data) {
    if (data == null) return;
    final String? type = data['type'];
    final String? senderId = data['senderId'] ?? data['sender_id'];

    // 깨우기 알림(wakeUp)은 FloatingNotification.onTap에서 이미 _dismiss()를 호출하므로
    // 추가적인 navigation 없이 알림만 지워지는 효과를 냅니다.

    if (type == 'friend_request' || type == 'friend_accept') {
      if (senderId != null) {
        AppRouter.navigatorKey.currentContext?.push('/friend/$senderId');
      }
    } else if (type == 'wake_up') {
      // 기상 알림인 경우 메인 화면으로 이동
      AppRouter.navigatorKey.currentContext?.push('/morning');
    } else if (type == 'cheer_message') {
      if (senderId != null) {
        AppRouter.navigatorKey.currentContext?.push('/friend/$senderId');
      }
    } else if (type == 'friend_reject' ||
        type == 'morning_diary' ||
        type == 'morning_reminder' ||
        type == 'nestInvite' ||
        type == 'nestDonation') {
      AppRouter.navigatorKey.currentContext?.push('/notification');
    }
  }

  void _showFallbackNotification({String? title, String? body}) {
    final messenger = _scaffoldMessengerKey?.currentState;
    if (messenger == null) return;

    final displayTitle = (title == null || title.isEmpty) ? '알림' : title;
    final displayBody = (body == null || body.isEmpty) ? null : body;

    messenger.clearMaterialBanners();
    messenger.showMaterialBanner(
      MaterialBanner(
        backgroundColor: Colors.black.withOpacity(0.85),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayTitle,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (displayBody != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  displayBody,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: messenger.hideCurrentMaterialBanner,
            child: const Text('닫기', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    _foregroundBannerTimer?.cancel();
    _foregroundBannerTimer = Timer(
      const Duration(seconds: 3),
      messenger.hideCurrentMaterialBanner,
    );
  }

  // 특정 주제(Topic) 구독
  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
    print('주제 구독: $topic');
  }

  // 주제 구독 해제
  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
    print('주제 구독 해제: $topic');
  }

  // iOS 포그라운드 알림 설정
  Future<void> setForegroundNotificationPresentationOptions() async {
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // 배지 카운트 초기화 (iOS)
  Future<void> clearBadge() async {
    // iOS에서 배지 카운트를 0으로 설정
    // Android에서는 별도의 플러그인 필요
  }

  // 로그아웃 시 모든 알림 관련 리소스 정리
  Future<void> cleanup() async {
    // 야간 알림 취소
    await cancelNightlyReminder();

    // 1. 토큰 갱신 핸들러 제거
    _onTokenRefresh = null;

    // 2. 토큰 갱신 구독 해제
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;

    // 3. FCM 토큰 삭제 (이 디바이스에서 이전 유저의 알림 수신 방지)
    try {
      await _fcm.deleteToken();
      _fcmToken = null;
      print('FCM 토큰 삭제 완료');
    } catch (e) {
      print('FCM 토큰 삭제 실패: $e');
    }

    // 4. 포그라운드 배너 타이머 정리
    _foregroundBannerTimer?.cancel();
    _foregroundBannerTimer = null;

    // 5. 현재 표시 중인 오버레이 알림 제거
    try {
      if (_currentOverlayEntry != null && _currentOverlayEntry!.mounted) {
        _currentOverlayEntry!.remove();
      }
    } catch (e) {
      print('오버레이 알림 제거 중 오류: $e');
    }
    _currentOverlayEntry = null;
  }
}
