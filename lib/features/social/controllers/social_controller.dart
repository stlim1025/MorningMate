import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../services/friend_service.dart';
import '../../../data/models/user_model.dart';

class SocialController extends ChangeNotifier {
  final FriendService _friendService;

  static const Duration _wakeUpCooldown = Duration(seconds: 10);
  static const Duration _cheerCooldown = Duration(seconds: 30);

  final Map<String, DateTime> _wakeUpCooldowns = {};
  final Map<String, DateTime> _cheerCooldowns = {};
  Timer? _cooldownTimer;
  StreamSubscription<List<Map<String, dynamic>>>? _friendRequestSubscription;

  SocialController(
    this._friendService,
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

  List<UserModel> get friends => _friends;
  List<Map<String, dynamic>> get friendRequests => _friendRequests;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 친구의 기상 상태를 가져오는 메서드 (UserModel 정보 활용)
  bool isFriendAwake(UserModel friend) {
    if (friend.lastDiaryDate == null) return false;

    final now = DateTime.now();
    final localLastDiaryDate = friend.lastDiaryDate!.toLocal();

    return localLastDiaryDate.year == now.year &&
        localLastDiaryDate.month == now.month &&
        localLastDiaryDate.day == now.day;
  }

  // 친구의 오늘의 기분을 가져오는 메서드
  String? getFriendMood(UserModel friend) {
    return friend.lastDiaryMood;
  }

  Future<void> refreshFriendAwakeStatus(String friendId) async {
    // Stream updates handle this now
    notifyListeners();
  }

  bool canSendWakeUp(String friendId) {
    final lastSentAt = _wakeUpCooldowns[friendId];
    if (lastSentAt == null) return true;

    final now = DateTime.now();
    return now.difference(lastSentAt) >= _wakeUpCooldown;
  }

  void startWakeUpCooldown(String friendId) {
    _wakeUpCooldowns[friendId] = DateTime.now();
    _startCooldownTimer();
    notifyListeners();
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
    final lastSentAt = _cheerCooldowns[friendId];
    if (lastSentAt == null) return true;

    final now = DateTime.now();
    return now.difference(lastSentAt) >= _cheerCooldown;
  }

  void startCheerCooldown(String friendId) {
    _cheerCooldowns[friendId] = DateTime.now();
    _startCooldownTimer();
    notifyListeners();
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
    // Notify only if necessary to show loading spinner immediately6
    notifyListeners();

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

      // 3. 일기 작성 여부는 UserModel에 포함되어 있으므로 별도 확인 불필요
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

  // Future<bool> hasFriendWrittenToday(String friendId) removed as it is no longer needed

  // 모든 상태 초기화 (로그아웃용)
  void clear() {
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    _friendRequestSubscription?.cancel();
    _friendRequestSubscription = null;
    _friends = [];
    _friendRequests = [];
    _wakeUpCooldowns.clear();
    _cheerCooldowns.clear();
    _isLoading = false;
    notifyListeners();
  }

  // 실시간 친구 목록 스트림
  Stream<List<UserModel>> getFriendsStream(String userId) {
    return _friendService.getFriendsStream(userId);
  }

  Future<void> likeStickyNote(String userId, String userNickname,
      String friendId, String memoId) async {
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(friendId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      if (data['roomDecoration'] == null) return;

      final decorationMap = Map<String, dynamic>.from(data['roomDecoration']);
      final props =
          List<Map<String, dynamic>>.from(decorationMap['props'] ?? []);

      bool updated = false;
      int? newHeartCount;
      List<String>? newLikedBy;

      for (var i = 0; i < props.length; i++) {
        // Handle "sticky_note"
        if (props[i]['id'] == memoId && props[i]['type'] == 'sticky_note') {
          final metadata =
              Map<String, dynamic>.from(props[i]['metadata'] ?? {});
          final likedBy = List<String>.from(metadata['likedBy'] ?? []);

          if (!likedBy.contains(userId)) {
            likedBy.add(userId);
            metadata['likedBy'] = likedBy;
            metadata['heartCount'] = (metadata['heartCount'] ?? 0) + 1;
            props[i]['metadata'] = metadata;

            newHeartCount = metadata['heartCount'];
            newLikedBy = likedBy;
            updated = true;
          }
        }
      }

      if (updated) {
        decorationMap['props'] = props;
        transaction.update(userRef, {'roomDecoration': decorationMap});

        // Update Archive (Memos collection)
        if (newHeartCount != null) {
          final memoRef = FirebaseFirestore.instance
              .collection('users')
              .doc(friendId)
              .collection('memos')
              .doc(memoId);

          transaction.set(
              memoRef,
              {
                'heartCount': newHeartCount,
                'likedBy': newLikedBy,
              },
              SetOptions(merge: true));
        }

        // Add Notification
        final notificationRef =
            FirebaseFirestore.instance.collection('notifications').doc();
        transaction.set(notificationRef, {
          'userId': friendId,
          'senderId': userId,
          'senderNickname': userNickname,
          'type': 'memoLike',
          'message': '$userNickname님이 내 메모에 하트를 보냈어요! ❤️',
          'isRead': false,
          'fcmSent': false,
          'createdAt': Timestamp.fromDate(DateTime.now()),
        });
      }
    });
  }

  // 친구 삭제
  Future<void> deleteFriend(String userId, String friendId) async {
    try {
      await _friendService.deleteFriend(userId, friendId);
      // 친구 목록 새로고침
      await loadFriends(userId);
    } catch (e) {
      print('친구 삭제 오류: $e');
      rethrow;
    }
  }

  // 신고하기
  Future<void> submitReport({
    required String reporterId,
    required String reporterName,
    required String targetUserId,
    required String targetUserName,
    required String targetContent,
    required String targetId,
    required String reason,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'reporterId': reporterId,
        'reporterName': reporterName,
        'targetUserId': targetUserId,
        'targetUserName': targetUserName,
        'targetContent': targetContent,
        'targetId': targetId,
        'reason': reason,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('신고하기 오류: $e');
      rethrow;
    }
  }
}
