import 'package:flutter/material.dart';
import '../../../services/user_service.dart';
import '../../../data/models/user_model.dart';

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

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isAwake => _isAwake;
  String get currentAnimation => _currentAnimation;
  CharacterState get characterState =>
      _getCharacterStateFromLevel(_currentUser?.characterLevel ?? 1);

  // 사용자 정보 로드
  Future<void> loadUserData(String userId) async {
    try {
      _currentUser = await _userService.getUser(userId);
      Future.microtask(() {
        notifyListeners();
      });
    } catch (e) {
      print('사용자 데이터 로드 오류: $e');
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

    await Future.delayed(const Duration(seconds: 3));

    await _userService.updateUser(userId, {
      'characterLevel': newLevel,
      'experience': 0, // 레벨업 후 경험치 초기화
    });

    _currentUser = _currentUser!.copyWith(
      characterLevel: newLevel,
      experience: 0,
    );

    _currentAnimation = 'idle';
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

  // 캐릭터 이미지 경로 가져오기
  String getCharacterImagePath() {
    final state = characterState;
    final animation = _currentAnimation;

    // assets/images/character/{state}_{animation}.png
    return 'assets/images/character/${state.toString().split('.').last}_$animation.png';
  }
}
