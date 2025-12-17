import 'dart:convert';
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
      model: 'gemini-2.5-flash-lite',
      apiKey: apiKey,
    );
  }

  Future<Map<String, dynamic>> identifyObject(Uint8List imageBytes, String targetLanguage) async {
    final promptText = '''
      Identify the main subject in this picture. Return the name of the subject in $targetLanguage. 
      Return the response as a JSON object with the following structure:
      {
        "subject": "The name of the subject in $targetLanguage",
        "language": "$targetLanguage"
      }
      Do not include markdown formatting like ```json. Just the raw JSON string.
    ''';

    final content = [
      Content.multi([
        TextPart(promptText),
        DataPart('image/jpeg', imageBytes),
      ])
    ];

    try {
      final response = await _model.generateContent(content);
      final responseText = response.text;

      if (responseText != null) {
        final cleanedText = responseText
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        
        return jsonDecode(cleanedText) as Map<String, dynamic>;
      }
      throw Exception('Empty response from Gemini');
    } catch (e) {
      throw Exception('Failed to identify object: $e');
    }
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
