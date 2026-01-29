import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/user_model.dart';
import 'user_service.dart';

class FriendService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final UserService _userService;

  FriendService(this._userService);

  CollectionReference get _friendsCollection => _db.collection('friends');

  // 친구 요청 보내기
  Future<String> sendFriendRequest(String userId, String friendId) async {
    // 이미 친구인지 또는 요청 상태인지 확인
    final existingParams = await _friendsCollection
        .where('userId', isEqualTo: userId)
        .where('friendId', isEqualTo: friendId)
        .get();

    if (existingParams.docs.isNotEmpty) {
      throw Exception('이미 친구이거나 요청을 보낸 상태입니다.');
    }

    // userId -> friendId (status: pending)
    final requestRef = await _friendsCollection.add({
      'userId': userId,
      'friendId': friendId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return requestRef.id;
  }

  // 친구 요청 수락
  Future<void> acceptFriendRequest(
      String requestId, String userId, String friendId) async {
    final batch = _db.batch();

    // 1. 요청 상태 업데이트 (pending -> accepted)
    final requestRef = _friendsCollection.doc(requestId);
    batch.update(requestRef, {
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    });

    // 2. 역방향 관계 생성 (friendId -> userId) - 바로 accepted
    // 역방향은 상대방 입장에서의 친구 추가이므로 새 문서 생성
    final reverseRef = _friendsCollection.doc();
    batch.set(reverseRef, {
      'userId': userId, // 요청을 받은 사람 (이제 친구가 됨)
      'friendId': friendId, // 요청을 보낸 사람
      'status': 'accepted',
      'createdAt': FieldValue.serverTimestamp(),
      'acceptedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // 친구 요청 거절
  Future<void> rejectFriendRequest(String requestId) async {
    await _friendsCollection.doc(requestId).delete();
  }

  // 이미 친구인지 확인 (accepted 상태만)
  Future<bool> checkIfFriends(String userId, String friendId) async {
    final query = await _friendsCollection
        .where('userId', isEqualTo: userId)
        .where('friendId', isEqualTo: friendId)
        .where('status', isEqualTo: 'accepted')
        .get();
    return query.docs.isNotEmpty;
  }

  // 받은 친구 요청 목록 가져오기
  Future<List<Map<String, dynamic>>> getReceivedFriendRequests(
      String userId) async {
    // 나에게 온 요청: friendId가 나(userId)이고 status가 pending인 것?
    // 아님, 저장 구조상: userId가 '요청 보낸 사람', friendId가 '요청 받은 사람' 일 때
    // 내가 받은 요청은 friendId == Me && status == pending

    final query = await _friendsCollection
        .where('friendId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .get();

    List<Map<String, dynamic>> requests = [];
    for (var doc in query.docs) {
      final senderId = doc['userId'] as String;
      final sender = await _userService.getUser(senderId);
      if (sender != null) {
        requests.add({
          'requestId': doc.id,
          'user': sender,
          'createdAt': (doc['createdAt'] as Timestamp?)?.toDate(),
        });
      }
    }
    return requests;
  }

  // 친구 목록 가져오기 (accepted 상태만)
  Future<List<UserModel>> getFriends(String userId) async {
    final query = await _friendsCollection
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'accepted')
        .get();

    List<UserModel> friends = [];
    for (var doc in query.docs) {
      final friendId = doc['friendId'] as String;
      final friend = await _userService.getUser(friendId);
      if (friend != null) {
        friends.add(friend);
      }
    }
    return friends;
  }

  // 친구 실시간 스트림
  Stream<List<UserModel>> getFriendsStream(String userId) {
    return _friendsCollection
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .asyncMap((snapshot) async {
      List<UserModel> friends = [];
      for (var doc in snapshot.docs) {
        final friendId = doc['friendId'] as String;
        final friend = await _userService.getUser(friendId);
        if (friend != null) {
          friends.add(friend);
        }
      }
      return friends;
    });
  }
}
