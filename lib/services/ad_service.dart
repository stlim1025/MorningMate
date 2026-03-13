import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/ad_log_model.dart';

class AdService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _adLogsCollection => _db.collection('ad_logs');

  // 광고 로그 기록
  Future<void> logAdEvent(AdLogModel log) async {
    try {
      await _adLogsCollection.add(log.toFirestore());
    } catch (e) {
      print('광고 로그 기록 실패: $e');
    }
  }

  // 관리자용: 광고 로그 페이징 조회
  Future<QuerySnapshot> getAdLogsPaginated({
    DocumentSnapshot? lastDocument,
    int limit = 50,
  }) async {
    Query query = _adLogsCollection.orderBy('timestamp', descending: true).limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    return await query.get();
  }

  // 관리자용: 최근 광고 로그 가져오기 (기존 유지용)
  Future<List<AdLogModel>> getRecentAdLogs({int limit = 50}) async {
    try {
      final querySnapshot = await _adLogsCollection
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) => AdLogModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('광고 로그 조회 실패: $e');
      return [];
    }
  }

  // 로그 삭제 (오래된 로그 정리용 - 필요시)
  Future<void> clearOldLogs(DateTime before) async {
    try {
      final query = await _adLogsCollection
          .where('timestamp', isLessThan: before)
          .get();
      
      final batch = _db.batch();
      for (var doc in query.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('오래된 광고 로그 삭제 실패: $e');
    }
  }
}
