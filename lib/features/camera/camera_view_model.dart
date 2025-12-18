import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/gemini_service.dart';
import '../../core/services/image_service.dart';
import '../../core/services/tts_service.dart';
import '../../core/services/settings_service.dart';
import '../../data/repositories/history_repository.dart';
import '../../data/models/image_record.dart';

final cameraViewModelProvider = StateNotifierProvider<CameraViewModel, CameraState>((ref) {
  return CameraViewModel(
    ref.read(geminiServiceProvider),
    ref.read(imageServiceProvider),
    ref.read(ttsServiceProvider),
    ref.read(historyRepositoryProvider),
    ref.read(settingsServiceProvider),
  );
});


class CameraState {
  final bool isAnalyzing;
  final bool isReviewing;
  final String targetLanguage;
  final Map<String, dynamic>? identifiedResult;
  final String? errorMessage;
  final Uint8List? capturedImage;

  CameraState({
    this.isAnalyzing = false,
    this.isReviewing = false,
    this.targetLanguage = 'Spanish',
    this.identifiedResult,
    this.errorMessage,
    this.capturedImage,
  });

  CameraState copyWith({
    bool? isAnalyzing,
    bool? isReviewing,
    String? targetLanguage,
    Map<String, dynamic>? identifiedResult,
    String? errorMessage,
    Uint8List? capturedImage,
  }) {
    return CameraState(
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      isReviewing: isReviewing ?? this.isReviewing,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      identifiedResult: identifiedResult ?? this.identifiedResult,
      errorMessage: errorMessage ?? this.errorMessage,
      capturedImage: capturedImage ?? this.capturedImage,
    );
  }
}

class CameraViewModel extends StateNotifier<CameraState> {
  final GeminiService _geminiService;
  final ImageService _imageService;
  final TtsService _ttsService;
  final HistoryRepository _historyRepository;
  final SettingsService _settingsService;
  final _uuid = const Uuid();

  CameraViewModel(this._geminiService, this._imageService, this._ttsService, this._historyRepository, this._settingsService) : super(CameraState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final targetLang = await _settingsService.getTargetLanguage();
    state = state.copyWith(targetLanguage: targetLang);
  }

  void setTargetLanguage(String language) {
    state = state.copyWith(targetLanguage: language);
    _settingsService.setTargetLanguage(language);
  }


  Future<void> capture(CameraController controller) async {
    try {
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      
      // Switch to review mode with the captured image
      state = state.copyWith(
        capturedImage: bytes,
        isReviewing: true,
        identifiedResult: null,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error capturing: $e');
    }
  }

  void retake() {
    state = state.copyWith(
      capturedImage: null,
      isReviewing: false,
      identifiedResult: null,
      errorMessage: null,
    );
  }

  Future<void> identify(String motherLanguage) async {
    if (state.capturedImage == null || state.isAnalyzing) return;

    try {
      state = state.copyWith(isAnalyzing: true, errorMessage: null);

      final compressedBytes = await _imageService.compressImage(state.capturedImage!);

      final result = await _geminiService.identifyObject(
        compressedBytes,
        state.targetLanguage,
        motherLanguage,
      );

      state = state.copyWith(
        isAnalyzing: false,
        identifiedResult: result,
      );
      
      // Auto-play pronunciation if available or just the word
      if (result.containsKey('subject')) {
        _speak(result['subject']);
        _saveResult(result);
      }

    } catch (e) {
      state = state.copyWith(
        isAnalyzing: false,
        errorMessage: 'Error identifying: $e',
      );
    }
  }

  /// Analyze an image from bytes (e.g., from image picker)
  Future<void> analyzeFromBytes(Uint8List bytes) async {
    // For image picker, we go straight to review mode
    state = state.copyWith(
      capturedImage: bytes,
      isReviewing: true,
      identifiedResult: null,
      errorMessage: null,
    );
  }
  
  void speakResult() {
    if (state.identifiedResult != null && state.identifiedResult!.containsKey('subject')) {
      _speak(state.identifiedResult!['subject']);
    }
  }

  void _speak(String text) {
    _ttsService.speak(text, language: state.targetLanguage);
  }

  Future<void> _saveResult(Map<String, dynamic> result) async {
    if (state.capturedImage == null) return;

    final name = result['subject'] ?? 'Unknown';
    final language = result['language'] ?? state.targetLanguage;
    
    try {
      final dir = await getApplicationDocumentsDirectory();
      final id = _uuid.v4();
      final imagePath = '${dir.path}/$id.jpg';
      final file = File(imagePath);
      await file.writeAsBytes(state.capturedImage!);

      final record = ImageRecord(
        id: id,
        imagePath: imagePath,
        subject: name,
        language: language,
        createdAt: DateTime.now(),
        translation: result['translation'],
      );


      await _historyRepository.addRecord(record);
    } catch (e) {
      print('Error saving history: $e');
    }
  }
  
  void resetResultOnly() {
    state = CameraState(
      isAnalyzing: state.isAnalyzing,
      isReviewing: state.isReviewing,
      targetLanguage: state.targetLanguage,
      identifiedResult: null,
      errorMessage: state.errorMessage,
      capturedImage: state.capturedImage,
    );
  }

  void reset() {
    state = CameraState();
  }
}
