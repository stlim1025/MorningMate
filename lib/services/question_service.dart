import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/question_model.dart';

class QuestionService {
  FirebaseFirestore get _db {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('QuestionService: FirebaseFirestore 인스턴스 획득 실패');
      rethrow;
    }
  }

  CollectionReference get _questionsCollection {
    try {
      return _db.collection('questions');
    } catch (e) {
      rethrow;
    }
  }

  // 랜덤 질문 가져오기
  Future<QuestionModel?> getRandomQuestion() async {
    final query = await _questionsCollection.get();

    if (query.docs.isEmpty) {
      return null;
    }

    final randomIndex =
        DateTime.now().millisecondsSinceEpoch % query.docs.length;
    final doc = query.docs[randomIndex];
    return QuestionModel.fromFirestore(doc);
  }

  // 질문 추가 (초기 설정용)
  Future<void> addQuestion(String question, String category,
      {String? engText, String? jaText}) async {
    await _questionsCollection.add({
      'text': question,
      'engText': engText,
      'jaText': jaText,
      'category': category,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 전체 질문 목록 가져오기 (번역 작업용)
  Future<List<QuestionModel>> getAllQuestions() async {
    final query = await _questionsCollection.get();
    return query.docs.map((doc) => QuestionModel.fromFirestore(doc)).toList();
  }

  // 특정 질문의 외국어 번역 업데이트 (영어/일본어 공용)
  Future<void> updateQuestionTranslation(String id,
      {String? engText, String? jaText}) async {
    final Map<String, dynamic> updates = {};
    if (engText != null) updates['engText'] = engText;
    if (jaText != null) updates['jaText'] = jaText;

    if (updates.isNotEmpty) {
      await _questionsCollection.doc(id).update(updates);
    }
  }

  // 질문이 있으면 업데이트, 없으면 추가
  Future<void> addOrUpdateQuestion({
    required String text,
    required String category,
    required String engText,
    String? jaText,
  }) async {
    final query =
        await _questionsCollection.where('text', isEqualTo: text).get();

    if (query.docs.isNotEmpty) {
      // 이미 존재하면 번역만 업데이트
      final Map<String, dynamic> updates = {
        'engText': engText,
        'category': category,
      };
      if (jaText != null) updates['jaText'] = jaText;

      await query.docs.first.reference.update(updates);
    } else {
      // 없으면 신규 추가
      await _questionsCollection.add({
        'text': text,
        'engText': engText,
        'jaText': jaText,
        'category': category,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
