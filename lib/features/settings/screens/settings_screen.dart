import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/memo_notification.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../services/user_service.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/language_provider.dart';

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
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Image.asset(
            'assets/icons/X_Button.png',
            width: 40,
            height: 40,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          AppLocalizations.of(context)?.get('settings') ?? 'Settings',
          style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
                color: colorScheme.textPrimary,
                fontFamily: 'BMJUA',
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/Diary_Background.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Consumer<AuthController>(
              builder: (context, authController, child) {
                final user = authController.userModel;

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // 계정 설정
                    _buildSectionTitle(
                        AppLocalizations.of(context)?.get('account') ??
                            'Account',
                        colorScheme),
                    const SizedBox(height: 12),
                    _buildOptionArea(
                      context,
                      children: [
                        _buildSettingsTile(
                          context,
                          colorScheme,
                          icon: Icons.person,
                          title: AppLocalizations.of(context)
                                  ?.get('changeNickname') ??
                              'Change Nickname',
                          subtitle: user?.nickname ?? '',
                          onTap: () => _showChangeNicknameDialog(
                              context, user?.nickname ?? '', colorScheme),
                        ),
                        _buildDivider(colorScheme),
                        _buildSettingsTile(
                          context,
                          colorScheme,
                          icon: Icons.email,
                          title: AppLocalizations.of(context)?.get('email') ??
                              'Email',
                          subtitle: (user?.email?.startsWith('kakao_') ?? false)
                              ? '카카오 로그인'
                              : (user?.email?.startsWith('apple_') ??
                                      false) // 애플 로그인도 비슷하게 처리할 수 있다면 추가
                                  ? 'Apple 로그인'
                                  : user?.email ?? '',
                          onTap: null,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // 보안 설정
                    _buildSectionTitle(
                        AppLocalizations.of(context)?.get('security') ??
                            'Security',
                        colorScheme),
                    const SizedBox(height: 12),
                    _buildOptionArea(
                      context,
                      children: [
                        _buildBiometricTile(
                            context, authController, colorScheme),
                        _buildDivider(colorScheme),
                        _buildSettingsTile(
                          context,
                          colorScheme,
                          icon: Icons.lock,
                          title: AppLocalizations.of(context)
                                  ?.get('changePassword') ??
                              'Change Password',
                          onTap: () =>
                              _showChangePasswordDialog(context, colorScheme),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // 앱 설정
                    _buildSectionTitle(
                        AppLocalizations.of(context)?.get('appSettings') ??
                            'App Settings',
                        colorScheme),
                    const SizedBox(height: 12),
                    _buildOptionArea(
                      context,
                      children: [
                        _buildWritingBlurTile(
                            context, authController, colorScheme),
                        _buildDivider(colorScheme),
                        _buildSettingsTile(
                          context,
                          colorScheme,
                          icon: Icons.language,
                          title:
                              AppLocalizations.of(context)?.get('language') ??
                                  'Language',
                          subtitle:
                              Localizations.localeOf(context).languageCode ==
                                      'ko'
                                  ? '한국어'
                                  : 'English',
                          onTap: () =>
                              _showLanguageDialog(context, colorScheme),
                        ),
                        _buildDivider(colorScheme),
                        _buildSettingsTile(
                          context,
                          colorScheme,
                          icon: Icons.notifications,
                          title: AppLocalizations.of(context)
                                  ?.get('notificationSettings') ??
                              'Notification Settings',
                          onTap: () {
                            context.pushNamed('notificationSettings');
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // 정보
                    _buildSectionTitle(
                        AppLocalizations.of(context)?.get('info') ?? 'Info',
                        colorScheme),
                    const SizedBox(height: 12),
                    _buildOptionArea(
                      context,
                      children: [
                        _buildSettingsTile(
                          context,
                          colorScheme,
                          icon: Icons.info,
                          title: AppLocalizations.of(context)
                                  ?.get('versionInfo') ??
                              'Version Info',
                          subtitle: _version.isEmpty ? 'Loading...' : _version,
                          onTap: null,
                        ),
                        _buildDivider(colorScheme),
                        _buildSettingsTile(
                          context,
                          colorScheme,
                          icon: Icons.description,
                          title: AppLocalizations.of(context)
                                  ?.get('termsOfService') ??
                              'Terms of Service',
                          onTap: () {
                            context.pushNamed('termsOfService');
                          },
                        ),
                        _buildDivider(colorScheme),
                        _buildSettingsTile(
                          context,
                          colorScheme,
                          icon: Icons.privacy_tip,
                          title: AppLocalizations.of(context)
                                  ?.get('privacyPolicy') ??
                              'Privacy Policy',
                          onTap: () {
                            context.pushNamed('privacyPolicy');
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // 로그아웃 버튼
                    _buildLogoutButton(context, authController, colorScheme),

                    const SizedBox(height: 16),

                    // 회원탈퇴
                    _buildDeleteAccountButton(
                        context, authController, colorScheme),

                    const SizedBox(height: 40),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(
      BuildContext context, user, AppColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.cardAccent.withOpacity(0.8),
                  colorScheme.secondaryButton.withOpacity(0.8),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.cardAccent.withOpacity(0.3),
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
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colorScheme.textPrimary,
                      ),
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
                        color: colorScheme.cardAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Lv. ${user?.characterLevel ?? 1}',
                        style: TextStyle(
                          color: colorScheme.cardAccent,
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
                        color: colorScheme.twig.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/branch.png',
                            width: 14,
                            height: 14,
                            cacheWidth: 56,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${user?.points ?? 0}',
                            style: TextStyle(
                              color: colorScheme.textPrimary,
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

  Widget _buildSectionTitle(String title, AppColorScheme colorScheme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Transform.translate(
        offset: const Offset(-10, 0),
        child: Container(
          width: 120,
          height: 32,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/icons/Store_Tab.png'),
              fit: BoxFit.fill,
            ),
          ),
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF4E342E),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'BMJUA',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    AppColorScheme colorScheme, {
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.iconPrimary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: colorScheme.iconPrimary, size: 24),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.textPrimary,
              fontFamily: 'BMJUA',
            ),
      ),
      subtitle: subtitle != null
          ? Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                subtitle,
                style: TextStyle(
                  color: colorScheme.textSecondary,
                  fontSize: 13,
                  fontFamily: 'BMJUA',
                ),
              ),
            )
          : null,
      trailing: onTap != null
          ? Icon(
              Icons.chevron_right,
              color: colorScheme.textSecondary.withOpacity(0.5),
            )
          : null,
      onTap: onTap,
    );
  }

  Widget _buildOptionArea(BuildContext context,
      {required List<Widget> children}) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/Option_Area.png'),
          fit: BoxFit.fill,
        ),
      ),
      padding: const EdgeInsets.only(top: 32, bottom: 15),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDivider(AppColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boxWidth = constraints.constrainWidth();
          const dashWidth = 3.0;
          const dashHeight = 1.0;
          final dashCount = (boxWidth / (2 * dashWidth)).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(dashCount, (_) {
              return SizedBox(
                width: dashWidth,
                height: dashHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF4E342E).withOpacity(0.2),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildWritingBlurTile(BuildContext context,
      AuthController authController, AppColorScheme colorScheme) {
    final user = authController.userModel;
    final blurEnabled = user?.writingBlurEnabled ?? true;

    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      secondary: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.iconPrimary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.visibility_off,
          color: colorScheme.iconPrimary,
          size: 24,
        ),
      ),
      title: Text(
        AppLocalizations.of(context)?.get('writingBlur') ??
            'Writing Blur Default',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.textPrimary,
              fontFamily: 'BMJUA',
            ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          blurEnabled
              ? (AppLocalizations.of(context)?.get('writingBlurDescEnabled') ??
                  'Blur writing by default')
              : (AppLocalizations.of(context)?.get('writingBlurDescDisabled') ??
                  'Show writing by default'),
          style: TextStyle(
            color: colorScheme.textSecondary,
            fontSize: 13,
            fontFamily: 'BMJUA',
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
                colorScheme,
              ),
      activeColor: colorScheme.primaryButton,
    );
  }

  Widget _buildBiometricTile(BuildContext context,
      AuthController authController, AppColorScheme colorScheme) {
    final user = authController.userModel;
    final biometricEnabled = user?.biometricEnabled ?? false;

    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      secondary: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.iconPrimary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.fingerprint,
          color: colorScheme.iconPrimary,
          size: 24,
        ),
      ),
      title: Text(
        AppLocalizations.of(context)?.get('biometricAuth') ?? 'Biometric Auth',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.textPrimary,
              fontFamily: 'BMJUA',
            ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          biometricEnabled
              ? (AppLocalizations.of(context)
                      ?.get('biometricAuthDescEnabled') ??
                  'Biometric auth required')
              : (AppLocalizations.of(context)
                      ?.get('biometricAuthDescDisabled') ??
                  'Protect app with biometric auth'),
          style: TextStyle(
            color: colorScheme.textSecondary,
            fontSize: 13,
            fontFamily: 'BMJUA',
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
                colorScheme,
              ),
      activeColor: colorScheme.primaryButton,
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthController authController,
      AppColorScheme colorScheme) {
    return GestureDetector(
      onTap: () => _showLogoutDialog(context, authController, colorScheme),
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/TextBox_Background.png'),
            fit: BoxFit.fill,
            filterQuality: FilterQuality.none,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout, size: 20, color: Color(0xFF5D4037)),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)?.get('logout') ?? 'Logout',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'BMJUA',
                  color: Color(0xFF5D4037),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteAccountButton(BuildContext context,
      AuthController authController, AppColorScheme colorScheme) {
    return Center(
      child: TextButton(
        onPressed: () =>
            _showDeleteAccountDialog(context, authController, colorScheme),
        child: Text(
          AppLocalizations.of(context)?.get('deleteAccount') ??
              'Delete Account',
          style: const TextStyle(
            color: Color(0xFF5D4037),
            decoration: TextDecoration.underline,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            fontFamily: 'BMJUA',
          ),
        ),
      ),
    );
  }

  Future<void> _showChangeNicknameDialog(BuildContext context,
      String currentNickname, AppColorScheme colorScheme) async {
    final controller = TextEditingController(text: currentNickname);
    final isCheckingNotifier = ValueNotifier<bool>(false);

    return AppDialog.show(
      context: context,
      key: AppDialogKey.changeNickname,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PopupTextField(
              controller: controller,
              hintText: AppLocalizations.of(context)?.get('enterNewNickname') ??
                  'Enter new nickname',
              maxLength: 10,
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: isCheckingNotifier,
            builder: (context, isChecking, child) {
              if (!isChecking) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primaryButton,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      actions: [
        AppDialogAction(
          label: AppLocalizations.of(context)?.get('cancel') ?? 'Cancel',
          onPressed: () => context.pop(),
        ),
        AppDialogAction(
          label: AppLocalizations.of(context)?.get('change') ?? 'Change',
          isPrimary: true,
          onPressed: (BuildContext context) async {
            final newNickname = controller.text.trim();
            AppDialog.showError(context, null); // Clear prev error

            if (newNickname.isEmpty || newNickname.length < 2) {
              AppDialog.showError(
                  context,
                  AppLocalizations.of(context)?.get('nicknameLengthError') ??
                      'Nickname must be at least 2 characters');
              return;
            }

            final authController = context.read<AuthController>();
            final userService = context.read<UserService>();
            final userId = authController.currentUser?.uid;

            if (userId != null) {
              try {
                if (newNickname != currentNickname) {
                  isCheckingNotifier.value = true;
                  final isAvailable =
                      await userService.isNicknameAvailable(newNickname);
                  isCheckingNotifier.value = false;

                  if (!isAvailable) {
                    AppDialog.showError(
                        context,
                        AppLocalizations.of(context)
                                ?.get('nicknameTakenError') ??
                            'Nickname is already taken');
                    return;
                  }
                }

                await userService.updateUser(userId, {
                  'nickname': newNickname,
                });

                authController.updateUserModel(
                  authController.userModel?.copyWith(nickname: newNickname),
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  MemoNotification.show(
                      context,
                      AppLocalizations.of(context)?.get('nicknameChanged') ??
                          'Nickname changed! ✨');
                }
              } catch (e) {
                if (context.mounted) {
                  isCheckingNotifier.value = false;
                  AppDialog.showError(context,
                      '${AppLocalizations.of(context)?.get('error') ?? 'Error'}: $e');
                }
              }
            }
          },
        ),
      ],
    );
  }

  Future<void> _updateWritingBlurSetting(
    BuildContext context,
    AuthController authController,
    bool value,
    AppColorScheme colorScheme,
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
        _buildSnackBar(
            '${AppLocalizations.of(context)?.get('errorSavingSettings') ?? 'Error saving settings: '}$e',
            colorScheme),
      );
    }
  }

  Future<void> _updateBiometricSetting(
    BuildContext context,
    AuthController authController,
    bool value,
    AppColorScheme colorScheme,
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
            _buildSnackBar('이 기기에서는 생체 인증을 사용할 수 없습니다', colorScheme),
          );
        }
        return;
      }

      final authenticated = await authController.authenticateWithBiometric();
      if (!authenticated) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            _buildSnackBar('생체 인증에 실패했습니다', colorScheme),
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
          _buildSnackBar('생체 인증 설정 저장 중 오류가 발생했습니다: $e', colorScheme),
        );
      }
    }
  }

  void _showLanguageDialog(BuildContext context, AppColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  AppLocalizations.of(context)?.get('selectLanguage') ??
                      'Select Language',
                  style: TextStyle(
                    fontFamily: 'BMJUA',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.textPrimary,
                  ),
                ),
              ),
              ListTile(
                title: const Text('한국어', style: TextStyle(fontFamily: 'BMJUA')),
                trailing: Localizations.localeOf(context).languageCode == 'ko'
                    ? Icon(Icons.check, color: colorScheme.primaryButton)
                    : null,
                onTap: () {
                  context
                      .read<LanguageProvider>()
                      .setLocale(const Locale('ko'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('English',
                    style: TextStyle(fontFamily: 'BMJUA')),
                trailing: Localizations.localeOf(context).languageCode == 'en'
                    ? Icon(Icons.check, color: colorScheme.primaryButton)
                    : null,
                onTap: () {
                  context
                      .read<LanguageProvider>()
                      .setLocale(const Locale('en'));
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showChangePasswordDialog(
      BuildContext context, AppColorScheme colorScheme) async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return AppDialog.show(
      context: context,
      key: AppDialogKey.changePassword,
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PopupTextField(
                controller: currentPasswordController,
                obscureText: true,
                hintText: '현재 비밀번호',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '현재 비밀번호를 입력해주세요';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PopupTextField(
                controller: newPasswordController,
                obscureText: true,
                hintText: '새 비밀번호 (6자 이상)',
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
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PopupTextField(
                controller: confirmPasswordController,
                obscureText: true,
                hintText: '비밀번호 확인',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '비밀번호 확인을 입력해주세요';
                  }
                  if (value != newPasswordController.text) {
                    return '비밀번호가 일치하지 않습니다';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        AppDialogAction(
          label: AppLocalizations.of(context)?.get('cancel') ?? 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        AppDialogAction(
          label: AppLocalizations.of(context)?.get('change') ?? 'Change',
          isPrimary: true,
          onPressed: (BuildContext context) async {
            AppDialog.showError(context, null);
            if (formKey.currentState?.validate() ?? false) {
              final authController = context.read<AuthController>();
              try {
                await authController.changePassword(
                  currentPasswordController.text.trim(),
                  newPasswordController.text.trim(),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    _buildSnackBar('비밀번호가 변경되었습니다', colorScheme,
                        isSuccess: true),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  String errorMessage = '오류가 발생했습니다';
                  if (e is FirebaseAuthException) {
                    switch (e.code) {
                      case 'wrong-password':
                      case 'invalid-credential':
                        errorMessage = '현재 비밀번호가 일치하지 않습니다';
                        break;
                      case 'requires-recent-login':
                        errorMessage = '보안을 위해 다시 로그인 후 시도해주세요';
                        break;
                      default:
                        errorMessage = e.message ?? errorMessage;
                    }
                  } else {
                    errorMessage = e.toString();
                  }
                  AppDialog.showError(context, errorMessage);
                }
              }
            }
          },
        ),
      ],
    );
  }

  Future<void> _showLogoutDialog(BuildContext context,
      AuthController authController, AppColorScheme colorScheme) async {
    return AppDialog.show(
      context: context,
      key: AppDialogKey.logout,
      actions: [
        AppDialogAction(
          label: AppLocalizations.of(context)?.get('cancel') ?? 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        AppDialogAction(
          label: AppLocalizations.of(context)?.get('logout') ?? 'Logout',
          isPrimary: true,
          onPressed: () async {
            await authController.signOut();
            if (context.mounted) {
              context.go('/login');
            }
          },
        ),
      ],
    );
  }

  Future<void> _showDeleteAccountDialog(BuildContext context,
      AuthController authController, AppColorScheme colorScheme) async {
    final passwordController = TextEditingController();
    final isCheckedNotifier = ValueNotifier<bool>(false);

    return AppDialog.show(
      context: context,
      key: AppDialogKey.deleteAccount,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            AppLocalizations.of(context)?.get('deleteAccountConfirmDesc') ??
                '정말로 탈퇴하시겠습니까?\n모든 데이터가 영구적으로 삭제됩니다.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          PopupTextField(
            controller: passwordController,
            obscureText: true,
            hintText:
                AppLocalizations.of(context)?.get('passwordConfirmHint') ??
                    '비밀번호 확인',
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<bool>(
            valueListenable: isCheckedNotifier,
            builder: (context, isChecked, child) {
              return InkWell(
                onTap: () => isCheckedNotifier.value = !isChecked,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => isCheckedNotifier.value = !isChecked,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isChecked
                              ? colorScheme.primaryButton
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isChecked
                                ? colorScheme.primaryButton
                                : colorScheme.textHint.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        child: isChecked
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)
                                ?.get('deleteAccountConsent') ??
                            '안내 사항을 모두 확인하였으며, 탈퇴에 동의합니다.',
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      actions: [
        AppDialogAction(
          label: AppLocalizations.of(context)?.get('cancel') ?? 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        AppDialogAction(
          label: AppLocalizations.of(context)?.get('deleteAccount') ??
              'Delete Account',
          isEnabled: isCheckedNotifier,
          onPressed: (BuildContext context) async {
            final password = passwordController.text.trim();
            AppDialog.showError(context, null);

            if (password.isEmpty) {
              AppDialog.showError(
                  context,
                  AppLocalizations.of(context)?.get('passwordRequired') ??
                      '비밀번호를 입력해주세요');
              return;
            }

            try {
              await authController.deleteAccount(password);
              if (context.mounted) {
                context.go('/login');
              }
            } on FirebaseAuthException catch (e) {
              if (context.mounted) {
                if (e.code == 'wrong-password' ||
                    e.code == 'invalid-credential') {
                  AppDialog.showError(context, '비밀번호가 틀렸습니다.');
                } else if (e.code == 'too-many-requests') {
                  AppDialog.showError(
                      context, '너무 많은 시도가 있었습니다. 잠시 후 다시 시도해주세요.');
                } else {
                  AppDialog.showError(context, '인증 오류: ${e.message}');
                }
              }
            } catch (e) {
              if (context.mounted) {
                AppDialog.showError(context, '탈퇴 중 오류가 발생했습니다.');
              }
              debugPrint('Account deletion error: $e');
            }
          },
        ),
      ],
    );
  }

  SnackBar _buildSnackBar(String message, AppColorScheme colorScheme,
      {bool isSuccess = false}) {
    return SnackBar(
      content: Text(message),
      backgroundColor: isSuccess ? colorScheme.success : colorScheme.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      duration: const Duration(seconds: 2),
    );
  }
}
