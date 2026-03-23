import 'package:flutter/material.dart';
import '../../../core/theme/app_color_scheme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final langCode = Localizations.localeOf(context).languageCode;
    final isKorean = langCode == 'ko';
    final isJapanese = langCode == 'ja';
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.iconPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isKorean ? '개인정보 처리방침' : (isJapanese ? 'プライバシーポリシー' : 'Privacy Policy'),
          style: TextStyle(
            color: colorScheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isKorean) ...[
              Text(
                "LemoNary(이하 '서비스 제공자')는 Morni 이용자의 개인정보를 중요하게 생각하며, 「개인정보 보호법」 및 관련 법령을 준수합니다.",
                style: TextStyle(
                  color: colorScheme.textSecondary,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              _buildSection(
                colorScheme,
                '1. 개인정보의 처리 목적',
                '서비스 제공자는 다음의 목적을 위해 개인정보를 처리합니다.\n- 회원 식별 및 계정 관리\n- Morni 서비스(일기 작성, 방 꾸미기, 친구 기능) 제공\n- 서비스 개선 및 통계 분석\n- 오류 분석 및 안정성 확보\n- 고객 문의 대응\n- 맞춤형 광고 제공',
              ),
              _buildSection(
                colorScheme,
                '2. 처리하는 개인정보의 항목',
                '- 필수 항목: 이메일 주소, 닉네임 (소셜 로그인 시 제공)\n- 사용자 생성 콘텐츠: 이용자가 작성한 일기 내용 및 방 꾸미기 데이터\n- 자동 수집 항목: 기기 정보(OS, 기기 모델), IP 주소, 앱 이용 기록, 광고 식별자(AAID/IDFA)\n- 문의 시: 사용자가 자발적으로 제공하는 이메일 및 문의 내용',
              ),
              _buildSection(
                colorScheme,
                '3. 개인정보의 처리 및 보유 기간',
                '서비스 제공자는 회원 탈퇴 시 지체 없이 개인정보를 삭제합니다.\n단, 관계 법령에 따라 보존이 필요한 경우 해당 기간 동안 보관 후 파기합니다.\nFirebase Analytics 및 Crashlytics 데이터는 Google 정책에 따른 보관 기간 동안 저장됩니다.',
              ),
              _buildSection(
                colorScheme,
                '4. 개인정보의 제3자 제공 및 처리 위탁',
                '서비스 제공자는 원활한 서비스 제공을 위해 아래 업체에 개인정보 처리를 위탁합니다.\n- Google LLC – Firebase Analytics, Crashlytics, Authentication, Cloud Firestore, AdMob\n- Apple Inc. – Apple 로그인\n- Kakao Corp. – 카카오 로그인',
              ),
              _buildSection(
                colorScheme,
                '5. 개인정보의 국외 이전',
                '서비스 제공자는 Google Firebase 및 AdMob 사용에 따라 개인정보를 국외로 이전할 수 있습니다.\n- 이전 국가: 미국 등 Google 데이터센터 소재 국가\n- 이전 항목: 기기 정보, 이용 기록, 광고 식별자, 사용자 생성 콘텐츠\n- 이전 목적: 서비스 제공, 데이터 저장, 분석, 광고 제공\n- 보관 기간: 서비스 이용 기간 또는 관련 법령에 따른 기간',
              ),
              _buildSection(
                colorScheme,
                '6. 맞춤형 광고',
                '서비스는 Google AdMob을 통해 광고를 제공하며, 광고 식별자를 활용하여 맞춤형 광고를 제공할 수 있습니다.\n사용자는 기기 설정을 통해 광고 개인화를 제한할 수 있습니다.',
              ),
              _buildSection(
                colorScheme,
                '7. 사용자 콘텐츠의 보호',
                '이용자가 작성한 일기 내용 및 관련 데이터는 Firebase 서버에 저장되며, 저장 시 암호화되어 보호됩니다.\n또한 전송 과정에서도 보안 프로토콜(HTTPS)을 통해 안전하게 처리됩니다.',
              ),
              _buildSection(
                colorScheme,
                '8. 정보주체의 권리 및 행사방법',
                '이용자는 언제든지 자신의 개인정보 조회, 수정, 삭제를 요청할 수 있습니다.\n앱 내 “계정 삭제” 기능을 통해 즉시 탈퇴할 수 있으며, 탈퇴 시 모든 개인정보(일기 및 방 데이터 포함)는 지체 없이 삭제됩니다.\n문의: stlim1026@gmail.com',
              ),
              _buildSection(
                colorScheme,
                '9. 아동의 개인정보 보호',
                '서비스는 만 13세 미만 아동의 개인정보를 의도적으로 수집하지 않습니다. 해당 정보가 발견될 경우 즉시 삭제합니다.',
              ),
              _buildSection(
                colorScheme,
                '10. 개인정보의 안전성 확보 조치',
                '서비스 제공자는 개인정보 암호화 저장, 접근 통제, 보안 서버 운영 등 기술적·관리적 보호 조치를 시행합니다.',
              ),
              _buildSection(
                colorScheme,
                '11. 개인정보 보호책임자',
                '성명: 임승택\n이메일: stlim1026@gmail.com',
              ),
              _buildSection(
                colorScheme,
                '12. 개인정보 처리방침 변경',
                '본 방침은 2026-02-19부터 시행됩니다.',
              ),
              _buildSection(
                colorScheme,
                '13. 사용자 생성 콘텐츠 및 운영 정책',
                'Morni는 이용자가 방에 메모를 작성하고, 친구가 이를 열람하거나 반응(하트 등)을 남길 수 있는 기능을 제공합니다.\n이용자가 작성한 메모는 친구에게 공개될 수 있으며, 서비스 운영 정책에 따라 관리됩니다.\n이용자는 부적절하거나 서비스 정책을 위반하는 콘텐츠를 신고할 수 있습니다. 신고된 콘텐츠는 검토 후 운영 정책에 위반될 경우 삭제될 수 있습니다.\n운영자가 삭제한 콘텐츠는 복구되지 않을 수 있습니다.\n이용자는 언제든지 친구를 삭제하거나 차단할 수 있으며, 친구 관계 해제 시 해당 이용자의 접근이 제한됩니다.',
              ),
              _buildSection(
                colorScheme,
                '커뮤니티 가이드라인',
                'Morni는 안전하고 긍정적인 커뮤니티 환경을 지향합니다.\n- 타인을 비방, 괴롭힘, 위협하는 행위를 금지합니다.\n- 혐오 표현, 차별적 발언, 음란물, 불법 콘텐츠 게시를 금지합니다.\n- 타인의 개인정보를 무단으로 공개하는 행위를 금지합니다.\n- 스팸, 광고성 콘텐츠 게시를 금지합니다.\n위 가이드라인을 위반하는 경우 콘텐츠 삭제, 기능 제한, 계정 제한 등의 조치가 이루어질 수 있습니다.\n이용자는 부적절한 콘텐츠를 신고할 수 있으며, 서비스 제공자는 합리적인 기간 내에 검토합니다.',
              ),
            ] else if (isJapanese) ...[
              Text(
                "LemoNary（以下「サービス提供者」）は、Morni利用者の個人情報を重要に考え、「個人情報保護法」および関連法令を遵守します。",
                style: TextStyle(
                  color: colorScheme.textSecondary,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              _buildSection(
                colorScheme,
                '1. 個人情報の処理目的',
                'サービス提供者は、以下の目的のために個人情報を処理します。\n- 会員の識別およびアカウント管理\n- Morniサービス（日記の作成、部屋の装飾、友達機能）の提供\n- サービスの改善および統計分析\n- エラー分析および安定性の確保\n- 顧客の問い合わせ対応\n- パーソナライズされた広告の提供',
              ),
              _buildSection(
                colorScheme,
                '2. 処理する個人情報の項目',
                '- 必須項目：メールアドレス、ニックネーム（ソーシャルログイン時に提供）\n- ユーザー生成コンテンツ：利用者が作成した日記の内容および部屋の装飾データ\n- 自動収集項目：デバイス情報（OS、デバイスモデル）、IPアドレス、アプリ利用記録、広告識別子（AAID/IDFA）\n- 問い合わせ時：利用者が自発的に提供するメールアドレスおよび問い合わせ内容',
              ),
              _buildSection(
                colorScheme,
                '3. 個人情報の処理および保有期間',
                'サービス提供者は、会員退会時に遅滞なく個人情報を削除します。\nただし、関連法令により保存が必要な場合、該当期間中は保管した後で破棄します。\nFirebase Analytics および Crashlytics のデータは、Googleのポリシーに基づく保管期間中保存されます。',
              ),
              _buildSection(
                colorScheme,
                '4. 個人情報の第三者提供および処理委託',
                'サービス提供者は、円滑なサービス提供のため以下の業者に個人情報の処理を委託します。\n- Google LLC – Firebase Analytics, Crashlytics, Authentication, Cloud Firestore, AdMob\n- Apple Inc. – Appleログイン\n- Kakao Corp. – Kakaoログイン',
              ),
              _buildSection(
                colorScheme,
                '5. 個人情報の国外移転',
                'サービス提供者は、Google Firebase および AdMob の使用に伴い、個人情報を国外に移転する場合があります。\n- 移転先：米国などGoogleデータセンターが所在する国\n- 移転項目：デバイス情報、利用記録、広告識別子、ユーザー生成コンテンツ\n- 移転目的：サービスの提供、データ保存、分析、広告提供\n- 保管期間：サービス利用期間または関連法令に基づく期間',
              ),
              _buildSection(
                colorScheme,
                '6. パーソナライズされた広告',
                '本サービスは、Google AdMobを通じて広告を提供し、広告識別子を活用してパーソナライズされた広告を提供することがあります。\nユーザーはデバイスの設定を通じて広告のパーソナライズを制限することができます。',
              ),
              _buildSection(
                colorScheme,
                '7. ユーザーコンテンツの保護',
                '利用者が作成した日記の内容および関連データはFirebaseサーバーに保存され、保存時に暗号化されて保護されます。\nまた、送信過程でもセキュリティプロトコル（HTTPS）を通じて安全に処理されます。',
              ),
              _buildSection(
                colorScheme,
                '8. 情報主体の権利とその行使方法',
                '利用者はいつでも自身の個人情報の照会、修正、削除を要請することができます。\nアプリ内の「アカウント削除」機能を通じて即時に退会することができ、退会時にはすべての個人情報（日記および部屋データを含む）は遅滞なく削除されます。\nお問い合わせ：stlim1026@gmail.com',
              ),
              _buildSection(
                colorScheme,
                '9. 児童の個人情報保護',
                '本サービスは、13歳未満の児童の個人情報を意図的に収集しません。該当する情報が発見された場合は直ちに削除します。',
              ),
              _buildSection(
                colorScheme,
                '10. 個人情報の安全性確保措置',
                'サービス提供者は、個人情報の暗号化保存、アクセス制御、セキュリティサーバーの運営などの技術的・管理的な保護措置を実施します。',
              ),
              _buildSection(
                colorScheme,
                '11. 個人情報保護責任者',
                '氏名：Lim Seung Taek\nメールアドレス：stlim1026@gmail.com',
              ),
              _buildSection(
                colorScheme,
                '12. 個人情報処理方針の変更',
                '本方針は2026年2月19日より施行されます。',
              ),
              _buildSection(
                colorScheme,
                '13. ユーザー生成コンテンツおよび運営ポリシー',
                'Morniは、利用者が部屋にメモを作成し、友達がそれを閲覧したり反応（ハートなど）を残すことができる機能を提供します。\n利用者が作成したメモは友達に公開される可能性があり、サービス運営ポリシーに従って管理されます。\n利用者は不適切なコンテンツやサービスポリシーに違反するコンテンツを報告することができます。報告されたコンテンツは検討後、運営ポリシーに違反する場合、削除されることがあります。\n運営者が削除したコンテンツは復旧されない場合があります。\n利用者はいつでも友達を削除またはブロックすることができ、友達関係が解除されると該当利用者のアクセスが制限されます。',
              ),
              _buildSection(
                colorScheme,
                'コミュニティガイドライン',
                'Morniは安全で肯定的なコミュニティ環境を目指しています。\n- 他人を誹謗中傷、嫌がらせ、脅迫する行為を禁止します。\n- ヘイトスピーチ、差別的な発言、ポルノ、違法コンテンツの掲示を禁止します。\n- 他人の個人情報を無断で公開する行為を禁止します。\n- スパム、広告目的のコンテンツ掲示を禁止します。\n上記のガイドラインに違反した場合、コンテンツの削除、機能制限、アカウント制限などの措置が行われる場合があります。\n利用者は不適切なコンテンツを報告することができ、サービス提供者は合理的な期間内に検討します。',
              ),
            ] else ...[
              Text(
                'This Privacy Policy applies to the Morni mobile application ("Application") developed by LemoNary ("Service Provider"). The Service Provider respects your privacy and is committed to protecting your personal information.',
                style: TextStyle(
                  color: colorScheme.textSecondary,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              _buildSection(
                colorScheme,
                '1. Information We Collect',
                'The Application may collect the following categories of information:\n- Account Information: Email address, nickname, and profile information provided through Google, Apple, or Kakao login.\n- User-Generated Content: Journal entries, room decoration data, and related content created within the Application.\n- Device Information: IP address, device model, operating system, and app usage data.\n- Advertising Identifiers: Advertising ID (AAID/IDFA) for advertising purposes.\n- Analytics & Diagnostics: Usage statistics and crash reports collected through Firebase Analytics and Firebase Crashlytics.\n- Support Information: Information you voluntarily provide when contacting support.',
              ),
              _buildSection(
                colorScheme,
                '2. How We Use Information',
                'We use collected information to:\n- Provide and maintain the Application\n- Enable account authentication and social features\n- Store and synchronize journal and room data\n- Improve performance and user experience\n- Monitor stability and fix errors\n- Provide personalized or non-personalized advertisements\n- Respond to customer inquiries',
              ),
              _buildSection(
                colorScheme,
                '3. Data Storage and Security',
                'User-generated content (including journal entries and room data) is stored on Firebase servers.\nAll data is transmitted securely using HTTPS encryption and is encrypted at rest in accordance with Firebase security standards.\nAppropriate technical and organizational safeguards are implemented to protect personal information.',
              ),
              _buildSection(
                colorScheme,
                '4. Third-Party Services',
                'The Application uses the following third-party services:\n- Google LLC – Firebase Authentication, Cloud Firestore, Firebase Analytics, Crashlytics, AdMob\n- Apple Inc. – Sign in with Apple\n- Kakao Corp. – Kakao Login\nThese providers may process data in accordance with their own privacy policies.',
              ),
              _buildSection(
                colorScheme,
                '5. International Data Transfers',
                'Information may be transferred to and processed in countries outside your country of residence, including the United States where Google data centers are located.\nTransferred data may include account information, device information, advertising identifiers, and user-generated content.\nData is processed for service provision, storage, analytics, and advertising purposes.',
              ),
              _buildSection(
                colorScheme,
                '6. Advertising',
                'The Application uses Google AdMob to display advertisements. AdMob may use advertising identifiers to provide personalized ads.\nYou may limit ad personalization through your device settings.',
              ),
              _buildSection(
                colorScheme,
                '7. Data Retention',
                'Personal information is retained for as long as your account is active.\nYou may delete your account at any time through the in-app account deletion feature. Upon deletion, your personal data, including journal entries and room data, will be permanently removed without undue delay, except where retention is required by law.',
              ),
              _buildSection(
                colorScheme,
                '8. Children\'s Privacy',
                'The Application is not directed to children under the age of 13. The Service Provider does not knowingly collect personal information from children under 13. If such information is discovered, it will be deleted immediately.',
              ),
              _buildSection(
                colorScheme,
                '9. Your Rights',
                'You may request access to, correction of, or deletion of your personal data by using the in-app account management features or by contacting us.\nContact: stlim1026@gmail.com',
              ),
              _buildSection(
                colorScheme,
                '10. Changes to This Policy',
                'This Privacy Policy may be updated from time to time. Continued use of the Application after changes constitutes acceptance of the revised policy.\nThis policy is effective as of 2026-02-19.',
              ),
              _buildSection(
                colorScheme,
                'Biometric Authentication',
                'The Application may offer optional biometric authentication (such as Face ID or fingerprint recognition) to protect access to the app and user content.\nBiometric data is processed locally by the device\'s operating system. The Application does not collect, store, or transmit biometric information to any server.',
              ),
              _buildSection(
                colorScheme,
                'User-Generated Content and Moderation',
                'The Application allows users to create notes within their rooms that may be visible to their friends. Other users may interact with these notes (such as by sending reactions).\nUsers may report content they believe violates community standards. Reported content may be reviewed and removed if it violates the Application\'s policies.\nRemoved content may not be recoverable.\nUsers may remove or block friends at any time. Once removed, access to shared content may be restricted.',
              ),
              _buildSection(
                colorScheme,
                'Community Guidelines',
                'Morni is committed to maintaining a safe and positive community environment.\n- No harassment, bullying, or threats toward other users.\n- No hate speech, discriminatory content, explicit content, or illegal material.\n- No sharing of personal information without consent.\n- No spam or unauthorized advertising.\nViolations of these guidelines may result in content removal, feature restrictions, or account suspension.\nUsers may report inappropriate content, and the Service Provider will review reports within a reasonable timeframe.',
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    AppColorScheme colorScheme,
    String title,
    String content,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colorScheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              color: colorScheme.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
