import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) {
  const apiKey = String.fromEnvironment('GEMINI_API_KEY'); 
  return GeminiService(apiKey);
});

class GeminiService {
  final String apiKey;
  late final GenerativeModel _model;

  GeminiService(this.apiKey) {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash', 
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.4,
      ),
    );
  }

  Future<Map<String, dynamic>> identifyObject(
    Uint8List imageBytes, 
    String targetLanguage,
    String motherLanguage,
  ) async {
    
    final promptText = '''
      You are an expert visual linguist.
      
      1. Analyze the image to identify the SINGLE main, dominant subject.
      2. Identify the name of this subject in "$targetLanguage".
      3. Translate that name into "$motherLanguage".
      
      RULES:
      - The "translation" MUST use the native script of "$motherLanguage" (e.g. Thai Script, Kanji, Cyrillic).
      - Return ONLY raw JSON matching this schema:
      {
         "subject": "String (Name in $targetLanguage)",
         "translation": "String (Name in $motherLanguage)",
         "language": "$targetLanguage"
      }
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
        return jsonDecode(responseText.trim()) as Map<String, dynamic>;
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