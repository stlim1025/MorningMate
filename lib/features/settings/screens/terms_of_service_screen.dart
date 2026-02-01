import 'package:flutter/material.dart';
import '../../../core/theme/app_color_scheme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
          '이용약관',
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
              '제 1조 (목적)',
              '본 약관은 "MorningMate"(이하 "서비스")가 제공하는 모든 서비스의 이용 조건 및 절차, 이용자와 서비스 운영자의 권리, 의무 및 책임 사항을 규정함을 목적으로 합니다.',
            ),
            _buildSection(
              colorScheme,
              '제 2조 (약관의 명시와 개정)',
              '1. 서비스는 이 약관의 내용을 이용자가 쉽게 알 수 있도록 서비스 화면에 게시합니다.\n2. 서비스는 관련 법령을 위배하지 않는 범위에서 이 약관을 개정할 수 있습니다.',
            ),
            _buildSection(
              colorScheme,
              '제 3조 (서비스의 제공 및 변경)',
              '1. 서비스는 이용자에게 다음과 같은 서비스를 제공합니다.\n  - 아침 일기 작성 및 기록 서비스\n  - 캐릭터 성장 및 포인트 시스템\n  - 친구 간 응원 메시지 전송 기능\n2. 서비스는 기술적 사양의 변경 등의 경우에는 장차 체결되는 계약에 의해 제공할 서비스의 내용을 변경할 수 있습니다.',
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
                style: TextStyle(
                  color: colorScheme.textHint,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      AppColorScheme colorScheme, String title, String content) {
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
