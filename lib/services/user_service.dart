import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/user_model.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _usersCollection => _db.collection('users');

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

  // 닉네임으로 사용자 찾기
  Future<UserModel?> getUserByNickname(String nickname) async {
    try {
      final query = await _usersCollection
          .where('nickname', isEqualTo: nickname)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return UserModel.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      print('닉네임으로 사용자 찾기 오류: $e');
      return null;
    }
  }

  // 닉네임 중복 확인
  Future<bool> isNicknameAvailable(String nickname) async {
    try {
      final query = await _usersCollection
          .where('nickname', isEqualTo: nickname)
          .limit(1)
          .get();
      return query.docs.isEmpty;
    } catch (e) {
      print('닉네임 중복 확인 오류: $e');
      return false;
    }
  }

  // 연속 기록 업데이트 (일기 작성 시 호출)
  Future<void> updateConsecutiveDays(String uid) async {
    final user = await getUser(uid);
    if (user == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 마지막 일기 작성 날짜 확인
    DateTime? lastDate = user.lastDiaryDate;
    if (lastDate != null) {
      lastDate = DateTime(lastDate.year, lastDate.month, lastDate.day);
    }

    int newConsecutiveDays = user.consecutiveDays;

    // 오늘 이미 작성했는지 확인 (이미 작성했다면 업데이트 안 함)
    if (lastDate != null && lastDate.isAtSameMomentAs(today)) {
      return;
    }

    // 어제 작성했는지 확인
    if (lastDate != null &&
        lastDate.add(const Duration(days: 1)).isAtSameMomentAs(today)) {
      // 어제 썼으면 연속 기록 +1
      newConsecutiveDays += 1;
    } else {
      // 어제 안 썼거나 처음이면 1일부터 시작
      newConsecutiveDays = 1;
    }

    // 최대 연속 기록 업데이트
    final newMaxConsecutiveDays = newConsecutiveDays > user.maxConsecutiveDays
        ? newConsecutiveDays
        : user.maxConsecutiveDays;

    await updateUser(uid, {
      'consecutiveDays': newConsecutiveDays,
      'maxConsecutiveDays': newMaxConsecutiveDays,
      'lastDiaryDate': Timestamp.fromDate(now),
    });
  }

  // 사용자 데이터 전체 삭제 (회원탈퇴)
  Future<void> deleteUserData(String uid) async {
    final batch = _db.batch();

    // 1. 사용자 문서 삭제
    batch.delete(_usersCollection.doc(uid));

    // 2. 일기 데이터 삭제 (컬렉션 그룹 혹은 하위 컬렉션이라면 방식 확인 필요)
    // 현재는 diaries 컬렉션이 uid를 문서 ID로 하거나 하위 컬렉션일 가능성이 높음
    // 여기서는 간단히 diaries/{uid} 혹은 diaries/{uid}/entries 등을 고려
    // 프로젝트 구조에 따라 diary_service에서 처리하는 것이 좋을 수 있음

    // 3. 알림 데이터 삭제
    final notifications = await _db
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .get();
    for (var doc in notifications.docs) {
      batch.delete(doc.reference);
    }

    // 보낸 알림도 삭제할지 여부 결정 (보통 같이 삭제)
    final sentNotifications = await _db
        .collection('notifications')
        .where('senderId', isEqualTo: uid)
        .get();
    for (var doc in sentNotifications.docs) {
      batch.delete(doc.reference);
    }

    // 4. 친구 요청 삭제
    final sentRequests = await _db
        .collection('friend_requests')
        .where('senderId', isEqualTo: uid)
        .get();
    for (var doc in sentRequests.docs) {
      batch.delete(doc.reference);
    }
    final receivedRequests = await _db
        .collection('friend_requests')
        .where('receiverId', isEqualTo: uid)
        .get();
    for (var doc in receivedRequests.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
