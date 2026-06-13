import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../models/ai/analysis_results.dart';
import '../ocr/ocr_service.dart';
import '../validation/diet_text_validator.dart';
import '../parsing/diet_plan_parser.dart';

/// Diet analysis service using OCR + rule-based parser.
/// No AI/Gemini used — diet plan is parsed from OCR text.
class DietAnalysisService {
  final OcrService _ocrService = OcrService();
  final DietTextValidator _validator = DietTextValidator();
  final DietPlanParser _parser = DietPlanParser();

  Future<DietAnalysisResult> analyzeDietDocument({
    required File file,
    required DocumentValidationResult validationResult,
  }) async {
    debugPrint('Diet analysis (rule-based) started');

    try {
      // 1. Run OCR
      final ocrResult = await _ocrService.extractText(file);

      if (!ocrResult.success || ocrResult.isEmpty) {
        return DietAnalysisResult(
          dailyCalorieTarget: null,
          breakfast: null,
          lunch: null,
          dinner: null,
          snacks: const [],
          proteinGrams: null,
          carbsGrams: null,
          fatGrams: null,
          avoidedFoods: const [],
          dietSummary: 'Diyet listesinden metin çıkarılamadı.',
          nutritionNotes: const ['Lütfen daha net bir belge yükleyin.'],
          rawExtractedText: '',
        );
      }

      // 2. Validate — reuse the validation result's matched signals
      final validation = _validator.validate(ocrResult);

      // 3. Parse the OCR text into structured meals
      final parsed = _parser.parse(ocrResult, validation.matchedSignals);

      // 4. Build DietMeals from parsed data
      DietMeal? breakfast;
      DietMeal? lunch;
      DietMeal? dinner;
      final List<DietMeal> snacks = [];

      for (final entry in parsed.meals.entries) {
        final mealType = entry.key;
        final items = entry.value;

        final dietMeal = DietMeal(
          name: _mealTypeToName(mealType),
          items: items,
          calories: null, // Calorie estimation not done at this stage
        );

        switch (mealType) {
          case 'breakfast':
            breakfast = dietMeal;
            break;
          case 'lunch':
            lunch = dietMeal;
            break;
          case 'dinner':
            dinner = dietMeal;
            break;
          case 'snack':
            snacks.add(dietMeal);
            break;
          default:
            // "general" or unknown → treat as additional snacks
            snacks.add(dietMeal);
        }
      }

      final mealPlanSummary = parsed.hasContent
          ? 'Diyet listesinde ${parsed.meals.length} öğün ve ${parsed.detectedFoodItems.length} besin tespit edildi.'
          : 'Diyet listesi okundu ancak öğün yapısı net olarak belirlenemedi.';

      return DietAnalysisResult(
        dailyCalorieTarget: null,
        breakfast: breakfast,
        lunch: lunch,
        dinner: dinner,
        snacks: snacks,
        proteinGrams: null,
        carbsGrams: null,
        fatGrams: null,
        avoidedFoods: const [],
        dietSummary: mealPlanSummary,
        nutritionNotes: const [
          'Bu analiz kural tabanlı olarak yapılmıştır. Tıbbi tavsiye niteliği taşımaz.',
        ],
        rawExtractedText: ocrResult.rawText,
      );
    } catch (e, st) {
      debugPrint('Diet analysis error: $e');
      debugPrint('Stack trace: $st');
      return DietAnalysisResult(
        dailyCalorieTarget: null,
        breakfast: null,
        lunch: null,
        dinner: null,
        snacks: const [],
        proteinGrams: null,
        carbsGrams: null,
        fatGrams: null,
        avoidedFoods: const [],
        dietSummary: 'Diyet listesi analiz edilemedi.',
        nutritionNotes: const [
          'Teknik bir sorun oluştu. Lütfen tekrar deneyin.',
        ],
        rawExtractedText: '',
      );
    }
  }

  String _mealTypeToName(String type) {
    switch (type) {
      case 'breakfast':
        return 'Kahvaltı';
      case 'lunch':
        return 'Öğle Yemeği';
      case 'dinner':
        return 'Akşam Yemeği';
      case 'snack':
        return 'Ara Öğün';
      default:
        return 'Öğün';
    }
  }
}
