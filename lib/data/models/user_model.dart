import 'package:cloud_firestore/cloud_firestore.dart';
import 'room_decoration_model.dart';

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
  final String? lastDiaryMood; // 마지막 일기 감정 (최적화용)
  final DateTime? lastStickyNoteDate; // 오늘 메모 작성 여부 체크용
  final DateTime? lastAdRewardDate; // 마지막 광고 보상 받은 시간
  final int adRewardCount; // 오늘 광고 보상 받은 횟수
  final DateTime createdAt;
  final Map<String, dynamic>? characterCustomization;
  final List<String> friendIds;
  final bool writingBlurEnabled;
  final bool biometricEnabled;
  final bool morningDiaryNoti;
  final bool wakeUpNoti;
  final bool cheerMessageNoti;
  final bool friendRequestNoti;
  final bool friendAcceptNoti;
  final bool friendRejectNoti;
  final List<String> purchasedThemeIds; // 구매한 테마 ID 목록
  final List<String> purchasedBackgroundIds; // 구매한 배경 ID 목록
  final List<String> purchasedPropIds; // 구매한 소품 ID 목록
  final List<String> purchasedFloorIds; // 구매한 바닥 ID 목록
  final List<String> purchasedEmoticonIds; // 구매한 이모티콘 ID 목록
  final List<String> activeEmoticonIds; // 활성화된 이모티콘 ID 목록
  final List<String> purchasedCharacterItemIds; // 구매한 캐릭터 아이템 ID 목록
  final Map<String, dynamic>
      equippedCharacterItems; // 장착된 캐릭터 아이템 (slot: itemId)
  final String currentThemeId; // 현재 선택된 테마 ID
  final RoomDecorationModel roomDecoration;

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
    this.lastDiaryMood,
    this.lastStickyNoteDate,
    this.lastAdRewardDate,
    this.adRewardCount = 0,
    required this.createdAt,
    this.characterCustomization,
    this.friendIds = const [],
    this.writingBlurEnabled = true,
    this.biometricEnabled = false,
    this.morningDiaryNoti = true,
    this.wakeUpNoti = true,
    this.cheerMessageNoti = true,
    this.friendRequestNoti = true,
    this.friendAcceptNoti = true,
    this.friendRejectNoti = true,
    this.purchasedThemeIds = const ['light'],
    this.purchasedBackgroundIds = const ['none'],
    this.purchasedPropIds = const [],
    this.purchasedFloorIds = const ['default'],
    this.purchasedEmoticonIds = const [
      'happy',
      'normal',
      'sad',
      'love'
    ], // 기본 이모티콘 4개
    this.activeEmoticonIds = const [
      'happy',
      'normal',
      'sad',
      'love'
    ], // 기본 활성화 이모티콘
    this.purchasedCharacterItemIds = const [],
    this.equippedCharacterItems = const {},
    this.currentThemeId = 'light',
    RoomDecorationModel? roomDecoration,
  }) : roomDecoration = roomDecoration ?? RoomDecorationModel();

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
      lastDiaryMood: data['lastDiaryMood'],
      lastStickyNoteDate: data['lastStickyNoteDate'] != null
          ? (data['lastStickyNoteDate'] as Timestamp).toDate()
          : null,
      lastAdRewardDate: data['lastAdRewardDate'] != null
          ? (data['lastAdRewardDate'] as Timestamp).toDate()
          : null,
      adRewardCount: data['adRewardCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      characterCustomization: data['characterCustomization'] ?? {},
      friendIds: List<String>.from(data['friendIds'] ?? []),
      writingBlurEnabled: data['writingBlurEnabled'] ?? true,
      biometricEnabled: data['biometricEnabled'] ?? false,
      morningDiaryNoti: data['morningDiaryNoti'] ?? true,
      wakeUpNoti: data['wakeUpNoti'] ?? true,
      cheerMessageNoti: data['cheerMessageNoti'] ?? true,
      friendRequestNoti: data['friendRequestNoti'] ?? true,
      friendAcceptNoti: data['friendAcceptNoti'] ?? true,
      friendRejectNoti: data['friendRejectNoti'] ?? true,
      purchasedThemeIds:
          List<String>.from(data['purchasedThemeIds'] ?? ['light']),
      purchasedBackgroundIds:
          List<String>.from(data['purchasedBackgroundIds'] ?? ['none']),
      purchasedPropIds: List<String>.from(data['purchasedPropIds'] ?? []),
      purchasedFloorIds:
          List<String>.from(data['purchasedFloorIds'] ?? ['default']),
      purchasedEmoticonIds: List<String>.from(
          data['purchasedEmoticonIds'] ?? ['happy', 'normal', 'sad', 'love']),
      activeEmoticonIds: List<String>.from(
          data['activeEmoticonIds'] ?? ['happy', 'normal', 'sad', 'love']),
      purchasedCharacterItemIds:
          List<String>.from(data['purchasedCharacterItemIds'] ?? []),
      equippedCharacterItems:
          data['equippedCharacterItems'] as Map<String, dynamic>? ?? {},
      currentThemeId: data['currentThemeId'] ?? 'light',
      roomDecoration: data['roomDecoration'] != null
          ? RoomDecorationModel.fromMap(
              data['roomDecoration'] as Map<String, dynamic>)
          : RoomDecorationModel(),
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
      'lastDiaryMood': lastDiaryMood,
      'lastStickyNoteDate': lastStickyNoteDate != null
          ? Timestamp.fromDate(lastStickyNoteDate!)
          : null,
      'lastAdRewardDate': lastAdRewardDate != null
          ? Timestamp.fromDate(lastAdRewardDate!)
          : null,
      'adRewardCount': adRewardCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'characterCustomization': characterCustomization ?? {},
      'friendIds': friendIds,
      'writingBlurEnabled': writingBlurEnabled,
      'biometricEnabled': biometricEnabled,
      'morningDiaryNoti': morningDiaryNoti,
      'wakeUpNoti': wakeUpNoti,
      'cheerMessageNoti': cheerMessageNoti,
      'friendRequestNoti': friendRequestNoti,
      'friendAcceptNoti': friendAcceptNoti,
      'friendRejectNoti': friendRejectNoti,
      'purchasedThemeIds': purchasedThemeIds,
      'purchasedBackgroundIds': purchasedBackgroundIds,
      'purchasedPropIds': purchasedPropIds,
      'purchasedFloorIds': purchasedFloorIds,
      'purchasedEmoticonIds': purchasedEmoticonIds,
      'activeEmoticonIds': activeEmoticonIds,
      'purchasedCharacterItemIds': purchasedCharacterItemIds,
      'equippedCharacterItems': equippedCharacterItems,
      'currentThemeId': currentThemeId,
      'roomDecoration': roomDecoration.toMap(),
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
    String? lastDiaryMood,
    DateTime? lastStickyNoteDate,
    DateTime? lastAdRewardDate,
    int? adRewardCount,
    DateTime? createdAt,
    Map<String, dynamic>? characterCustomization,
    List<String>? friendIds,
    bool? writingBlurEnabled,
    bool? biometricEnabled,
    bool? morningDiaryNoti,
    bool? wakeUpNoti,
    bool? cheerMessageNoti,
    bool? friendRequestNoti,
    bool? friendAcceptNoti,
    bool? friendRejectNoti,
    List<String>? purchasedThemeIds,
    List<String>? purchasedBackgroundIds,
    List<String>? purchasedPropIds,
    List<String>? purchasedFloorIds,
    List<String>? purchasedEmoticonIds,
    List<String>? activeEmoticonIds,
    List<String>? purchasedCharacterItemIds,
    Map<String, dynamic>? equippedCharacterItems,
    String? currentThemeId,
    RoomDecorationModel? roomDecoration,
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
      lastDiaryMood: lastDiaryMood ?? this.lastDiaryMood,
      lastStickyNoteDate: lastStickyNoteDate ?? this.lastStickyNoteDate,
      lastAdRewardDate: lastAdRewardDate ?? this.lastAdRewardDate,
      adRewardCount: adRewardCount ?? this.adRewardCount,
      createdAt: createdAt ?? this.createdAt,
      characterCustomization:
          characterCustomization ?? this.characterCustomization,
      friendIds: friendIds ?? this.friendIds,
      writingBlurEnabled: writingBlurEnabled ?? this.writingBlurEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      morningDiaryNoti: morningDiaryNoti ?? this.morningDiaryNoti,
      wakeUpNoti: wakeUpNoti ?? this.wakeUpNoti,
      cheerMessageNoti: cheerMessageNoti ?? this.cheerMessageNoti,
      friendRequestNoti: friendRequestNoti ?? this.friendRequestNoti,
      friendAcceptNoti: friendAcceptNoti ?? this.friendAcceptNoti,
      friendRejectNoti: friendRejectNoti ?? this.friendRejectNoti,
      purchasedThemeIds: purchasedThemeIds ?? this.purchasedThemeIds,
      purchasedBackgroundIds:
          purchasedBackgroundIds ?? this.purchasedBackgroundIds,
      purchasedPropIds: purchasedPropIds ?? this.purchasedPropIds,
      purchasedFloorIds: purchasedFloorIds ?? this.purchasedFloorIds,
      purchasedEmoticonIds: purchasedEmoticonIds ?? this.purchasedEmoticonIds,
      activeEmoticonIds: activeEmoticonIds ?? this.activeEmoticonIds,
      purchasedCharacterItemIds:
          purchasedCharacterItemIds ?? this.purchasedCharacterItemIds,
      equippedCharacterItems:
          equippedCharacterItems ?? this.equippedCharacterItems,
      currentThemeId: currentThemeId ?? this.currentThemeId,
      roomDecoration: roomDecoration ?? this.roomDecoration,
    );
  }

  // 경험치 관련 헬퍼 메서드
  static int getRequiredExpForLevel(int level) {
    // 레벨별 필요 경험치: 30, 50, 100, 150, 200
    // 1->2: 30, 2->3: 50, 3->4: 100, 4->5: 150, 5->6: 200
    const expTable = [0, 30, 50, 100, 150, 200];
    if (level < 1 || level >= expTable.length) return 0;
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

  // 화면 표시용 연속 기록 (날짜가 지났으면 0으로 표시)
  int get displayConsecutiveDays {
    if (lastDiaryDate == null) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate =
        DateTime(lastDiaryDate!.year, lastDiaryDate!.month, lastDiaryDate!.day);

    // 오늘 - 마지막작성일
    final difference = today.difference(lastDate).inDays;

    // 오늘(0) 이거나 어제(1) 작성했으면 유지
    if (difference <= 1) {
      return consecutiveDays;
    }

    // 그 외(2일 이상 지남)는 깨짐
    return 0;
  }
}
