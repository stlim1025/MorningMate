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
    _authService.authStateChanges.listen(_handleAuthStateChange);
  }

  User? _currentUser;
  UserModel? _userModel;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  Future<void> _handleAuthStateChange(User? user) async {
    _currentUser = user;
    if (user != null) {
      _notificationService.setOnTokenRefreshHandler(
        (token) => _userService.updateFcmToken(user.uid, token),
      );
      _userModel = await _userService.getUser(user.uid);
      await _updateFcmToken(user.uid);
    } else {
      _notificationService.setOnTokenRefreshHandler(null);
      _userModel = null;
    }
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

  // 로그아웃
  Future<void> signOut() async {
    await _authService.signOut();
    _userModel = null;
    Future.microtask(() {
      notifyListeners();
    });
  }

  // 생체 인증으로 로그인
  Future<bool> authenticateWithBiometric() async {
    return await _authService.authenticateWithBiometric();
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
  Future<void> changePassword(String newPassword) async {
    final user = _currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
    }
  }

  // 회원 탈퇴
  Future<void> deleteAccount() async {
    final user = _currentUser;
    if (user != null) {
      final uid = user.uid;
      // 1. Firestore 데이터 삭제
      await _userService.deleteUserData(uid);
      // 2. Auth 유저 삭제
      await user.delete();
      // 3. 로그아웃 상태 처리
      _currentUser = null;
      _userModel = null;
      notifyListeners();
    }
  }
}
