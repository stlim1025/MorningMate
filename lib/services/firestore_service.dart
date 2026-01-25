import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/user_model.dart';
import '../data/models/diary_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collections
  CollectionReference get _usersCollection => _db.collection('users');
  CollectionReference get _diariesCollection => _db.collection('diaries');
  CollectionReference get _friendsCollection => _db.collection('friends');
  CollectionReference get _questionsCollection => _db.collection('questions');

  // ==================== User 관련 ====================

  // 사용자 생성
  Future<void> createUser(UserModel user) async {
    await _usersCollection.doc(user.uid).set(user.toFirestore());
  }

  // 사용자 정보 가져오기
  Future<UserModel?> getUser(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  // 사용자 정보 업데이트
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _usersCollection.doc(uid).update(data);
  }

  // FCM 토큰 업데이트
  Future<void> updateFcmToken(String uid, String token) async {
    await _usersCollection.doc(uid).update({
      'fcmToken': token,
    });
  }

  // 사용자 실시간 스트림
  Stream<UserModel?> getUserStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }

  // ==================== Diary 관련 ====================

  // 일기 생성
  Future<String> createDiary(DiaryModel diary) async {
    final docRef = await _diariesCollection.add(diary.toFirestore());
    return docRef.id;
  }

  // 일기 가져오기
  Future<DiaryModel?> getDiary(String diaryId) async {
    final doc = await _diariesCollection.doc(diaryId).get();
    if (doc.exists) {
      return DiaryModel.fromFirestore(doc);
    }
    return null;
  }

  // 특정 날짜의 일기 가져오기
  Future<DiaryModel?> getDiaryByDate(String userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final query = await _diariesCollection
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return DiaryModel.fromFirestore(query.docs.first);
    }
    return null;
  }

  // 사용자의 모든 일기 가져오기
  Future<List<DiaryModel>> getUserDiaries(String userId) async {
    final query = await _diariesCollection
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .get();

    return query.docs.map((doc) => DiaryModel.fromFirestore(doc)).toList();
  }

  // 일기 업데이트
  Future<void> updateDiary(String diaryId, Map<String, dynamic> data) async {
    await _diariesCollection.doc(diaryId).update(data);
  }

  // 이메일로 사용자 찾기
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final query = await _usersCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return UserModel.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      print('이메일로 사용자 찾기 오류: $e');
      return null;
    }
  }

  // ==================== Friends 관련 ====================

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
      final friend = await getUser(friendId);
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
        final friend = await getUser(friendId);
        if (friend != null) {
          friends.add(friend);
        }
      }
      return friends;
    });
  }

  // ==================== Questions 관련 ====================

  // 랜덤 질문 가져오기
  Future<String> getRandomQuestion() async {
    final query = await _questionsCollection.get();

    if (query.docs.isEmpty) {
      return '오늘 하루는 어땠나요?'; // 기본 질문
    }

    final randomIndex =
        DateTime.now().millisecondsSinceEpoch % query.docs.length;
    final doc = query.docs[randomIndex];
    return doc['text'] as String;
  }

  // 질문 추가 (초기 설정용)
  Future<void> addQuestion(String question, String category) async {
    await _questionsCollection.add({
      'text': question,
      'category': category,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
