import 'package:flutter/material.dart';

/// 간단한 다국어 지원 헬퍼
/// 한국어(ko)가 아닌 경우 영어 텍스트를 반환합니다.
class L10n {
  static bool isKorean(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return locale.languageCode == 'ko';
  }

  static String t(BuildContext context,
      {required String ko, required String en}) {
    return isKorean(context) ? ko : en;
  }
}
