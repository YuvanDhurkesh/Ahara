import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  static const String _prefKey = 'selected_language';

  Locale get locale => _locale;

  LanguageProvider() {
    _loadFromPrefs();
  }

  Future<void> setLanguage(String languageCode) async {
    _locale = Locale(languageCode);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, languageCode);
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefKey);
    if (code != null) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  String getLanguageName() {
    switch (_locale.languageCode) {
      case 'hi': return 'हिन्दी';
      case 'ta': return 'தமிழ்';
      case 'te': return 'తెలుగు';
      case 'en': 
      default: return 'English';
    }
  }
}
