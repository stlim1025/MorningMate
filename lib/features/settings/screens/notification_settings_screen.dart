import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../services/user_service.dart';
import '../../../core/widgets/memo_notification.dart';
import '../../../core/localization/app_localizations.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Image.asset(
            'assets/icons/X_Button.png',
            width: 40,
            height: 40,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)?.get('notificationSettings') ??
              'Notification Settings',
          style: TextStyle(
            color: colorScheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<AuthController>(
        builder: (context, authController, child) {
          final user = authController.userModel;
          if (user == null) return const SizedBox.shrink();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildSectionTitle(
                  AppLocalizations.of(context)?.get('serviceNotification') ??
                      'Service Notifications',
                  colorScheme),
              const SizedBox(height: 12),
              _buildOptionArea(
                context,
                children: [
                  _buildNotiTile(
                    context,
                    AppLocalizations.of(context)?.get('morningDiaryNoti') ??
                        'Morning Diary Alert',
                    AppLocalizations.of(context)?.get('morningDiaryNotiDesc') ??
                        'Remind you to write diary every morning',
                    user.morningDiaryNoti,
                    (val) => _updateNoti(
                        context, authController, {'morningDiaryNoti': val}),
                    colorScheme,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(
                  AppLocalizations.of(context)?.get('activityNotification') ??
                      'Activity Notifications',
                  colorScheme),
              const SizedBox(height: 12),
              _buildOptionArea(
                context,
                children: [
                  _buildNotiTile(
                    context,
                    AppLocalizations.of(context)?.get('wakeUpNoti') ??
                        'Wake Up Alert',
                    AppLocalizations.of(context)?.get('wakeUpNotiDesc') ??
                        'Get notified when a friend wakes you up',
                    user.wakeUpNoti,
                    (val) => _updateNoti(
                        context, authController, {'wakeUpNoti': val}),
                    colorScheme,
                  ),
                  _buildDivider(colorScheme),
                  _buildNotiTile(
                    context,
                    AppLocalizations.of(context)?.get('cheerMessageNoti') ??
                        'Cheer Message Alert',
                    AppLocalizations.of(context)?.get('cheerMessageNotiDesc') ??
                        'Get notified when a friend sends a cheer',
                    user.cheerMessageNoti,
                    (val) => _updateNoti(
                        context, authController, {'cheerMessageNoti': val}),
                    colorScheme,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(
                  AppLocalizations.of(context)?.get('friendNotification') ??
                      'Friend Notifications',
                  colorScheme),
              const SizedBox(height: 12),
              _buildOptionArea(
                context,
                children: [
                  _buildNotiTile(
                    context,
                    AppLocalizations.of(context)?.get('friendRequestNoti') ??
                        'Friend Request Alert',
                    AppLocalizations.of(context)
                            ?.get('friendRequestNotiDesc') ??
                        'Get notified of new friend requests',
                    user.friendRequestNoti,
                    (val) => _updateNoti(
                        context, authController, {'friendRequestNoti': val}),
                    colorScheme,
                  ),
                  _buildDivider(colorScheme),
                  _buildNotiTile(
                    context,
                    AppLocalizations.of(context)?.get('friendAcceptNoti') ??
                        'Friend Accept Alert',
                    AppLocalizations.of(context)?.get('friendAcceptNotiDesc') ??
                        'Get notified when your request is accepted',
                    user.friendAcceptNoti,
                    (val) => _updateNoti(
                        context, authController, {'friendAcceptNoti': val}),
                    colorScheme,
                  ),
                  _buildDivider(colorScheme),
                  _buildNotiTile(
                    context,
                    AppLocalizations.of(context)?.get('friendRejectNoti') ??
                        'Friend Reject Alert',
                    AppLocalizations.of(context)?.get('friendRejectNotiDesc') ??
                        'Get notified when your request is rejected',
                    user.friendRejectNoti,
                    (val) => _updateNoti(
                        context, authController, {'friendRejectNoti': val}),
                    colorScheme,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, AppColorScheme colorScheme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Transform.translate(
        offset: const Offset(-10, 0),
        child: Container(
          width: 140, // Increased from 120
          height: 42, // Increased from 32 to prevent clipping
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/icons/Store_Tab.png'),
              fit: BoxFit.fill,
            ),
          ),
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                45, 2, 16, 0), // Increased left padding from 20 to 32
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF4E342E),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'BMJUA',
                height: 1.1, // Adjusted line height
              ),
              maxLines: 2,
              overflow: TextOverflow.visible,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotiTile(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    AppColorScheme colorScheme,
  ) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: colorScheme.textPrimary,
          fontSize: 16,
          fontFamily: 'BMJUA',
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: TextStyle(
            color: colorScheme.textSecondary,
            fontSize: 13,
            fontFamily: 'BMJUA',
          ),
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: colorScheme.primaryButton,
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
      padding: const EdgeInsets.only(top: 30, bottom: 12),
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

  Future<void> _updateNoti(
    BuildContext context,
    AuthController authController,
    Map<String, dynamic> data,
  ) async {
    final userService = context.read<UserService>();
    final userId = authController.currentUser?.uid;
    if (userId == null) return;

    try {
      await userService.updateUser(userId, data);

      // 로컬 모델 업데이트
      final currentModel = authController.userModel!;
      authController.updateUserModel(
        currentModel.copyWith(
          morningDiaryNoti: data['morningDiaryNoti'],
          wakeUpNoti: data['wakeUpNoti'],
          cheerMessageNoti: data['cheerMessageNoti'],
          friendRequestNoti: data['friendRequestNoti'],
          friendAcceptNoti: data['friendAcceptNoti'],
          friendRejectNoti: data['friendRejectNoti'],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        MemoNotification.show(context,
            '${AppLocalizations.of(context)?.get('errorSavingSettings') ?? 'Error saving settings: '} ⚠️');
      }
    }
  }
}
