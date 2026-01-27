import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String nickname;
  final int points;
  final int characterLevel;
  final String characterState; // 'egg', 'hatchling', 'adult', 'explorer'
  final int consecutiveDays;
  final DateTime? lastLoginDate;
  final DateTime createdAt;
  final Map<String, dynamic>? characterCustomization;
  final List<String> friendIds;
  final bool writingBlurEnabled;

  UserModel({
    required this.uid,
    required this.email,
    required this.nickname,
    this.points = 0,
    this.characterLevel = 1,
    this.characterState = 'egg',
    this.consecutiveDays = 0,
    this.lastLoginDate,
    required this.createdAt,
    this.characterCustomization,
    this.friendIds = const [],
    this.writingBlurEnabled = true,
  });

  // Firestore에서 가져오기
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      nickname: data['nickname'] ?? '',
      points: data['points'] ?? 0,
      characterLevel: data['characterLevel'] ?? 1,
      characterState: data['characterState'] ?? 'egg',
      consecutiveDays: data['consecutiveDays'] ?? 0,
      lastLoginDate: data['lastLoginDate'] != null
          ? (data['lastLoginDate'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      characterCustomization: data['characterCustomization'],
      friendIds: List<String>.from(data['friendIds'] ?? []),
      writingBlurEnabled: data['writingBlurEnabled'] ?? true,
    );
  }

  // Firestore에 저장하기
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'nickname': nickname,
      'points': points,
      'characterLevel': characterLevel,
      'characterState': characterState,
      'consecutiveDays': consecutiveDays,
      'lastLoginDate': lastLoginDate != null 
          ? Timestamp.fromDate(lastLoginDate!) 
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'characterCustomization': characterCustomization ?? {},
      'friendIds': friendIds,
      'writingBlurEnabled': writingBlurEnabled,
    };
  }

  // copyWith 메서드
  UserModel copyWith({
    String? uid,
    String? email,
    String? nickname,
    int? points,
    int? characterLevel,
    String? characterState,
    int? consecutiveDays,
    DateTime? lastLoginDate,
    DateTime? createdAt,
    Map<String, dynamic>? characterCustomization,
    List<String>? friendIds,
    bool? writingBlurEnabled,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      points: points ?? this.points,
      characterLevel: characterLevel ?? this.characterLevel,
      characterState: characterState ?? this.characterState,
      consecutiveDays: consecutiveDays ?? this.consecutiveDays,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      createdAt: createdAt ?? this.createdAt,
      characterCustomization: characterCustomization ?? this.characterCustomization,
      friendIds: friendIds ?? this.friendIds,
      writingBlurEnabled: writingBlurEnabled ?? this.writingBlurEnabled,
    );
  }
}
