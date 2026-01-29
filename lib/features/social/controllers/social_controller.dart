import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/diary_service.dart';
import '../../../services/friend_service.dart';
import '../../../services/notification_service.dart';
import '../../../data/models/user_model.dart';

class SocialController extends ChangeNotifier {
  final FriendService _friendService;
  final DiaryService _diaryService;
  final NotificationService _notificationService;

  SocialController(
    this._friendService,
    this._diaryService,
    this._notificationService,
  );

  List<UserModel> _friends = [];
  List<Map<String, dynamic>> _friendRequests = []; // 친구 요청 목록
  // 친구 기상 상태 캐싱 (friendId -> isAwake)
  final Map<String, bool> _friendsAwakeStatus = {};

  bool _isLoading = false;

  List<UserModel> get friends => _friends;
  List<Map<String, dynamic>> get friendRequests => _friendRequests;
  bool get isLoading => _isLoading;

  // 친구의 기상 상태를 가져오는 메서드 (캐시 사용)
  bool isFriendAwake(String friendId) {
    return _friendsAwakeStatus[friendId] ?? false;
  }

  // 친구 목록 로드
  Future<void> loadFriends(String userId) async {
    _isLoading = true;
    Future.microtask(() => notifyListeners());

    try {
      // 1. 친구 목록 가져오기
      _friends = await _friendService.getFriends(userId);

      // 2. 친구 요청 목록 가져오기
      _friendRequests = await _friendService.getReceivedFriendRequests(userId);

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
      await _friendService.sendFriendRequest(userId, friendId);

      // 친구 요청 알림 생성
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': friendId, // 받는 사람
        'senderId': userId, // 보낸 사람
        'senderNickname': senderNickname,
        'type': 'friendRequest',
        'message': '$senderNickname님이 친구 요청을 보냈습니다! 👋',
        'isRead': false,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('친구 요청 오류: $e');
      rethrow;
    }
  }

  // 친구 요청 수락
  Future<void> acceptFriendRequest(
      String requestId, String userId, String friendId) async {
    try {
      await _friendService.acceptFriendRequest(requestId, userId, friendId);
      // 목록 새로고침
      await loadFriends(userId);
    } catch (e) {
      print('친구 수락 오류: $e');
      rethrow;
    }
  }

  // 친구 요청 거절
  Future<void> rejectFriendRequest(String requestId, String userId) async {
    try {
      await _friendService.rejectFriendRequest(requestId);
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

      // 깨우기 알림 생성
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': friendId, // 받는 사람
        'senderId': userId, // 보낸 사람
        'senderNickname': userNickname,
        'type': 'wakeUp',
        'message': '$userNickname님이 당신을 깨우고 있어요! ⏰',
        'isRead': false,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });

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
