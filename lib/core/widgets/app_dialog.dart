import 'package:flutter/material.dart';

import '../theme/app_color_scheme.dart';

enum AppDialogKey {
  biometricRetry,
  changeNickname,
  changePassword,
  logout,
  deleteAccount,
  addFriend,
  guestbook,
  exitWriting,
}

class AppDialogAction {
  const AppDialogAction({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.useHighlight = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool useHighlight;
}

class AppDialogConfig {
  const AppDialogConfig({
    required this.title,
    this.leading,
    this.content,
    this.actions = const [],
  });

  final String title;
  final Widget? leading;
  final Widget? content;
  final List<AppDialogAction> actions;
}

class AppDialog {
  const AppDialog._();

  static AppDialogConfig buildConfig({
    required AppDialogKey key,
    required BuildContext context,
    Widget? content,
    Widget? leading,
    List<AppDialogAction>? actions,
  }) {
    switch (key) {
      case AppDialogKey.biometricRetry:
        return AppDialogConfig(
          title: '생체 인증 실패',
          content: const Text(
            '생체 인증에 실패했습니다. 다시 시도하거나 로그아웃할 수 있습니다.',
          ),
          actions: actions ?? const [],
        );
      case AppDialogKey.changeNickname:
        return AppDialogConfig(
          title: '닉네임 변경',
          content: content,
          actions: actions ?? const [],
        );
      case AppDialogKey.changePassword:
        return AppDialogConfig(
          title: '비밀번호 변경',
          content: content,
          actions: actions ?? const [],
        );
      case AppDialogKey.logout:
        return AppDialogConfig(
          title: '로그아웃',
          content: const Text('정말 로그아웃 하시겠습니까?'),
          actions: actions ?? const [],
        );
      case AppDialogKey.deleteAccount:
        return AppDialogConfig(
          title: '회원탈퇴',
          content: const Text(
            '정말 회원탈퇴 하시겠습니까?\n모든 데이터가 삭제되며 복구할 수 없습니다.',
          ),
          actions: actions ?? const [],
        );
      case AppDialogKey.addFriend:
        return AppDialogConfig(
          title: '친구 추가',
          leading: leading,
          content: content,
          actions: actions ?? const [],
        );
      case AppDialogKey.guestbook:
        return AppDialogConfig(
          title: '응원 메시지',
          content: content,
          actions: actions ?? const [],
        );
      case AppDialogKey.exitWriting:
        return AppDialogConfig(
          title: '작성을 중단하시겠어요?',
          content: content,
          actions: actions ?? const [],
        );
    }
  }

  static Future<T?> show<T>({
    required BuildContext context,
    required AppDialogKey key,
    Widget? content,
    Widget? leading,
    List<AppDialogAction>? actions,
    bool barrierDismissible = true,
  }) {
    final config = buildConfig(
      key: key,
      context: context,
      content: content,
      leading: leading,
      actions: actions,
    );
    final colors = Theme.of(context).extension<AppColorScheme>();

    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(dialogContext).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            if (config.leading != null) ...[
              config.leading!,
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                config.title,
                style: TextStyle(
                  color: colors?.dialogTitle ??
                      Theme.of(dialogContext).textTheme.titleLarge?.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: config.content != null
            ? DefaultTextStyle.merge(
                style: TextStyle(
                  color: colors?.dialogBody ??
                      Theme.of(dialogContext).textTheme.bodyMedium?.color,
                ),
                child: config.content!,
              )
            : null,
        actions: config.actions
            .map((action) => _buildActionButton(dialogContext, action, colors))
            .toList(),
      ),
    );
  }

  static Widget _buildActionButton(
    BuildContext context,
    AppDialogAction action,
    AppColorScheme? colors,
  ) {
    final Color backgroundColor;
    final Color foregroundColor;

    if (action.useHighlight) {
      backgroundColor =
          colors?.dialogHighlightBackground ?? Theme.of(context).primaryColor;
      foregroundColor =
          colors?.dialogHighlightForeground ?? Theme.of(context).primaryColor;
    } else if (action.isPrimary) {
      backgroundColor =
          colors?.dialogConfirmBackground ?? Theme.of(context).primaryColor;
      foregroundColor = colors?.dialogConfirmForeground ?? Colors.white;
    } else {
      backgroundColor =
          colors?.dialogCancelBackground ?? Colors.grey.shade200;
      foregroundColor =
          colors?.dialogCancelForeground ?? Colors.grey.shade800;
    }

    return ElevatedButton(
      onPressed: action.onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: action.isPrimary || action.useHighlight ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        action.label,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
