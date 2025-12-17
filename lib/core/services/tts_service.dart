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

  Future<void> speak(String text) async {
    if (!_isSupported || _flutterTts == null) {
      debugPrint('TtsService: Would speak: "$text" (TTS not available on this platform)');
      return;
    }
    
    try {
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
