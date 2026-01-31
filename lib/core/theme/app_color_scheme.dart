import 'package:flutter/material.dart';

import 'app_colors.dart';

@immutable
class AppColorScheme extends ThemeExtension<AppColorScheme> {
  const AppColorScheme({
    required this.dialogTitle,
    required this.dialogBody,
    required this.dialogCancelBackground,
    required this.dialogCancelForeground,
    required this.dialogConfirmBackground,
    required this.dialogConfirmForeground,
    required this.dialogHighlightBackground,
    required this.dialogHighlightForeground,
  });

  final Color dialogTitle;
  final Color dialogBody;
  final Color dialogCancelBackground;
  final Color dialogCancelForeground;
  final Color dialogConfirmBackground;
  final Color dialogConfirmForeground;
  final Color dialogHighlightBackground;
  final Color dialogHighlightForeground;

  static const light = AppColorScheme(
    dialogTitle: AppColors.textPrimary,
    dialogBody: AppColors.textSecondary,
    dialogCancelBackground: Color(0xFFF0F0F0),
    dialogCancelForeground: AppColors.textSecondary,
    dialogConfirmBackground: AppColors.primary,
    dialogConfirmForeground: Colors.white,
    dialogHighlightBackground: AppColors.streakGold,
    dialogHighlightForeground: AppColors.textPrimary,
  );

  static const dark = AppColorScheme(
    dialogTitle: Colors.white,
    dialogBody: Color(0xFFE0E0E0),
    dialogCancelBackground: Color(0xFF424242),
    dialogCancelForeground: Color(0xFFE0E0E0),
    dialogConfirmBackground: AppColors.primary,
    dialogConfirmForeground: Color(0xFF5D4E37),
    dialogHighlightBackground: AppColors.streakGold,
    dialogHighlightForeground: AppColors.textPrimary,
  );

  static const sky = AppColorScheme(
    dialogTitle: AppColors.skyTextPrimary,
    dialogBody: AppColors.skyTextSecondary,
    dialogCancelBackground: Color(0xFFE3EFFB),
    dialogCancelForeground: AppColors.skyTextSecondary,
    dialogConfirmBackground: AppColors.skyPrimary,
    dialogConfirmForeground: Colors.white,
    dialogHighlightBackground: AppColors.skySecondary,
    dialogHighlightForeground: AppColors.skyTextPrimary,
  );

  @override
  AppColorScheme copyWith({
    Color? dialogTitle,
    Color? dialogBody,
    Color? dialogCancelBackground,
    Color? dialogCancelForeground,
    Color? dialogConfirmBackground,
    Color? dialogConfirmForeground,
    Color? dialogHighlightBackground,
    Color? dialogHighlightForeground,
  }) {
    return AppColorScheme(
      dialogTitle: dialogTitle ?? this.dialogTitle,
      dialogBody: dialogBody ?? this.dialogBody,
      dialogCancelBackground:
          dialogCancelBackground ?? this.dialogCancelBackground,
      dialogCancelForeground:
          dialogCancelForeground ?? this.dialogCancelForeground,
      dialogConfirmBackground:
          dialogConfirmBackground ?? this.dialogConfirmBackground,
      dialogConfirmForeground:
          dialogConfirmForeground ?? this.dialogConfirmForeground,
      dialogHighlightBackground:
          dialogHighlightBackground ?? this.dialogHighlightBackground,
      dialogHighlightForeground:
          dialogHighlightForeground ?? this.dialogHighlightForeground,
    );
  }

  @override
  AppColorScheme lerp(ThemeExtension<AppColorScheme>? other, double t) {
    if (other is! AppColorScheme) return this;
    return AppColorScheme(
      dialogTitle: Color.lerp(dialogTitle, other.dialogTitle, t) ?? dialogTitle,
      dialogBody: Color.lerp(dialogBody, other.dialogBody, t) ?? dialogBody,
      dialogCancelBackground:
          Color.lerp(dialogCancelBackground, other.dialogCancelBackground, t) ??
              dialogCancelBackground,
      dialogCancelForeground:
          Color.lerp(dialogCancelForeground, other.dialogCancelForeground, t) ??
              dialogCancelForeground,
      dialogConfirmBackground:
          Color.lerp(dialogConfirmBackground, other.dialogConfirmBackground, t) ??
              dialogConfirmBackground,
      dialogConfirmForeground:
          Color.lerp(dialogConfirmForeground, other.dialogConfirmForeground, t) ??
              dialogConfirmForeground,
      dialogHighlightBackground:
          Color.lerp(dialogHighlightBackground, other.dialogHighlightBackground, t) ??
              dialogHighlightBackground,
      dialogHighlightForeground:
          Color.lerp(dialogHighlightForeground, other.dialogHighlightForeground, t) ??
              dialogHighlightForeground,
    );
  }
}
