import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  String _uiMode = 'standard';
  bool _isManualSelection = false;
  
  static const String _langKey = 'selected_language';
  static const String _uiKey = 'ui_mode';

  Locale get locale => _locale;
  String get uiMode => _uiMode;
  bool get isSimplified => _uiMode == 'simplified';
  bool get isManualSelection => _isManualSelection;

  LanguageProvider() {
    _loadFromPrefs();
  }

  Future<void> setLanguage(String languageCode, {bool isManual = true}) async {
    _locale = Locale(languageCode);
    if (isManual) _isManualSelection = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, languageCode);
  }

  Future<void> setUiMode(String mode, {bool isManual = true}) async {
    _uiMode = mode;
    if (isManual) _isManualSelection = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_uiKey, mode);
  }

  Future<void> confirmCurrentLanguage() async {
    _isManualSelection = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, _locale.languageCode);
    await prefs.setString(_uiKey, _uiMode);
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_langKey);
    if (code != null) {
      _locale = Locale(code);
      _isManualSelection = true;
    }
    final mode = prefs.getString(_uiKey);
    if (mode != null) {
      _uiMode = mode;
      _isManualSelection = true;
    }
    notifyListeners();
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
