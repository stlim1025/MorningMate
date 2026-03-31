import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/memo_notification.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../social/controllers/social_controller.dart';
import '../../social/controllers/nest_controller.dart';
import '../../character/controllers/character_controller.dart';
import '../../morning/controllers/morning_controller.dart';
import '../../../services/user_service.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/language_provider.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

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
                fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA',
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
                  padding: EdgeInsets.all(20),
                  children: [
                    // 계정 설정
                    _buildSectionTitle(
                        AppLocalizations.of(context)?.get('account') ??
                            'Account',
                        colorScheme),
                    SizedBox(height: 12),
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
                          onTap: () async {
                            if (authController.isLoading) return;
                            if (user?.isAnonymous ?? false) {
                              final provider = await AppDialog.show<String>(
                                context: context,
                                key: AppDialogKey.guestMigration,
                                title: AppLocalizations.of(context)
                                        ?.get('availableAfterSocialLogin') ??
                                    '소셜 로그인 후 이용 가능합니다',
                              );

                              if (provider != null && context.mounted) {
                                try {
                                  await authController
                                      .linkWithSocialProvider(provider);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('성공적으로 계정이 연결되었습니다!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('계정 연결 실패: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                              return;
                            }
                            _showChangeNicknameDialog(
                                context, user?.nickname ?? '', colorScheme);
                          },
                        ),
                        _buildDivider(colorScheme),
                        _buildSettingsTile(
                          context,
                          colorScheme,
                          icon: Icons.email,
                          title: AppLocalizations.of(context)?.get('email') ??
                              'Email',
                          subtitle: user?.isAnonymous ?? false
                              ? (AppLocalizations.of(context)
                                      ?.get('guestLogin') ??
                                  'Guest Login')
                              : (user?.email ?? '').startsWith('kakao_')
                                  ? (AppLocalizations.of(context)
                                          ?.get('kakaoLogin') ??
                                      'Kakao Login')
                                  : ((user?.email ?? '').startsWith('apple_') ||
                                          (user?.email ?? '')
                                              .contains('privaterelay.appleid.com'))
                                      ? (AppLocalizations.of(context)
                                              ?.get('appleLogin') ??
                                          'Apple Login')
                                      : user?.email ?? '',
                          onTap: null,
                        ),
                        if (user?.referralCode != null) ...[
                          _buildDivider(colorScheme),
                          _buildSettingsTile(
                            context,
                            colorScheme,
                            icon: Icons.card_giftcard,
                            title: AppLocalizations.of(context)
                                    ?.get('myReferralCode') ??
                                'My Referral Code',
                            subtitle: '${user?.referralCode ?? ''}',
                            trailingIcon: Icons.copy,
                            onTap: () async {
                              await Clipboard.setData(
                                  ClipboardData(text: user!.referralCode!));
                              if (context.mounted) {
                                MemoNotification.show(
                                    context,
                                    AppLocalizations.of(context)
                                            ?.get('referralCodeCopied') ??
                                        'Referral code copied.');
                              }
                            },
                          ),
                        ],
                      ],
                    ),

                    SizedBox(height: 12),

                    // 보안 설정
                    _buildSectionTitle(
                        AppLocalizations.of(context)?.get('security') ??
                            'Security',
                        colorScheme),
                    SizedBox(height: 12),
                    _buildOptionArea(
                      context,
                      children: [
                        if (user?.isAnonymous ?? false)
                          _buildSettingsTile(
                            context,
                            colorScheme,
                            icon: Icons.lock_outline,
                            title: AppLocalizations.of(context)
                                    ?.get('availableAfterSocialLogin') ??
                                'Available after social login',
                            onTap: null,
                          )
                        else ...[
                          _buildBiometricTile(
                              context, authController, colorScheme),
                          if (user?.provider != 'kakao' &&
                              user?.provider != 'google' &&
                              user?.provider != 'apple' &&
                              !(authController.currentUser?.providerData.any(
                                      (p) => p.providerId != 'password') ??
                                  false)) ...[
                            _buildDivider(colorScheme),
                            _buildSettingsTile(
                              context,
                              colorScheme,
                              icon: Icons.lock,
                              title: AppLocalizations.of(context)
                                      ?.get('changePassword') ??
                                  'Change Password',
                              onTap: () => _showChangePasswordDialog(
                                  context, colorScheme),
                            ),
                          ],
                        ],
                      ],
                    ),

                    SizedBox(height: 12),

                    // 앱 설정
                    _buildSectionTitle(
                        AppLocalizations.of(context)?.get('appSettings') ??
                            'App Settings',
                        colorScheme),
                    SizedBox(height: 12),
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
                              Localizations.localeOf(context).languageCode == 'ko'
                                  ? '한국어'
                                  : Localizations.localeOf(context).languageCode == 'ja'
                                      ? '日本語'
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

                    SizedBox(height: 12),

                    // 정보
                    _buildSectionTitle(
                        AppLocalizations.of(context)?.get('info') ?? 'Info',
                        colorScheme),
                    SizedBox(height: 12),
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
                          icon: Icons.help_outline,
                          title: AppLocalizations.of(context)?.get('faq') ?? 'FAQ',
                          onTap: () => context.pushNamed('faq'),
                        ),
                        _buildDivider(colorScheme),
                        _buildSettingsTile(
                          context,
                          colorScheme,
                          icon: Icons.mail_outline,
                          title: AppLocalizations.of(context)?.get('support') ?? 'Contact Us',
                          onTap: () => _sendSupportEmail(context, authController),
                        ),
                        _buildDivider(colorScheme),
                        _buildSettingsTile(
                          context,
                          colorScheme,
                          icon: Icons.description,
                          title: AppLocalizations.of(context)?.get('termsAndPrivacy') ?? 'Terms & Privacy',
                          onTap: () {
                            context.pushNamed('termsOfService');
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

  Widget _buildSectionTitle(String title, AppColorScheme colorScheme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Transform.translate(
        offset: Offset(-10, 0),
        child: Container(
          width: 120,
          height: 32,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/icons/Store_Tab.png'),
              fit: BoxFit.fill,
            ),
          ),
          alignment: Alignment.center,
          child: Padding(
            padding: EdgeInsets.only(left: 20),
            child: Text(
              title,
              style: TextStyle(
                color: Color(0xFF4E342E),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA',
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
    IconData? trailingIcon,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
              fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA',
            ),
      ),
      subtitle: subtitle != null
          ? Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                subtitle,
                style: TextStyle(
                  color: colorScheme.textSecondary,
                  fontSize: 13,
                  fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA',
                ),
              ),
            )
          : null,
      trailing: onTap != null
          ? Icon(
              trailingIcon ?? Icons.chevron_right,
              color: colorScheme.textSecondary.withOpacity(0.5),
              size: trailingIcon != null ? 20 : 24,
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
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
              fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA',
            ),
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(top: 4),
        child: Text(
          blurEnabled
              ? (AppLocalizations.of(context)?.get('writingBlurDescEnabled') ??
                  'Blur writing by default')
              : (AppLocalizations.of(context)?.get('writingBlurDescDisabled') ??
                  'Show writing by default'),
          style: TextStyle(
            color: colorScheme.textSecondary,
            fontSize: 13,
            fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA',
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
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
              fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA',
            ),
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(top: 4),
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
            fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA',
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
        decoration: BoxDecoration(
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
              Icon(Icons.logout, size: 20, color: Color(0xFF5D4037)),
              SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)?.get('logout') ?? 'Logout',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA',
                  color: const Color(0xFF5D4037),
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
          style: TextStyle(
            color: Color(0xFF5D4037),
            decoration: TextDecoration.underline,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA',
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
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: PopupTextField(
              controller: controller,
              hintText: AppLocalizations.of(context)?.get('enterNewNickname') ??
                  'Enter new nickname',
              maxLength: 15,
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
            image: DecorationImage(
              image: AssetImage('assets/images/Memo.png'),
              fit: BoxFit.fill,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.only(
                    top: 36, left: 16, right: 16, bottom: 16),
                child: Text(
                  AppLocalizations.of(context)?.get('selectLanguage') ??
                      'Select Language',
                  style: TextStyle(
                    fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.textPrimary,
                  ),
                ),
              ),
              ListTile(
                title: Text(
                  AppLocalizations.of(context)?.get('korean') ?? '한국어',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.textPrimary,
                        fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA',
                      ),
                ),
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
                title: Text(
                  AppLocalizations.of(context)?.get('english') ?? 'English',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.textPrimary,
                        fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA',
                      ),
                ),
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
              ListTile(
                title: Text(
                  '日本語',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.textPrimary,
                        fontFamily: 'KiwiMaru',
                      ),
                ),
                trailing: Localizations.localeOf(context).languageCode == 'ja'
                    ? Icon(Icons.check, color: colorScheme.primaryButton)
                    : null,
                onTap: () {
                  context
                      .read<LanguageProvider>()
                      .setLocale(const Locale('ja'));
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 20),
              SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
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
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: PopupTextField(
                controller: currentPasswordController,
                obscureText: true,
                hintText:
                    AppLocalizations.of(context)?.get('currentPassword') ??
                        'Current Password',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(context)
                            ?.get('currentPasswordRequired') ??
                        'Please enter current password';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: PopupTextField(
                controller: newPasswordController,
                obscureText: true,
                hintText:
                    AppLocalizations.of(context)?.get('newPasswordHint') ??
                        'New Password (min 6 chars)',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(context)
                            ?.get('newPasswordRequired') ??
                        'Please enter new password';
                  }
                  if (value.trim().length < 6) {
                    return AppLocalizations.of(context)
                            ?.get('passwordLengthError') ??
                        'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: PopupTextField(
                controller: confirmPasswordController,
                obscureText: true,
                hintText:
                    AppLocalizations.of(context)?.get('passwordConfirmHint') ??
                        'Confirm Password',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(context)
                            ?.get('passwordConfirmRequired') ??
                        'Please confirm new password';
                  }
                  if (value != newPasswordController.text) {
                    return AppLocalizations.of(context)
                            ?.get('passwordMismatch') ??
                        'Passwords do not match';
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
                    _buildSnackBar(
                        AppLocalizations.of(context)
                                ?.get('passwordChangedSuccess') ??
                            'Password successfully changed',
                        colorScheme,
                        isSuccess: true),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  String errorMessage =
                      AppLocalizations.of(context)?.get('errorOccurred') ??
                          'An error occurred';
                  if (e is FirebaseAuthException) {
                    switch (e.code) {
                      case 'wrong-password':
                      case 'invalid-credential':
                        errorMessage = AppLocalizations.of(context)
                                ?.get('currentPasswordMismatch') ??
                            'Current password does not match';
                        break;
                      case 'requires-recent-login':
                        errorMessage = AppLocalizations.of(context)
                                ?.get('requireRecentLogin') ??
                            'Please log in again for security';
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

            // 모든 컨트롤러 상태 초기화 (signOut 이후 실행해야 Firestore 스트림의
            // onError 핸들러가 permission-denied를 정상 처리함)
            if (context.mounted) {
              context.read<SocialController>().clear();
              context.read<NestController>().clear();
              context.read<CharacterController>().clear();
              context.read<MorningController>().clear();
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
          SizedBox(height: 16),
          if (authController.userModel?.provider != 'kakao' &&
              authController.userModel?.provider != 'google' &&
              authController.userModel?.provider != 'apple' &&
              !(authController.currentUser?.providerData
                      .any((p) => p.providerId != 'password') ??
                  false)) ...[
            PopupTextField(
              controller: passwordController,
              obscureText: true,
              hintText:
                  AppLocalizations.of(context)?.get('passwordConfirmHint') ??
                      '비밀번호 확인',
            ),
            const SizedBox(height: 16),
          ],
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
                    SizedBox(width: 8),
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
            final provider = authController.userModel?.provider;
            final isSocialUser = provider == 'kakao' ||
                provider == 'google' ||
                provider == 'apple' ||
                (authController.currentUser?.providerData
                        .any((p) => p.providerId != 'password') ??
                    false);
            final isEmailUser = !isSocialUser;
            final password = passwordController.text.trim();
            AppDialog.showError(context, null);

            if (isEmailUser && password.isEmpty) {
              AppDialog.showError(
                  context,
                  AppLocalizations.of(context)?.get('passwordRequired') ??
                      '비밀번호를 입력해주세요');
              return;
            }

            try {
              await authController.deleteAccount(isEmailUser ? password : null);
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

  Future<void> _sendSupportEmail(BuildContext context, AuthController authController) async {
    final user = authController.userModel;
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceInfo = DeviceInfoPlugin();
    
    String os = '';
    String model = '';
    
    if (!kIsWeb && Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      os = 'Android ${androidInfo.version.release}';
      model = androidInfo.model;
    } else if (!kIsWeb && Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      os = 'iOS ${iosInfo.systemVersion}';
      model = iosInfo.utsname.machine;
    } else if (kIsWeb) {
      os = 'Web';
      model = 'Browser';
    }

    final email = 'stlim1026@gmail.com';
    final subject = '[Morni 문의사항]';
    final body = '''
닉네임: ${user?.nickname ?? 'Guest'}
OS: $os
앱 버전: ${packageInfo.version}
핸드폰 기기: $model

-----------------------------------
내용:
''';

    final Uri uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('메일 앱을 열 수 없습니다.')),
        );
      }
    }
  }
}
