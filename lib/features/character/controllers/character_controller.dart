import 'package:flutter/material.dart';
import '../../../services/firestore_service.dart';
import '../../../data/models/user_model.dart';

// 캐릭터 상태 정의
enum CharacterState {
  egg, // 알 (초기)
  hatchling, // 부화 (7일 연속)
  adult, // 성체 (친구 깨우기 5회)
  explorer, // 탐험가 (특별 조건)
  sleeping, // 수면 (3일 미활동)
}

class CharacterController extends ChangeNotifier {
  final FirestoreService _firestoreService;

  CharacterController(this._firestoreService);

  // 상태 변수
  UserModel? _currentUser;
  bool _isAwake = false;
  String _currentAnimation = 'idle';

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isAwake => _isAwake;
  String get currentAnimation => _currentAnimation;
  CharacterState get characterState =>
      _getCharacterStateFromString(_currentUser?.characterState ?? 'egg');

  // 사용자 정보 로드
  Future<void> loadUserData(String userId) async {
    try {
      _currentUser = await _firestoreService.getUser(userId);
      Future.microtask(() {
        notifyListeners();
      });
    } catch (e) {
      print('사용자 데이터 로드 오류: $e');
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

    // 포인트 지급 (+10)
    await _addPoints(userId, 10);

    // 연속 일수 체크 및 업데이트
    await _updateConsecutiveDays(userId);

    // 상태 전이 체크
    await _checkStateTransition(userId);
  }

  // 외부에서 상태 강제 설정 (앱 초기화용)
  void setAwake(bool awake) {
    _isAwake = awake;
    notifyListeners();
  }

  // 포인트 추가
  Future<void> _addPoints(String userId, int points) async {
    if (_currentUser == null) return;

    final newPoints = _currentUser!.points + points;
    await _firestoreService.updateUser(userId, {
      'points': newPoints,
    });

    _currentUser = _currentUser!.copyWith(points: newPoints);
    Future.microtask(() {
      notifyListeners();
    });
  }

  // 연속 일수 업데이트
  Future<void> _updateConsecutiveDays(String userId) async {
    if (_currentUser == null) return;

    final lastLogin = _currentUser!.lastLoginDate;
    final today = DateTime.now();
    int newConsecutiveDays = _currentUser!.consecutiveDays;

    if (lastLogin == null) {
      newConsecutiveDays = 1;
    } else {
      final difference = today.difference(lastLogin).inDays;
      if (difference == 1) {
        // 연속
        newConsecutiveDays++;
        // 연속 보너스 포인트 (+20)
        await _addPoints(userId, 20);
      } else if (difference > 1) {
        // 연속 끊김
        newConsecutiveDays = 1;
      }
    }

    await _firestoreService.updateUser(userId, {
      'consecutiveDays': newConsecutiveDays,
      'lastLoginDate': DateTime.now(),
    });

    _currentUser = _currentUser!.copyWith(
      consecutiveDays: newConsecutiveDays,
      lastLoginDate: today,
    );
    Future.microtask(() {
      notifyListeners();
    });
  }

  // 캐릭터 상태 전이 체크
  Future<void> _checkStateTransition(String userId) async {
    if (_currentUser == null) return;

    CharacterState newState = characterState;
    bool shouldEvolve = false;

    // 상태 전이 규칙
    switch (characterState) {
      case CharacterState.egg:
        // 7일 연속 작성 시 부화
        if (_currentUser!.consecutiveDays >= 7) {
          newState = CharacterState.hatchling;
          shouldEvolve = true;
        }
        break;

      case CharacterState.hatchling:
        // 친구로부터 깨우기 5회 이상 수신 시 성체
        // (이 부분은 SocialController에서 처리)
        break;

      case CharacterState.adult:
        // 특정 조건 달성 시 탐험가
        if (_currentUser!.points >= 1000) {
          newState = CharacterState.explorer;
          shouldEvolve = true;
        }
        break;

      case CharacterState.sleeping:
        // 일기 작성으로 다시 활성화
        newState = CharacterState.hatchling;
        shouldEvolve = true;
        break;

      default:
        break;
    }

    // 진화 실행
    if (shouldEvolve) {
      await _evolveCharacter(userId, newState);
    }
  }

  // 캐릭터 진화
  Future<void> _evolveCharacter(String userId, CharacterState newState) async {
    _currentAnimation = 'evolve';
    Future.microtask(() {
      notifyListeners();
    });

    await Future.delayed(const Duration(seconds: 3));

    final stateString = _getStringFromCharacterState(newState);
    await _firestoreService.updateUser(userId, {
      'characterState': stateString,
      'characterLevel': _currentUser!.characterLevel + 1,
    });

    _currentUser = _currentUser!.copyWith(
      characterState: stateString,
      characterLevel: _currentUser!.characterLevel + 1,
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

  // Helper: String -> CharacterState
  CharacterState _getCharacterStateFromString(String state) {
    switch (state) {
      case 'egg':
        return CharacterState.egg;
      case 'hatchling':
        return CharacterState.hatchling;
      case 'adult':
        return CharacterState.adult;
      case 'explorer':
        return CharacterState.explorer;
      case 'sleeping':
        return CharacterState.sleeping;
      default:
        return CharacterState.egg;
    }
  }

  // Helper: CharacterState -> String
  String _getStringFromCharacterState(CharacterState state) {
    return state.toString().split('.').last;
  }

  // 캐릭터 이미지 경로 가져오기
  String getCharacterImagePath() {
    final state = characterState;
    final animation = _currentAnimation;

    // assets/images/character/{state}_{animation}.png
    return 'assets/images/character/${state.toString().split('.').last}_$animation.png';
  }
}
