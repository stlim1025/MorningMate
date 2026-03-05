import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../router/app_router.dart'; // navigatorKey 접근을 위해
import '../../../services/user_service.dart';
import '../../../services/point_history_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/room_decoration_model.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/memo_notification.dart';
import '../../challenge/data/challenge_data.dart';
import '../../../data/models/notification_model.dart';
import '../../../core/localization/app_localizations.dart';

// 캐릭터 상태 정의 - 6단계로 확장
enum CharacterState {
  egg, // 1레벨: 알
  cracking, // 2레벨: 알에 금이 감
  hatching, // 3레벨: 알에서 얼굴이 보임
  baby, // 4레벨: 새가 완전히 나옴
  young, // 5레벨: 새가 조금 성숙해짐
  adult, // 6레벨: 완전히 성숙한 귀여운 새
  sleeping, // 수면 중 (3일 미활동)
}

class CharacterController extends ChangeNotifier {
  final UserService _userService;
  final PointHistoryService _pointHistoryService;

  CharacterController(this._userService, this._pointHistoryService) {
    _startShopDiscountListener();
  }

  // 상점 할인 정보
  Map<String, int> _shopDiscounts = {};
  Map<String, int> get shopDiscounts => _shopDiscounts;
  StreamSubscription? _shopDiscountSubscription;

