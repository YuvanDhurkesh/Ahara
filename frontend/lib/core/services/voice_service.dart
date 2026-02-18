/// File: voice_service.dart
/// Purpose: Accessibility and hands-free interaction service.
/// 
/// Responsibilities:
/// - Orchestrates Speech-to-Text (STT) and Text-to-Speech (TTS) transformations
/// - Manages multi-lingual voice synthesis and recognition
/// - Provides reactive state for listening status and captured transcriptions
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

/// Reactive cross-platform voice interaction engine.
/// 
/// Features:
/// - Singleton architectural pattern for global availability
/// - Integrated [SpeechToText] and [FlutterTts] lifecycle management
/// - Context-aware language switching for TTS synthesis
class VoiceService extends ChangeNotifier {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isListening = false;
  bool get isListening => _isListening;

  String _lastWords = '';
  String get lastWords => _lastWords;

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    
    _isInitialized = await _speech.initialize(
      onStatus: (status) => debugPrint('STT Status: $status'),
      onError: (error) => debugPrint('STT Error: $error'),
    );
    
    await _tts.setLanguage("en-US");
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);
    
    notifyListeners();
  }

  Future<void> startListening(Function(String) onResult) async {
    if (!_isInitialized) await init();
    
    _isListening = true;
    _lastWords = '';
    notifyListeners();

    await _speech.listen(
      onResult: (result) {
        _lastWords = result.recognizedWords;
        if (result.finalResult) {
          _isListening = false;
          onResult(_lastWords);
          notifyListeners();
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
    _isListening = false;
    notifyListeners();
  }

  Future<void> speak(String text, {String? languageCode}) async {
    if (languageCode != null) {
      await _tts.setLanguage(languageCode);
    }
    await _tts.speak(text);
  }

  Future<void> setLanguage(String languageCode) async {
    // Map app language to TTS locales
    String locale = "en-US";
    switch (languageCode) {
      case 'hi': locale = "hi-IN"; break;
      case 'ta': locale = "ta-IN"; break;
      case 'te': locale = "te-IN"; break;
    }
    await _tts.setLanguage(locale);
  }
}
