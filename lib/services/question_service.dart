import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/question_model.dart';

class QuestionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _questionsCollection => _db.collection('questions');

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
      {String? engText}) async {
    await _questionsCollection.add({
      'text': question,
      'engText': engText,
      'category': category,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 전체 질문 목록 가져오기 (번역 작업용)
  Future<List<QuestionModel>> getAllQuestions() async {
    final query = await _questionsCollection.get();
    return query.docs.map((doc) => QuestionModel.fromFirestore(doc)).toList();
  }

  // 특정 질문의 영문 번역 업데이트
  Future<void> updateQuestionTranslation(String id, String engText) async {
    await _questionsCollection.doc(id).update({
      'engText': engText,
    });
  }

  // 질문이 있으면 업데이트, 없으면 추가
  Future<void> addOrUpdateQuestion({
    required String text,
    required String category,
    required String engText,
  }) async {
    final query =
        await _questionsCollection.where('text', isEqualTo: text).get();

    if (query.docs.isNotEmpty) {
      // 이미 존재하면 번역만 업데이트
      await query.docs.first.reference.update({
        'engText': engText,
        'category': category, // 카테고리도 최신화
      });
    } else {
      // 없으면 신규 추가
      await _questionsCollection.add({
        'text': text,
        'engText': engText,
        'category': category,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
