import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../core/widgets/floating_notification.dart';
import '../router/app_router.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  Future<void> Function(String token)? _onTokenRefresh;
  StreamSubscription<String>? _tokenRefreshSubscription;
  GlobalKey<ScaffoldMessengerState>? _scaffoldMessengerKey;
  GlobalKey<NavigatorState>? _navigatorKey;
  Timer? _foregroundBannerTimer;
  OverlayEntry? _currentOverlayEntry;

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
      );
      print('제목: ${message.notification!.title}');
      print('내용: ${message.notification!.body}');
    }

    // 데이터 메시지 처리
    if (message.data.isNotEmpty) {
      if (message.notification == null) {
        _showInAppNotificationFromData(message.data);
      }
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
        case 'friendRequest':
          // 친구 요청 - 알림 화면으로 이동
          print('새로운 친구 요청이 있습니다.');
          AppRouter.router.go('/notification');
          break;
        case 'friend_accept':
        case 'friendAccept':
        case 'friend_reject':
        case 'friendReject':
          AppRouter.router.go('/notification');
          break;
        case 'morning_reminder':
          // 아침 알림 - 작성 화면으로 이동
          print('아침 일기를 작성할 시간입니다!');
          break;
        case 'cheer_message':
          print('친구가 응원 메시지를 보냈습니다!');
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
        final String? friendName =
            data['friendName'] ?? data['senderNickname'];
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
        title = '친구가 응원 메시지를 보냈어요.';
        body = data['message']?.toString();
        break;
      case 'friend_request':
      case 'friendRequest':
        final String? friendName =
            data['friendName'] ?? data['senderNickname'];
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
      default:
        title = '알림';
        body = data['message']?.toString();
        break;
    }

    _showInAppNotification(title: title, body: body);
  }

  void _showInAppNotification({String? title, String? body}) {
    final overlayState = _navigatorKey?.currentState?.overlay;
    if (overlayState == null) {
      // Overlay를 찾을 수 없거나 Navigator가 준비되지 않았을 경우 기존 방식(MaterialBanner)으로 표시
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
}
