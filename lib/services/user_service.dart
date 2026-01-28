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
}
