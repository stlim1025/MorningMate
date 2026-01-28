import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../services/user_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: const Text('설정', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Consumer<AuthController>(
          builder: (context, authController, child) {
            final user = authController.userModel;
            
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 프로필 섹션
                _buildProfileSection(context, user),
                
                const SizedBox(height: 24),
                
                // 계정 설정
                _buildSectionTitle('계정'),
                _buildSettingsTile(
                  icon: Icons.person,
                  title: '닉네임 변경',
                  subtitle: user?.nickname ?? '',
                  onTap: () => _showChangeNicknameDialog(context, user?.nickname ?? ''),
                ),
                _buildSettingsTile(
                  icon: Icons.email,
                  title: '이메일',
                  subtitle: user?.email ?? '',
                  onTap: null, // 이메일은 변경 불가
                ),
                
                const SizedBox(height: 24),
                
                // 보안 설정
                _buildSectionTitle('보안'),
                _buildSettingsTile(
                  icon: Icons.fingerprint,
                  title: '생체 인증',
                  subtitle: '앱 잠금 설정',
                  onTap: () {
                    // TODO: 생체 인증 설정
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('생체 인증 설정 기능은 개발 중입니다')),
                    );
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.lock,
                  title: '비밀번호 변경',
                  onTap: () {
                    // TODO: 비밀번호 변경
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('비밀번호 변경 기능은 개발 중입니다')),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                
                // 앱 설정
                _buildSectionTitle('앱 설정'),
                _buildWritingBlurTile(context, authController),
                _buildSettingsTile(
                  icon: Icons.notifications,
                  title: '알림 설정',
                  onTap: () {
                    // TODO: 알림 설정
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('알림 설정 기능은 개발 중입니다')),
                    );
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.dark_mode,
                  title: '다크 모드',
                  subtitle: '항상 켜짐',
                  onTap: null,
                ),
                
                const SizedBox(height: 24),
                
                // 정보
                _buildSectionTitle('정보'),
                _buildSettingsTile(
                  icon: Icons.info,
                  title: '버전 정보',
                  subtitle: 'v1.0.0',
                  onTap: null,
                ),
                _buildSettingsTile(
                  icon: Icons.description,
                  title: '이용약관',
                  onTap: () {},
                ),
                _buildSettingsTile(
                  icon: Icons.privacy_tip,
                  title: '개인정보 처리방침',
                  onTap: () {},
                ),
                
                const SizedBox(height: 32),
                
                // 로그아웃 버튼
                _buildLogoutButton(context, authController),
                
                const SizedBox(height: 16),
                
                // 회원탈퇴
                _buildDeleteAccountButton(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary,
            child: Text(
              user?.nickname?.substring(0, 1).toUpperCase() ?? 'U',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.nickname ?? '사용자',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lv. ${user?.characterLevel ?? 1} • ${user?.points ?? 0} 포인트',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(color: Colors.white54),
              )
            : null,
        trailing: onTap != null
            ? const Icon(Icons.chevron_right, color: Colors.white54)
            : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildWritingBlurTile(
      BuildContext context, AuthController authController) {
    final user = authController.userModel;
    final blurEnabled = user?.writingBlurEnabled ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        secondary: const Icon(Icons.visibility_off, color: AppColors.primary),
        title: const Text(
          '글 작성 블러 기본값',
          style: TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          blurEnabled ? '작성 중인 글을 기본으로 블러 처리합니다' : '작성 중인 글을 기본으로 표시합니다',
          style: const TextStyle(color: Colors.white54),
        ),
        value: blurEnabled,
        onChanged: user == null
            ? null
            : (value) => _updateWritingBlurSetting(
                  context,
                  authController,
                  value,
                ),
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthController authController) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutDialog(context, authController),
        icon: const Icon(Icons.logout),
        label: const Text('로그아웃'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cardDark,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteAccountButton(BuildContext context) {
    return TextButton(
      onPressed: () => _showDeleteAccountDialog(context),
      child: const Text(
        '회원탈퇴',
        style: TextStyle(
          color: AppColors.error,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Future<void> _showChangeNicknameDialog(BuildContext context, String currentNickname) async {
    final controller = TextEditingController(text: currentNickname);
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text(
          '닉네임 변경',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '새 닉네임 입력',
            hintStyle: const TextStyle(color: Colors.white30),
            filled: true,
            fillColor: AppColors.backgroundDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          maxLength: 10,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newNickname = controller.text.trim();
              if (newNickname.isEmpty || newNickname.length < 2) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('닉네임은 2자 이상이어야 합니다')),
                );
                return;
              }

              final authController = context.read<AuthController>();
              final userService = context.read<UserService>();
              final userId = authController.currentUser?.uid;

              if (userId != null) {
                try {
                  await userService.updateUser(userId, {
                    'nickname': newNickname,
                  });
                  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('닉네임이 변경되었습니다'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('오류: $e')),
                  );
                }
              }
            },
            child: const Text('변경'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateWritingBlurSetting(
    BuildContext context,
    AuthController authController,
    bool value,
  ) async {
    final userService = context.read<UserService>();
    final userId = authController.currentUser?.uid;
    final currentUser = authController.userModel;

    if (userId == null || currentUser == null) return;

    try {
      await userService.updateUser(userId, {
        'writingBlurEnabled': value,
      });
      authController.updateUserModel(
        currentUser.copyWith(writingBlurEnabled: value),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('설정 저장 중 오류가 발생했습니다: $e')),
      );
    }
  }

  Future<void> _showLogoutDialog(BuildContext context, AuthController authController) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text(
          '로그아웃',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '정말 로그아웃 하시겠습니까?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              await authController.signOut();
              if (context.mounted) {
                Navigator.pop(context);
                context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text(
          '회원탈퇴',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '정말 회원탈퇴 하시겠습니까?\n모든 데이터가 삭제되며 복구할 수 없습니다.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: 회원탈퇴 로직 구현
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('회원탈퇴 기능은 개발 중입니다')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('탈퇴'),
          ),
        ],
      ),
    );
  }
}
