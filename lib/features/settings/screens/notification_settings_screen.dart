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
          icon: Image.asset(
            'assets/icons/X_Button.png',
            width: 40,
            height: 40,
          ),
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
              _buildOptionArea(
                context,
                children: [
                  _buildNotiTile(
                    context,
                    '아침 일기 알림',
                    '아침마다 일기 작성을 잊지 않도록 알려드려요',
                    user.morningDiaryNoti,
                    (val) => _updateNoti(
                        context, authController, {'morningDiaryNoti': val}),
                    colorScheme,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('활동 알림', colorScheme),
              const SizedBox(height: 12),
              _buildOptionArea(
                context,
                children: [
                  _buildNotiTile(
                    context,
                    '깨우기 알림',
                    '친구가 나를 깨웠을 때 알림을 받아요',
                    user.wakeUpNoti,
                    (val) => _updateNoti(
                        context, authController, {'wakeUpNoti': val}),
                    colorScheme,
                  ),
                  _buildDivider(colorScheme),
                  _buildNotiTile(
                    context,
                    '응원 메시지 알림',
                    '친구가 응원 메시지를 남겼을 때 알림을 받아요',
                    user.cheerMessageNoti,
                    (val) => _updateNoti(
                        context, authController, {'cheerMessageNoti': val}),
                    colorScheme,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('친구 알림', colorScheme),
              const SizedBox(height: 12),
              _buildOptionArea(
                context,
                children: [
                  _buildNotiTile(
                    context,
                    '친구 요청 알림',
                    '새로운 친구 요청이 오면 알려드려요',
                    user.friendRequestNoti,
                    (val) => _updateNoti(
                        context, authController, {'friendRequestNoti': val}),
                    colorScheme,
                  ),
                  _buildDivider(colorScheme),
                  _buildNotiTile(
                    context,
                    '친구 수락 알림',
                    '상대방이 내 친구 요청을 수락하면 알려드려요',
                    user.friendAcceptNoti,
                    (val) => _updateNoti(
                        context, authController, {'friendAcceptNoti': val}),
                    colorScheme,
                  ),
                  _buildDivider(colorScheme),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('설정 저장 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }
}
