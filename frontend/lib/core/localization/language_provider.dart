import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_localizations.dart';

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
    AppLocalizations.onDynamicTranslationUpdated = () {
      notifyListeners();
    };
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

  String getTranslatedText(BuildContext context, Map<String, dynamic>? itemData, String defaultKey) {
    if (itemData == null) return "Unknown";
    final text = itemData[defaultKey] ?? "Unknown";
    final String rawString = text.toString();
    
    // If English or translations missing, return default (English) text fallback
    if (_locale.languageCode == 'en') return rawString;
    
    final translations = itemData['translations'];
    if (translations != null && translations[_locale.languageCode] != null) {
      final translated = translations[_locale.languageCode][defaultKey];
      if (translated != null && translated.toString().isNotEmpty) {
        return translated.toString();
      }
    }
    
    // Fall back to dynamic translation via AppLocalizations
    final localizations = AppLocalizations.of(context);
    if (localizations != null) {
      final dynTranslation = localizations.translate(rawString);
      if (dynTranslation != null && dynTranslation.isNotEmpty) {
        return dynTranslation;
      }
    }
    
    return rawString;
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
