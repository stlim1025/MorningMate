import 'package:flutter/material.dart';

import 'app_color_scheme.dart';
import 'app_colors.dart';
import 'app_theme_type.dart';

class AppThemePalette {
  const AppThemePalette({
    required this.brightness,
    required this.primary,
    required this.secondary,
    required this.background,
    required this.card,
    required this.textPrimary,
    required this.iconColor,
    required this.inputFill,
    required this.bottomNavBackground,
    required this.unselectedNavItemColor,
    required this.appColorScheme,
    this.inputBorder,
    this.inputHint,
  });

  final Brightness brightness;
  final Color primary;
  final Color secondary;
  final Color background;
  final Color card;
  final Color textPrimary;
  final Color iconColor;
  final Color inputFill;
  final Color bottomNavBackground;
  final Color unselectedNavItemColor;
  final AppColorScheme appColorScheme;
  final Color? inputBorder;
  final Color? inputHint;
}

class AppTheme {
  static const AppThemePalette _lightPalette = AppThemePalette(
    brightness: Brightness.light,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    background: AppColors.backgroundLight,
    card: Colors.white,
    textPrimary: Colors.black87,
    iconColor: Colors.black87,
    inputFill: Color(0xFFF5F2EC),
    bottomNavBackground: Colors.white,
    unselectedNavItemColor: Colors.grey,
    appColorScheme: AppColorScheme.light,
  );

  static final Map<AppThemeType, AppThemePalette> _palettes = {
    AppThemeType.light: _lightPalette,
  };

  static ThemeData themeFor(AppThemeType type) {
    return _buildTheme(_palettes[type] ?? _lightPalette);
  }

  static ThemeData get lightTheme => themeFor(AppThemeType.light);

  static ThemeData _buildTheme(AppThemePalette palette) {
    final isDark = palette.brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: palette.brightness,
      fontFamily: 'Pretendard',
      colorScheme: ColorScheme(
        brightness: palette.brightness,
        primary: palette.primary,
        onPrimary: Colors.white,
        secondary: palette.secondary,
        onSecondary: Colors.white,
        surface: palette.card,
        onSurface: palette.textPrimary,
        background: palette.background,
        onBackground: palette.textPrimary,
        error: AppColors.error,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: palette.background,
      cardColor: palette.card,
      dialogBackgroundColor: palette.card,
      textTheme: _textTheme(palette.textPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: palette.iconColor),
        titleTextStyle: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: palette.textPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: palette.inputBorder == null
            ? null
            : OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: palette.inputBorder!),
              ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: palette.inputHint == null
            ? null
            : TextStyle(color: palette.inputHint),
      ),
      iconTheme: IconThemeData(color: palette.iconColor),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: palette.bottomNavBackground,
        selectedItemColor: palette.primary,
        unselectedItemColor: palette.unselectedNavItemColor,
        elevation: isDark ? null : 0,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return palette.primary;
          }
          return isDark ? Colors.grey[400] : Colors.white;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return palette.primary.withOpacity(isDark ? 0.3 : 0.5);
          }
          return isDark ? Colors.grey[700] : Colors.grey[300];
        }),
        trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
      ),
      extensions: [
        palette.appColorScheme,
      ],
    );
  }

  static TextTheme _textTheme(Color baseColor) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Pretendard',
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: baseColor,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Pretendard',
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: baseColor,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Pretendard',
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Pretendard',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Pretendard',
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: baseColor,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Pretendard',
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: baseColor,
      ),
    );
  }
}
