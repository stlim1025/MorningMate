import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';
import 'app_theme_type.dart';

class ThemeController extends ChangeNotifier {
  static const String _themeKey = 'themeType';

  AppThemeType get themeType => AppThemeType.light;

  bool get isDarkMode => false;

  ThemeData get themeData => AppTheme.themeFor(AppThemeType.light);

  ThemeController() {
    // 테마 리셋 (항상 라이트로)
    _resetToLight();
  }

  Future<void> _resetToLight() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, AppThemeType.light.name);
  }

  Future<void> setTheme(AppThemeType themeType) async {
    // 현재는 라이트 테마만 지원하므로 무시
  }

  Future<void> syncWithUserTheme(String? themeId) async {
    // 현재는 라이트 테마만 지원하므로 무시
  }

  Future<void> resetToDefault() async {
    // 개발 단계에서 라이트로 강제 고정
  }
}
