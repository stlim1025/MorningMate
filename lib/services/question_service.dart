import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _questionsCollection => _db.collection('questions');

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
