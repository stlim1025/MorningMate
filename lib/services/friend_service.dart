import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/user_model.dart';
import 'user_service.dart';

class FriendService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final UserService _userService;

  FriendService(this._userService);

  CollectionReference get _friendsCollection => _db.collection('friends');

  // 친구 관계 생성 (양방향)
  Future<void> createFriendship(String userId, String friendId) async {
    final batch = _db.batch();

    // userId -> friendId
    final ref1 = _friendsCollection.doc('${userId}_$friendId');
    batch.set(ref1, {
      'userId': userId,
      'friendId': friendId,
      'status': 'accepted', // 바로 수락됨
      'createdAt': FieldValue.serverTimestamp(),
    });

    // friendId -> userId (양방향)
    final ref2 = _friendsCollection.doc('${friendId}_$userId');
    batch.set(ref2, {
      'userId': friendId,
      'friendId': userId,
      'status': 'accepted',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // 이미 친구인지 확인
  Future<bool> checkIfFriends(String userId, String friendId) async {
    final doc = await _friendsCollection.doc('${userId}_$friendId').get();
    return doc.exists;
  }

  // 친구 요청 수락
  Future<void> acceptFriendRequest(String friendshipId) async {
    await _friendsCollection.doc(friendshipId).update({
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    });
  }

  // 친구 목록 가져오기
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
