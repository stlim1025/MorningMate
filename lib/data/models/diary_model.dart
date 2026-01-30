import 'package:cloud_firestore/cloud_firestore.dart';

class DiaryModel {
  final String id;
  final String userId;
  final DateTime date;
  final String dateKey;
  final String? encryptedContent; // 로컬에 암호화 저장, Firestore에는 메타데이터만
  final int wordCount;
  final int writingDuration; // 작성 시간 (초)
  final String? mood; // 'happy', 'neutral', 'sad', 'excited' 등
  final bool isCompleted;
  final DateTime createdAt;
  final String? promptQuestion; // 사용한 랜덤 질문

  DiaryModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.dateKey,
    this.encryptedContent,
    this.wordCount = 0,
    this.writingDuration = 0,
    this.mood,
    this.isCompleted = false,
    required this.createdAt,
    this.promptQuestion,
  });

  // Firestore에서 가져오기
  factory DiaryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final date = (data['date'] as Timestamp).toDate();
    return DiaryModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      date: date,
      dateKey: data['dateKey'] ?? DiaryModel.buildDateKey(date),
      encryptedContent: data['encryptedContent'], // 암호화된 내용도 가져오기
      wordCount: data['wordCount'] ?? 0,
      writingDuration: data['writingDuration'] ?? 0,
      mood: data['mood'],
      isCompleted: data['isCompleted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      promptQuestion: data['promptQuestion'],
    );
  }

  // Firestore에 저장하기 (암호화된 내용 포함)
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'dateKey': dateKey,
      'encryptedContent': encryptedContent, // 암호화된 내용 저장
      'wordCount': wordCount,
      'writingDuration': writingDuration,
      'mood': mood,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'promptQuestion': promptQuestion,
    };
  }

  DiaryModel copyWith({
    String? id,
    String? userId,
    DateTime? date,
    String? dateKey,
    String? encryptedContent,
    int? wordCount,
    int? writingDuration,
    String? mood,
    bool? isCompleted,
    DateTime? createdAt,
    String? promptQuestion,
  }) {
    return DiaryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      dateKey: dateKey ?? this.dateKey,
      encryptedContent: encryptedContent ?? this.encryptedContent,
      wordCount: wordCount ?? this.wordCount,
      writingDuration: writingDuration ?? this.writingDuration,
      mood: mood ?? this.mood,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      promptQuestion: promptQuestion ?? this.promptQuestion,
    );
  }

  static String buildDateKey(DateTime date) {
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  DateTime get dateOnly {
    final parts = dateKey.split('-');
    if (parts.length != 3) {
      return DateTime(date.year, date.month, date.day);
    }
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}
