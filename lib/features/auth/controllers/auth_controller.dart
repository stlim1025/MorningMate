import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _isSigningOut = false;
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
    // 로그아웃 중에는 signOut()에서 직접 정리하므로 여기서는 무시
    if (_isSigningOut) return;

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
          if (_userModel?.morningDiaryNoti == true) {
            _notificationService.scheduleMorningReminder(
                _userModel?.morningDiaryNotiTime ?? '08:00');
          } else {
            _notificationService.cancelMorningReminder();
          }
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
          if (_userModel?.morningDiaryNoti == true) {
            _notificationService.scheduleMorningReminder(
                _userModel?.morningDiaryNotiTime ?? '08:00');
          } else {
            _notificationService.cancelMorningReminder();
          }
          notifyListeners();
        }
      }, onError: (e) {
        // 로그아웃 타이밍에 발생하는 permission-denied는 무시
        debugPrint('사용자 스트림 에러 (무시됨): $e');
      });

      // UI 블로킹 방지를 위해 await 제거
      _updateFcmToken(user.uid);
      try {
        await _userService.updateLastLogin(user.uid);
        unawaited(_userService.logLogin(user.uid)); // 통계용 로그인 히스토리 기록 (UI 블로킹 방지)
        
        // 플랫폼 및 국가 정보가 없으면 업데이트
        if (_userModel != null && (_userModel!.platform == null || _userModel!.countryCode == null)) {
          final platform = Platform.isIOS ? 'ios' : (Platform.isAndroid ? 'android' : 'other');
          final countryCode = WidgetsBinding.instance.platformDispatcher.locale.countryCode;
          
          final Map<String, dynamic> updates = {};
          if (_userModel!.platform == null) updates['platform'] = platform;
          if (_userModel!.countryCode == null) updates['countryCode'] = countryCode;
          
          if (updates.isNotEmpty) {
            await _userService.updateUser(user.uid, updates);
            _userModel = _userModel!.copyWith(
              platform: updates['platform'],
              countryCode: updates['countryCode'],
            );
          }
        }
      } catch (e) {
        debugPrint('로그인 정보 업데이트 실패: $e');
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
    if (_userModel?.morningDiaryNoti == true) {
      _notificationService
          .scheduleMorningReminder(_userModel?.morningDiaryNotiTime ?? '08:00');
    } else {
      _notificationService.cancelMorningReminder();
    }
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
  Future<void> signUp(String email, String password, [String? nickname]) async {
    _isLoading = true;
    Future.microtask(() {
      notifyListeners();
    });

    try {
      final userCredential =
          await _authService.signUpWithEmail(email, password);
      final user = userCredential.user;

      if (user != null) {
        final finalNickname = (nickname == null || nickname.isEmpty)
            ? 'User_${user.uid.substring(0, 5)}'
            : nickname;

        final userModel = UserModel(
          uid: user.uid,
          email: email,
          nickname: finalNickname,
          createdAt: DateTime.now(),
          lastLoginDate: DateTime.now(), // ✨ 신규 가입 시 접속 기록 즉시 설정
          provider: 'email',
          isSetupComplete: false,
          platform: Platform.isIOS ? 'ios' : (Platform.isAndroid ? 'android' : 'other'),
          countryCode: WidgetsBinding.instance.platformDispatcher.locale.countryCode,
        );

        await _userService.createUser(userModel);
        _userModel = userModel;

        // FCM 토큰 업데이트 - 비동기로 처리하여 UI 블로킹 방지
        _updateFcmToken(user.uid);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
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
        _updateFcmToken(_currentUser!.uid);
      }
    } on FirebaseAuthException catch (e) {
      throw _authService.handleAuthException(e);
    } finally {
      _isLoading = false;
      notifyListeners();
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
            lastLoginDate: DateTime.now(), // ✨ 신규 가입 시 접속 기록 즉시 설정
            provider: 'google',
            isSetupComplete: false,
            platform: Platform.isIOS ? 'ios' : (Platform.isAndroid ? 'android' : 'other'),
            countryCode: WidgetsBinding.instance.platformDispatcher.locale.countryCode,
          );
          await _userService.createUser(userModel);
          _userModel = userModel;
        } else {
          _userModel = existingUser;
          // 기존 유저인데 provider가 없는 경우 업데이트
          if (existingUser.provider == null) {
            await _userService.updateUser(user.uid, {'provider': 'google'});
            _userModel = existingUser.copyWith(provider: 'google');
          }
        }

        // FCM 토큰 업데이트 - 비동기로 처리하여 UI 블로킹 방지
        _updateFcmToken(user.uid);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
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
            lastLoginDate: DateTime.now(), // ✨ 신규 가입 시 접속 기록 즉시 설정
            provider: 'kakao',
            isSetupComplete: false,
            platform: Platform.isIOS ? 'ios' : (Platform.isAndroid ? 'android' : 'other'),
            countryCode: WidgetsBinding.instance.platformDispatcher.locale.countryCode,
          );
          await _userService.createUser(userModel);
          _userModel = userModel;
        } else {
          _userModel = existingUser;
          // 기존 유저인데 provider가 없는 경우 업데이트
          if (existingUser.provider == null) {
            await _userService.updateUser(user.uid, {'provider': 'kakao'});
            _userModel = existingUser.copyWith(provider: 'kakao');
          }
        }

        // FCM 토큰 업데이트 - 비동기로 처리하여 UI 블로킹 방지
        _updateFcmToken(user.uid);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
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
            lastLoginDate: DateTime.now(), // ✨ 신규 가입 시 접속 기록 즉시 설정
            provider: 'apple',
            isSetupComplete: false,
            platform: Platform.isIOS ? 'ios' : (Platform.isAndroid ? 'android' : 'other'),
            countryCode: WidgetsBinding.instance.platformDispatcher.locale.countryCode,
          );
          await _userService.createUser(userModel);
          _userModel = userModel;
        } else {
          _userModel = existingUser;
          // 기존 유저인데 provider가 없는 경우 업데이트
          if (existingUser.provider == null) {
            await _userService.updateUser(user.uid, {'provider': 'apple'});
            _userModel = existingUser.copyWith(provider: 'apple');
          }
        }

        // FCM 토큰 업데이트 - 비동기로 처리하여 UI 블로킹 방지
        _updateFcmToken(user.uid);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 익명 로그인 (임시 로그인)
  Future<void> signInAnonymously() async {
    final prefs = await SharedPreferences.getInstance();
    String? guestEmail = prefs.getString('guest_email');
    String? guestPassword = prefs.getString('guest_password');

    _isLoading = true;
    notifyListeners();

    try {
      if (guestEmail != null && guestPassword != null) {
        // 1. 기존에 발급된 임시 계정이 있는 경우 -> 해당 계정으로 로그인
        debugPrint('GuestLogin: Found existing guest credentials. Logging in...');
        try {
          await _authService.signInWithEmail(guestEmail, guestPassword);
          // _authController의 _handleAuthStateChange에서 userModel을 자동으로 로드함
        } on FirebaseAuthException catch (e) {
          if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
            // Firebase에서 계정이 삭제된 경우 (예: 회원탈퇴) -> 로컬 정보 초기화 후 새 계정 생성
            debugPrint('GuestLogin: Existing guest deleted from Firebase. Resetting local info...');
            await prefs.remove('guest_email');
            await prefs.remove('guest_password');
            await prefs.remove('guest_uid');
            await prefs.remove('hasUsedGuest');
            
            // 다시 null로 설정하여 아래의 '새 계정 생성' 로직을 타게 함
            guestEmail = null;
          } else {
            rethrow;
          }
        }
      }

      if (guestEmail == null) {
        // 2. 처음 임시 로그인을 시도하는 경우 (또는 기존 정보가 초기화된 경우) -> 새 계정 생성
        debugPrint('GuestLogin: No existing guest. Creating new temporary account...');
        
        // 고유 아이디 생성을 위해 시간과 무작위 값 조합
        final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        final String randomId = timestamp.substring(timestamp.length - 6);
        final String newGuestEmail = 'guest_$timestamp@morni.mate';
        final String newGuestPassword = 'pw_$randomId!morni';

        final userCredential = await _authService.signUpWithEmail(newGuestEmail, newGuestPassword);
        final user = userCredential.user;

        if (user != null) {
          final userModel = UserModel(
            uid: user.uid,
            email: newGuestEmail,
            nickname: 'Guest_$randomId',
            createdAt: DateTime.now(),
            lastLoginDate: DateTime.now(),
            provider: 'guest',
            isSetupComplete: true, // 임시 로그인은 설정 화면 스킵
            isAnonymous: true,
            platform: Platform.isIOS ? 'ios' : (Platform.isAndroid ? 'android' : 'other'),
            countryCode: WidgetsBinding.instance.platformDispatcher.locale.countryCode,
          );

          await _userService.createUser(userModel);

          // 기기에 임시 계정 정보 저장 (재접속용)
          await prefs.setBool('has_used_guest_account', true);
          await prefs.setString('guest_email', newGuestEmail);
          await prefs.setString('guest_password', newGuestPassword);
          await prefs.setString('guest_uid', user.uid);

          _userModel = userModel;
          _updateFcmToken(user.uid);
          debugPrint('GuestLogin: New temporary account created and saved.');
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('GuestLogin Error (FA): ${e.code}');
      debugPrint('GuestLogin Error Message: ${_authService.handleAuthException(e)}');
      rethrow;
    } catch (e) {
      debugPrint('GuestLogin Error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 소셜 계정 연결 (익명 데이터 이전)
  Future<void> linkWithSocialProvider(String provider) async {
    _isLoading = true;
    notifyListeners();

    try {
      AuthCredential credential;
      switch (provider) {
        case 'google':
          credential = await _authService.getGoogleCredential();
          break;
        case 'kakao':
          credential = await _authService.getKakaoCredential();
          break;
        case 'apple':
          credential = await _authService.getAppleCredential();
          break;
        default:
          throw '지원하지 않는 로그인 방식입니다.';
      }

      final userCredential = await _authService.linkWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // 소셜 계정의 이메일 찾기
        String? socialEmail;
        if (provider == 'kakao' && credential is EmailAuthCredential) {
          socialEmail = credential.email;
        } else {
          // 구글/애플의 경우 providerData에서 해당 제공자의 이메일을 찾음
          final targetProviderId = provider == 'google' ? 'google.com' : 'apple.com';
          for (var info in user.providerData) {
            if (info.providerId == targetProviderId) {
              socialEmail = info.email;
              break;
            }
          }
        }

        final finalEmail = socialEmail ?? user.email;

        // Firestore 데이터 업데이트 (익명 해제 및 제공자 설정)
        final updates = {
          'isAnonymous': false,
          'provider': provider,
          'isSetupComplete': false, // 소셜 연동 후 닉네임 설정 필요
          if (finalEmail != null && finalEmail.isNotEmpty) 'email': finalEmail,
        };

        await _userService.updateUser(user.uid, updates);

        // 기기에서 임시 계정 정보 제거 (연동 성공 시 더 이상 임시 계정이 아님)
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('guest_email');
        await prefs.remove('guest_password');
        await prefs.remove('guest_uid');
        await prefs.remove('hasUsedGuest'); // 초기화

        // Firestore 정보 업데이트 (임시 -> 정식 유저)
        if (_userModel != null) {
          _userModel = _userModel!.copyWith(
            isAnonymous: false,
            provider: provider,
            isSetupComplete: false,
            email: finalEmail,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        throw '이미 다른 계정에서 사용 중인 소셜 계정입니다. 해당 계정으로 로그인하려면 로그아웃 후 다시 시도해주세요.';
      } else if (e.code == 'provider-already-linked') {
        // 이미 연동된 경우라면 성공으로 간주하거나 적절한 메시지
        return;
      }
      rethrow;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    _isSigningOut = true;
    final uid = _currentUser?.uid;

    // 1. Firestore에서 FCM 토큰 제거 (아직 인증된 상태에서 실행)
    if (uid != null) {
      try {
        await _userService.removeFcmToken(uid);
      } catch (e) {
        debugPrint('FCM 토큰 제거 중 오류 (무시): $e');
      }
    }

    // 2. 알림 서비스 정리 (FCM 토큰 삭제, 구독 해제, 오버레이 알림 정리)
    await _notificationService.cleanup();

    // 3. Firebase Auth 로그아웃
    //    → Firestore 스트림은 아직 살아있어 onError 핸들러가 permission-denied를 잡아줌
    //    → _handleAuthStateChange는 _isSigningOut 플래그로 무시됨
    await _authService.signOut();

    // 4. Auth 로그아웃 후 Firestore 스트림 해제
    //    (네이티브 에러 이벤트가 onError에서 이미 처리된 후 안전하게 취소)
    _userStreamSubscription?.cancel();
    _userStreamSubscription = null;

    // 5. 로컬 상태 초기화
    _userModel = null;
    _currentUser = null;
    _isBiometricVerified = false;
    _isAuthCheckDone = false;
    _isSigningOut = false;

    notifyListeners();
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
      try {
        // 0. 재인증 (최근 로그인 확인)
        await _authService.reauthenticate(email, currentPassword);
        // 1. 비밀번호 업데이트
        await user.updatePassword(newPassword);
      } on FirebaseAuthException catch (e) {
        throw _authService.handleAuthException(e);
      }
    }
  }

  // 회원 탈퇴
  Future<void> deleteAccount(String? password) async {
    final user = _currentUser;
    final email = _userModel?.email;
    final provider = _userModel?.provider;

    if (user != null && email != null) {
      _isDeletingAccount = true;
      try {
        // 1. 재인증 시도 (로그인 만료 대비)
        if (password != null && password.isNotEmpty) {
          await _authService.reauthenticate(email, password);
        } else if (provider == 'email') {
          throw '비밀번호를 입력해야 합니다.';
        } else if (provider == 'google') {
          await _authService.reauthenticateWithGoogle();
        } else if (provider == 'apple') {
          await _authService.reauthenticateWithApple();
        } else if (provider == 'kakao' && email.contains('kakao_')) {
          // 카카오 계정은 고유 규칙으로 비밀번호 재구성이 가능할 수도 있음
          // 데이터 구조상 'kakao_{id}@morningmate.app' 형태인 경우
          try {
            final kakaoId = email.split('@')[0].split('_')[1];
            final kakaoPassword = 'kakao_${kakaoId}_morningmate';
            await _authService.reauthenticate(email, kakaoPassword);
          } catch (e) {
            debugPrint('카카오 자동 재인증 실패 (무시하고 진행): $e');
          }
        }

        final uid = user.uid;

        // 2. Auth 유저 삭제 전 Firestore 데이터 전체 삭제 (인증된 상태에서만 삭제 가능할 수 있음)
        await _userService.deleteUserData(uid);

        // 3. 소셜 계정 연동 해제 (Google disconnect, Kakao unlink 등)
        await _authService.disconnectSocial();

        // 4. Auth 유저 삭제 (가장 민감한 작업)
        try {
          await user.delete();
        } on FirebaseAuthException catch (e) {
          if (e.code == 'requires-recent-login') {
            throw '보안을 위해 다시 로그인이 필요합니다. 로그아웃 후 다시 로그인하여 시도해주세요.';
          }
          rethrow;
        }

        // 5. 로그아웃 상태 처리
        _currentUser = null;
        _userModel = null;
        notifyListeners();
      } on FirebaseAuthException catch (e) {
        throw _authService.handleAuthException(e);
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

  // 튜토리얼 완료 처리
  Future<void> completeTutorial() async {
    final user = _currentUser;
    if (user == null) return;

    try {
      await _userService.updateUser(user.uid, {'hasSeenTutorial': true});
      if (_userModel != null) {
        _userModel = _userModel!.copyWith(hasSeenTutorial: true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('튜토리얼 완료 처리 중 오류: $e');
    }
  }

  // 메인 튜토리얼 단계 업데이트
  Future<void> setMainTutorialStep(String step) async {
    final user = _currentUser;
    if (user == null) return;

    try {
      await _userService.updateUser(user.uid, {'mainTutorialStep': step});
      if (_userModel != null) {
        _userModel = _userModel!.copyWith(mainTutorialStep: step);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('메인 튜토리얼 단계 업데이트 중 오류: $e');
    }
  }

  // 글쓰기 가이드 완료 처리
  Future<void> completeWritingTutorial() async {
    final user = _currentUser;
    if (user == null) return;

    try {
      await _userService.updateUser(user.uid, {'hasSeenWritingTutorial': true});
      if (_userModel != null) {
        _userModel = _userModel!.copyWith(hasSeenWritingTutorial: true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('글쓰기 튜토리얼 완료 처리 중 오류: $e');
    }
  }
  // 소셜 튜토리얼 완료 처리
  Future<void> completeSocialTutorial() async {
    final user = _currentUser;
    if (user == null) return;
    try {
      await _userService.updateUser(user.uid, {'hasSeenSocialTutorial': true});
      if (_userModel != null) {
        _userModel = _userModel!.copyWith(hasSeenSocialTutorial: true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('소셜 튜토리얼 완료 처리 중 오류: $e');
    }
  }

  // 둥지 튜토리얼 완료 처리
  Future<void> completeNestTutorial() async {
    final user = _currentUser;
    if (user == null) return;
    try {
      await _userService.updateUser(user.uid, {'hasSeenNestTutorial': true});
      if (_userModel != null) {
        _userModel = _userModel!.copyWith(hasSeenNestTutorial: true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('둥지 튜토리얼 완료 처리 중 오류: $e');
    }
  }

  // 아카이브(기록) 튜토리얼 완료 처리
  Future<void> completeArchiveTutorial() async {
    final user = _currentUser;
    if (user == null) return;
    try {
      await _userService.updateUser(user.uid, {'hasSeenArchiveTutorial': true});
      if (_userModel != null) {
        _userModel = _userModel!.copyWith(hasSeenArchiveTutorial: true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('기록 튜토리얼 완료 처리 중 오류: $e');
    }
  }

  // 상점 튜토리얼 완료 처리
  Future<void> completeShopTutorial() async {
    final user = _currentUser;
    if (user == null) return;
    try {
      await _userService.updateUser(user.uid, {
        'hasSeenShopTutorial': true,
        'hasSeenTutorial': true,
        'mainTutorialStep': 'completed',
      });
      if (_userModel != null) {
        _userModel = _userModel!.copyWith(
          hasSeenShopTutorial: true,
          hasSeenTutorial: true,
          mainTutorialStep: 'completed',
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('상점 튜토리얼 완료 처리 중 오류: $e');
    }
  }

  /// 모든 튜토리얼을 스킵하고 완료된 것으로 처리합니다.
  Future<void> skipAllTutorials() async {
    final user = _currentUser;
    if (user == null) return;
    try {
      await _userService.updateUser(user.uid, {
        'hasSeenTutorial': true,
        'hasSeenWritingTutorial': true,
        'hasSeenSocialTutorial': true,
        'hasSeenNestTutorial': true,
        'hasSeenArchiveTutorial': true,
        'hasSeenShopTutorial': true,
        'mainTutorialStep': 'completed',
      });
      if (_userModel != null) {
        _userModel = _userModel!.copyWith(
          hasSeenTutorial: true,
          hasSeenWritingTutorial: true,
          hasSeenSocialTutorial: true,
          hasSeenNestTutorial: true,
          hasSeenArchiveTutorial: true,
          hasSeenShopTutorial: true,
          mainTutorialStep: 'completed',
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('튜토리얼 전체 스킵 처리 중 오류: $e');
    }
  }
}
