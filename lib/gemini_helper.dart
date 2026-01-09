import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiHelper {
  // ⚠️ PASTE YOUR NEW KEY HERE
  static const String _apiKey = "AIzaSyAfA7qgtGTCsTeaU5Go3z6r05ijmPO9dUQ"; 

  late final GenerativeModel _model;
  late final GenerativeModel _visionModel;

  GeminiHelper() {
    // Relying on prompt for JSON structure
    
    _model = GenerativeModel(
      model: 'gemini-1.0-pro', 
      apiKey: _apiKey,
    );

    _visionModel = GenerativeModel(
      model: 'gemini-1.0-pro-vision', 
      apiKey: _apiKey,
    );
  }

  Future<void> listModels() async {
    try {
      // This is a hacky way to test the key/listing if the SDK supports it, 
      // but the current SDK version might not expose listModels easily on the client.
      // Instead, we will print a startup log.
      print("🔍 Attempting to use: gemini-1.0-pro and gemini-1.0-pro-vision");
    } catch (e) {
      print("Error listing models: $e");
    }
  }

  static const _systemPrompt = """
  You are an intelligent data parser for a shopkeeper in Indore, India. 
  Your job is to extract the intent from a voice note or image text.

  Rules:
  1. Identify if it is 'CREDIT_SALE' (Udhaar/Baaki/Likh do) or 'PAYMENT' (Jama/Cash/Diye).
  2. Identify the Customer Name.
  3. Identify the Amount.
  4. If the language is Hindi or mixed Hinglish, translate the intent accurately.

  Output ONLY JSON in this exact structure:
  {
    "customer_name": "String (Capitalized)",
    "amount": Number,
    "transaction_type": "CREDIT_SALE" or "PAYMENT",
    "items": "String (Items list or 'Cash')",
    "summary_hindi": "String (Short Hinglish summary, e.g., 'Ramesh ne 500 jama kiye')"
  }

  Examples:
  Input: "Ramesh se 500 lene hain" -> {"customer_name": "Ramesh", "amount": 500, "transaction_type": "CREDIT_SALE", "items": "Unknown", "summary_hindi": "Ramesh - 500 baaki"}
  Input: "Suresh ne 200 jama kiye" -> {"customer_name": "Suresh", "amount": 200, "transaction_type": "PAYMENT", "items": "Cash", "summary_hindi": "Suresh ne 200 diye"}

  Only return valid JSON. Do not include markdown formatting like ```json.
  If an image is provided, extract transaction details from the image using these same rules.
  """;

  Future<String?> processInput(String text, [List<int>? imageBytes]) async {
    try {
      print("🚀 Sending INPUT to Gemini: $text (Image: ${imageBytes != null})");
      
      final parts = <Part>[
        TextPart(_systemPrompt),
        TextPart("Transaction Note/Context: $text"),
      ];

      if (imageBytes != null) {
        parts.add(DataPart('image/jpeg', Uint8List.fromList(imageBytes)));
        final content = [Content.multi(parts)];
        final response = await _visionModel.generateContent(content);
        print("✅ Gemini Vision Response: ${response.text}");
        return response.text;
      } else {
        final content = [Content.multi(parts)];
        final response = await _model.generateContent(content);
        print("✅ Gemini Text Response: ${response.text}");
        return response.text;
      }
    } catch (e) {
      print("❌ GEMINI ERROR: $e");
      print("⚠️ Switching to Local Fallback parsing...");
      return _attemptLocalParsing(text);
    }
  }

  String _attemptLocalParsing(String text) {
    text = text.toLowerCase();
    
    // 1. Extract Amount
    final amountRegex = RegExp(r'(\d+)');
    final amountMatch = amountRegex.firstMatch(text);
    final int amount = amountMatch != null ? int.parse(amountMatch.group(0)!) : 0;

    // 2. Identify Type (Credit vs Payment)
    String type = 'CREDIT_SALE'; // Default to credit
    String summaryType = 'Udhaar';
    
    final paymentKeywords = ['jama', 'diye', 'de gaya', 'aaye', 'cash'];
    for (var word in paymentKeywords) {
      if (text.contains(word)) {
        type = 'PAYMENT';
        summaryType = 'Jama';
        break;
      }
    }

    // 3. Identify Name (Simple heuristic: First word usually)
    // Cleanup common stopwords if needed, but for now simple first word is enough
    final words = text.split(' ');
    String name = "Unknown Customer";
    if (words.isNotEmpty) {
      // Capitalize first letter
      String rawName = words[0];
      name = "${rawName[0].toUpperCase()}${rawName.substring(1)}";
    }

    // 4. Construct JSON
    // { "customer_name", "amount", "transaction_type", "items", "summary_hindi" }
    final json = """
    {
      "customer_name": "$name",
      "amount": $amount,
      "transaction_type": "$type",
      "items": "Local Parsed",
      "summary_hindi": "$name - $amount $summaryType"
    }
    """;
    
    print("✅ Local Parser Result: $json");
    return json;
  }
}