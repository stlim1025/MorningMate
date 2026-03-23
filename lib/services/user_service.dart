import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/user_model.dart';

class UserService {
  FirebaseFirestore get _db {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('UserService: FirebaseFirestore 인스턴스 획득 실패 (Firebase 미초기화)');
      rethrow;
    }
  }

  CollectionReference get _usersCollection {
    try {
      return _db.collection('users');
    } catch (e) {
      rethrow;
    }
  }

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

  // FCM 토큰 제거 (로그아웃 시)
  Future<void> removeFcmToken(String uid) async {
    try {
      await _usersCollection.doc(uid).update({
        'fcmToken': FieldValue.delete(),
      });
    } catch (e) {
      print('FCM 토큰 제거 실패: $e');
    }
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

  // 추천인 코드로 사용자 찾기
  Future<UserModel?> getUserByReferralCode(String referralCode) async {
    try {
      final query = await _usersCollection
          .where('referralCode', isEqualTo: referralCode)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return UserModel.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      print('추천인 코드로 사용자 찾기 오류: $e');
      return null;
    }
  }

  // 특정 추천인을 통해 가입한 유저 수 가져오기
  Future<int> getReferralCount(String referredByUid) async {
    try {
      final query = await _usersCollection
          .where('referredBy', isEqualTo: referredByUid)
          .count()
          .get();
      return query.count ?? 0;
    } catch (e) {
      print('추천인 수 조회 오류: $e');
      return 0;
    }
  }

  // 기기가 예전에 추천인 보상을 받았는지 확인
  Future<bool> hasDeviceBeenUsedForReferral(String deviceId) async {
    try {
      final doc = await _db.collection('used_devices').doc(deviceId).get();
      return doc.exists;
    } catch (e) {
      print('기기 확인 오류: $e');
      return false;
    }
  }

  // 추천인 보상을 받은 기기 등록
  Future<void> registerDeviceForReferral(String deviceId, String uid) async {
    try {
      await _db.collection('used_devices').doc(deviceId).set({
        'usedAt': FieldValue.serverTimestamp(),
        'uid': uid,
      });
    } catch (e) {
      print('기기 등록 오류: $e');
    }
  }

  // 연속 기록 업데이트 (일기 작성 시 호출)
  Future<void> updateConsecutiveDays(String uid) async {
    final user = await getUser(uid);
    if (user == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 마지막 일기 작성 날짜 확인
    DateTime? lastDate = user.lastDiaryDate?.toLocal();
    if (lastDate != null) {
      lastDate = DateTime(lastDate.year, lastDate.month, lastDate.day);
    }

    int newConsecutiveDays = user.consecutiveDays;

    // 오늘 이미 작성했는지 확인 (이미 작성했다면 업데이트 안 함)
    // today는 이미 Local 기준 DateTime(y,m,d)
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
      // lastDiaryDate는 MorningController에서 업데이트하므로 여기서는 제거하거나 유지해도 됨
      // 중복 업데이트 방지를 위해 여기서는 연속일수만 업데이트
    });
  }

  // 마지막 로그인 시간 업데이트
  Future<void> updateLastLogin(String uid) async {
    await _usersCollection.doc(uid).update({
      'lastLoginDate': FieldValue.serverTimestamp(),
    });
  }

  // 로그인 기록 저장 (역사적 통계용)
  Future<void> logLogin(String uid) async {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final docId = "${uid}_$todayStr";
    
    await _db.collection('login_history').doc(docId).set({
      'userId': uid,
      'loginDate': FieldValue.serverTimestamp(),
      'dateStr': todayStr,
    }, SetOptions(merge: true));
  }

  // 광고 시청 기록 저장 (역사적 통계용, 중복 시청해도 하루 1개 문서 유지)
  Future<void> logAdReward(String uid) async {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final docId = "${uid}_$todayStr";
    
    await _db.collection('ad_history').doc(docId).set({
      'userId': uid,
      'rewardDate': FieldValue.serverTimestamp(),
      'dateStr': todayStr,
    }, SetOptions(merge: true));
  }

  // 닉네임 업데이트
  Future<void> updateNickname(String uid, String nickname) async {
    await _usersCollection.doc(uid).update({
      'nickname': nickname,
    });
  }

  // 사용자 데이터 전체 삭제 (회원탈퇴)
  Future<void> deleteUserData(String uid) async {
    // 1. 사용자 문서 먼저 정보 백업
    final userDoc = await _usersCollection.doc(uid).get();
    final nestIds = userDoc.exists
        ? List<String>.from(
            (userDoc.data() as Map<String, dynamic>)['nestIds'] ?? [])
        : <String>[];

    final batch = _db.batch();

    // 2. 사용자 문서 삭제
    batch.delete(_usersCollection.doc(uid));

    // 3. 일기 데이터 삭제
    final diaries =
        await _db.collection('diaries').where('userId', isEqualTo: uid).get();
    for (var doc in diaries.docs) {
      batch.delete(doc.reference);
    }

    // 4. 알림 데이터 삭제 (수신/발신)
    final notifications = await _db
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .get();
    for (var doc in notifications.docs) {
      batch.delete(doc.reference);
    }
    final sentNotifications = await _db
        .collection('notifications')
        .where('senderId', isEqualTo: uid)
        .get();
    for (var doc in sentNotifications.docs) {
      batch.delete(doc.reference);
    }

    // 5. 친구 데이터 삭제 (친구 목록 + 요청)
    final friends =
        await _db.collection('friends').where('userId', isEqualTo: uid).get();
    for (var doc in friends.docs) {
      batch.delete(doc.reference);
    }
    final targetFriends =
        await _db.collection('friends').where('friendId', isEqualTo: uid).get();
    for (var doc in targetFriends.docs) {
      batch.delete(doc.reference);
    }

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

    // 6. 둥지 초대 삭제
    final sentInvites = await _db
        .collection('nest_invites')
        .where('senderId', isEqualTo: uid)
        .get();
    for (var doc in sentInvites.docs) {
      batch.delete(doc.reference);
    }
    final receivedInvites = await _db
        .collection('nest_invites')
        .where('receiverId', isEqualTo: uid)
        .get();
    for (var doc in receivedInvites.docs) {
      batch.delete(doc.reference);
    }

    // 7. 둥지에서 멤버 제거
    for (final nestId in nestIds) {
      batch.update(_db.collection('nests').doc(nestId), {
        'memberIds': FieldValue.arrayRemove([uid])
      });
    }

    // 8. 사용된 기기 데이터 삭제
    final usedDevices =
        await _db.collection('used_devices').where('uid', isEqualTo: uid).get();
    for (var doc in usedDevices.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
