import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/localization/language_provider.dart';

void main() {
  group('LanguageProvider Tests', () {
    late LanguageProvider languageProvider;

    setUp(() async {
      // Initialize SharedPreferences with empty values
      SharedPreferences.setMockInitialValues({});
      languageProvider = LanguageProvider();
      // Wait for async initialization
      await Future.delayed(const Duration(milliseconds: 100));
    });

    test('Initial locale should be English', () {
      expect(languageProvider.locale.languageCode, equals('en'));
    });

    test('Initial UI mode should be standard', () {
      expect(languageProvider.uiMode, equals('standard'));
      expect(languageProvider.isSimplified, isFalse);
    });

    test('setLanguage should update locale correctly', () async {
      await languageProvider.setLanguage('hi');
      expect(languageProvider.locale.languageCode, equals('hi'));
    });

    test('setLanguage should mark as manual selection', () async {
      await languageProvider.setLanguage('ta', isManual: true);
      expect(languageProvider.isManualSelection, isTrue);
    });

    test('setUiMode should update UI mode correctly', () async {
      await languageProvider.setUiMode('simplified');
      expect(languageProvider.uiMode, equals('simplified'));
      expect(languageProvider.isSimplified, isTrue);
    });

    test('setUiMode should mark as manual selection', () async {
      await languageProvider.setUiMode('simplified', isManual: true);
      expect(languageProvider.isManualSelection, isTrue);
    });

    test('confirmCurrentLanguage should mark selection as manual', () async {
      await languageProvider.confirmCurrentLanguage();
      expect(languageProvider.isManualSelection, isTrue);
    });

    test('confirmCurrentLanguage should persist to SharedPreferences', () async {
      await languageProvider.setLanguage('te');
      await languageProvider.setUiMode('simplified');
      await languageProvider.confirmCurrentLanguage();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selected_language'), equals('te'));
      expect(prefs.getString('ui_mode'), equals('simplified'));
    });

    test('getLanguageName should return correct name for English', () {
      expect(languageProvider.getLanguageName(), equals('English'));
    });

    test('getLanguageName should return correct name for Hindi', () async {
      await languageProvider.setLanguage('hi');
      expect(languageProvider.getLanguageName(), equals('हिन्दी'));
    });

    test('getLanguageName should return correct name for Tamil', () async {
      await languageProvider.setLanguage('ta');
      expect(languageProvider.getLanguageName(), equals('தமிழ்'));
    });

    test('getLanguageName should return correct name for Telugu', () async {
      await languageProvider.setLanguage('te');
      expect(languageProvider.getLanguageName(), equals('తెలుగు'));
    });

    test('Language persists across provider instances', () async {
      await languageProvider.setLanguage('hi');
      await languageProvider.confirmCurrentLanguage();

      // Create new provider instance
      final newProvider = LanguageProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(newProvider.locale.languageCode, equals('hi'));
      expect(newProvider.isManualSelection, isTrue);
    });

    test('UI mode persists across provider instances', () async {
      await languageProvider.setUiMode('simplified');
      await languageProvider.confirmCurrentLanguage();

      // Create new provider instance
      final newProvider = LanguageProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(newProvider.uiMode, equals('simplified'));
      expect(newProvider.isSimplified, isTrue);
    });
  });
}
