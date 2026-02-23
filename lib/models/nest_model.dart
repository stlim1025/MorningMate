import 'package:cloud_firestore/cloud_firestore.dart';

class NestModel {
  final String id;
  final String name;
  final String description; // Short description (up to 15 chars)
  final String creatorId; // UID of the creator
  final List<String> memberIds;
  final int level;
  final int totalGaji;
  final DateTime createdAt;
  final DateTime lastActivityAt; // Useful for showing "activity time" in list

  NestModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.creatorId,
    required this.memberIds,
    this.level = 1,
    this.totalGaji = 0,
    required this.createdAt,
    required this.lastActivityAt,
  });

  factory NestModel.fromMap(String id, Map<String, dynamic> data) {
    return NestModel(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      creatorId: data['creatorId'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      level: (data['level'] as num?)?.toInt() ?? 1,
      totalGaji: (data['totalGaji'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActivityAt:
          (data['lastActivityAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'creatorId': creatorId,
      'memberIds': memberIds,
      'level': level,
      'totalGaji': totalGaji,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActivityAt': Timestamp.fromDate(lastActivityAt),
    };
  }

  NestModel copyWith({
    String? name,
    String? description,
    List<String>? memberIds,
    int? level,
    int? totalGaji,
    DateTime? lastActivityAt,
  }) {
    return NestModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      creatorId: creatorId,
      memberIds: memberIds ?? this.memberIds,
      level: level ?? this.level,
      totalGaji: totalGaji ?? this.totalGaji,
      createdAt: createdAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
    );
  }
}
