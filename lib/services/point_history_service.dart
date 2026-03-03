import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/point_history_model.dart';

class PointHistoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _historyCollection => _db.collection('point_history');

  // 기록 추가
  Future<void> addHistory({
    required String userId,
    required String type,
    required String description,
    required int amount,
  }) async {
    await _historyCollection.add({
      'userId': userId,
      'type': type,
      'description': description,
      'amount': amount,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 특정 사용자의 기록 가져오기 (시간 역순)
  Future<List<PointHistoryModel>> getUserHistory(String userId) async {
    final query = await _historyCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50) // 최근 50개만
        .get();

    return query.docs
        .map((doc) => PointHistoryModel.fromFirestore(doc))
        .toList();
  }

  // 실시간 기록 스트림
  Stream<List<PointHistoryModel>> getUserHistoryStream(String userId) {
    return _historyCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PointHistoryModel.fromFirestore(doc))
            .toList());
  }
}
