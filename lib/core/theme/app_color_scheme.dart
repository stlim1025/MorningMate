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
    required this.primaryButton,
    required this.primaryButtonForeground,
    required this.secondaryButton,
    required this.secondaryButtonForeground,
    required this.iconPrimary,
    required this.iconSecondary,
    required this.gaugeActive,
    required this.gaugeInactive,
    required this.calendarSelected,
    required this.calendarToday,
    required this.calendarDefault,
    required this.tabSelected,
    required this.tabUnselected,
    required this.cardAccent,
    required this.progressBar,
    required this.streakGold,
    required this.success,
    required this.error,
    required this.warning,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.backgroundLight,
    required this.backgroundDark,
    required this.accent,
    required this.secondary,
    required this.friendAwake,
    required this.friendSleep,
    required this.pointStar,
    required this.twig,
    required this.info,
    required this.shadowColor,
    required this.awakeGradientStart,
    required this.awakeGradientMid,
    required this.awakeGradientEnd,
    required this.sleepGradientStart,
    required this.sleepGradientMid,
    required this.sleepGradientEnd,
  });

  final Color dialogTitle;
  final Color dialogBody;
  final Color dialogCancelBackground;
  final Color dialogCancelForeground;
  final Color dialogConfirmBackground;
  final Color dialogConfirmForeground;
  final Color dialogHighlightBackground;
  final Color dialogHighlightForeground;

  final Color primaryButton;
  final Color primaryButtonForeground;
  final Color secondaryButton;
  final Color secondaryButtonForeground;
  final Color iconPrimary;
  final Color iconSecondary;
  final Color gaugeActive;
  final Color gaugeInactive;
  final Color calendarSelected;
  final Color calendarToday;
  final Color calendarDefault;
  final Color tabSelected;
  final Color tabUnselected;
  final Color cardAccent;
  final Color progressBar;
  final Color streakGold;
  final Color success;
  final Color error;
  final Color warning;

  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;

  final Color backgroundLight;
  final Color backgroundDark;

  final Color accent;
  final Color secondary;

  final Color friendAwake;
  final Color friendSleep;

  final Color pointStar;
  final Color twig;

  final Color info;
  final Color shadowColor;
  final Color awakeGradientStart;
  final Color awakeGradientMid;
  final Color awakeGradientEnd;
  final Color sleepGradientStart;
  final Color sleepGradientMid;
  final Color sleepGradientEnd;

  static const light = AppColorScheme(
    dialogTitle: AppColors.textPrimary,
    dialogBody: AppColors.textSecondary,
    dialogCancelBackground: Color(0xFFF0F0F0),
    dialogCancelForeground: AppColors.textSecondary,
    dialogConfirmBackground: AppColors.primary,
    dialogConfirmForeground: Colors.white,
    dialogHighlightBackground: AppColors.streakGold,
    dialogHighlightForeground: AppColors.textPrimary,
    primaryButton: AppColors.primary,
    primaryButtonForeground: Colors.white,
    secondaryButton: Color(0xFFF0F0F0),
    secondaryButtonForeground: AppColors.textSecondary,
    iconPrimary: AppColors.primary,
    iconSecondary: AppColors.textSecondary,
    gaugeActive: AppColors.primary,
    gaugeInactive: Color(0xFFE0E0E0),
    calendarSelected: AppColors.primary,
    calendarToday: AppColors.secondary,
    calendarDefault: AppColors.textSecondary,
    tabSelected: AppColors.primary,
    tabUnselected: Colors.grey,
    cardAccent: AppColors.primary,
    progressBar: AppColors.primary,
    streakGold: AppColors.streakGold,
    success: AppColors.success,
    error: AppColors.error,
    warning: AppColors.warning,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textHint: AppColors.textHint,
    backgroundLight: AppColors.backgroundLight,
    backgroundDark: AppColors.backgroundDark,
    accent: AppColors.accent,
    secondary: AppColors.secondary,
    friendAwake: AppColors.friendActive,
    friendSleep: AppColors.friendSleep,
    pointStar: AppColors.pointStar,
    twig: AppColors.twig,
    info: AppColors.info,
    shadowColor: Color(0x26D4A574),
    awakeGradientStart: Color(0xFFFFF8E7),
    awakeGradientMid: Color(0xFFFFE4E1),
    awakeGradientEnd: Color(0xFFFAF3E0),
    sleepGradientStart: Color(0xFF2D241E),
    sleepGradientMid: Color(0xFF1F1A16),
    sleepGradientEnd: Color(0xFF12100E),
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
    Color? primaryButton,
    Color? primaryButtonForeground,
    Color? secondaryButton,
    Color? secondaryButtonForeground,
    Color? iconPrimary,
    Color? iconSecondary,
    Color? gaugeActive,
    Color? gaugeInactive,
    Color? calendarSelected,
    Color? calendarToday,
    Color? calendarDefault,
    Color? tabSelected,
    Color? tabUnselected,
    Color? cardAccent,
    Color? progressBar,
    Color? streakGold,
    Color? success,
    Color? error,
    Color? warning,
    Color? textPrimary,
    Color? textSecondary,
    Color? textHint,
    Color? backgroundLight,
    Color? backgroundDark,
    Color? accent,
    Color? secondary,
    Color? friendAwake,
    Color? friendSleep,
    Color? pointStar,
    Color? twig,
    Color? info,
    Color? shadowColor,
    Color? awakeGradientStart,
    Color? awakeGradientMid,
    Color? awakeGradientEnd,
    Color? sleepGradientStart,
    Color? sleepGradientMid,
    Color? sleepGradientEnd,
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
      primaryButton: primaryButton ?? this.primaryButton,
      primaryButtonForeground:
          primaryButtonForeground ?? this.primaryButtonForeground,
      secondaryButton: secondaryButton ?? this.secondaryButton,
      secondaryButtonForeground:
          secondaryButtonForeground ?? this.secondaryButtonForeground,
      iconPrimary: iconPrimary ?? this.iconPrimary,
      iconSecondary: iconSecondary ?? this.iconSecondary,
      gaugeActive: gaugeActive ?? this.gaugeActive,
      gaugeInactive: gaugeInactive ?? this.gaugeInactive,
      calendarSelected: calendarSelected ?? this.calendarSelected,
      calendarToday: calendarToday ?? this.calendarToday,
      calendarDefault: calendarDefault ?? this.calendarDefault,
      tabSelected: tabSelected ?? this.tabSelected,
      tabUnselected: tabUnselected ?? this.tabUnselected,
      cardAccent: cardAccent ?? this.cardAccent,
      progressBar: progressBar ?? this.progressBar,
      streakGold: streakGold ?? this.streakGold,
      success: success ?? this.success,
      error: error ?? this.error,
      warning: warning ?? this.warning,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
      backgroundLight: backgroundLight ?? this.backgroundLight,
      backgroundDark: backgroundDark ?? this.backgroundDark,
      accent: accent ?? this.accent,
      secondary: secondary ?? this.secondary,
      friendAwake: friendAwake ?? this.friendAwake,
      friendSleep: friendSleep ?? this.friendSleep,
      pointStar: pointStar ?? this.pointStar,
      twig: twig ?? this.twig,
      info: info ?? this.info,
      shadowColor: shadowColor ?? this.shadowColor,
      awakeGradientStart: awakeGradientStart ?? this.awakeGradientStart,
      awakeGradientMid: awakeGradientMid ?? this.awakeGradientMid,
      awakeGradientEnd: awakeGradientEnd ?? this.awakeGradientEnd,
      sleepGradientStart: sleepGradientStart ?? this.sleepGradientStart,
      sleepGradientMid: sleepGradientMid ?? this.sleepGradientMid,
      sleepGradientEnd: sleepGradientEnd ?? this.sleepGradientEnd,
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
      dialogConfirmBackground: Color.lerp(
              dialogConfirmBackground, other.dialogConfirmBackground, t) ??
          dialogConfirmBackground,
      dialogConfirmForeground: Color.lerp(
              dialogConfirmForeground, other.dialogConfirmForeground, t) ??
          dialogConfirmForeground,
      dialogHighlightBackground: Color.lerp(
              dialogHighlightBackground, other.dialogHighlightBackground, t) ??
          dialogHighlightBackground,
      dialogHighlightForeground: Color.lerp(
              dialogHighlightForeground, other.dialogHighlightForeground, t) ??
          dialogHighlightForeground,
      primaryButton:
          Color.lerp(primaryButton, other.primaryButton, t) ?? primaryButton,
      primaryButtonForeground: Color.lerp(
              primaryButtonForeground, other.primaryButtonForeground, t) ??
          primaryButtonForeground,
      secondaryButton: Color.lerp(secondaryButton, other.secondaryButton, t) ??
          secondaryButton,
      secondaryButtonForeground: Color.lerp(
              secondaryButtonForeground, other.secondaryButtonForeground, t) ??
          secondaryButtonForeground,
      iconPrimary: Color.lerp(iconPrimary, other.iconPrimary, t) ?? iconPrimary,
      iconSecondary:
          Color.lerp(iconSecondary, other.iconSecondary, t) ?? iconSecondary,
      gaugeActive: Color.lerp(gaugeActive, other.gaugeActive, t) ?? gaugeActive,
      gaugeInactive:
          Color.lerp(gaugeInactive, other.gaugeInactive, t) ?? gaugeInactive,
      calendarSelected:
          Color.lerp(calendarSelected, other.calendarSelected, t) ??
              calendarSelected,
      calendarToday:
          Color.lerp(calendarToday, other.calendarToday, t) ?? calendarToday,
      calendarDefault: Color.lerp(calendarDefault, other.calendarDefault, t) ??
          calendarDefault,
      tabSelected: Color.lerp(tabSelected, other.tabSelected, t) ?? tabSelected,
      tabUnselected:
          Color.lerp(tabUnselected, other.tabUnselected, t) ?? tabUnselected,
      cardAccent: Color.lerp(cardAccent, other.cardAccent, t) ?? cardAccent,
      progressBar: Color.lerp(progressBar, other.progressBar, t) ?? progressBar,
      streakGold: Color.lerp(streakGold, other.streakGold, t) ?? streakGold,
      success: Color.lerp(success, other.success, t) ?? success,
      error: Color.lerp(error, other.error, t) ?? error,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary:
          Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      textHint: Color.lerp(textHint, other.textHint, t) ?? textHint,
      backgroundLight: Color.lerp(backgroundLight, other.backgroundLight, t) ??
          backgroundLight,
      backgroundDark:
          Color.lerp(backgroundDark, other.backgroundDark, t) ?? backgroundDark,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      secondary: Color.lerp(secondary, other.secondary, t) ?? secondary,
      friendAwake: Color.lerp(friendAwake, other.friendAwake, t) ?? friendAwake,
      friendSleep: Color.lerp(friendSleep, other.friendSleep, t) ?? friendSleep,
      pointStar: Color.lerp(pointStar, other.pointStar, t)!,
      twig: Color.lerp(twig, other.twig, t)!,
      info: Color.lerp(info, other.info, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
      awakeGradientStart:
          Color.lerp(awakeGradientStart, other.awakeGradientStart, t)!,
      awakeGradientMid:
          Color.lerp(awakeGradientMid, other.awakeGradientMid, t)!,
      awakeGradientEnd:
          Color.lerp(awakeGradientEnd, other.awakeGradientEnd, t)!,
      sleepGradientStart:
          Color.lerp(sleepGradientStart, other.sleepGradientStart, t)!,
      sleepGradientMid:
          Color.lerp(sleepGradientMid, other.sleepGradientMid, t)!,
      sleepGradientEnd:
          Color.lerp(sleepGradientEnd, other.sleepGradientEnd, t)!,
    );
  }
}
