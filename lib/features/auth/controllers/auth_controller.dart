import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/auth_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/user_service.dart';
import '../../../data/models/user_model.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService;
  final UserService _userService;
  final NotificationService _notificationService;

  AuthController(
      this._authService, this._userService, this._notificationService) {
    // 인증 상태 변경 리스너
    _authSubscription =
        _authService.authStateChanges.listen(_handleAuthStateChange);
  }

  User? _currentUser;
  UserModel? _userModel;
  bool _isLoading = false;
  bool _isDeletingAccount = false;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<UserModel?>? _userStreamSubscription;

  User? get currentUser => _currentUser;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  // ✨ [추가] 초기 인증 체크가 끝났는지 확인하는 플래그
  bool _isAuthCheckDone = false;
  bool get isAuthCheckDone => _isAuthCheckDone;

  // ✨ [추가] 생체 인증이 이미 완료되었는지 확인하는 플래그 (중복 요청 방지)
  bool _isBiometricVerified = false;
  bool get isBiometricVerified => _isBiometricVerified;

  void setBiometricVerified(bool verified) {
    _isBiometricVerified = verified;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _userStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleAuthStateChange(User? user) async {
    _currentUser = user;
    _userStreamSubscription?.cancel();

    if (user != null) {
      // FCM 토큰 갱신 리스너 등록
      _notificationService.setOnTokenRefreshHandler(
        (token) => _userService.updateFcmToken(user.uid, token),
      );

      // 🚨 [핵심 수정] 스트림 연결 전에, '단건 조회'로 데이터를 먼저 확실히 가져옵니다.
      try {
        final initialUserData = await _userService.getUser(user.uid);
        if (initialUserData != null) {
          _userModel = initialUserData;
        }
      } catch (e) {
        debugPrint("초기 유저 정보 로드 실패: $e");
      }

      // 사용자 데이터 실시간 감시
      _userStreamSubscription =
          _userService.getUserStream(user.uid).listen((model) {
        if (model == null && _currentUser != null && !_isDeletingAccount) {
          debugPrint('User document missing...');
        } else {
          _userModel = model;
          notifyListeners();
        }
      });

      await _updateFcmToken(user.uid);
      try {
        await _userService.updateLastLogin(user.uid);
      } catch (e) {
        debugPrint('로그인 시간 업데이트 실패: $e');
      }
    } else {
      _notificationService.setOnTokenRefreshHandler(null);
      _userModel = null;
    }

    // ✨ [추가] 모든 로직이 끝났으므로 "확인 완료" 도장을 찍습니다.
    _isAuthCheckDone = true;
    notifyListeners();
  }

  void updateUserModel(UserModel? userModel) {
    _userModel = userModel;
    notifyListeners();
  }

  // FCM 토큰 업데이트
  Future<void> _updateFcmToken(String userId) async {
    try {
      _notificationService.setOnTokenRefreshHandler(
        (token) => _userService.updateFcmToken(userId, token),
      );
      await _notificationService.initialize();
      final token = _notificationService.fcmToken;
      if (token != null) {
        await _userService.updateFcmToken(userId, token);
      }
    } catch (e) {
      print('FCM 토큰 업데이트 실패: $e');
    }
  }

  // 회원가입
  Future<void> signUp(String email, String password, String nickname) async {
    _isLoading = true;
    Future.microtask(() {
      notifyListeners();
    });

    try {
      final userCredential =
          await _authService.signUpWithEmail(email, password);
      final user = userCredential.user;

      if (user != null) {
        // Firestore에 사용자 데이터 생성
        final userModel = UserModel(
          uid: user.uid,
          email: email,
          nickname: nickname,
          createdAt: DateTime.now(),
          provider: 'email',
        );

        await _userService.createUser(userModel);
        _userModel = userModel;

        // FCM 토큰 업데이트
        await _updateFcmToken(user.uid);
      }
    } finally {
      // ...
    }
  }

  // 로그인
  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    Future.microtask(() {
      notifyListeners();
    });

    try {
      await _authService.signInWithEmail(email, password);

      if (_currentUser != null) {
        // Firestore에서 사용자 데이터 가져오기
        _userModel = await _userService.getUser(_currentUser!.uid);

        // FCM 토큰 업데이트
        await _updateFcmToken(_currentUser!.uid);
      }
    } finally {
      // ...
    }
  }

  // 구글 로그인
  Future<void> signInWithGoogle() async {
    _isLoading = true;
    Future.microtask(() {
      notifyListeners();
    });

    try {
      final userCredential = await _authService.signInWithGoogle();
      final user = userCredential.user;

      if (user != null) {
        // Firestore에서 사용자 데이터 확인
        UserModel? existingUser = await _userService.getUser(user.uid);

        if (existingUser == null) {
          // 신규 사용자인 경우 데이터 생성
          final userModel = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            nickname: user.displayName ?? '사용자',
            createdAt: DateTime.now(),
          );
          await _userService.createUser(userModel);
          _userModel = userModel;
        } else {
          _userModel = existingUser;
        }

        // FCM 토큰 업데이트
        await _updateFcmToken(user.uid);
      }
    } finally {
      // ...
    }
  }

  // 카카오 로그인
  Future<void> signInWithKakao() async {
    _isLoading = true;
    Future.microtask(() {
      notifyListeners();
    });

    try {
      final userCredential = await _authService.signInWithKakao();
      final user = userCredential.user;

      if (user != null) {
        // Firestore에서 사용자 데이터 확인
        UserModel? existingUser = await _userService.getUser(user.uid);

        if (existingUser == null) {
          // 신규 사용자인 경우 데이터 생성
          // 닉네임이 없으면 '사용자' 대신 카카오 ID와 유사한 형태로 저장하여 닉네임 변경 팝업 유도
          // (MorningScreen에서 숫자로만 구성된 닉네임은 변경 팝업을 띄움)
          // user.displayName이 '사용자'일 수도 있으므로, 여기서 강제로 uid 등을 사용할 수도 있음
          // 하지만 AuthService에서 displayName을 user.id로 설정했으므로 그 값이 올 것으로 기대함
          // 만약 null이라면 uid 사용하여 숫자로 구성된 문자열 생성
          String initialNickname = user.displayName ?? user.uid;

          // 만약 "사용자"라면 강제로 uid 사용 (팝업 유도)
          if (initialNickname == '사용자') {
            // 카카오 ID만 추출하기 위해 uid에서 숫자만 남기거나 그냥 uid 사용
            // 여기선 간단히 uid 사용 (숫자가 아닐 수도 있지만, 고유값 보장)
            // AuthService에서 user.id (숫자)를 displayName으로 설정했으므로
            // 정상적이라면 숫자가 들어옴.
            // 만약 실패해서 '사용자'가 들어왔다면 여기서 처리.
            initialNickname = user.uid.replaceAll(RegExp(r'[^0-9]'), '');
            if (initialNickname.isEmpty) initialNickname = user.uid;
          }

          final userModel = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            nickname: initialNickname,
            createdAt: DateTime.now(),
            provider: 'kakao',
          );
          await _userService.createUser(userModel);
          _userModel = userModel;
        } else {
          _userModel = existingUser;
        }

        // FCM 토큰 업데이트
        await _updateFcmToken(user.uid);
      }
    } finally {
      // ...
    }
  }

  // 애플 로그인
  Future<void> signInWithApple() async {
    _isLoading = true;
    Future.microtask(() {
      notifyListeners();
    });

    try {
      final userCredential = await _authService.signInWithApple();
      final user = userCredential.user;

      if (user != null) {
        // Firestore에서 사용자 데이터 확인
        UserModel? existingUser = await _userService.getUser(user.uid);

        if (existingUser == null) {
          // 신규 사용자인 경우 데이터 생성
          final userModel = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            nickname: user.displayName ?? '사용자',
            createdAt: DateTime.now(),
          );
          await _userService.createUser(userModel);
          _userModel = userModel;
        } else {
          _userModel = existingUser;
        }

        // FCM 토큰 업데이트
        await _updateFcmToken(user.uid);
      }
    } finally {
      // ...
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    await _authService.signOut();
    _userModel = null;
    Future.microtask(() {
      notifyListeners();
    });
  }

  // 생체 인증으로 로그인/인증
  Future<bool> authenticateWithBiometric({String? localizedReason}) async {
    return await _authService.authenticateWithBiometric(
      localizedReason: localizedReason ?? '일기를 보호하기 위해 인증이 필요합니다',
    );
  }

  // 생체 인증 가능 여부 확인
  Future<bool> canUseBiometric() async {
    return await _authService.canUseBiometric();
  }

  // 비밀번호 재설정 이메일 발송
  Future<void> sendPasswordResetEmail(String email) async {
    await _authService.sendPasswordResetEmail(email);
  }

  // 비밀번호 직접 변경
  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    final user = _currentUser;
    final email = _userModel?.email;

    if (user != null && email != null) {
      // 0. 재인증 (최근 로그인 확인)
      await _authService.reauthenticate(email, currentPassword);
      // 1. 비밀번호 업데이트
      await user.updatePassword(newPassword);
    }
  }

  // 회원 탈퇴
  Future<void> deleteAccount(String password) async {
    final user = _currentUser;
    final email = _userModel?.email;

    if (user != null && email != null) {
      _isDeletingAccount = true;
      try {
        // 0. 재인증 (최근 로그인 확인)
        await _authService.reauthenticate(email, password);

        final uid = user.uid;
        // 1. Firestore 데이터 삭제
        await _userService.deleteUserData(uid);
        // 2. Auth 유저 삭제
        await user.delete();
        // 3. 로그아웃 상태 처리
        _currentUser = null;
        _userModel = null;
        notifyListeners();
      } finally {
        _isDeletingAccount = false;
      }
    }
  }

  // 닉네임 변경
  Future<void> updateNickname(String newNickname) async {
    final user = _currentUser;
    if (user == null) return;

    try {
      // 1. Firebase Auth 프로필 업데이트
      await user.updateDisplayName(newNickname);

      // 2. Firestore 사용자 정보 업데이트
      await _userService.updateNickname(user.uid, newNickname);

      // 3. 로컬 상태 업데이트
      if (_userModel != null) {
        _userModel = _userModel!.copyWith(nickname: newNickname);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('닉네임 업데이트 실패: $e');
      rethrow;
    }
  }
}
