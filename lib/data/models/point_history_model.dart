import 'package:cloud_firestore/cloud_firestore.dart';

class PointHistoryModel {
  final String id;
  final String userId;
  final String
      type; // 'diary', 'challenge', 'ad', 'purchase', 'donation', 'referral', 'sticky_note'
  final String
      description; // e.g. "Diary completion", "Purchased: Item Name", "Donated to: Nest Name"
  final int amount; // +20, -100
  final DateTime createdAt;

  PointHistoryModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.description,
    required this.amount,
    required this.createdAt,
  });

  factory PointHistoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PointHistoryModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: data['type'] ?? 'general',
      description: data['description'] ?? '',
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type,
      'description': description,
      'amount': amount,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
