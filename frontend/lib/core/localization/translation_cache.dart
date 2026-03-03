import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TranslationCache {
  static const String _cacheKey = 'dynamic_translations_cache';
  
  // Cache structure: { 'hi': { 'Hello': 'नमस्ते' }, 'ta': { ... } }
  static Map<String, Map<String, String>> _cache = {};
  static bool _isLoaded = false;

  static Future<void> init() async {
    if (_isLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    final String? cachedData = prefs.getString(_cacheKey);
    
    if (cachedData != null) {
      try {
        final decoded = json.decode(cachedData) as Map<String, dynamic>;
        _cache = decoded.map((lang, translations) {
          return MapEntry(lang, Map<String, String>.from(translations as Map));
        });
      } catch (e) {
        print('Error loading translation cache: $e');
        _cache = {};
      }
    }
    _isLoaded = true;
  }

  static String? getTranslation(String text, String targetLanguage) {
    return _cache[targetLanguage]?[text];
  }

  static Future<void> saveTranslation(String text, String targetLanguage, String translatedText) async {
    if (!_cache.containsKey(targetLanguage)) {
      _cache[targetLanguage] = {};
    }
    _cache[targetLanguage]![text] = translatedText;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, json.encode(_cache));
  }

  static Future<void> clearCache() async {
    _cache = {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }
}
