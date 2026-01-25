import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // FCM 토큰
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // 알림 초기화
  Future<void> initialize() async {
    // 알림 권한 요청
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true, // iOS Critical Alert
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('알림 권한이 허용되었습니다.');
      
      // FCM 토큰 가져오기
      _fcmToken = await _fcm.getToken();
      print('FCM 토큰: $_fcmToken');
      
      // 토큰 갱신 리스너
      _fcm.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        print('FCM 토큰 갱신: $newToken');
        // TODO: 새 토큰을 Firestore에 업데이트
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
      // TODO: 인앱 알림 표시 (SnackBar, Dialog 등)
      print('제목: ${message.notification!.title}');
      print('내용: ${message.notification!.body}');
    }

    // 데이터 메시지 처리
    if (message.data.isNotEmpty) {
      _handleDataMessage(message.data);
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
          // 친구 요청 - 소셜 화면으로 이동
          print('새로운 친구 요청이 있습니다.');
          break;
        case 'morning_reminder':
          // 아침 알림 - 작성 화면으로 이동
          print('아침 일기를 작성할 시간입니다!');
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
    }
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
}
