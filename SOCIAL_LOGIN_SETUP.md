# 소셜 로그인 설정 가이드

이 문서는 Morni 앱에서 구글, 카카오, 애플 소셜 로그인을 설정하는 방법을 안내합니다.

## 📋 목차
1. [구글 로그인 설정](#1-구글-로그인-설정)
2. [카카오 로그인 설정](#2-카카오-로그인-설정)
3. [애플 로그인 설정](#3-애플-로그인-설정)
4. [Firebase 설정](#4-firebase-설정)

---

## 1. 구글 로그인 설정

### 1.1 Firebase Console 설정
1. [Firebase Console](https://console.firebase.google.com/)에 접속
2. 프로젝트 선택
3. **Authentication** > **Sign-in method** 이동
4. **Google** 제공업체 활성화
5. 프로젝트 지원 이메일 설정 후 저장

### 1.2 Android 설정
1. `android/app/build.gradle` 파일 확인
   - `applicationId`가 Firebase에 등록된 패키지명과 일치하는지 확인

2. SHA-1 인증서 지문 등록
   ```bash
   # 디버그 키 SHA-1 가져오기
   cd android
   ./gradlew signingReport
   ```
   
3. Firebase Console에서 SHA-1 등록
   - **프로젝트 설정** > **Android 앱** > **SHA 인증서 지문 추가**

### 1.3 iOS 설정
1. `ios/Runner/Info.plist`에 URL Scheme 추가 (Firebase가 자동으로 처리)
2. Firebase Console에서 `GoogleService-Info.plist` 다운로드
3. Xcode에서 `ios/Runner` 폴더에 파일 추가

---

## 2. 카카오 로그인 설정

### 2.1 카카오 개발자 콘솔 설정
1. [카카오 개발자 콘솔](https://developers.kakao.com/) 접속
2. **내 애플리케이션** > **애플리케이션 추가하기**
3. 앱 이름, 사업자명 입력 후 저장

### 2.2 네이티브 앱 키 발급
1. 생성한 앱 선택
2. **앱 키** 탭에서 **네이티브 앱 키** 복사
3. `lib/main.dart` 파일에서 다음 부분 수정:
   ```dart
   KakaoSdk.init(
     nativeAppKey: 'YOUR_KAKAO_NATIVE_APP_KEY', // 여기에 복사한 키 입력
   );
   ```

### 2.3 Android 설정
1. `android/app/src/main/AndroidManifest.xml` 수정:
   ```xml
   <manifest>
       <application>
           <!-- 기존 코드 -->
           
           <!-- 카카오 로그인 -->
           <activity
               android:name="com.kakao.sdk.auth.AuthCodeHandlerActivity"
               android:exported="true">
               <intent-filter>
                   <action android:name="android.intent.action.VIEW" />
                   <category android:name="android.intent.category.DEFAULT" />
                   <category android:name="android.intent.category.BROWSABLE" />
                   <data
                       android:host="oauth"
                       android:scheme="kakao{YOUR_NATIVE_APP_KEY}" />
               </intent-filter>
           </activity>
       </application>
   </manifest>
   ```

2. 키 해시 등록
   ```bash
   # 디버그 키 해시 생성
   keytool -exportcert -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android -keypass android | openssl sha1 -binary | openssl base64
   ```
   
3. 카카오 개발자 콘솔에서 키 해시 등록
   - **플랫폼** > **Android** > **키 해시** 등록

### 2.4 iOS 설정
1. `ios/Runner/Info.plist` 수정:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleTypeRole</key>
           <string>Editor</string>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>kakao{YOUR_NATIVE_APP_KEY}</string>
           </array>
       </dict>
   </array>
   
   <key>LSApplicationQueriesSchemes</key>
   <array>
       <string>kakaokompassauth</string>
       <string>kakaolink</string>
   </array>
   
   <key>KAKAO_APP_KEY</key>
   <string>{YOUR_NATIVE_APP_KEY}</string>
   ```

2. 카카오 개발자 콘솔에서 iOS 번들 ID 등록
   - **플랫폼** > **iOS** > **번들 ID** 등록

---

## 3. 애플 로그인 설정

### 3.1 Apple Developer 설정
1. [Apple Developer](https://developer.apple.com/) 접속
2. **Certificates, Identifiers & Profiles** 이동
3. **Identifiers** > 앱 선택
4. **Sign in with Apple** 체크박스 활성화

### 3.2 iOS 설정
1. Xcode에서 프로젝트 열기
2. **Signing & Capabilities** 탭
3. **+ Capability** 클릭
4. **Sign in with Apple** 추가

### 3.3 Android 설정 (선택사항)
Android에서 애플 로그인을 사용하려면 추가 설정이 필요합니다:
1. [Apple Developer](https://developer.apple.com/)에서 Service ID 생성
2. Return URLs 설정
3. `android/app/src/main/AndroidManifest.xml`에 설정 추가

---

## 4. Firebase 설정

### 4.1 Firebase Authentication 활성화
1. Firebase Console > **Authentication** > **Sign-in method**
2. 다음 제공업체 활성화:
   - ✅ Google
   - ✅ Apple (iOS만 해당)

### 4.2 카카오 로그인을 위한 Custom Authentication
카카오 로그인은 Firebase Custom Token을 사용합니다.

**중요**: 현재 구현은 개발/테스트용입니다. 프로덕션 환경에서는 다음 방법을 권장합니다:

1. **백엔드 서버 구축** (Firebase Cloud Functions 또는 별도 서버)
2. 카카오 토큰을 받아 Firebase Custom Token 생성
3. 클라이언트에서 Custom Token으로 Firebase 로그인

예시 (Firebase Cloud Functions):
```javascript
const admin = require('firebase-admin');
const functions = require('firebase-functions');

exports.createCustomToken = functions.https.onCall(async (data, context) => {
  const kakaoUid = `kakao_${data.kakaoId}`;
  const customToken = await admin.auth().createCustomToken(kakaoUid);
  return { token: customToken };
});
```

---

## 🔧 테스트 방법

### 구글 로그인 테스트
1. 앱 실행
2. 로그인 화면에서 "Google로 계속하기" 버튼 클릭
3. 구글 계정 선택
4. 로그인 성공 확인

### 카카오 로그인 테스트
1. 카카오톡 앱 설치 (선택사항)
2. 앱 실행
3. 로그인 화면에서 "카카오로 계속하기" 버튼 클릭
4. 카카오 계정으로 로그인
5. 로그인 성공 확인

### 애플 로그인 테스트
1. iOS 기기에서 앱 실행
2. 로그인 화면에서 "Apple로 계속하기" 버튼 클릭
3. Face ID/Touch ID 인증
4. 로그인 성공 확인

---

## ⚠️ 주의사항

1. **카카오 네이티브 앱 키**: `lib/main.dart`에서 반드시 실제 키로 교체해야 합니다.
2. **프로덕션 배포**: 카카오 로그인은 백엔드 서버를 통한 Custom Token 방식으로 변경 권장
3. **SHA-1 인증서**: 릴리즈 빌드 시 릴리즈 키스토어의 SHA-1도 등록해야 합니다.
4. **애플 로그인**: iOS에서만 완전히 지원되며, Android는 추가 설정 필요

---

## 📚 참고 문서

- [Firebase Authentication](https://firebase.google.com/docs/auth)
- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
- [Kakao Flutter SDK](https://developers.kakao.com/docs/latest/ko/flutter/getting-started)
- [Sign in with Apple](https://pub.dev/packages/sign_in_with_apple)
