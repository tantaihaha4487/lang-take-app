import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/gemini_service.dart';
import '../../core/services/image_service.dart';
import '../../core/services/tts_service.dart';
import '../../data/repositories/history_repository.dart';
import '../../data/models/history_item.dart';

final cameraViewModelProvider = StateNotifierProvider<CameraViewModel, CameraState>((ref) {
  return CameraViewModel(
    ref.read(geminiServiceProvider),
    ref.read(imageServiceProvider),
    ref.read(ttsServiceProvider),
    ref.read(historyRepositoryProvider),
  );
});

class CameraState {
  final bool isAnalyzing;
  final String? resultText;
  final Uint8List? capturedImage;

  CameraState({
    this.isAnalyzing = false,
    this.resultText,
    this.capturedImage,
  });

  CameraState copyWith({
    bool? isAnalyzing,
    String? resultText,
    Uint8List? capturedImage,
  }) {
    return CameraState(
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      resultText: resultText ?? this.resultText,
      capturedImage: capturedImage ?? this.capturedImage,
    );
  }
}

class CameraViewModel extends StateNotifier<CameraState> {
  final GeminiService _geminiService;
  final ImageService _imageService;
  final TtsService _ttsService;
  final HistoryRepository _historyRepository;
  final _uuid = const Uuid();

  CameraViewModel(this._geminiService, this._imageService, this._ttsService, this._historyRepository) : super(CameraState());

  Future<void> captureAndAnalyze(CameraController controller) async {
    if (state.isAnalyzing) return;

    try {
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();

      state = state.copyWith(isAnalyzing: true, capturedImage: bytes, resultText: '');

      final compressedBytes = await _imageService.compressImage(bytes);

      _geminiService.analyzeImage(compressedBytes).listen((text) {
        state = state.copyWith(resultText: (state.resultText ?? '') + text);
      }, onDone: () {
        state = state.copyWith(isAnalyzing: false);
        _speakResult(state.resultText ?? '');
        _saveResult(state.resultText ?? '');
      }, onError: (e) {
        state = state.copyWith(isAnalyzing: false, resultText: 'Error: $e');
      });

    } catch (e) {
      state = state.copyWith(isAnalyzing: false, resultText: 'Error capturing: $e');
    }
  }

  /// Analyze an image from bytes (e.g., from image picker)
  Future<void> analyzeFromBytes(Uint8List bytes) async {
    if (state.isAnalyzing) return;

    try {
      state = state.copyWith(isAnalyzing: true, capturedImage: bytes, resultText: '');

      final compressedBytes = await _imageService.compressImage(bytes);

      _geminiService.analyzeImage(compressedBytes).listen((text) {
        state = state.copyWith(resultText: (state.resultText ?? '') + text);
      }, onDone: () {
        state = state.copyWith(isAnalyzing: false);
        _speakResult(state.resultText ?? '');
        _saveResult(state.resultText ?? '');
      }, onError: (e) {
        state = state.copyWith(isAnalyzing: false, resultText: 'Error: $e');
      });
    } catch (e) {
      state = state.copyWith(isAnalyzing: false, resultText: 'Error analyzing: $e');
    }
  }
  
  void _speakResult(String text) {
    final nameMatch = RegExp(r"Name: (.*)").firstMatch(text);
    if (nameMatch != null) {
      _ttsService.speak(nameMatch.group(1)!);
    }
  }

  Future<void> _saveResult(String text) async {
    if (state.capturedImage == null) return;

    final name = RegExp(r"Name: (.*)").firstMatch(text)?.group(1) ?? 'Unknown';
    final pronunciation = RegExp(r"Pronunciation: (.*)").firstMatch(text)?.group(1) ?? '';
    final translation = RegExp(r"Translation: (.*)").firstMatch(text)?.group(1) ?? '';
    final description = RegExp(r"Description: (.*)").firstMatch(text)?.group(1) ?? '';

    try {
      final dir = await getApplicationDocumentsDirectory();
      final imagePath = '${dir.path}/${_uuid.v4()}.jpg';
      final file = File(imagePath);
      await file.writeAsBytes(state.capturedImage!);

      final item = HistoryItem(
        id: _uuid.v4(),
        name: name,
        pronunciation: pronunciation,
        translation: translation,
        description: description,
        timestamp: DateTime.now(),
        imagePath: imagePath,
      );

      await _historyRepository.saveHistoryItem(item);
    } catch (e) {
      // Handle save error silently or log
      print('Error saving history: $e');
    }
  }
  
  void reset() {
    state = CameraState();
  }
}
