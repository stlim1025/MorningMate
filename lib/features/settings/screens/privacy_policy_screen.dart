import 'package:flutter/material.dart';
import '../../../core/theme/app_color_scheme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          '개인정보 처리방침',
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
            _buildSection(
              colorScheme,
              '1. 수집하는 개인정보 항목',
              '서비스는 회원가입 및 서비스 제공을 위해 아래와 같은 개인정보를 수집하고 있습니다.\n- 필수항목: 이메일, 비밀번호, 닉네임',
            ),
            _buildSection(
              colorScheme,
              '2. 개인정보의 수집 및 이용목적',
              '서비스는 수집한 개인정보를 다음의 목적을 위해 활용합니다.\n- 서비스 제공에 관한 계약 이행 및 서비스 제공에 따른 요금정산\n- 회원 관리: 회원제 서비스 이용에 따른 본인확인, 개인 식별, 불량회원의 부정 이용 방지와 비인가 사용 방지, 가입 의사 확인',
            ),
            _buildSection(
              colorScheme,
              '3. 개인정보의 보유 및 이용기간',
              '원칙적으로 개인정보 수집 및 이용목적이 달성된 후에는 해당 정보를 지체 없이 파기합니다. 단, 관계법령의 규정에 의하여 보존할 필요가 있는 경우 일정 기간 동안 회원정보를 보관할 수 있습니다.',
            ),
            _buildSection(
              colorScheme,
              '4. 개인정보 파기절차 및 방법',
              '이용자의 개인정보는 원칙적으로 개인정보의 수집 및 이용목적이 달성되면 지체 없이 파기합니다. 파기절차 및 방법은 다음과 같습니다.\n- 파기절차: 회원가입 등을 위해 입력한 정보는 목적이 달성된 후 별도의 DB로 옮겨져 일정 기간 저장된 후 파기됩니다.\n- 파기방법: 전자적 파일형태로 저장된 개인정보는 기록을 재생할 수 없는 기술적 방법을 사용하여 삭제합니다.',
            ),
            _buildSection(
              colorScheme,
              '5. 이용자의 권리',
              '이용자는 언제든지 등록되어 있는 자신의 개인정보를 조회하거나 수정할 수 있으며 가입해지(탈퇴)를 요청할 수도 있습니다.',
            ),
            _buildSection(
              colorScheme,
              '6. 개인정보의 보호 (암호화)',
              '사용자가 작성한 일기 내용은 강력한 암호화 기술을 사용하여 안전하게 저장됩니다. Morni는 사용자의 소중한 기록을 보호하기 위해 최선을 다하고 있습니다.',
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                '시행일자: 2026년 2월 1일',
                style: TextStyle(color: colorScheme.textHint, fontSize: 12),
              ),
            ),
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
