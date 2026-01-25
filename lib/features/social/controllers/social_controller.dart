import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../services/firestore_service.dart';
import '../../../services/notification_service.dart';
import '../../../data/models/user_model.dart';

class SocialController extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final NotificationService _notificationService;

  SocialController(this._firestoreService, this._notificationService);

  List<UserModel> _friends = [];
  bool _isLoading = false;

  List<UserModel> get friends => _friends;
  bool get isLoading => _isLoading;

  // 친구 목록 로드
  Future<void> loadFriends(String userId) async {
    _isLoading = true;
    Future.microtask(() {
      notifyListeners();
    });

    try {
      _friends = await _firestoreService.getFriends(userId);
    } catch (e) {
      print('친구 목록 로드 오류: $e');
    }

    _isLoading = false;
    Future.microtask(() {
      notifyListeners();
    });
  }

  // 친구 추가
  Future<void> addFriend(String userId, String friendId) async {
    try {
      await _firestoreService.createFriendship(userId, friendId);
    } catch (e) {
      print('친구 추가 오류: $e');
      rethrow;
    }
  }

  // 이미 친구인지 확인
  Future<bool> checkIfAlreadyFriend(String userId, String friendId) async {
    try {
      return await _firestoreService.checkIfFriends(userId, friendId);
    } catch (e) {
      print('친구 확인 오류: $e');
      return false;
    }
  }

  // 친구 요청
  Future<void> sendFriendRequest(String userId, String friendId) async {
    try {
      await _firestoreService.createFriendship(userId, friendId);
      // TODO: 친구에게 푸시 알림 발송
    } catch (e) {
      print('친구 요청 오류: $e');
      rethrow;
    }
  }

  // 친구 깨우기
  Future<void> wakeUpFriend(
      String userId, String friendId, String friendName) async {
    try {
      // Cloud Functions 호출
      final callable = FirebaseFunctions.instance.httpsCallable('wakeUpFriend');
      await callable.call({
        'userId': userId,
        'friendId': friendId,
        'friendName': friendName,
      });

      // 성공 시 포인트 지급 (+5)
      print('친구 깨우기 성공!');
    } catch (e) {
      print('친구 깨우기 오류: $e');
      rethrow;
    }
  }

  // 친구가 오늘 일기를 작성했는지 확인
  Future<bool> hasFriendWrittenToday(String friendId) async {
    try {
      final diary = await _firestoreService.getDiaryByDate(
        friendId,
        DateTime.now(),
      );
      return diary?.isCompleted ?? false;
    } catch (e) {
      print('친구 일기 확인 오류: $e');
      return false;
    }
  }

  // 실시간 친구 목록 스트림
  Stream<List<UserModel>> getFriendsStream(String userId) {
    return _firestoreService.getFriendsStream(userId);
  }
}
