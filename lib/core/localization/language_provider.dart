import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('ko');

  Locale get locale => _locale;

  LanguageProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString('languageCode');

    if (languageCode != null) {
      _locale = Locale(languageCode);
    } else {
      // Detect device locale
      final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
      if (deviceLocale.languageCode == 'ko') {
        _locale = const Locale('ko');
      } else {
        _locale = const Locale('en');
      }
    }
    notifyListeners();

    // Sync to Firestore on initial load
    _syncLanguageToFirestore(_locale.languageCode);
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale.languageCode);
    notifyListeners();

    // Sync to Firestore for Firebase Functions to read
    await _syncLanguageToFirestore(locale.languageCode);
  }

  Future<void> _syncLanguageToFirestore(String languageCode) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'languageCode': languageCode});
      }
    } catch (e) {
      debugPrint('Firestore 언어 동기화 실패: $e');
    }
  }
}
