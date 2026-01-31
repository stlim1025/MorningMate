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
    info: AppColors.info,
    shadowColor: Color(0x26D4A574),
    awakeGradientStart: Color(0xFFFFF8E7),
    awakeGradientMid: Color(0xFFFFE4E1),
    awakeGradientEnd: Color(0xFFFAF3E0),
    sleepGradientStart: Color(0xFF2D241E),
    sleepGradientMid: Color(0xFF1F1A16),
    sleepGradientEnd: Color(0xFF12100E),
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
    primaryButton: AppColors.primary,
    primaryButtonForeground: Color(0xFF5D4E37),
    secondaryButton: Color(0xFF424242),
    secondaryButtonForeground: Color(0xFFE0E0E0),
    iconPrimary: AppColors.primary,
    iconSecondary: Color(0xFFE0E0E0),
    gaugeActive: AppColors.primary,
    gaugeInactive: Color(0xFF424242),
    calendarSelected: AppColors.primary,
    calendarToday: AppColors.secondary,
    calendarDefault: Color(0xFFE0E0E0),
    tabSelected: AppColors.primary,
    tabUnselected: Colors.grey,
    cardAccent: AppColors.primary,
    progressBar: AppColors.primary,
    streakGold: AppColors.streakGold,
    success: AppColors.success,
    error: AppColors.error,
    warning: AppColors.warning,
    textPrimary: Colors.white,
    textSecondary: Color(0xFFE0E0E0),
    textHint: Color(0xFF757575),
    backgroundLight: Color(0xFF2C2C2C),
    backgroundDark: Color(0xFF1E1E1E),
    accent: AppColors.primary,
    secondary: AppColors.secondary,
    friendAwake: AppColors.friendActive,
    friendSleep: AppColors.friendSleep,
    pointStar: AppColors.pointStar,
    info: AppColors.info,
    shadowColor: Colors.black45,
    awakeGradientStart: Color(0xFF1A1A1A),
    awakeGradientMid: Color(0xFF0F0F0F),
    awakeGradientEnd: Color(0xFF000000),
    sleepGradientStart: Color(0xFF0F2027),
    sleepGradientMid: Color(0xFF203A43),
    sleepGradientEnd: Color(0xFF2C5364),
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
    primaryButton: AppColors.skyPrimary,
    primaryButtonForeground: Colors.white,
    secondaryButton: Color(0xFFE3EFFB),
    secondaryButtonForeground: AppColors.skyTextSecondary,
    iconPrimary: AppColors.skyPrimary,
    iconSecondary: AppColors.skyTextSecondary,
    gaugeActive: AppColors.skyPrimary,
    gaugeInactive: Color(0xFFE3EFFB),
    calendarSelected: AppColors.skyPrimary,
    calendarToday: AppColors.skySecondary,
    calendarDefault: AppColors.skyTextSecondary,
    tabSelected: AppColors.skyPrimary,
    tabUnselected: Color(0xFF7F9FC9),
    cardAccent: AppColors.skyPrimary,
    progressBar: AppColors.skyPrimary,
    streakGold: Color(0xFF5AA9E6),
    success: Color(0xFF7EC8E3),
    error: Color(0xFFFF9AA2),
    warning: Color(0xFFFFD97D),
    textPrimary: AppColors.skyTextPrimary,
    textSecondary: AppColors.skyTextSecondary,
    textHint: Color(0xFF9CB4CC),
    backgroundLight: Color(0xFFF0F7FF),
    backgroundDark: Color(0xFFE3EFFB),
    accent: Color(0xFF5AA9E6), // Sky 테마에서는 확실한 파란색 계열
    secondary: AppColors.skySecondary,
    friendAwake: Color(0xFF7EC8E3),
    friendSleep: Color(0xFF9CB4CC),
    pointStar: Color(0xFFFFD97D),
    info: Color(0xFFAEC6CF),
    shadowColor: Color(0xFF7F9FC9),
    awakeGradientStart: Color(0xFF87CEEB),
    awakeGradientMid: Color(0xFFB0E0E6),
    awakeGradientEnd: Color(0xFFFFF8DC),
    sleepGradientStart: Color(0xFF0F2027),
    sleepGradientMid: Color(0xFF203A43),
    sleepGradientEnd: Color(0xFF2C5364),
  );

  static const purple = AppColorScheme(
    dialogTitle: AppColors.purpleTextPrimary,
    dialogBody: AppColors.purpleTextPrimary,
    dialogCancelBackground: Color(0xFFF1EDFF),
    dialogCancelForeground: AppColors.purpleTextPrimary,
    dialogConfirmBackground: AppColors.purplePrimary,
    dialogConfirmForeground: Colors.white,
    dialogHighlightBackground: AppColors.purpleSecondary,
    dialogHighlightForeground: AppColors.purpleTextPrimary,
    primaryButton: AppColors.purplePrimary,
    primaryButtonForeground: Colors.white,
    secondaryButton: Color(0xFFF1EDFF),
    secondaryButtonForeground: AppColors.purpleTextPrimary,
    iconPrimary: AppColors.purplePrimary,
    iconSecondary: AppColors.purpleTextPrimary,
    gaugeActive: AppColors.purplePrimary,
    gaugeInactive: Color(0xFFF1EDFF),
    calendarSelected: AppColors.purplePrimary,
    calendarToday: AppColors.purpleSecondary,
    calendarDefault: AppColors.purpleTextPrimary,
    tabSelected: AppColors.purplePrimary,
    tabUnselected: Color(0xFFB4A5D1),
    cardAccent: AppColors.purplePrimary,
    progressBar: AppColors.purplePrimary,
    streakGold: Color(0xFFFFD700),
    success: Color(0xFFB5EAD7),
    error: Color(0xFFFF9AA2),
    warning: Color(0xFFFFDAC1),
    textPrimary: AppColors.purpleTextPrimary,
    textSecondary: Color(0xFF6C5A9A),
    textHint: Color(0xFFB4A5D1),
    backgroundLight: Color(0xFFF8F5FF),
    backgroundDark: Color(0xFFF1EDFF),
    accent: AppColors.purplePrimary,
    secondary: AppColors.purpleSecondary,
    friendAwake: Color(0xFFB5EAD7),
    friendSleep: Color(0xFFD4C4B0),
    pointStar: Color(0xFFFFD700),
    info: Color(0xFFAEC6CF),
    shadowColor: Color(0x339B6BFF),
    awakeGradientStart: Color(0xFFF1EDFF),
    awakeGradientMid: Color(0xFFE2D9FF),
    awakeGradientEnd: Color(0xFFF8F5FF),
    sleepGradientStart: Color(0xFF1A0B2E),
    sleepGradientMid: Color(0xFF10071C),
    sleepGradientEnd: Color(0xFF08040E),
  );

  static const pink = AppColorScheme(
    dialogTitle: AppColors.pinkTextPrimary,
    dialogBody: AppColors.pinkTextPrimary,
    dialogCancelBackground: Color(0xFFFFEDF5),
    dialogCancelForeground: AppColors.pinkTextPrimary,
    dialogConfirmBackground: AppColors.pinkPrimary,
    dialogConfirmForeground: Colors.white,
    dialogHighlightBackground: AppColors.pinkSecondary,
    dialogHighlightForeground: AppColors.pinkTextPrimary,
    primaryButton: AppColors.pinkPrimary,
    primaryButtonForeground: Colors.white,
    secondaryButton: Color(0xFFFFEDF5),
    secondaryButtonForeground: AppColors.pinkTextPrimary,
    iconPrimary: AppColors.pinkPrimary,
    iconSecondary: AppColors.pinkTextPrimary,
    gaugeActive: AppColors.pinkPrimary,
    gaugeInactive: Color(0xFFFFEDF5),
    calendarSelected: AppColors.pinkPrimary,
    calendarToday: AppColors.pinkSecondary,
    calendarDefault: AppColors.pinkTextPrimary,
    tabSelected: AppColors.pinkPrimary,
    tabUnselected: Color(0xFFD4A5B1),
    cardAccent: AppColors.pinkPrimary,
    progressBar: AppColors.pinkPrimary,
    streakGold: Color(0xFFFFD700),
    success: Color(0xFFB5EAD7),
    error: Color(0xFFFF9AA2),
    warning: Color(0xFFFFDAC1),
    textPrimary: AppColors.pinkTextPrimary,
    textSecondary: Color(0xFFA65C7C),
    textHint: Color(0xFFD4A5B1),
    backgroundLight: Color(0xFFFFF5F8),
    backgroundDark: Color(0xFFFFEDF5),
    accent: AppColors.pinkPrimary,
    secondary: AppColors.pinkSecondary,
    friendAwake: Color(0xFFB5EAD7),
    friendSleep: Color(0xFFD4C4B0),
    pointStar: Color(0xFFFFD700),
    info: Color(0xFFAEC6CF),
    shadowColor: Color(0x33FF7EB3),
    awakeGradientStart: Color(0xFFFFEDF5),
    awakeGradientMid: Color(0xFFFFD1E1),
    awakeGradientEnd: Color(0xFFFFF5F8),
    sleepGradientStart: Color(0xFF2E0B1A),
    sleepGradientMid: Color(0xFF1C0710),
    sleepGradientEnd: Color(0xFF0E0408),
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
