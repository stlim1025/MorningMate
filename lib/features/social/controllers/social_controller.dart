import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../services/diary_service.dart';
import '../../../services/friend_service.dart';
import '../../../data/models/user_model.dart';

class SocialController extends ChangeNotifier {
  final FriendService _friendService;
  final DiaryService _diaryService;

  static const Duration _wakeUpCooldown = Duration(seconds: 10);
  static const Duration _cheerCooldown = Duration(seconds: 30);

  final Map<String, DateTime> _wakeUpCooldowns = {};
  final Map<String, DateTime> _cheerCooldowns = {};
  Timer? _cooldownTimer;
  StreamSubscription<List<Map<String, dynamic>>>? _friendRequestSubscription;

  SocialController(
    this._friendService,
    this._diaryService,
  );

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _friendRequestSubscription?.cancel();
    super.dispose();
  }

  void _startCooldownTimer() {
    if (_cooldownTimer != null && _cooldownTimer!.isActive) return;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_wakeUpCooldowns.isEmpty && _cheerCooldowns.isEmpty) {
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      // 만료된 쿨다운 제거
      _wakeUpCooldowns
          .removeWhere((id, time) => now.difference(time) >= _wakeUpCooldown);
      _cheerCooldowns
          .removeWhere((id, time) => now.difference(time) >= _cheerCooldown);

      notifyListeners();

      if (_wakeUpCooldowns.isEmpty && _cheerCooldowns.isEmpty) {
        timer.cancel();
      }
    });
  }

  List<UserModel> _friends = [];
  List<Map<String, dynamic>> _friendRequests = []; // 친구 요청 목록
  // 친구 기상 상태 캐싱 (friendId -> isAwake)
  final Map<String, bool> _friendsAwakeStatus = {};

  List<UserModel> get friends => _friends;
  List<Map<String, dynamic>> get friendRequests => _friendRequests;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 친구의 기상 상태를 가져오는 메서드 (캐시 사용)
  bool isFriendAwake(String friendId, [DateTime? lastDiaryDate]) {
    // 1. 확인된 상태가 있으면 우선 사용
    if (_friendsAwakeStatus.containsKey(friendId)) {
      return _friendsAwakeStatus[friendId]!;
    }

    // 2. 확인 중일 때의 임시 상태 (UserModel 정보 활용)
    if (lastDiaryDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final diaryDate =
          DateTime(lastDiaryDate.year, lastDiaryDate.month, lastDiaryDate.day);
      return diaryDate.isAtSameMomentAs(today);
    }

    return false;
  }

  Future<bool> refreshFriendAwakeStatus(String friendId) async {
    final isAwake = await hasFriendWrittenToday(friendId);
    _friendsAwakeStatus[friendId] = isAwake;
    notifyListeners();
    return isAwake;
  }

  bool canSendWakeUp(String friendId) {
    final now = DateTime.now();
    final lastSentAt = _wakeUpCooldowns[friendId];
    if (lastSentAt == null) {
      _wakeUpCooldowns[friendId] = now;
      _startCooldownTimer();
      notifyListeners(); // 즉시 UI 반영
      return true;
    }

    if (now.difference(lastSentAt) >= _wakeUpCooldown) {
      _wakeUpCooldowns[friendId] = now;
      _startCooldownTimer();
      notifyListeners(); // 즉시 UI 반영
      return true;
    }

    return false;
  }

  Duration wakeUpCooldownRemaining(String friendId) {
    final lastSentAt = _wakeUpCooldowns[friendId];
    if (lastSentAt == null) return Duration.zero;

    final elapsed = DateTime.now().difference(lastSentAt);
    if (elapsed >= _wakeUpCooldown) return Duration.zero;

    // 10.0초에서 시작하도록 올림 처리
    return _wakeUpCooldown - elapsed;
  }

  bool canSendCheer(String friendId) {
    final now = DateTime.now();
    final lastSentAt = _cheerCooldowns[friendId];
    if (lastSentAt == null) {
      _cheerCooldowns[friendId] = now;
      _startCooldownTimer();
      notifyListeners();
      return true;
    }

    if (now.difference(lastSentAt) >= _cheerCooldown) {
      _cheerCooldowns[friendId] = now;
      _startCooldownTimer();
      notifyListeners();
      return true;
    }

    return false;
  }

  Duration cheerCooldownRemaining(String friendId) {
    final lastSentAt = _cheerCooldowns[friendId];
    if (lastSentAt == null) return Duration.zero;

    final elapsed = DateTime.now().difference(lastSentAt);
    if (elapsed >= _cheerCooldown) return Duration.zero;

    return _cheerCooldown - elapsed;
  }

  // 친구 목록 로드
  Future<void> loadFriends(String userId) async {
    _isLoading = true;
    Future.microtask(() => notifyListeners());

    // 기존 스트림 구독 취소
    await _friendRequestSubscription?.cancel();

    try {
      // 1. 친구 목록 가져오기
      _friends = await _friendService.getFriends(userId);

      // 2. 친구 요청 실시간 구독 시작
      _friendRequestSubscription = _friendService
          .getReceivedFriendRequestsStream(userId)
          .listen((requests) {
        _friendRequests = requests;
        notifyListeners();
      });

      // 3. 각 친구의 기상 상태(일기 작성 여부) 확인 및 캐싱
      for (var friend in _friends) {
        final isAwake = await hasFriendWrittenToday(friend.uid);
        _friendsAwakeStatus[friend.uid] = isAwake;
      }
    } catch (e) {
      print('친구 목록 로드 오류: $e');
    }

    _isLoading = false;
    Future.microtask(() => notifyListeners());
  }

  // 친구 요청 보내기
  Future<void> sendFriendRequest(
      String userId, String senderNickname, String friendId) async {
    try {
      final requestId =
          await _friendService.sendFriendRequest(userId, friendId);

      final notificationRef =
          FirebaseFirestore.instance.collection('notifications').doc();
      // 친구 요청 알림 생성
      await notificationRef.set({
        'userId': friendId, // 받는 사람
        'senderId': userId, // 보낸 사람
        'senderNickname': senderNickname,
        'type': 'friendRequest',
        'message': '$senderNickname님이 친구 요청을 보냈습니다! 👋',
        'isRead': false,
        'fcmSent': false,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'data': {
          'requestId': requestId,
        },
      });

      final callable = FirebaseFunctions.instance
          .httpsCallable('sendFriendRequestNotification');
      unawaited(() async {
        try {
          await callable.call({
            'userId': userId,
            'friendId': friendId,
            'senderNickname': senderNickname,
          });
        } catch (e) {
          print('친구 요청 FCM 전송 오류: $e');
        }
      }());
    } catch (e) {
      print('친구 요청 오류: $e');
      rethrow;
    }
  }

  // 친구 요청 수락
  Future<void> acceptFriendRequest(String requestId, String userId,
      String userNickname, String friendId, String friendNickname) async {
    try {
      await _friendService.acceptFriendRequest(requestId, userId, friendId);

      final notificationRef =
          FirebaseFirestore.instance.collection('notifications').doc();
      await notificationRef.set({
        'userId': friendId,
        'senderId': userId,
        'senderNickname': userNickname,
        'type': 'friendAccept',
        'message': '$userNickname님이 친구 요청을 수락했어요.',
        'isRead': false,
        'fcmSent': false,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });

      final callable = FirebaseFunctions.instance
          .httpsCallable('sendFriendAcceptNotification');
      unawaited(() async {
        try {
          await callable.call({
            'userId': userId,
            'friendId': friendId,
            'senderNickname': userNickname,
          });
        } catch (e) {
          print('친구 수락 FCM 전송 오류: $e');
        }
      }());

      // 친구 요청 알림 업데이트 (동기화)
      final notificationsSnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('data.requestId', isEqualTo: requestId)
          .get();

      final b = FirebaseFirestore.instance.batch();
      for (var doc in notificationsSnapshot.docs) {
        b.update(doc.reference, {
          'message': '$friendNickname님과 친구가 되었습니다!',
          'type': 'system',
          'isRead': true,
        });
      }
      await b.commit();

      // 목록 새로고침
      await loadFriends(userId);
    } catch (e) {
      print('친구 수락 오류: $e');
      rethrow;
    }
  }

  // 친구 요청 거절
  Future<void> rejectFriendRequest(String requestId, String userId,
      String friendId, String userNickname, String friendNickname) async {
    try {
      await _friendService.rejectFriendRequest(requestId);

      final notificationRef =
          FirebaseFirestore.instance.collection('notifications').doc();
      await notificationRef.set({
        'userId': friendId,
        'senderId': userId,
        'senderNickname': userNickname,
        'type': 'friendReject',
        'message': '$userNickname님이 친구 요청을 거절했어요.',
        'isRead': false,
        'fcmSent': false,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });

      final callable = FirebaseFunctions.instance
          .httpsCallable('sendFriendRejectNotification');
      unawaited(() async {
        try {
          await callable.call({
            'userId': userId,
            'friendId': friendId,
            'senderNickname': userNickname,
          });
        } catch (e) {
          print('친구 거절 FCM 전송 오류: $e');
        }
      }());

      // 친구 요청 알림 업데이트 (동기화)
      final notificationsSnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('data.requestId', isEqualTo: requestId)
          .get();

      final b = FirebaseFirestore.instance.batch();
      for (var doc in notificationsSnapshot.docs) {
        final docData = doc.data();
        final isRecipient = docData['userId'] == userId;
        b.update(doc.reference, {
          'message': isRecipient
              ? '$friendNickname님의 친구 요청을 거절했습니다.'
              : '$userNickname님이 친구 요청을 거절하셨습니다.',
          'type': 'system',
          'isRead': true,
        });
      }
      await b.commit();

      // 목록 새로고침
      await loadFriends(userId);
    } catch (e) {
      print('친구 거절 오류: $e');
      rethrow;
    }
  }

  // 이미 친구인지 확인
  Future<bool> checkIfAlreadyFriend(String userId, String friendId) async {
    try {
      return await _friendService.checkIfFriends(userId, friendId);
    } catch (e) {
      print('친구 확인 오류: $e');
      return false;
    }
  }

  // 친구 깨우기
  Future<void> wakeUpFriend(String userId, String userNickname, String friendId,
      String friendName) async {
    try {
      print('친구($friendId) 깨우기 실행: $friendName');

      final callable = FirebaseFunctions.instance.httpsCallable('wakeUpFriend');
      // 깨우기 알림 생성
      final notificationRef =
          FirebaseFirestore.instance.collection('notifications').doc();
      await notificationRef.set({
        'userId': friendId, // 받는 사람
        'senderId': userId, // 보낸 사람
        'senderNickname': userNickname,
        'type': 'wakeUp',
        'message': '$userNickname님이 당신을 깨우고 있어요! ⏰',
        'isRead': false,
        'fcmSent': false,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });

      unawaited(() async {
        try {
          await callable.call({
            'userId': userId,
            'friendId': friendId,
            'friendName': userNickname,
          });
        } catch (e) {
          print('깨우기 FCM 전송 오류: $e');
        }
      }());

      print('친구 깨우기 성공!');
    } catch (e) {
      print('친구 깨우기 오류: $e');
      rethrow;
    }
  }

  // 친구가 오늘 일기를 작성했는지 확인
  Future<bool> hasFriendWrittenToday(String friendId) async {
    try {
      final diary = await _diaryService.getDiaryByDate(
        friendId,
        DateTime.now(), // 로컬 시간 기준
      );
      return diary?.isCompleted ?? false;
    } catch (e) {
      print('친구 일기 확인 오류: $e');
      return false;
    }
  }

  // 실시간 친구 목록 스트림
  Stream<List<UserModel>> getFriendsStream(String userId) {
    return _friendService.getFriendsStream(userId);
  }
}
