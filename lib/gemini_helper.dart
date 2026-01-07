import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiHelper {
  // ⚠️ PASTE YOUR NEW KEY HERE
  static const String _apiKey = "AIzaSyAfA7qgtGTCsTeaU5Go3z6r05ijmPO9dUQ"; 

  late final GenerativeModel _model;

  GeminiHelper() {
    _model = GenerativeModel(
      // We use Flash because it is the standard for new keys
      model: 'gemini-1.5-flash', 
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );
  }

  static const _systemPrompt = """
  You are an accountant. Analyze this transaction text.
  Extract: transaction_type, customer_name, amount, items, summary_hindi.
  Return ONLY JSON.
  """;

  Future<String?> processText(String text) async {
    try {
      print("🚀 Sending TEXT to Gemini: $text");
      final content = [
        Content.multi([
          TextPart(_systemPrompt),
          TextPart("Transaction: $text"),
        ])
      ];

      final response = await _model.generateContent(content);
      print("✅ Gemini Response: ${response.text}");
      return response.text;
    } catch (e) {
      print("❌ GEMINI ERROR: $e");
      return null;
    }
  }
}