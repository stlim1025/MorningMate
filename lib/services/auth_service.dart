import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' as kakao;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  AuthService() {
    // Set the language code for FirebaseAuth to Korean to avoid locale-related warnings.
    // This is done once when the AuthService is instantiated.
    FirebaseAuth.instance.setLanguageCode('ko');
  }

  FirebaseAuth get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (e) {
      debugPrint('AuthService: FirebaseAuth 인스턴스 획득 실패 (Firebase 미초기화)');
      rethrow;
    }
  }

  final LocalAuthentication _localAuth = LocalAuthentication();

  // 현재 사용자
  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (e) {
      return null;
    }
  }

  // 인증 상태 스트림
  Stream<User?> get authStateChanges {
    try {
      return _auth.authStateChanges();
    } catch (e) {
      return const Stream.empty();
    }
  }

  // 이메일/비밀번호 회원가입
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (_) {
      rethrow;
    }
  }

  // 이메일/비밀번호 로그인
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (_) {
      rethrow;
    }
  }

  // 구글 로그인
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Google Sign In 시작
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw '구글 로그인이 취소되었습니다.';
      }

      // Google 인증 정보 가져오기
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Firebase 인증 자격 증명 생성
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase에 로그인
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw handleAuthException(e);
    } catch (e) {
      throw '구글 로그인 중 오류가 발생했습니다: $e';
    }
  }

  // 카카오 로그인
  Future<UserCredential> signInWithKakao() async {
    try {
      print('카카오 로그인 시작');

      // 카카오톡 설치 여부 확인
      bool isKakaoTalkInstalled = await kakao.isKakaoTalkInstalled();
      print('카카오톡 설치 여부: $isKakaoTalkInstalled');

      if (isKakaoTalkInstalled) {
        // 카카오톡으로 로그인
        print('카카오톡으로 로그인 시도');
        await kakao.UserApi.instance.loginWithKakaoTalk();
      } else {
        // 카카오 계정으로 로그인
        print('카카오 계정으로 로그인 시도');
        await kakao.UserApi.instance.loginWithKakaoAccount();
      }

      print('카카오 로그인 성공, 사용자 정보 가져오는 중');

      // 카카오 사용자 정보 가져오기
      final kakao.User user = await kakao.UserApi.instance.me();
      print('카카오 사용자 ID: ${user.id}');
      print('카카오 사용자 닉네임: ${user.kakaoAccount?.profile?.nickname}');
      print('카카오 사용자 이메일: ${user.kakaoAccount?.email}');

      // 카카오 ID를 기반으로 고유한 이메일 생성
      final String email =
          user.kakaoAccount?.email ?? 'kakao_${user.id}@morningmate.app';
      final String password =
          'kakao_${user.id}_morningmate'; // 카카오 ID 기반 고유 비밀번호

      // 요청사항: 닉네임을 카카오 ID로 설정 (사용자가 첫 로그인 시 변경하도록 함)
      final String displayName = '${user.id}';

      print('생성된 이메일: $email');
      print('설정할 닉네임: $displayName');

      UserCredential userCredential;

      try {
        // 먼저 로그인 시도
        print('기존 계정으로 로그인 시도');
        userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        print('기존 계정 로그인 성공');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
          // 계정이 없으면 새로 생성
          print('계정이 없음, 새 계정 생성 시도');
          userCredential = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          print('새 계정 생성 성공');

          // 사용자 정보 업데이트
          await userCredential.user?.updateDisplayName(displayName);
          print('사용자 닉네임 업데이트 완료: $displayName');
        } else {
          // 다른 오류는 그대로 throw
          rethrow;
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Firebase 인증 오류: ${e.code} - ${e.message}');
      throw handleAuthException(e);
    } on kakao.KakaoException catch (e) {
      print('카카오 로그인 오류: ${e.toString()}');
      throw '카카오 로그인 중 오류가 발생했습니다: ${e.message}';
    } catch (e) {
      print('카카오 로그인 알 수 없는 오류: $e');
      throw '카카오 로그인 중 오류가 발생했습니다: $e';
    }
  }

  // 애플 로그인
  Future<UserCredential> signInWithApple() async {
    try {
      // 애플 로그인 요청
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Firebase 인증 자격 증명 생성
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Firebase에 로그인
      return await _auth.signInWithCredential(oauthCredential);
    } on FirebaseAuthException catch (e) {
      throw handleAuthException(e);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw '애플 로그인이 취소되었습니다.';
      }
      throw '애플 로그인 중 오류가 발생했습니다: ${e.message}';
    } catch (e) {
      throw '애플 로그인 중 오류가 발생했습니다: $e';
    }
  }

  // 익명 로그인
  Future<UserCredential> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException [${e.code}]: ${e.message}');
      throw handleAuthException(e);
    } catch (e) {
      debugPrint('General Exception in signInAnonymously: $e');
      rethrow;
    }
  }

  // 구글 자격 증명 가져오기
  Future<AuthCredential> getGoogleCredential() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) throw '구글 로그인이 취소되었습니다.';
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    return GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
  }

  // 카카오 자격 증명 가져오기 (MorningMate에서는 이메일/비밀번호 방식을 사용하므로 EmailAuthCredential 반환)
  Future<AuthCredential> getKakaoCredential() async {
    // 카카오톡 설치 여부 확인
    bool isKakaoTalkInstalled = await kakao.isKakaoTalkInstalled();
    if (isKakaoTalkInstalled) {
      await kakao.UserApi.instance.loginWithKakaoTalk();
    } else {
      await kakao.UserApi.instance.loginWithKakaoAccount();
    }
    final kakao.User user = await kakao.UserApi.instance.me();
    final String email =
        user.kakaoAccount?.email ?? 'kakao_${user.id}@morningmate.app';
    final String password = 'kakao_${user.id}_morningmate';
    return EmailAuthProvider.credential(email: email, password: password);
  }

  // 애플 자격 증명 가져오기
  Future<AuthCredential> getAppleCredential() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    return OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );
  }

  // 자격 증명으로 계정 연결 (익명 -> 정식)
  Future<UserCredential> linkWithCredential(AuthCredential credential) async {
    final user = _auth.currentUser;
    if (user == null) throw '연결할 사용자가 없습니다.';
    try {
      return await user.linkWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      // 이미 해당 소셜 계정으로 가입된 유저가 있는 경우 link가 실패할 수 있음
      if (e.code == 'credential-already-in-use') {
        throw '이미 다른 계정에 연결된 소셜 계정입니다.';
      }
      throw handleAuthException(e);
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      // 구글 로그아웃
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
    } catch (e) {
      print('구글 로그아웃 중 오류 (무시): $e');
    }

    try {
      // 카카오 로그아웃
      if (await kakao.AuthApi.instance.hasToken()) {
        await kakao.UserApi.instance.logout();
      }
    } catch (e) {
      print('카카오 로그아웃 중 오류 (무시): $e');
    }

    await _auth.signOut();
  }

  // 소셜 계정 연동 해제 (회원탈퇴 시)
  Future<void> disconnectSocial() async {
    try {
      // 구글 연동 해제
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.disconnect();
      }
    } catch (e) {
      print('구글 연동 해제 중 오류: $e');
    }

    try {
      // 카카오 연동 해제 (Unlink)
      if (await kakao.AuthApi.instance.hasToken()) {
        await kakao.UserApi.instance.unlink();
      }
    } catch (e) {
      print('카카오 연동 해제 중 오류: $e');
    }
  }

  // 재인증 (회원탈퇴 등 민감한 작업 전 필요)
  Future<void> reauthenticate(String email, String password) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      }
    } on FirebaseAuthException catch (_) {
      rethrow;
    }
  }

  // 구글 재인증
  Future<void> reauthenticateWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw '구글 인증이 취소되었습니다.';
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.currentUser?.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw handleAuthException(e);
    } catch (e) {
      throw '구글 인증 중 오류가 발생했습니다: $e';
    }
  }

  // 애플 재인증
  Future<void> reauthenticateWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      await _auth.currentUser?.reauthenticateWithCredential(oauthCredential);
    } on FirebaseAuthException catch (e) {
      throw handleAuthException(e);
    } catch (e) {
      throw '애플 인증 중 오류가 발생했습니다: $e';
    }
  }

  // 비밀번호 재설정 이메일 발송
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw handleAuthException(e);
    }
  }

  // 생체 인증 가능 여부 확인
  Future<bool> canUseBiometric() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  // 사용 가능한 생체 인증 방법 확인
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  // 생체 인증 실행
  Future<bool> authenticateWithBiometric({
    String localizedReason = '일기를 보호하기 위해 인증이 필요합니다',
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } on PlatformException catch (e) {
      print('생체 인증 오류: $e');
      return false;
    }
  }

  // Firebase Auth 예외 처리
  String handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return '비밀번호가 너무 약합니다. 6자 이상의 비밀번호를 사용해주세요.';
      case 'email-already-in-use':
        return '이미 사용 중인 이메일입니다.';
      case 'user-not-found':
      case 'invalid-credential':
        return '이메일 또는 비밀번호가 틀렸습니다.';
      case 'wrong-password':
        return '비밀번호가 틀렸습니다.';
      case 'invalid-email':
        return '유효하지 않은 이메일 형식입니다.';
      case 'user-disabled':
        return '관리자에 의해 비활성화된 계정입니다.';
      case 'too-many-requests':
        return '여러 번 로그인 시도에 실패하여 접근이 차단되었습니다. 잠시 후 다시 시도해주세요.';
      case 'credential-already-in-use':
      case 'account-exists-with-different-credential':
        return '이미 다른 계정에서 사용 중인 소셜 계정입니다. 다른 계정을 사용하거나 로그아웃 후 해당 계정으로 로그인해주세요.';
      case 'provider-already-linked':
        return '이미 현재 계정에 연결된 소셜 계정입니다.';
      case 'network-request-failed':
        return '네트워크 연결이 원활하지 않습니다. 인터넷 연결을 확인해주세요.';
      default:
        return '로그인 중 오류가 발생했습니다. 다시 시도해주세요. (${e.code})';
    }
  }
}
