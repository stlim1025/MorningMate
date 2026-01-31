import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';
import 'app_theme_type.dart';

class ThemeController extends ChangeNotifier {
  static const String _themeKey = 'themeType';
  static const String _legacyDarkKey = 'isDarkMode';
  AppThemeType _themeType = AppThemeType.light;

  AppThemeType get themeType => _themeType;

  bool get isDarkMode => _themeType == AppThemeType.dark;

  ThemeData get themeData => AppTheme.themeFor(_themeType);

  ThemeController() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final storedTheme = prefs.getString(_themeKey);
    if (storedTheme != null) {
      _themeType = AppThemeType.values.firstWhere(
        (type) => type.name == storedTheme,
        orElse: () => AppThemeType.light,
      );
    } else {
      final isDarkMode = prefs.getBool(_legacyDarkKey) ?? false;
      _themeType = isDarkMode ? AppThemeType.dark : AppThemeType.light;
    }
    notifyListeners();
  }

  Future<void> setTheme(AppThemeType themeType) async {
    if (_themeType == themeType) return;
    _themeType = themeType;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeType.name);
    await prefs.setBool(_legacyDarkKey, themeType == AppThemeType.dark);
    notifyListeners();
  }

  Future<void> syncWithUserTheme(String? themeId) async {
    if (themeId == null) return;

    final themeType = AppThemeType.values.firstWhere(
      (type) => type.name == themeId,
      orElse: () => AppThemeType.light,
    );

    if (_themeType != themeType) {
      await setTheme(themeType);
    }
  }
}
