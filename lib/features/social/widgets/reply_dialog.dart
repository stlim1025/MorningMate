import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/localization/app_localizations.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../notification/controllers/notification_controller.dart';
import '../../../core/widgets/memo_notification.dart';

class ReplyDialog {
  static Future<void> show(
    BuildContext context, {
    required String receiverId,
    required String receiverNickname,
    String? notificationId, // 알림 읽음 처리를 위한 ID (선택)
    VoidCallback? onSuccess,
  }) async {
    final messageController = TextEditingController();
    final authController = context.read<AuthController>();
    final notificationController = context.read<NotificationController>();

    return AppDialog.show(
      context: context,
      key: AppDialogKey.guestbook,
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: PopupTextField(
          controller: messageController,
          hintText: AppLocalizations.of(context)?.getFormat('replyToHint', {'nickname': receiverNickname}) ?? '$receiverNickname님께 답장하기',
          maxLines: 3,
          fontFamily: 'KyoboHandwriting2024psw',
        ),
      ),
      actions: [
        AppDialogAction(
          label: AppLocalizations.of(context)?.get('cancel') ?? '취소',
          onPressed: () => Navigator.pop(context),
        ),
        AppDialogAction(
          label: AppLocalizations.of(context)?.get('sendReply') ?? '보내기',
          isPrimary: true,
          onPressed: () async {
            final message = messageController.text.trim();
            if (message.isEmpty) return;

            final userModel = authController.userModel;
            if (userModel == null) return;

            try {
              // 1. UI 즉시 반응: 다이얼로그 닫고 알림 표시
              Navigator.pop(context);
              MemoNotification.show(
                  context, AppLocalizations.of(context)?.getFormat('replySentSuccess', {'nickname': receiverNickname}) ?? '$receiverNickname님께 답장을 보냈습니다! 💌');
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
                  try {
                    await callable.call({
                      'userId': userModel.uid,
                      'friendId': receiverId,
                      'message': message,
                      'senderNickname': userModel.nickname,
                    });
                  } catch (e) {
                    debugPrint('답장 FCM 전송 오류: $e');
                  }

                  // DB 알림 생성
                  await notificationController.sendCheerMessage(
                    userModel.uid,
                    userModel.nickname,
                    receiverId,
                    message,
                    fcmSent: false,
                    isReply: true,
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
