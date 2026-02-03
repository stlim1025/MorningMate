import 'package:flutter/material.dart';
import '../../../services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/room_decoration_model.dart';

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

  CharacterController(this._userService);

  // 상태 변수
  UserModel? _currentUser;
  bool _isAwake = false;
  String _currentAnimation = 'idle';
  bool _showLevelUpDialog = false;
  int? _justLeveledUpTo;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isAwake => _isAwake;
  String get currentAnimation => _currentAnimation;
  bool get showLevelUpDialog => _showLevelUpDialog;
  int? get justLeveledUpTo => _justLeveledUpTo;

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
            user.roomDecoration.props.length) {
      _currentUser = user;
      notifyListeners();
    }
  }

  // 방 꾸미기 설정 저장
  Future<void> updateRoomDecoration(
      String userId, RoomDecorationModel decoration) async {
    if (_currentUser == null) return;

    final oldProps = _currentUser!.roomDecoration.props;
    final newProps = decoration.props;

    // 새롭게 추가된 스티커 메모가 있는지 확인
    // 기존 소품에 스티커 메모가 없었고, 새로운 소품에 스티커 메모가 있다면 새로 추가된 것으로 간주
    bool newlyAddedStickyNote = !oldProps.any((p) => p.type == 'sticky_note') &&
        newProps.any((p) => p.type == 'sticky_note');

    Map<String, dynamic> updates = {
      'roomDecoration': decoration.toMap(),
    };

    if (newlyAddedStickyNote) {
      // 1. 일회용 소품 소비 (인벤토리에서 제거)
      final updatedPurchasedProps =
          List<String>.from(_currentUser!.purchasedPropIds);
      updatedPurchasedProps.remove('sticky_note');

      updates['purchasedPropIds'] = updatedPurchasedProps;
      updates['lastStickyNoteDate'] = FieldValue.serverTimestamp();

      // 로컬 모델 미리 업데이트 (UI 반영용)
      _currentUser = _currentUser!.copyWith(
        purchasedPropIds: updatedPurchasedProps,
        lastStickyNoteDate: DateTime.now(),
      );
    }

    await _userService.updateUser(userId, updates);

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

  /// 만료된(오늘 날짜가 아닌) 메모를 확인하고 제거합니다.
  Future<void> checkAndClearExpiredMemos(String userId) async {
    if (_currentUser == null) return;

    final decoration = _currentUser!.roomDecoration;
    final now = DateTime.now();

    // 오늘 날짜가 아닌 스티커 메모 필터링
    final activeProps = decoration.props.where((p) {
      if (p.type != 'sticky_note') return true;
      if (p.metadata == null || p.metadata!['createdAt'] == null) return false;

      try {
        final createdAt = DateTime.parse(p.metadata!['createdAt']);
        return createdAt.year == now.year &&
            createdAt.month == now.month &&
            createdAt.day == now.day;
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

    // 포인트 및 경험치 지급
    await _addPointsAndExp(userId, 10, 10);

    // 일기 작성 후 최신 사용자 정보 동기화
    await _syncUserData(userId);

    // 레벨업 체크
    await _checkLevelUp(userId);
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

    final newPurchasedThemes =
        List<String>.from(_currentUser!.purchasedThemeIds)..add(themeId);
    final newPoints = _currentUser!.points - price;

    await _userService.updateUser(userId, {
      'points': newPoints,
      'purchasedThemeIds': newPurchasedThemes,
    });

    _currentUser = _currentUser!.copyWith(
      points: newPoints,
      purchasedThemeIds: newPurchasedThemes,
    );
    notifyListeners();
  }

  // 배경 구매
  Future<void> purchaseBackground(
      String userId, String backgroundId, int price) async {
    if (_currentUser == null) return;
    if (_currentUser!.points < price) throw Exception('가지가 부족합니다');
    if (_currentUser!.purchasedBackgroundIds.contains(backgroundId)) {
      throw Exception('이미 구매한 배경입니다');
    }

    final newPurchasedBackgrounds =
        List<String>.from(_currentUser!.purchasedBackgroundIds)
          ..add(backgroundId);
    final newPoints = _currentUser!.points - price;

    await _userService.updateUser(userId, {
      'points': newPoints,
      'purchasedBackgroundIds': newPurchasedBackgrounds,
    });

    _currentUser = _currentUser!.copyWith(
      points: newPoints,
      purchasedBackgroundIds: newPurchasedBackgrounds,
    );
    notifyListeners();
  }

  // 벽지 구매
  Future<void> purchaseWallpaper(
      String userId, String wallpaperId, int price) async {
    if (_currentUser == null) return;
    if (_currentUser!.points < price) throw Exception('가지가 부족합니다');

    if (_currentUser!.purchasedThemeIds.contains(wallpaperId)) {
      throw Exception('이미 구매한 벽지입니다');
    }

    final newPurchasedThemes =
        List<String>.from(_currentUser!.purchasedThemeIds)..add(wallpaperId);
    final newPoints = _currentUser!.points - price;

    await _userService.updateUser(userId, {
      'points': newPoints,
      'purchasedThemeIds': newPurchasedThemes,
    });

    _currentUser = _currentUser!.copyWith(
      points: newPoints,
      purchasedThemeIds: newPurchasedThemes,
    );
    notifyListeners();
  }

  // 소품 구매
  Future<void> purchaseProp(String userId, String propId, int price) async {
    if (_currentUser == null) return;
    if (_currentUser!.points < price) throw Exception('가지가 부족합니다');
    if (_currentUser!.purchasedPropIds.contains(propId)) {
      throw Exception('이미 구매한 소품입니다');
    }

    // 스티커 메모는 하루에 한 번만 작성 가능
    if (propId == 'sticky_note' && _currentUser!.lastStickyNoteDate != null) {
      final now = DateTime.now();
      final lastDate = _currentUser!.lastStickyNoteDate!;
      if (lastDate.year == now.year &&
          lastDate.month == now.month &&
          lastDate.day == now.day) {
        throw Exception('메모는 하루에 한 번만 작성할 수 있습니다.');
      }
    }

    final newPurchasedProps = List<String>.from(_currentUser!.purchasedPropIds)
      ..add(propId);
    final newPoints = _currentUser!.points - price;

    await _userService.updateUser(userId, {
      'points': newPoints,
      'purchasedPropIds': newPurchasedProps,
    });

    _currentUser = _currentUser!.copyWith(
      points: newPoints,
      purchasedPropIds: newPurchasedProps,
    );
    notifyListeners();
  }

  // 바닥 구매
  Future<void> purchaseFloor(String userId, String floorId, int price) async {
    if (_currentUser == null) return;
    if (_currentUser!.points < price) throw Exception('가지가 부족합니다');
    if (_currentUser!.purchasedFloorIds.contains(floorId)) {
      throw Exception('이미 구매한 바닥입니다');
    }

    final newPurchasedFloors =
        List<String>.from(_currentUser!.purchasedFloorIds)..add(floorId);
    final newPoints = _currentUser!.points - price;

    await _userService.updateUser(userId, {
      'points': newPoints,
      'purchasedFloorIds': newPurchasedFloors,
    });

    _currentUser = _currentUser!.copyWith(
      points: newPoints,
      purchasedFloorIds: newPurchasedFloors,
    );
    notifyListeners();
  }

  // 테마 설정
  Future<void> setTheme(String userId, String themeId) async {
    if (_currentUser == null) return;
    if (!_currentUser!.purchasedThemeIds.contains(themeId)) {
      throw Exception('구매하지 않은 테마입니다');
    }

    await _userService.updateUser(userId, {
      'currentThemeId': themeId,
    });

    _currentUser = _currentUser!.copyWith(currentThemeId: themeId);
    notifyListeners();
  }

  // 모든 상태 초기화 (로그아웃용)
  void clear() {
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
}
