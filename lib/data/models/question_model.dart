import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionModel {
  final String id;
  final String text;
  final String? engText;
  final String category;
  final DateTime? createdAt;

  QuestionModel({
    required this.id,
    required this.text,
    this.engText,
    required this.category,
    this.createdAt,
  });

  factory QuestionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuestionModel(
      id: doc.id,
      text: data['text'] ?? '',
      engText: data['engText'],
      category: data['category'] ?? 'default',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
      'engText': engText,
      'category': category,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  String getLocalizedText(String languageCode) {
    if (languageCode == 'en' && engText != null && engText!.isNotEmpty) {
      return engText!;
    }
    return text;
  }
}
