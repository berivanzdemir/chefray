import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'ai/gemini_service.dart' as ai;

class GeminiService {
  final ai.GeminiService _delegate = ai.GeminiService();

  Future<Map<String, dynamic>> analyzeDietList(String inputOrPrompt) async {
    final prompt = '''
Sen profesyonel bir diyetisyensin. Kullanıcının gönderdiği diyet verisini analiz edeceksin.
Aşağıdaki bilgileri JSON formatında döndür. Sadece JSON kodunu yaz, markdown işareti kullanma:
{
  "totalCalories": 2450,
  "protein": 140,
  "carbs": 220,
  "fat": 75,
  "score": 8.5,
  "summary": "Bu diyet protein açısından zengin ancak biraz daha lif eklenebilir."
}

İşte veri: $inputOrPrompt
''';

    try {
      final responseText = await _delegate.generateText(prompt: prompt);
      
      // Clean JSON formatting
      String clean = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      final firstBrace = clean.indexOf('{');
      final lastBrace = clean.lastIndexOf('}');
      if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
        clean = clean.substring(firstBrace, lastBrace + 1);
      }

      return json.decode(clean) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Legacy analyzeDietList error: $e');
      return {
        "totalCalories": 2100,
        "protein": 110,
        "carbs": 180,
        "fat": 65,
        "score": 8.0,
        "summary": "Analiz başarısız oldu ancak verileriniz işleniyor. Sistem hatası."
      };
    }
  }

  Future<String> generateDailyTip() async {
    final prompt = 'Sen ChefRay isimli sağlıklı beslenme ve yemek uygulaması içindeki AI beslenme koçusun. Kullanıcıya 1 veya 2 cümlelik, motive edici ve sağlıklı beslenme ile ilgili çok kısa bir ipucu ver. Samimi bir dil kullan. Emojiler içerebilir.';
    
    try {
      final responseText = await _delegate.generateText(prompt: prompt);
      return responseText.trim();
    } catch (e) {
      debugPrint('Legacy generateDailyTip error: $e');
      return "Hedeflerine ulaşmak için harika bir gün! Dengeli tabaklar oluşturmaya devam et 🥦";
    }
  }
}