  void _startShopDiscountListener() {
    _shopDiscountSubscription = FirebaseFirestore.instance
        .collection('settings')
        .doc('shop')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        if (data['discounts'] != null) {
          _shopDiscounts = Map<String, int>.from(data['discounts']);
          notifyListeners();
        }
      } else {
        _shopDiscounts = {};
        notifyListeners();
      }
    }, onError: (e) {
      // 로그아웃 시 permission-denied 에러 무시
      debugPrint('상점 할인 스트림 에러 (무시됨): $e');
    });
  }

  @override
  void dispose() {
    _shopDiscountSubscription?.cancel();
    super.dispose();
  }

  int getDiscountedPrice(String itemId, int originalPrice) {
    if (_shopDiscounts.containsKey(itemId)) {
      return _shopDiscounts[itemId]!;
    }
    return originalPrice;
  }

  // 상태 변수
  UserModel? _currentUser;
  bool _isAwake = false;
  String _currentAnimation = 'idle';
  bool _showLevelUpDialog = false;
  int? _justLeveledUpTo;

  // 광고 관련 상태
  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isAwake => _isAwake;
  String get currentAnimation => _currentAnimation;
  bool get showLevelUpDialog => _showLevelUpDialog;
  int? get justLeveledUpTo => _justLeveledUpTo;
  bool get isAdLoading => _isAdLoading;
  bool get isAdReady => _rewardedAd != null;

  void consumeLevelUpDialog() {
    _showLevelUpDialog = false;
    _justLeveledUpTo = null;
    notifyListeners();
  }

  CharacterState get characterState =>
      _getCharacterStateFromLevel(_currentUser?.characterLevel ?? 1);

  // 사용자 정보 업데이트 (AuthController로부터)
  void updateFromUser(UserModel? user) {
    if (user == null) {
      _currentUser = null;
      notifyListeners();
      return;
    }

    if (_currentUser?.uid != user.uid ||
        _currentUser?.points != user.points ||
        _currentUser?.characterLevel != user.characterLevel ||
        _currentUser?.experience != user.experience ||
        _currentUser?.currentThemeId != user.currentThemeId ||
        _currentUser?.purchasedThemeIds.length !=
            user.purchasedThemeIds.length ||
        _currentUser?.purchasedBackgroundIds.length !=
            user.purchasedBackgroundIds.length ||
        _currentUser?.purchasedPropIds.length != user.purchasedPropIds.length ||
        _currentUser?.purchasedFloorIds.length !=
            user.purchasedFloorIds.length ||
        _currentUser?.roomDecoration.wallpaperId !=
            user.roomDecoration.wallpaperId ||
        _currentUser?.roomDecoration.backgroundId !=
            user.roomDecoration.backgroundId ||
        _currentUser?.roomDecoration.floorId != user.roomDecoration.floorId ||
        _currentUser?.roomDecoration.props.length !=
            user.roomDecoration.props.length ||
        _currentUser?.equippedCharacterItems != user.equippedCharacterItems ||
        _currentUser?.friendIds.length != user.friendIds.length ||
        _currentUser?.memoCount != user.memoCount ||
        _currentUser?.diaryCount != user.diaryCount ||
        _currentUser?.consecutiveDays != user.consecutiveDays ||
        _currentUser?.completedChallengeIds.length !=
            user.completedChallengeIds.length) {
      _currentUser = user;
      notifyListeners();
    }
  }

  // 방 꾸미기 설정 저장
  Future<void> updateRoomDecoration(
    String userId,
    RoomDecorationModel decoration,
  ) async {
    if (_currentUser == null) return;

    // 둥지 꾸미기 업데이트 (메모 개별 소비 로직은 useStickyNote로 분리됨)
    await _userService
        .updateUser(userId, {'roomDecoration': decoration.toMap()});

    // Sticky Note Sync (Archive)
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();
    bool hasMemos = false;

    for (final prop in decoration.props) {
      if (prop.type == 'sticky_note' && prop.metadata != null) {
        final memoRef = firestore
            .collection('users')
            .doc(userId)
            .collection('memos')
            .doc(prop.id);

        batch.set(
            memoRef,
            {
              'id': prop.id,
              'content': prop.metadata!['content'],
              'heartCount': prop.metadata!['heartCount'] ?? 0,
              'likedBy': prop.metadata!['likedBy'] ?? [],
              'createdAt': prop.metadata!['createdAt'] ??
                  DateTime.now().toIso8601String(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));
        hasMemos = true;
      }
    }

    if (hasMemos) {
      await batch.commit();
    }

    _currentUser = _currentUser!.copyWith(roomDecoration: decoration);
    notifyListeners();
  }

  /// 메모 작성 시 5가지를 차감하고 마지막 작성 시간을 기록합니다.
  Future<void> useStickyNote(String userId) async {
    if (_currentUser == null) return;
    if (_currentUser!.points < 5) throw Exception('가지가 부족합니다 (5가지 필요)');

    final now = DateTime.now();
    final updates = {
      'points': FieldValue.increment(-5),
      'lastStickyNoteDate': FieldValue.serverTimestamp(),
      'memoCount': FieldValue.increment(1),
    };

    await _pointHistoryService.addHistory(
      userId: userId,
      type: 'sticky_note',
      description: '메모 작성',
      amount: -5,
    );

    await _userService.updateUser(userId, updates);

    _currentUser = _currentUser!.copyWith(
      points: _currentUser!.points - 5,
      lastStickyNoteDate: now,
      memoCount: _currentUser!.memoCount + 1,
    );
    notifyListeners();

    // 도전과제 달성 체크
    await checkAchievements();
  }

  /// 만료된(72시간이 지난) 메모를 확인하고 제거합니다.
  Future<void> checkAndClearExpiredMemos(String userId) async {
    if (_currentUser == null) return;

    final decoration = _currentUser!.roomDecoration;
    final now = DateTime.now();

    // 72시간(3일)이 지나지 않은 메모만 유지
    final activeProps = decoration.props.where((p) {
      if (p.type != 'sticky_note') return true;
      if (p.metadata == null || p.metadata!['createdAt'] == null) return false;

      try {
        final createdAt = DateTime.parse(p.metadata!['createdAt']);
        return now.difference(createdAt).inHours < 72;
      } catch (e) {
        return false;
      }
    }).toList();

    // 변경사항이 있는 경우에만 업데이트
    if (activeProps.length != decoration.props.length) {
      final newDecoration = decoration.copyWith(props: activeProps);
      await updateRoomDecoration(userId, newDecoration);
    }
  }

  // 레벨에서 캐릭터 상태 결정
  CharacterState _getCharacterStateFromLevel(int level) {
    switch (level) {
      case 1:
        return CharacterState.egg;
      case 2:
        return CharacterState.cracking;
      case 3:
        return CharacterState.hatching;
      case 4:
        return CharacterState.baby;
      case 5:
        return CharacterState.young;
      case 6:
        return CharacterState.adult;
      default:
        return CharacterState.egg;
    }
  }

  // 캐릭터 깨우기 (일기 작성 완료 시)
  Future<void> wakeUpCharacter(String userId) async {
    _isAwake = true;
    _currentAnimation = 'wake_up';
    Future.microtask(() {
      notifyListeners();
    });

    // 잠시 후 idle 애니메이션으로 전환
    await Future.delayed(const Duration(seconds: 2));
    _currentAnimation = 'idle';
    Future.microtask(() {
      notifyListeners();
    });

    // 경험치만 지급 (포인트는 MorningController에서 통합 지급)
    await _addPointsAndExp(userId, 0, 10);

    // 일기 작성 후 최신 사용자 정보 동기화
    await _syncUserData(userId);

    // 레벨업 체크
    await _checkLevelUp(userId);

    // 도전과제 달성 체크
    await checkAchievements();
  }

  // 외부에서 상태 강제 설정 (앱 초기화용)
  void setAwake(bool awake) {
    _isAwake = awake;
    notifyListeners();
  }

  // 포인트 및 경험치 추가
  Future<void> _addPointsAndExp(String userId, int points, int exp) async {
    if (_currentUser == null) return;

    final newPoints = _currentUser!.points + points;
    final newExp = _currentUser!.experience + exp;

    await _userService.updateUser(userId, {
      'points': newPoints,
      'experience': newExp,
    });

    _currentUser = _currentUser!.copyWith(
      points: newPoints,
      experience: newExp,
    );
    Future.microtask(() {
      notifyListeners();
    });
  }

  // 일기 작성 후 최신 사용자 정보 동기화
  Future<void> _syncUserData(String userId) async {
    final user = await _userService.getUser(userId);
    if (user == null) return;

    _currentUser = user;
    Future.microtask(() {
      notifyListeners();
    });
  }

  // 레벨업 체크
  Future<void> _checkLevelUp(String userId) async {
    if (_currentUser == null) return;

    final currentLevel = _currentUser!.characterLevel;
    final currentExp = _currentUser!.experience;

    // 최대 레벨 체크
    if (currentLevel >= 6) return;

    // 다음 레벨 필요 경험치
    final requiredExp = UserModel.getRequiredExpForLevel(currentLevel);

    // 레벨업 조건 충족 확인
    if (currentExp >= requiredExp) {
      await _levelUp(userId, currentLevel + 1);
    }
  }

  // 레벨업 실행
  Future<void> _levelUp(String userId, int newLevel) async {
    _currentAnimation = 'evolve';
    Future.microtask(() {
      notifyListeners();
    });

    await Future.delayed(const Duration(seconds: 1));

    await _userService.updateUser(userId, {
      'characterLevel': newLevel,
      'experience': 0, // 레벨업 후 경험치 초기화
    });

    _currentUser = _currentUser!.copyWith(
      characterLevel: newLevel,
      experience: 0,
    );

    _currentAnimation = 'idle';
    _showLevelUpDialog = true;
    _justLeveledUpTo = newLevel;
    Future.microtask(() {
      notifyListeners();
    });
  }

  // 친구에게 깨우기 당함 (외부에서 호출)
  Future<void> receiveWakeUp(String userId) async {
    _currentAnimation = 'shake';
    Future.microtask(() {
      notifyListeners();
    });

    await Future.delayed(const Duration(milliseconds: 500));
    _currentAnimation = 'idle';
    Future.microtask(() {
      notifyListeners();
    });
  }

  // 테마 구매
  Future<void> purchaseTheme(String userId, String themeId, int price) async {
    if (_currentUser == null) return;
    if (_currentUser!.points < price) throw Exception('가지가 부족합니다');
    if (_currentUser!.purchasedThemeIds.contains(themeId)) {
      throw Exception('이미 구매한 테마입니다');
    }

    final newPurchasedThemes = List<String>.from(
      _currentUser!.purchasedThemeIds,
    )..add(themeId);
    final newPoints = _currentUser!.points - price;

    await _pointHistoryService.addHistory(
      userId: userId,
      type: 'purchase',
      description: '테마 구매: $themeId',
      amount: -price,
    );

    await _userService.updateUser(userId, {
      'points': newPoints,
      'purchasedThemeIds': newPurchasedThemes,
    });

    _currentUser = _currentUser!.copyWith(
      points: newPoints,
      purchasedThemeIds: newPurchasedThemes,
    );
    notifyListeners();

    await checkAchievements();
  }

  // 배경 구매
  Future<void> purchaseBackground(
    String userId,
    String backgroundId,
    int price,
  ) async {
    if (_currentUser == null) return;
    if (_currentUser!.points < price) throw Exception('가지가 부족합니다');
    if (_currentUser!.purchasedBackgroundIds.contains(backgroundId)) {
      throw Exception('이미 구매한 배경입니다');
    }

    final newPurchasedBackgrounds = List<String>.from(
      _currentUser!.purchasedBackgroundIds,
    )..add(backgroundId);
    final newPoints = _currentUser!.points - price;

    await _pointHistoryService.addHistory(
      userId: userId,
      type: 'purchase',
      description: '배경 구매: $backgroundId',
      amount: -price,
    );

    await _userService.updateUser(userId, {
      'points': newPoints,
      'purchasedBackgroundIds': newPurchasedBackgrounds,
    });

    _currentUser = _currentUser!.copyWith(
      points: newPoints,
      purchasedBackgroundIds: newPurchasedBackgrounds,
    );
    notifyListeners();

    await checkAchievements();
  }

  // 벽지 구매
  Future<void> purchaseWallpaper(
    String userId,
    String wallpaperId,
    int price,
  ) async {
    if (_currentUser == null) return;
    if (_currentUser!.points < price) throw Exception('가지가 부족합니다');

    if (_currentUser!.purchasedThemeIds.contains(wallpaperId)) {
      throw Exception('이미 구매한 벽지입니다');
    }

    final newPurchasedThemes = List<String>.from(
      _currentUser!.purchasedThemeIds,
    )..add(wallpaperId);
    final newPoints = _currentUser!.points - price;

    await _pointHistoryService.addHistory(
      userId: userId,
      type: 'purchase',
      description: '벽지 구매: $wallpaperId',
      amount: -price,
    );

    await _userService.updateUser(userId, {
      'points': newPoints,
      'purchasedThemeIds': newPurchasedThemes,
    });

    _currentUser = _currentUser!.copyWith(
      points: newPoints,
      purchasedThemeIds: newPurchasedThemes,
    );
    notifyListeners();

    await checkAchievements();
  }

  // 소품 구매
  Future<void> purchaseProp(String userId, String propId, int price) async {
    if (_currentUser == null) return;
    if (_currentUser!.points < price) throw Exception('가지가 부족합니다');
    if (_currentUser!.purchasedPropIds.contains(propId)) {
      throw Exception('이미 구매한 소품입니다');
    }

    // 스티커 메모는 이제 useStickyNote에서 처리하므로 여기서는 일반 구매 불가
    if (propId == 'sticky_note') {
      throw Exception('메모는 꾸미기 화면에서 직접 작성할 수 있습니다.');
    }

    final newPurchasedProps = List<String>.from(_currentUser!.purchasedPropIds)
      ..add(propId);
    final newPoints = _currentUser!.points - price;

    await _pointHistoryService.addHistory(
      userId: userId,
      type: 'purchase',
      description: '소품 구매: $propId',
      amount: -price,
    );

    await _userService.updateUser(userId, {
      'points': newPoints,
      'purchasedPropIds': newPurchasedProps,
    });

    _currentUser = _currentUser!.copyWith(
      points: newPoints,
      purchasedPropIds: newPurchasedProps,
    );
    notifyListeners();

    await checkAchievements();
  }

  // 이모티콘 구매
  Future<void> purchaseEmoticon(
    String userId,
    String emoticonId,
    int price,
  ) async {
    if (_currentUser == null) return;
    if (_currentUser!.points < price) throw Exception('가지가 부족합니다');
    if (_currentUser!.purchasedEmoticonIds.contains(emoticonId)) {
      throw Exception('이미 구매한 이모티콘입니다');
    }

    final newPurchasedEmoticons = List<String>.from(
      _currentUser!.purchasedEmoticonIds,
    )..add(emoticonId);
    final newPoints = _currentUser!.points - price;

    await _pointHistoryService.addHistory(
      userId: userId,
      type: 'purchase',
      description: '이모티콘 구매: $emoticonId',
      amount: -price,
    );

    await _userService.updateUser(userId, {
      'points': newPoints,
      'purchasedEmoticonIds': newPurchasedEmoticons,
    });

    _currentUser = _currentUser!.copyWith(
      points: newPoints,
      purchasedEmoticonIds: newPurchasedEmoticons,
    );
    notifyListeners();

    await checkAchievements();
  }

  // 바닥 구매
  Future<void> purchaseFloor(String userId, String floorId, int price) async {
    if (_currentUser == null) return;
    if (_currentUser!.points < price) throw Exception('가지가 부족합니다');
    if (_currentUser!.purchasedFloorIds.contains(floorId)) {
      throw Exception('이미 구매한 바닥입니다');
    }

    final newPurchasedFloors = List<String>.from(
      _currentUser!.purchasedFloorIds,
    )..add(floorId);
    final newPoints = _currentUser!.points - price;

    await _pointHistoryService.addHistory(
      userId: userId,
      type: 'purchase',
      description: '바닥 구매: $floorId',
      amount: -price,
    );

    await _userService.updateUser(userId, {
      'points': newPoints,
      'purchasedFloorIds': newPurchasedFloors,
    });

    _currentUser = _currentUser!.copyWith(
      points: newPoints,
      purchasedFloorIds: newPurchasedFloors,
    );
    notifyListeners();

    await checkAchievements();
  }

  // 창문 구매
  Future<void> purchaseWindow(String userId, String windowId, int price) async {
    if (_currentUser == null) return;
    if (_currentUser!.points < price) throw Exception('가지가 부족합니다');
    if (_currentUser!.purchasedWindowIds.contains(windowId)) {
      throw Exception('이미 구매한 창문입니다');
    }

    final newPurchasedWindows = List<String>.from(
      _currentUser!.purchasedWindowIds,
    )..add(windowId);
    final newPoints = _currentUser!.points - price;

    await _pointHistoryService.addHistory(
      userId: userId,
      type: 'purchase',
      description: '창문 구매: $windowId',
      amount: -price,
    );

    await _userService.updateUser(userId, {
      'points': newPoints,
      'purchasedWindowIds': newPurchasedWindows,
    });

    _currentUser = _currentUser!.copyWith(
      points: newPoints,
      purchasedWindowIds: newPurchasedWindows,
    );
    notifyListeners();

    await checkAchievements();
  }

  // 캐릭터 아이템 구매
  Future<void> purchaseCharacterItem(
    String userId,
    String itemId,
    int price,
  ) async {
    if (_currentUser == null) return;
    if (_currentUser!.points < price) throw Exception('가지가 부족합니다');
    if (_currentUser!.purchasedCharacterItemIds.contains(itemId)) {
      throw Exception('이미 구매한 아이템입니다');
    }

    final newPurchasedItems = List<String>.from(
      _currentUser!.purchasedCharacterItemIds,
    )..add(itemId);
    final newPoints = _currentUser!.points - price;

    await _pointHistoryService.addHistory(
      userId: userId,
      type: 'purchase',
      description: '캐릭터 아이템 구매: $itemId',
      amount: -price,
    );

    await _userService.updateUser(userId, {
      'points': newPoints,
      'purchasedCharacterItemIds': newPurchasedItems,
    });

    _currentUser = _currentUser!.copyWith(
      points: newPoints,
      purchasedCharacterItemIds: newPurchasedItems,
    );
    notifyListeners();

    await checkAchievements();
  }

  // 캐릭터 아이템 장착/해제
  Future<void> equipCharacterItem(String userId, String itemId) async {
    if (_currentUser == null) return;

    // 만약 구매한 아이템이 아니면 에러 (해제의 경우 구매여부 상관없을 수도 있지만 일단 체크)
    if (itemId.isNotEmpty &&
        !_currentUser!.purchasedCharacterItemIds.contains(itemId)) {
      throw Exception('구매하지 않은 아이템입니다');
    }

    final currentEquipped = Map<String, dynamic>.from(
      _currentUser!.equippedCharacterItems,
    );

    // 아이템별 슬롯 지정
    String slot = 'face';
    if (itemId == 'necktie') {
      slot = 'body';
    } else if (itemId == 'space_clothes' || itemId == 'prog_clothes') {
      slot = 'clothes';
    } else if (itemId == 'sprout' || itemId == 'plogeyes') {
      slot = 'head';
    }

    // 이미 어딘가에 장착되어 있는지 체크 (슬롯 변경 대응 및 중복 방지)
    String? existingSlot;
    currentEquipped.forEach((key, value) {
      if (value == itemId) {
        existingSlot = key;
      }
    });

    if (existingSlot != null) {
      // 이미 장착되어 있다면 해당 슬롯에서 제거 (해제)
      currentEquipped.remove(existingSlot);
    } else {
      // 장착되어 있지 않다면 지정된 슬롯에 장착
      currentEquipped[slot] = itemId;
    }

    await _userService.updateUser(userId, {
      'equippedCharacterItems': currentEquipped,
    });

    _currentUser = _currentUser!.copyWith(
      equippedCharacterItems: currentEquipped,
    );
    notifyListeners();
  }

  // 캐릭터 아이템 일괄 장착 (저장하기용)
  Future<void> updateEquippedCharacterItems(
    String userId,
    Map<String, String> newEquippedItems,
  ) async {
    if (_currentUser == null) return;

    await _userService.updateUser(userId, {
      'equippedCharacterItems': newEquippedItems,
    });

    _currentUser = _currentUser!.copyWith(
      equippedCharacterItems: newEquippedItems,
    );
    notifyListeners();
  }

  // 테마 설정
  Future<void> setTheme(String userId, String themeId) async {
    if (_currentUser == null) return;
    if (!_currentUser!.purchasedThemeIds.contains(themeId)) {
      throw Exception('구매하지 않은 테마입니다');
    }

    await _userService.updateUser(userId, {'currentThemeId': themeId});

    _currentUser = _currentUser!.copyWith(currentThemeId: themeId);
    notifyListeners();
  }

  // 활성 이모티콘 설정
  Future<void> updateActiveEmoticons(
    String userId,
    List<String> emoticonIds,
  ) async {
    if (_currentUser == null) return;
    // Limit removed as per user request (4 or more allowed)

    // 모두 구매한 이모티콘인지 확인
    for (final id in emoticonIds) {
      if (!_currentUser!.purchasedEmoticonIds.contains(id)) {
        throw Exception('구매하지 않은 이모티콘이 포함되어 있습니다: $id');
      }
    }

    await _userService.updateUser(userId, {'activeEmoticonIds': emoticonIds});

    _currentUser = _currentUser!.copyWith(activeEmoticonIds: emoticonIds);
    notifyListeners();
  }

  // 광고 로드
  void loadRewardedAd({BuildContext? context}) {
    if (_rewardedAd != null || _isAdLoading) return;

    final currentContext = context ?? AppRouter.navigatorKey.currentContext;
    if (currentContext == null) return;

    _isAdLoading = true;
    notifyListeners();

    // Test Ad Unit ID
    // Android: ca-app-pub-3940256099942544/5224354917
    // iOS: ca-app-pub-3940256099942544/1712485313
    final adUnitId = Theme.of(currentContext).platform == TargetPlatform.iOS
        ? 'ca-app-pub-3940256099942544/1712485313'
        : 'ca-app-pub-3940256099942544/5224354917';

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('$ad loaded.');
          _rewardedAd = ad;
          _isAdLoading = false;
          notifyListeners();
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('RewardedAd failed to load: $error');
          _isAdLoading = false;
          notifyListeners();
        },
      ),
    );
  }

  // 광고 보여주기
  void showRewardedAd(BuildContext context) {
    if (_rewardedAd == null) {
      loadRewardedAd(context: context);
      MemoNotification.show(context, '광고가 아직 준비되지 않았습니다. 잠시 후 다시 시도해주세요. 📺');
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd(); // 다음 광고 미리 로드
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem rewardItem) async {
        if (_currentUser != null) {
          await watchAdAndGetPoints(_currentUser!.uid);
          if (context.mounted) {
            // 팝업 표시
            await AppDialog.show(context: context, key: AppDialogKey.adReward);
          }
        }
      },
    );
  }

  Future<void> watchAdAndGetPoints(String userId) async {
    if (_currentUser == null) return;

    final now = DateTime.now();
    int currentCount = _currentUser!.adRewardCount;
    DateTime? lastDate = _currentUser!.lastAdRewardDate;

    // 날짜가 바뀌었는지 확인 (어제 이전에 봤다면 카운트 초기화)
    if (lastDate != null) {
      if (lastDate.year != now.year ||
          lastDate.month != now.month ||
          lastDate.day != now.day) {
        currentCount = 0;
      }
    }

    // 하루 최대 5번 제한
    if (currentCount >= 5) {
      throw Exception('오늘은 더 이상 광고를 통해\n가지를 획득할 수 없습니다.\n(일일 최대 5회)');
    }

    final newPoints = _currentUser!.points + 20;
    final newCount = currentCount + 1;

    await _pointHistoryService.addHistory(
      userId: userId,
      type: 'ad',
      description: '광고 시청 보상',
      amount: 20,
    );

    await _userService.updateUser(userId, {
      'points': newPoints,
      'adRewardCount': newCount,
      'lastAdRewardDate': FieldValue.serverTimestamp(),
    });

    _currentUser = _currentUser!.copyWith(
      points: newPoints,
      adRewardCount: newCount,
      lastAdRewardDate: now,
    );
    notifyListeners();
  }

  // 모든 상태 초기화 (로그아웃용)
  void clear() {
    _shopDiscountSubscription?.cancel();
    _shopDiscountSubscription = null;
    _currentUser = null;
    _isAwake = false;
    _currentAnimation = 'idle';
    notifyListeners();
  }

  // 캐릭터 이미지 경로 가져오기
  String getCharacterImagePath() {
    final state = characterState;
    final animation = _currentAnimation;

    // assets/images/character/{state}_{animation}.png
    return 'assets/images/character/${state.toString().split('.').last}_$animation.png';
  }

  // 도전과제 달성 체크
  Future<void> checkAchievements([BuildContext? context]) async {
    if (_currentUser == null) return;

    final currentContext = context ?? AppRouter.navigatorKey.currentContext;
    // context가 없으면 다이얼로그나 로컬라이제이션을 사용할 수 없으므로 중단
    if (currentContext == null) return;

    final user = _currentUser!;
    final List<Challenge> completedNow = [];

    // 1. 달성된 도전과제 찾기
    for (final challenge in challenges) {
      // 이미 완료된 도전과제는 스킵
      if (!user.completedChallengeIds.contains(challenge.id)) {
        // 조건 충족 시
        if (challenge.isCompleted(user)) {
          completedNow.add(challenge);
        }
      }
    }

    if (completedNow.isEmpty) return;

    // 2. 보상 지급 및 상태 업데이트 (Firestore)
    // List를 복사하여 수정 불가능한 리스트 오류 방지
    final newCompletedIds = List<String>.from(user.completedChallengeIds)
      ..addAll(completedNow.map((c) => c.id));

    int totalReward = 0;
    for (final c in completedNow) {
      totalReward += c.reward;
    }

    final newPoints = user.points + totalReward;

    for (final c in completedNow) {
      await _pointHistoryService.addHistory(
        userId: user.uid,
        type: 'challenge',
        description: '도전과제 달성: ${c.id}',
        amount: c.reward,
      );
    }

    await _userService.updateUser(user.uid, {
      'completedChallengeIds': newCompletedIds,
      'points': newPoints,
    });

    // 3. 로컬 상태 업데이트
    _currentUser = _currentUser!.copyWith(
      completedChallengeIds: newCompletedIds,
      points: newPoints,
    );
    notifyListeners();

    // 4. 알림 생성 및 다이얼로그 표시 (각 도전과제별)
    for (final challenge in completedNow) {
      final title =
          AppLocalizations.of(currentContext)?.get(challenge.titleKey) ?? '';
      final challengeCompletedText =
          AppLocalizations.of(currentContext)?.get('challengeCompleted') ??
              'Challenge Completed!';
      final message = '$challengeCompletedText: $title';
      final branchText =
          AppLocalizations.of(currentContext)?.get('branch') ?? 'Branch';

      // 알림 추가 (Firestore 직접 접근)
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': user.uid,
        'senderId': 'system',
        'senderNickname': 'Morni',
        'type': NotificationType.challenge.toString().split('.').last,
        'message': message,
        'isRead': false,
        'fcmSent': false,
        'createdAt': FieldValue.serverTimestamp(),
        'data': {
          'challengeId': challenge.id,
          'challengeTitleKey': challenge.titleKey,
          'reward': challenge.reward,
        },
      });

      // 팝업 표시
      if (currentContext.mounted) {
        await AppDialog.show(
          context: currentContext,
          key: AppDialogKey.challengeCompleted,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'BMJUA',
                  fontSize: 20,
                  color: Color(0xFF4E342E),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Image.asset(
                'assets/images/branch.png',
                width: 60,
                height: 60,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 8),
              Text(
                '+ ${challenge.reward} $branchText',
                style: const TextStyle(
                  fontFamily: 'BMJUA',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
            ],
          ),
        );
      }
    }
  }
}
