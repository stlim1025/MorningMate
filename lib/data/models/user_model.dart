import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String nickname;
  final int points;
  final int characterLevel;
  final int experience; // 경험치 필드 추가
  final String characterState; // 'egg', 'hatchling', 'adult', 'explorer'
  final int consecutiveDays;
  final int maxConsecutiveDays;
  final DateTime? lastLoginDate;
  final DateTime? lastDiaryDate;
  final DateTime createdAt;
  final Map<String, dynamic>? characterCustomization;
  final List<String> friendIds;
  final bool writingBlurEnabled;
  final bool biometricEnabled;

  UserModel({
    required this.uid,
    required this.email,
    required this.nickname,
    this.points = 0,
    this.characterLevel = 1,
    this.experience = 0, // 기본값 0
    this.characterState = 'egg',
    this.consecutiveDays = 0,
    this.maxConsecutiveDays = 0,
    this.lastLoginDate,
    this.lastDiaryDate,
    required this.createdAt,
    this.characterCustomization,
    this.friendIds = const [],
    this.writingBlurEnabled = true,
    this.biometricEnabled = false,
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
      experience: data['experience'] ?? 0, // 경험치 필드 추가
      characterState: data['characterState'] ?? 'egg',
      consecutiveDays: data['consecutiveDays'] ?? 0,
      maxConsecutiveDays: data['maxConsecutiveDays'] ?? 0,
      lastLoginDate: data['lastLoginDate'] != null
          ? (data['lastLoginDate'] as Timestamp).toDate()
          : null,
      lastDiaryDate: data['lastDiaryDate'] != null
          ? (data['lastDiaryDate'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      characterCustomization: data['characterCustomization'],
      friendIds: List<String>.from(data['friendIds'] ?? []),
      writingBlurEnabled: data['writingBlurEnabled'] ?? true,
      biometricEnabled: data['biometricEnabled'] ?? false,
    );
  }

  // Firestore에 저장하기
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'nickname': nickname,
      'points': points,
      'characterLevel': characterLevel,
      'experience': experience, // 경험치 필드 추가
      'characterState': characterState,
      'consecutiveDays': consecutiveDays,
      'maxConsecutiveDays': maxConsecutiveDays,
      'lastLoginDate':
          lastLoginDate != null ? Timestamp.fromDate(lastLoginDate!) : null,
      'lastDiaryDate':
          lastDiaryDate != null ? Timestamp.fromDate(lastDiaryDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'characterCustomization': characterCustomization ?? {},
      'friendIds': friendIds,
      'writingBlurEnabled': writingBlurEnabled,
      'biometricEnabled': biometricEnabled,
    };
  }

  // copyWith 메서드
  UserModel copyWith({
    String? uid,
    String? email,
    String? nickname,
    int? points,
    int? characterLevel,
    int? experience, // 경험치 필드 추가
    String? characterState,
    int? consecutiveDays,
    int? maxConsecutiveDays,
    DateTime? lastLoginDate,
    DateTime? lastDiaryDate,
    DateTime? createdAt,
    Map<String, dynamic>? characterCustomization,
    List<String>? friendIds,
    bool? writingBlurEnabled,
    bool? biometricEnabled,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      points: points ?? this.points,
      characterLevel: characterLevel ?? this.characterLevel,
      experience: experience ?? this.experience, // 경험치 필드 추가
      characterState: characterState ?? this.characterState,
      consecutiveDays: consecutiveDays ?? this.consecutiveDays,
      maxConsecutiveDays: maxConsecutiveDays ?? this.maxConsecutiveDays,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      lastDiaryDate: lastDiaryDate ?? this.lastDiaryDate,
      createdAt: createdAt ?? this.createdAt,
      characterCustomization:
          characterCustomization ?? this.characterCustomization,
      friendIds: friendIds ?? this.friendIds,
      writingBlurEnabled: writingBlurEnabled ?? this.writingBlurEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }

  // 경험치 관련 헬퍼 메서드
  static int getRequiredExpForLevel(int level) {
    // 레벨별 필요 경험치: 10, 50, 100, 200, 350, 500
    const expTable = [0, 10, 30, 50, 100, 200, 300];
    if (level < 1 || level > 6) return 0;
    return expTable[level];
  }

  int get requiredExpForNextLevel {
    return getRequiredExpForLevel(characterLevel);
  }

  double get expProgress {
    if (characterLevel >= 6) return 1.0;
    final required = requiredExpForNextLevel;
    if (required == 0) return 1.0;
    return (experience / required).clamp(0.0, 1.0);
  }
}
