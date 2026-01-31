import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../notification/controllers/notification_controller.dart';

class ReplyDialog {
  static Future<void> show(
    BuildContext context, {
    required String receiverId,
    required String receiverNickname,
    String? notificationId, // 알림 읽음 처리를 위한 ID (선택)
    VoidCallback? onSuccess,
  }) async {
    final messageController = TextEditingController();
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;
    final authController = context.read<AuthController>();
    final notificationController = context.read<NotificationController>();

    return AppDialog.show(
      context: context,
      key: AppDialogKey.guestbook,
      content: TextField(
        controller: messageController,
        maxLines: 3,
        autofocus: true,
        style: TextStyle(color: colorScheme.textPrimary),
        decoration: InputDecoration(
          hintText: '$receiverNickname님께 답장하기',
          hintStyle: TextStyle(color: colorScheme.textHint),
          filled: true,
          fillColor: Theme.of(context).scaffoldBackgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      actions: [
        AppDialogAction(
          label: '취소',
          onPressed: () => Navigator.pop(context),
        ),
        AppDialogAction(
          label: '보내기',
          isPrimary: true,
          onPressed: () async {
            final message = messageController.text.trim();
            if (message.isEmpty) return;

            final userModel = authController.userModel;
            if (userModel == null) return;

            try {
              // 1. UI 즉시 반응: 다이얼로그 닫고 스낵바 표시
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$receiverNickname님께 답장을 보냈습니다! 💌'),
                  backgroundColor: colorScheme.success,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
              onSuccess?.call();

              // 2. 실제 작업은 백그라운드에서 수행
              unawaited(() async {
                try {
                  // 알림 읽음 및 답장 완료 처리
                  if (notificationId != null) {
                    await notificationController.markAsReplied(notificationId);
                  }

                  // FCM 발송 (Functions 호출)
                  final callable = FirebaseFunctions.instance
                      .httpsCallable('sendCheerMessage');
                  bool isPushSent = false;
                  try {
                    final result = await callable.call({
                      'userId': userModel.uid,
                      'friendId': receiverId,
                      'message': message,
                      'senderNickname': userModel.nickname,
                    });
                    if (result.data is Map && result.data['success'] == true) {
                      isPushSent = true;
                    }
                  } catch (e) {
                    debugPrint('답장 FCM 전송 오류: $e');
                  }

                  // DB 알림 생성
                  await notificationController.sendCheerMessage(
                    userModel.uid,
                    userModel.nickname,
                    receiverId,
                    message,
                    fcmSent: isPushSent,
                  );
                } catch (e) {
                  debugPrint('답장 백그라운드 작업 오류: $e');
                }
              }());
            } catch (e) {
              debugPrint('답장 처리 준비 오류: $e');
            }
          },
        ),
      ],
    );
  }
}
