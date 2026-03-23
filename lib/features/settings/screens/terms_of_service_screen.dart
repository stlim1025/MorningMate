import 'package:flutter/material.dart';
import '../../../core/theme/app_color_scheme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
          isKorean ? '서비스 이용약관' : (isJapanese ? 'サービス利用規約' : 'Service Terms'),
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
              _buildSection(
                colorScheme,
                '제 1조 (목적)',
                '본 약관은 "Morni"(이하 "서비스")가 제공하는 모든 서비스의 이용 조건 및 절차, 이용자와 서비스 운영자의 권리, 의무 및 책임 사항을 규정함을 목적으로 합니다.',
              ),
              _buildSection(
                colorScheme,
                '제 2조 (약관의 명시와 개정)',
                '1. 서비스는 이 약관의 내용을 이용자가 쉽게 알 수 있도록 서비스 화면에 게시합니다.\n2. 서비스는 관련 법령을 위배하지 않는 범위에서 이 약관을 개정할 수 있습니다.',
              ),
              _buildSection(
                colorScheme,
                '제 3조 (서비스의 제공 및 변경)',
                '1. 서비스는 이용자에게 다음과 같은 서비스를 제공합니다.\n  - 아침 일기 작성 및 기록 서비스\n  - 캐릭터 성장 및 나뭇가지 시스템\n  - 친구 간 응원 메시지 전송 기능\n2. 서비스는 기술적 사양의 변경 등의 경우에는 장차 체결되는 계약에 의해 제공할 서비스의 내용을 변경할 수 있습니다.',
              ),
              _buildSection(
                colorScheme,
                '제 4조 (이용자의 의무)',
                '이용자는 다음 행위를 하여서는 안 됩니다.\n1. 신청 또는 변경 시 허위 내용의 등록\n2. 타인의 정보 도용\n3. 서비스 게시된 정보의 변경\n4. 서비스가 정한 정보 이외의 정보(컴퓨터 프로그램 등) 등의 송신 또는 게시',
              ),
              _buildSection(
                colorScheme,
                '제 5조 (계약해지 및 이용제한)',
                '이용자가 이용계약을 해지하고자 하는 때에는 이용자 본인이 서비스 내 계정 탈퇴 기능을 이용하여 가입해지를 해야 합니다.',
              ),
              const SizedBox(height: 40),
              Center(
                child: Text(
                  '시행일자: 2026년 2월 1일',
                  style: TextStyle(color: colorScheme.textHint, fontSize: 12),
                ),
              ),
            ] else if (isJapanese) ...[
              _buildSection(
                colorScheme,
                '第1条（目的）',
                '本規約は、「Morni」（以下「サービス」）が提供するすべてのサービスの利用条件および手続き、利用者とサービス運営者の権利、義務、および責任事項を規定することを目的とします。',
              ),
              _buildSection(
                colorScheme,
                '第2条（規約の明示と改定）',
                '1. サービスは、本規約の内容をサービス画面に掲示し、利用者が容易に確認できるようにします。\n2. サービスは、関連法令に違反しない範囲で本規約を改定することができます。',
              ),
              _buildSection(
                colorScheme,
                '第3条（サービスの提供および変更）',
                '1. サービスは、利用者に以下のサービスを提供します。\n  - 朝の日記作成および記録サービス\n  - キャラクターの成長およびブランチシステム\n  - 友達間の応援メッセージ送信機能\n2. サービスは、技術的仕様の変更などの場合、将来締結される契約に基づいて提供するサービスの内容を変更することができます。',
              ),
              _buildSection(
                colorScheme,
                '第4条（利用者の義務）',
                '利用者は以下の行為をしてはなりません。\n1. 申込または変更時の虚偽内容の登録\n2. 他人の情報の盗用\n3. サービスに掲示された情報の変更\n4. サービスが定めた情報以外の情報（コンピュータープログラムなど）の送信または掲示',
              ),
              _buildSection(
                colorScheme,
                '第5条（契約解除および利用制限）',
                '利用者が利用契約を解除しようとする場合、利用者本人がサービス内のアカウント退会機能を使用して解除する必要があります。',
              ),
              const SizedBox(height: 40),
              Center(
                child: Text(
                  '施行日：2026年2月1日',
                  style: TextStyle(color: colorScheme.textHint, fontSize: 12),
                ),
              ),
            ] else ...[
              _buildSection(
                colorScheme,
                'Article 1 (Purpose)',
                'This agreement aims to define the terms and procedures for using all services provided by "Morni" (hereinafter referred to as the "Service"), as well as the rights, duties, and responsibilities of the user and the Service Provider.',
              ),
              _buildSection(
                colorScheme,
                'Article 2 (Specification and Revision of Terms)',
                '1. The Service will post the contents of these terms on the service screen so that users can easily understand them.\n2. The Service may revise these terms within the scope that does not violate relevant laws.',
              ),
              _buildSection(
                colorScheme,
                'Article 3 (Provision and Change of Service)',
                '1. The Service provides the following services to users:\n  - Morning diary writing and recording service\n  - Character growth and branch system\n  - Cheering message transmission function between friends\n2. The Service may change the contents of the service to be provided by a future contract in the event of a change in technical specifications, etc.',
              ),
              _buildSection(
                colorScheme,
                'Article 4 (User\'s Obligations)',
                'Users must not engage in the following acts:\n1. Registration of false information during application or change\n2. Theft of other\'s information\n3. Change of information posted on the service\n4. Transmission or posting of information (computer programs, etc.) other than the information set by the service',
              ),
              _buildSection(
                colorScheme,
                'Article 5 (Contract Cancellation and Use Restriction)',
                'When a user wishes to cancel the use contract, the user must cancel the subscription using the account deletion function in the service.',
              ),
              const SizedBox(height: 40),
              Center(
                child: Text(
                  'Effective Date: February 1, 2026',
                  style: TextStyle(color: colorScheme.textHint, fontSize: 12),
                ),
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
