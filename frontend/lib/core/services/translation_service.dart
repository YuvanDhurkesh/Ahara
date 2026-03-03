import 'package:translator/translator.dart';
import '../localization/translation_cache.dart';

class TranslationService {
  static final _translator = GoogleTranslator();

  static Future<String?> translate(String text, String targetLanguage) async {
    // 1. Check Cache First
    final cached = TranslationCache.getTranslation(text, targetLanguage);
    if (cached != null) return cached;

    // 2. Call Google Translate (Free Public Engine)
    try {
      final translation = await _translator.translate(
        text,
        to: targetLanguage,
      );

      final translatedText = translation.text;
      
      // 3. Save to Cache
      await TranslationCache.saveTranslation(text, targetLanguage, translatedText);
      
      return translatedText;
    } catch (e) {
      print('Translation Service Exception: $e');
      return null;
    }
  }

  // Batch translation helper
  static Future<Map<String, String>> translateBatch(List<String> texts, String targetLanguage) async {
    Map<String, String> results = {};
    for (var text in texts) {
      final result = await translate(text, targetLanguage);
      if (result != null) results[text] = result;
    }
    return results;
  }
}
