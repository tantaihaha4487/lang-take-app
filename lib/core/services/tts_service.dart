import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ttsServiceProvider = Provider((ref) => TtsService());

class TtsService {
  FlutterTts? _flutterTts;
  bool _isSupported = false;

  TtsService() {
    _initTts();
  }

  Future<void> _initTts() async {
    // flutter_tts does not support Linux
    if (!kIsWeb && Platform.isLinux) {
      debugPrint('TtsService: TTS is not supported on Linux platform');
      _isSupported = false;
      return;
    }

    try {
      _flutterTts = FlutterTts();
      await _flutterTts!.setLanguage("en-US");
      await _flutterTts!.setPitch(1.0);
      _isSupported = true;
    } catch (e) {
      debugPrint('TtsService: Failed to initialize TTS: $e');
      _isSupported = false;
    }
  }

  final Map<String, String> _languageCodes = {
    'English': 'en-US',
    'Spanish': 'es-ES',
    'Japanese': 'ja-JP',
    'French': 'fr-FR',
    'German': 'de-DE',
    'Italian': 'it-IT',
    'Chinese': 'zh-CN',
    'Korean': 'ko-KR',
    'Russian': 'ru-RU',
    'Portuguese': 'pt-BR',
  };

  Future<void> speak(String text, {String? language}) async {
    if (!_isSupported || _flutterTts == null) {
      debugPrint('TtsService: Would speak: "$text" in $language (TTS not available on this platform)');
      return;
    }
    
    try {
      if (language != null) {
        final code = _languageCodes[language] ?? 'en-US';
        await _flutterTts!.setLanguage(code);
      }
      await _flutterTts!.speak(text);
    } catch (e) {
      debugPrint('TtsService: Error speaking: $e');
    }
  }

  Future<void> stop() async {
    if (!_isSupported || _flutterTts == null) {
      return;
    }
    
    try {
      await _flutterTts!.stop();
    } catch (e) {
      debugPrint('TtsService: Error stopping: $e');
    }
  }
  
  bool get isSupported => _isSupported;
}
