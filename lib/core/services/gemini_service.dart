import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) {
  // TODO: Replace with actual API key mechanism (e.g. --dart-define or .env)
  const apiKey = String.fromEnvironment('GEMINI_API_KEY');
  return GeminiService(apiKey);
});

class GeminiService {
  final String apiKey;
  late final GenerativeModel _model;

  GeminiService(this.apiKey) {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );
  }

  Stream<String> analyzeImage(Uint8List imageBytes) async* {
    final prompt = TextPart("Identify the main object in this image. Format the response exactly as follows:\nName: [Name]\nPronunciation: [Phonetic]\nTranslation: [Translation]\nDescription: [Brief description]");
    final image = DataPart('image/jpeg', imageBytes);

    final response = _model.generateContentStream([
      Content.multi([prompt, image])
    ]);

    await for (final chunk in response) {
      if (chunk.text != null) {
        yield chunk.text!;
      }
    }
  }
}
