import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' as kakao;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();

  // 현재 사용자
  User? get currentUser => _auth.currentUser;

  // 인증 상태 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 이메일/비밀번호 회원가입
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // 이메일/비밀번호 로그인
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
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
      throw _handleAuthException(e);
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
      throw _handleAuthException(e);
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
      throw _handleAuthException(e);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw '애플 로그인이 취소되었습니다.';
      }
      throw '애플 로그인 중 오류가 발생했습니다: ${e.message}';
    } catch (e) {
      throw '애플 로그인 중 오류가 발생했습니다: $e';
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    await _auth.signOut();
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
      // 한글 메시지로 변환하지 않고 원본 예외를 그대로 던져서
      // 호출하는 쪽에서 e.code를 직접 확인할 수 있게 합니다.
      rethrow;
    }
  }

  // 비밀번호 재설정 이메일 발송
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
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
  String _handleAuthException(FirebaseAuthException e) {
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
      case 'network-request-failed':
        return '네트워크 연결이 원활하지 않습니다. 인터넷 연결을 확인해주세요.';
      default:
        return '로그인 중 오류가 발생했습니다. 다시 시도해주세요.';
    }
  }
}
