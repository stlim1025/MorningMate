import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:nanoid/nanoid.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../controllers/auth_controller.dart';
import '../../notification/controllers/notification_controller.dart';
import '../../../../services/user_service.dart';

class NicknameSetupScreen extends StatefulWidget {
  const NicknameSetupScreen({super.key});

  @override
  State<NicknameSetupScreen> createState() => _NicknameSetupScreenState();
}

class _NicknameSetupScreenState extends State<NicknameSetupScreen> {
  final _nicknameController = TextEditingController();
  final _referralController = TextEditingController();
  bool _isLoading = false;
  String? _referralError;

  @override
  void dispose() {
    _nicknameController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  Future<String?> _getDeviceId(String userId) async {
    if (kIsWeb) return 'web_${userId.substring(0, 5)}';
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    try {
      if (io.Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (io.Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor;
      }
    } catch (e) {
      debugPrint('Failed to get device ID: $e');
    }
    return null;
  }

  Future<void> _submit() async {
    final nickname = _nicknameController.text.trim();
    final referralCodeInput = _referralController.text.trim();

    if (nickname.isEmpty || nickname.length < 2) {
      if (!mounted) return;
      AppDialog.show(
        context: context,
        key: AppDialogKey.changeNickname,
        content: const Text('닉네임은 2자 이상이어야 합니다.'),
        actions: [
          AppDialogAction(
            label: '확인',
            onPressed: (context) => Navigator.pop(context),
            isPrimary: true,
          ),
        ],
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _referralError = null;
    });

    try {
      final authController = context.read<AuthController>();
      final userService = context.read<UserService>();
      final currentUserModel = authController.userModel;

      if (currentUserModel == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다.');
      }

      final userId = currentUserModel.uid;

      // 1. Nickname duplicate check
      if (nickname != currentUserModel.nickname) {
        final isAvailable = await userService.isNicknameAvailable(nickname);
        if (!isAvailable) {
          if (!mounted) return;
          AppDialog.show(
            context: context,
            key: AppDialogKey.changeNickname,
            content: const Text('이미 사용 중인 닉네임입니다.'),
            actions: [
              AppDialogAction(
                label: '확인',
                onPressed: (context) => Navigator.pop(context),
                isPrimary: true,
              ),
            ],
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      String? validReferralUid;
      // 2. Referral logic
      if (referralCodeInput.isNotEmpty) {
        // Find user by referral code
        final inviterUser =
            await userService.getUserByReferralCode(referralCodeInput);
        if (inviterUser == null) {
          if (!mounted) return;
          setState(() {
            _referralError = '유효하지 않은 추천인 코드입니다.';
            _isLoading = false;
          });
          return;
        }

        // Self-referral check
        if (inviterUser.uid == userId) {
          if (!mounted) return;
          setState(() {
            _referralError = '자신의 코드는 입력할 수 없습니다.';
            _isLoading = false;
          });
          return;
        }

        // Referral limit check
        final referralCount =
            await userService.getReferralCount(inviterUser.uid);
        if (referralCount >= 5) {
          if (!mounted) return;
          setState(() {
            _referralError = '만료된 추천인 코드입니다. (초대 보상 한도 초과)';
            _isLoading = false;
          });
          return;
        }

        // Device farming check
        final deviceId = await _getDeviceId(userId);
        if (deviceId != null) {
          final isUsed =
              await userService.hasDeviceBeenUsedForReferral(deviceId);
          if (isUsed) {
            if (!mounted) return;
            // Prevent multiple accounts on same device from claiming referral
            AppDialog.show(
              context: context,
              key: AppDialogKey.changeNickname,
              content: const Text('이 기기에서는 이미 추천인 혜택을 받았습니다.'),
              actions: [
                AppDialogAction(
                  label: '확인',
                  onPressed: (context) => Navigator.pop(context),
                  isPrimary: true,
                ),
              ],
            );
            await _completeSetupWithoutReferral(
                userId, nickname, userService, authController, deviceId);
            setState(() => _isLoading = false);
            return;
          }
          await userService.registerDeviceForReferral(deviceId, userId);
        }
        validReferralUid = inviterUser.uid;
      }

      // Referral points distribution
      if (validReferralUid != null) {
        // Reward both users. For instance, 100 points
        try {
          final inviter = await userService.getUser(validReferralUid);
          if (inviter != null) {
            await userService
                .updateUser(validReferralUid, {'points': inviter.points + 100});

            // 추천인 보상 알림 전송 (주인에게)
            if (mounted) {
              final notificationController =
                  context.read<NotificationController>();
              await notificationController.sendReferralNotification(
                receiverId: validReferralUid,
                senderId: userId,
                senderNickname: nickname,
                pointAmount: 100,
              );
            }
          }
          // We also increase points of the new user by 100
          await userService
              .updateUser(userId, {'points': currentUserModel.points + 100});
        } catch (e) {
          debugPrint('Failed to give points: $e');
        }
      }

      // 3. Generate new referral code for this user
      final myReferralCode =
          customAlphabet('ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789', 8);

      await userService.updateUser(userId, {
        'nickname': nickname,
        'isSetupComplete': true,
        'referralCode': myReferralCode,
        if (validReferralUid != null) 'referredBy': validReferralUid,
      });

      // Update auth controller state
      authController.updateUserModel(
        currentUserModel.copyWith(
          nickname: nickname,
          isSetupComplete: true,
          referralCode: myReferralCode,
          referredBy: validReferralUid,
          points:
              currentUserModel.points + (validReferralUid != null ? 100 : 0),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AppDialog.show(
        context: context,
        key: AppDialogKey.changeNickname,
        content: Text('오류가 발생했습니다: $e'),
        actions: [
          AppDialogAction(
            label: '확인',
            onPressed: (context) => Navigator.pop(context),
            isPrimary: true,
          ),
        ],
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _completeSetupWithoutReferral(
      String userId,
      String nickname,
      UserService userService,
      AuthController authController,
      String? deviceId) async {
    final currentUserModel = authController.userModel!;
    final myReferralCode =
        customAlphabet('ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789', 8);

    await userService.updateUser(userId, {
      'nickname': nickname,
      'isSetupComplete': true,
      'referralCode': myReferralCode,
    });

    authController.updateUserModel(
      currentUserModel.copyWith(
        nickname: nickname,
        isSetupComplete: true,
        referralCode: myReferralCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/Diary_Background.png'),
            fit: BoxFit.fill,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    Image.asset(
                      'assets/icons/Charactor_Icon.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 60),
                    Text(
                      '환영합니다!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF5F5F0),
                        fontFamily: 'BMJUA',
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '사용하실 닉네임과 추천인 코드를 입력해주세요.',
                      style: TextStyle(
                        fontSize: 16,
                        color: const Color(0xFFF5F5F0),
                        fontFamily: 'BMJUA',
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(0, 1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 60),
                    Text(
                      '닉네임',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF5F5F0),
                        fontFamily: 'BMJUA',
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(0, 1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    PopupTextField(
                      controller: _nicknameController,
                      maxLength: 15,
                      hintText: '닉네임을 입력하세요',
                      fontFamily: 'KyoboHandwriting2024psw',
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '추천인 코드 (선택)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF5F5F0),
                        fontFamily: 'BMJUA',
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(0, 1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    PopupTextField(
                      controller: _referralController,
                      hintText: '추천인 코드가 있다면 입력해주세요 (혜택 제공)',
                      fontFamily: 'KyoboHandwriting2024psw',
                    ),
                    if (_referralError != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 8.0),
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDD8D8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFD32F2F).withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          _referralError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFD32F2F),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'BMJUA',
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '나와 친구가 같이 ',
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color(0xFFF5F5F0),
                            fontFamily: 'BMJUA',
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                offset: const Offset(0, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                        Image.asset(
                          'assets/images/branch.png',
                          width: 18,
                          height: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '100개 받아요!',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFF5F5F0),
                            fontFamily: 'BMJUA',
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                offset: const Offset(0, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 60),
                    GestureDetector(
                      onTap: _isLoading ? null : _submit,
                      child: Opacity(
                        opacity: _isLoading ? 0.6 : 1.0,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              'assets/images/Confirm_Button.png',
                              width: double.infinity,
                              height: 60,
                              fit: BoxFit.fill,
                            ),
                            _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFF4E342E)),
                                    ),
                                  )
                                : const Text(
                                    '시작하기',
                                    style: TextStyle(
                                      fontFamily: 'BMJUA',
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4E342E),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 뒤로가기 버튼 (로그아웃) - 맨 마지막에 배치하여 클릭 우선순위 최상위로
              Positioned(
                top: 10,
                left: 10,
                child: GestureDetector(
                  onTap: () => context.read<AuthController>().signOut(),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Image.asset(
                          'assets/icons/X_Button.png',
                          width: 55,
                          height: 55,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
