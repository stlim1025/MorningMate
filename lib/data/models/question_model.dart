import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionModel {
  final String id;
  final String text;
  final String? engText;
  final String? jaText;
  final String category;
  final DateTime? createdAt;

  QuestionModel({
    required this.id,
    required this.text,
    this.engText,
    this.jaText,
    required this.category,
    this.createdAt,
  });

  factory QuestionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuestionModel(
      id: doc.id,
      text: data['text'] ?? '',
      engText: data['engText'],
      jaText: data['jaText'],
      category: data['category'] ?? 'default',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
      'engText': engText,
      'jaText': jaText,
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
    if (languageCode == 'ja' && jaText != null && jaText!.isNotEmpty) {
      return jaText!;
    }
    return text;
  }
}
