import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/diary_model.dart';

class DiaryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _diariesCollection => _db.collection('diaries');

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
    final dateKey = DiaryModel.buildDateKey(date);

    final queryByKey = await _diariesCollection
        .where('userId', isEqualTo: userId)
        .where('dateKey', isEqualTo: dateKey)
        .limit(1)
        .get();

    if (queryByKey.docs.isNotEmpty) {
      return DiaryModel.fromFirestore(queryByKey.docs.first);
    }

    final startOfDay = DateTime(date.year, date.month, date.day);
    final nextDay = startOfDay.add(const Duration(days: 1));

    final query = await _diariesCollection
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(nextDay))
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
}
