import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../services/user_service.dart';

import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _version = 'v${info.version}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '설정',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Consumer<AuthController>(
          builder: (context, authController, child) {
            final user = authController.userModel;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 프로필 섹션
                _buildProfileSection(context, user),

                const SizedBox(height: 24),

                // 계정 설정
                _buildSectionTitle('계정'),
                const SizedBox(height: 12),
                _buildSettingsTile(
                  icon: Icons.person,
                  title: '닉네임 변경',
                  subtitle: user?.nickname ?? '',
                  onTap: () =>
                      _showChangeNicknameDialog(context, user?.nickname ?? ''),
                ),
                const SizedBox(height: 8),
                _buildSettingsTile(
                  icon: Icons.email,
                  title: '이메일',
                  subtitle: user?.email ?? '',
                  onTap: null,
                ),

                const SizedBox(height: 24),

                // 보안 설정
                _buildSectionTitle('보안'),
                const SizedBox(height: 12),
                _buildBiometricTile(context, authController),
                const SizedBox(height: 8),
                _buildSettingsTile(
                  icon: Icons.lock,
                  title: '비밀번호 변경',
                  onTap: () => _showChangePasswordDialog(context),
                ),

                const SizedBox(height: 24),

                // 앱 설정
                _buildSectionTitle('앱 설정'),
                const SizedBox(height: 12),
                _buildDarkModeTile(context),
                const SizedBox(height: 8),
                _buildWritingBlurTile(context, authController),
                const SizedBox(height: 8),
                _buildSettingsTile(
                  icon: Icons.notifications,
                  title: '알림 설정',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      _buildSnackBar('알림 설정 기능은 개발 중입니다'),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // 정보
                _buildSectionTitle('정보'),
                const SizedBox(height: 12),
                _buildSettingsTile(
                  icon: Icons.info,
                  title: '버전 정보',
                  subtitle: _version.isEmpty ? '불러오는 중...' : _version,
                  onTap: null,
                ),
                const SizedBox(height: 8),
                _buildSettingsTile(
                  icon: Icons.description,
                  title: '이용약관',
                  onTap: () {},
                ),
                const SizedBox(height: 8),
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
                _buildDeleteAccountButton(context, authController),

                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.8),
                  AppColors.secondary.withOpacity(0.8),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                user?.nickname?.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.nickname ?? '사용자',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Lv. ${user?.characterLevel ?? 1}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.pointStar.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: AppColors.pointStar,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${user?.points ?? 0}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
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
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.smallCardShadow,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: subtitle != null
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              )
            : null,
        trailing: onTap != null
            ? Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary.withOpacity(0.5),
              )
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
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.smallCardShadow,
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.visibility_off,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        title: Text(
          '글 작성 블러 기본값',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            blurEnabled ? '작성 중인 글을 기본으로 블러 처리합니다' : '작성 중인 글을 기본으로 표시합니다',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
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

  Widget _buildBiometricTile(
      BuildContext context, AuthController authController) {
    final user = authController.userModel;
    final biometricEnabled = user?.biometricEnabled ?? false;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.smallCardShadow,
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.fingerprint,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        title: Text(
          '생체 인증',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            biometricEnabled ? '앱 실행과 일기 열기에 생체 인증이 필요합니다' : '생체 인증으로 앱을 보호합니다',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        value: biometricEnabled,
        onChanged: user == null
            ? null
            : (value) => _updateBiometricSetting(
                  context,
                  authController,
                  value,
                ),
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildDarkModeTile(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.smallCardShadow,
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.dark_mode,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        title: Text(
          '다크 모드',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            '어두운 테마를 사용합니다',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        value: themeController.isDarkMode,
        onChanged: (value) => themeController.toggleTheme(value),
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildLogoutButton(
      BuildContext context, AuthController authController) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.smallCardShadow,
      ),
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutDialog(context, authController),
        icon: const Icon(Icons.logout, size: 22),
        label: const Text(
          '로그아웃',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).cardColor,
          foregroundColor: AppColors.error,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: AppColors.error.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildDeleteAccountButton(
      BuildContext context, AuthController authController) {
    return Center(
      child: TextButton(
        onPressed: () => _showDeleteAccountDialog(context, authController),
        child: const Text(
          '회원탈퇴',
          style: TextStyle(
            color: AppColors.textSecondary,
            decoration: TextDecoration.underline,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Future<void> _showChangeNicknameDialog(
      BuildContext context, String currentNickname) async {
    final controller = TextEditingController(text: currentNickname);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          '닉네임 변경',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            hintText: '새 닉네임 입력',
            hintStyle: TextStyle(color: AppColors.textHint),
            filled: true,
            fillColor: Theme.of(context).inputDecorationTheme.fillColor ??
                AppColors.backgroundLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          maxLength: 10,
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : const Color(0xFFF0F0F0),
              foregroundColor: AppColors.textSecondary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newNickname = controller.text.trim();
              if (newNickname.isEmpty || newNickname.length < 2) {
                ScaffoldMessenger.of(context).showSnackBar(
                  _buildSnackBar('닉네임은 2자 이상이어야 합니다'),
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

                  // 즉시 로컬 모델 업데이트 (반영 속도 향상)
                  authController.updateUserModel(
                    authController.userModel?.copyWith(nickname: newNickname),
                  );

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    _buildSnackBar('닉네임이 변경되었습니다', isSuccess: true),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    _buildSnackBar('오류: $e'),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: AppColors.textPrimary,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '변경',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
        _buildSnackBar('설정 저장 중 오류가 발생했습니다: $e'),
      );
    }
  }

  Future<void> _updateBiometricSetting(
    BuildContext context,
    AuthController authController,
    bool value,
  ) async {
    final userService = context.read<UserService>();
    final userId = authController.currentUser?.uid;
    final currentUser = authController.userModel;

    if (userId == null || currentUser == null) return;

    if (value) {
      final canUse = await authController.canUseBiometric();
      if (!canUse) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            _buildSnackBar('이 기기에서는 생체 인증을 사용할 수 없습니다'),
          );
        }
        return;
      }

      final authenticated = await authController.authenticateWithBiometric();
      if (!authenticated) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            _buildSnackBar('생체 인증에 실패했습니다'),
          );
        }
        return;
      }
    }

    try {
      await userService.updateUser(userId, {
        'biometricEnabled': value,
      });
      authController.updateUserModel(
        currentUser.copyWith(biometricEnabled: value),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildSnackBar('생체 인증 설정 저장 중 오류가 발생했습니다: $e'),
        );
      }
    }
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          '비밀번호 변경',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: '새 비밀번호 (6자 이상)',
                  hintStyle: TextStyle(color: AppColors.textHint),
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor ??
                      AppColors.backgroundLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '새 비밀번호를 입력해주세요';
                  }
                  if (value.trim().length < 6) {
                    return '비밀번호는 최소 6자 이상이어야 합니다';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: '새 비밀번호 확인',
                  hintStyle: TextStyle(color: AppColors.textHint),
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor ??
                      AppColors.backgroundLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '비밀번호 확인을 입력해주세요';
                  }
                  if (value.trim() != newPasswordController.text.trim()) {
                    return '비밀번호가 일치하지 않습니다';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : const Color(0xFFF0F0F0),
              foregroundColor: AppColors.textSecondary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final authController = context.read<AuthController>();
              try {
                await authController
                    .changePassword(newPasswordController.text.trim());
                if (context.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    _buildSnackBar('비밀번호가 변경되었습니다', isSuccess: true),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    _buildSnackBar('비밀번호 변경 실패: $e'),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: AppColors.textPrimary,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '변경',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLogoutDialog(
      BuildContext context, AuthController authController) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          '로그아웃',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          '정말 로그아웃 하시겠습니까?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF0F0F0),
              foregroundColor: AppColors.textSecondary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: AppColors.textPrimary,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '로그아웃',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteAccountDialog(
    BuildContext context,
    AuthController authController,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          '회원탈퇴',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          '정말 회원탈퇴 하시겠습니까?\n모든 데이터가 삭제되며 복구할 수 없습니다.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF0F0F0),
              foregroundColor: AppColors.textSecondary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: AppColors.textPrimary,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '탈퇴',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await authController.deleteAccount();
                if (context.mounted) {
                  context.go('/login');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    _buildSnackBar('회원탈퇴 실패: $e'),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  SnackBar _buildSnackBar(String message, {bool isSuccess = false}) {
    return SnackBar(
      content: Text(message),
      backgroundColor: isSuccess ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
    );
  }
}
