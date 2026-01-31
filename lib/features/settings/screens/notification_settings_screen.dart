import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../services/user_service.dart';

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
          icon: Icon(Icons.arrow_back, color: colorScheme.iconPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '알림 설정',
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
              _buildSectionTitle('서비스 알림', colorScheme),
              const SizedBox(height: 12),
              _buildNotiTile(
                context,
                '아침 일기 알림',
                '아침마다 일기 작성을 잊지 않도록 알려드려요',
                user.morningDiaryNoti,
                (val) => _updateNoti(
                    context, authController, {'morningDiaryNoti': val}),
                colorScheme,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('활동 알림', colorScheme),
              const SizedBox(height: 12),
              _buildNotiTile(
                context,
                '깨우기 알림',
                '친구가 나를 깨웠을 때 알림을 받아요',
                user.wakeUpNoti,
                (val) =>
                    _updateNoti(context, authController, {'wakeUpNoti': val}),
                colorScheme,
              ),
              const SizedBox(height: 8),
              _buildNotiTile(
                context,
                '응원 메시지 알림',
                '친구가 응원 메시지를 남겼을 때 알림을 받아요',
                user.cheerMessageNoti,
                (val) => _updateNoti(
                    context, authController, {'cheerMessageNoti': val}),
                colorScheme,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('친구 알림', colorScheme),
              const SizedBox(height: 12),
              _buildNotiTile(
                context,
                '친구 요청 알림',
                '새로운 친구 요청이 오면 알려드려요',
                user.friendRequestNoti,
                (val) => _updateNoti(
                    context, authController, {'friendRequestNoti': val}),
                colorScheme,
              ),
              const SizedBox(height: 8),
              _buildNotiTile(
                context,
                '친구 수락 알림',
                '상대방이 내 친구 요청을 수락하면 알려드려요',
                user.friendAcceptNoti,
                (val) => _updateNoti(
                    context, authController, {'friendAcceptNoti': val}),
                colorScheme,
              ),
              const SizedBox(height: 8),
              _buildNotiTile(
                context,
                '친구 거절 알림',
                '내 친구 요청이 거절되었을 때 알림을 받아요',
                user.friendRejectNoti,
                (val) => _updateNoti(
                    context, authController, {'friendRejectNoti': val}),
                colorScheme,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, AppColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: colorScheme.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.textPrimary,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: TextStyle(
              color: colorScheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: colorScheme.primaryButton,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('설정 저장 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }
}
