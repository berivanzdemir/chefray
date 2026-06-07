import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../models/ai/analysis_results.dart';
import '../../models/ai/full_analysis_result.dart';
import '../../models/recipes/recommended_recipe_view_model.dart';
import '../../models/recipe_model.dart';
import '../../models/user_health_profile.dart';
import '../ai/recipe_recommendation_service.dart';
import '../ocr/ocr_service.dart';
import '../validation/diet_text_validator.dart';
import '../validation/blood_text_validator.dart';
import '../parsing/diet_plan_parser.dart';
import '../parsing/blood_value_parser.dart';
import '../engine/health_rule_engine.dart';
import '../../repositories/recipes/supabase_recipe_repository.dart';
import '../../repositories/analysis/analysis_history_repository.dart';

class AnalysisException implements Exception {
  final String code;
  final String message;
  final Object? originalError;
  final StackTrace? stackTrace;

  AnalysisException(
    this.code,
    this.message, {
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'AnalysisException($code): $message';
}

typedef AnalysisStepCallback = void Function(int stepIndex, String message);

class FullAnalysisOrchestrator {
  final RecipeRecommendationService _recipeRecommendationService = RecipeRecommendationService();
  final SupabaseRecipeRepository _supabaseRecipeRepository = SupabaseRecipeRepository();
  final AnalysisHistoryRepository _analysisHistoryRepository = AnalysisHistoryRepository.instance;
  final OcrService _ocrService = OcrService();
  final HealthRuleEngine _ruleEngine = HealthRuleEngine();
  final DietPlanParser _dietPlanParser = DietPlanParser();
  final BloodValueParser _bloodValueParser = BloodValueParser();
  final DietTextValidator _dietValidator = DietTextValidator();
  final BloodTextValidator _bloodValidator = BloodTextValidator();

  DietAnalysisResult fallbackDietAnalysis(DocumentValidationResult? validationResult) {
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
      dietSummary: 'Diyet listesi doğrulandı ancak detayların bir kısmı net okunamadı.',
      nutritionNotes: const ['Diyet listesi kural tabanlı doğrulandı. Tarif önerileri profil ve kan değerleriyle birlikte genel uyuma göre hazırlanacaktır.'],
      rawExtractedText: validationResult?.extractedTextSummary ?? '',
    );
  }

  Future<FullAnalysisResult> runFullAnalysis({
    DietAnalysisResult? dietAnalysis,
    File? dietFile,
    File? bloodFile,
    BloodAnalysisResult? previousBloodAnalysis,
    required UserHealthProfile userProfile,
    DocumentValidationResult? dietValidationResult,
    DocumentValidationResult? bloodValidationResult,
    AnalysisStepCallback? onProgress,
  }) async {
    debugPrint('========== FULL ANALYSIS START (RULE-BASED) ==========');
    debugPrint('Diet file exists: ${dietFile != null}');
    debugPrint('Diet validation exists: ${dietValidationResult != null}');
    debugPrint('Diet validation valid: ${dietValidationResult?.isValid}');
    debugPrint('Blood file exists: ${bloodFile != null}');
    debugPrint('Blood validation valid: ${bloodValidationResult?.isValid}');

    try {
      // ── STEP 0: OCR + Validation for both documents ────────
      if (onProgress != null) {
        onProgress(0, 'Belgeler OCR ile okunuyor...');
      }

      // Diet OCR + Validation
      DietAnalysisResult finalDietAnalysis;
      DietValidationResult? dietValidation;

      if (dietAnalysis != null) {
        finalDietAnalysis = dietAnalysis;
        debugPrint('Using pre-computed diet analysis');
      } else {
        if (dietFile == null) {
          throw AnalysisException('missing_diet_file', 'Diyet dosyası bulunamadı.');
        }

        // Run OCR
        final dietOcr = await _ocrService.extractText(dietFile);
        if (!dietOcr.success) {
          throw AnalysisException('diet_ocr_failed', 'Diyet listesinden metin çıkarılamadı.');
        }

        // Validate
        dietValidation = _dietValidator.validate(dietOcr);
        if (!dietValidation.isDiet) {
          throw AnalysisException('invalid_diet', dietValidation.message);
        }
        debugPrint('Diet validation: confidence=${dietValidation.confidence}');

        // Parse diet plan
        final parsedDiet = _dietPlanParser.parse(dietOcr, dietValidation.matchedSignals);

        // Build DietAnalysisResult from parsed data
        DietMeal? breakfast;
        DietMeal? lunch;
        DietMeal? dinner;
        final List<DietMeal> snacks = [];

        for (final entry in parsedDiet.meals.entries) {
          final meal = DietMeal(name: _mealTypeToName(entry.key), items: entry.value);
          switch (entry.key) {
            case 'breakfast':
              breakfast = meal;
              break;
            case 'lunch':
              lunch = meal;
              break;
            case 'dinner':
              dinner = meal;
              break;
            default:
              snacks.add(meal);
          }
        }

        finalDietAnalysis = DietAnalysisResult(
          dailyCalorieTarget: null,
          breakfast: breakfast,
          lunch: lunch,
          dinner: dinner,
          snacks: snacks,
          proteinGrams: null,
          carbsGrams: null,
          fatGrams: null,
          avoidedFoods: const [],
          dietSummary: parsedDiet.hasContent
              ? 'Diyet listesinde ${parsedDiet.meals.length} öğün ve ${parsedDiet.detectedFoodItems.length} besin tespit edildi.'
              : 'Diyet listesi okundu ancak öğün yapısı net değil.',
          nutritionNotes: const ['Bu analiz kural tabanlı yapılmıştır. Tıbbi tavsiye niteliği taşımaz.'],
          rawExtractedText: dietOcr.rawText,
        );
      }
      debugPrint('[0] Diet OCR + validation + parsing done');

      // ── STEP 1: Blood OCR + Validation ─────────────────────
      if (onProgress != null) {
        onProgress(1, 'Kan değerleri OCR ile okunuyor...');
      }

      BloodAnalysisResult? finalBloodAnalysis;
      BloodValidationResult? bloodValidation;
      ParsedBloodValues? parsedBloodValues;

      if (previousBloodAnalysis != null) {
        finalBloodAnalysis = previousBloodAnalysis;
        debugPrint('Using previous blood analysis');
      } else if (bloodFile != null) {
        // Run OCR
        final bloodOcr = await _ocrService.extractText(bloodFile);
        if (!bloodOcr.success) {
          throw AnalysisException('blood_ocr_failed', 'Kan değerlerinden metin çıkarılamadı.');
        }

        // Validate
        bloodValidation = _bloodValidator.validate(bloodOcr);
        if (!bloodValidation.isBloodTest) {
          throw AnalysisException('invalid_blood', bloodValidation.message);
        }
        debugPrint('Blood validation: confidence=${bloodValidation.confidence}');

        // Parse blood values
        parsedBloodValues = _bloodValueParser.parse(bloodOcr, bloodValidation.matchedSignals);

        // Convert to BloodAnalysisResult
        final List<BloodMarker> markers = [];
        for (final entry in parsedBloodValues.values.entries) {
          final pv = entry.value;
          markers.add(BloodMarker(
            name: pv.name,
            value: pv.value?.toString(),
            unit: pv.unit,
            referenceRange: pv.referenceRangeLow != null && pv.referenceRangeHigh != null
                ? '${pv.referenceRangeLow} - ${pv.referenceRangeHigh}'
                : null,
            status: pv.status,
          ));
        }

        final attention = markers
            .where((m) => m.status == 'low' || m.status == 'high')
            .map((m) => m.name)
            .toList();

        finalBloodAnalysis = BloodAnalysisResult(
          markers: markers,
          generalNote: markers.isNotEmpty
              ? '${markers.length} kan değeri tespit edildi.${attention.isNotEmpty ? ' Dikkat edilmesi gerekenler: ${attention.join(", ")}.' : ''}'
              : 'Kan değerleri okundu.',
          safetyWarning: 'Bu değerlendirme yalnızca beslenme kişiselleştirmesi içindir. Kesin değerlendirme için sağlık uzmanına danışın.',
          rawExtractedText: bloodOcr.rawText,
        );
      } else {
        throw AnalysisException('missing_blood', 'Kan değeri belgesi bulunamadı.');
      }
      debugPrint('[1] Blood OCR + validation + parsing done');

      // ── STEP 2: Health Rule Engine ─────────────────────────
      if (onProgress != null) {
        onProgress(2, 'Kural motoru çalışıyor...');
      }

      // Parse diet for rule engine if needed
      ParsedDietPlan? parsedDietForEngine;
      if (dietFile != null && dietAnalysis == null) {
        final dietOcr = await _ocrService.extractText(dietFile);
        if (dietOcr.success) {
          final dv = _dietValidator.validate(dietOcr);
          parsedDietForEngine = _dietPlanParser.parse(dietOcr, dv.matchedSignals);
        }
      }

      // Parse blood for rule engine if not already done
      ParsedBloodValues bpvForEngine = parsedBloodValues ?? ParsedBloodValues(
        isBloodTest: true,
        confidence: 0.8,
        message: 'From previous analysis',
        values: {},
      );

      // If we used previous blood analysis, try parsing from its markers
      if (parsedBloodValues == null && previousBloodAnalysis != null) {
        final values = <String, ParsedBloodValue>{};
        for (final m in previousBloodAnalysis.markers) {
          final normalizedName = _normalizeMarkerName(m.name);
          if (normalizedName != null) {
            values[normalizedName] = ParsedBloodValue(
              name: m.name,
              value: double.tryParse(m.value ?? ''),
              unit: m.unit ?? '',
              status: m.status,
              referenceRangeLow: m.referenceRange?.split(' - ').firstOrNull,
              referenceRangeHigh: m.referenceRange?.split(' - ').lastOrNull,
            );
          }
        }
        bpvForEngine = ParsedBloodValues(
          isBloodTest: true,
          confidence: 0.8,
          message: 'From previous analysis',
          values: values,
        );
      }

      final ruleResult = _ruleEngine.evaluate(
        bloodValues: bpvForEngine,
        dietPlan: parsedDietForEngine,
      );

      debugPrint('[2] Rule engine results:');
      debugPrint('  lab_flags: ${ruleResult.labFlags}');
      debugPrint('  recipe_tags: ${ruleResult.recipeTags}');
      debugPrint('  avoid_tags: ${ruleResult.avoidTags}');
      debugPrint('  diet_gaps: ${ruleResult.dietGaps}');

      // ── STEP 3: Combined Health Analysis ───────────────────
      if (onProgress != null) {
        onProgress(3, 'Beslenme profili değerlendiriliyor...');
      }

      // Combined analysis uses rule engine results instead of raw AI
      final combinedAnalysis = CombinedHealthAnalysis(
        combinedSummary: _buildCombinedSummary(finalDietAnalysis, finalBloodAnalysis, ruleResult),
        nutritionPriorities: ruleResult.recipeTags,
        avoidOrLimit: ruleResult.avoidTags,
        recommendedMealFocus: ruleResult.dietGaps,
        safetyNotes: const [
          'Bu değerlendirme yalnızca beslenme kişiselleştirmesi içindir. Kesin değerlendirme için sağlık uzmanına danışın.',
        ],
      );
      debugPrint('[3] Combined analysis done (rule-based)');

      // ── STEP 4: Fetch Recipes ──────────────────────────────
      if (onProgress != null) {
        onProgress(4, 'Tarifler getiriliyor...');
      }

      List<RecipeModel> recipes = [];
      try {
        recipes = await _supabaseRecipeRepository.getAllRecipes();
      } catch (e) {
        debugPrint('[4] Supabase recipes fetch failed: $e');
        // Non-fatal: continue with empty recipes
      }
      debugPrint('[4] Supabase recipe count: ${recipes.length}');

      // ── STEP 5: Filter Recipes by Tags ─────────────────────
      if (onProgress != null) {
        onProgress(4, 'Tarifler etiketlere göre filtreleniyor...');
      }

      // Filter recipes matching recipe_tags from rule engine
      List<RecipeModel> filteredRecipes = recipes;
      if (ruleResult.recipeTags.isNotEmpty && recipes.isNotEmpty) {
        filteredRecipes = recipes.where((r) {
          final recipeTagSet = r.tags.map((t) => t.toLowerCase()).toSet();
          for (final tag in ruleResult.recipeTags) {
            final normalTag = tag.toLowerCase().replaceAll('_', ' ');
            if (recipeTagSet.any((rt) => rt.contains(normalTag) || normalTag.contains(rt))) {
              return true;
            }
          }
          // Also check ingredient names for tag matches
          for (final ing in r.ingredients) {
            final ingLower = ing.name.toLowerCase();
            for (final tag in ruleResult.recipeTags) {
              final normalTag = tag.toLowerCase().replaceAll('_', ' ');
              if (ingLower.contains(normalTag) || normalTag.contains(ingLower)) {
                return true;
              }
            }
          }
          return false;
        }).toList();

        if (filteredRecipes.isEmpty) {
          filteredRecipes = recipes; // Fallback to all recipes
        }
        debugPrint('[5] Filtered recipes: ${filteredRecipes.length}');
      }

      // ── STEP 6: AI-based Recipe Recommendation ─────────────
      // Only sends anonymized JSON to AI, never raw documents
      List<RecommendedRecipeViewModel> recommendations = [];
      if (filteredRecipes.isNotEmpty) {
        try {
          recommendations = await _recipeRecommendationService.recommendRecipes(
            userProfile: userProfile,
            dietAnalysis: finalDietAnalysis,
            bloodAnalysis: finalBloodAnalysis,
            combinedAnalysis: combinedAnalysis,
            candidateRecipes: filteredRecipes,
            labFlags: ruleResult.labFlags,
            recipeTags: ruleResult.recipeTags,
            avoidTags: ruleResult.avoidTags,
            dietGaps: ruleResult.dietGaps,
            dietPlanSummary: parsedDietForEngine?.meals ?? {},
          );
        } catch (e) {
          debugPrint('[6] Recipe recommendation failed: $e');
        }
      }
      debugPrint('[6] Recommendations: ${recommendations.length}');

      // ── STEP 7: Save to History ────────────────────────────
      bool savedToHistory = false;
      try {
        await _analysisHistoryRepository.saveAnalysisHistory(
          dietAnalysis: finalDietAnalysis,
          bloodAnalysis: finalBloodAnalysis,
          combinedAnalysis: combinedAnalysis,
        );
        savedToHistory = true;
      } catch (saveError) {
        debugPrint('[7] History save failed: $saveError');
      }

      debugPrint('========== FULL ANALYSIS SUCCESS ==========');
      return FullAnalysisResult(
        dietAnalysis: finalDietAnalysis,
        bloodAnalysis: finalBloodAnalysis,
        combinedAnalysis: combinedAnalysis,
        recommendations: recommendations,
        userHealthProfile: userProfile,
        candidateRecipes: filteredRecipes,
        savedToHistory: savedToHistory,
      );
    } catch (e, st) {
      debugPrint('========== FULL ANALYSIS FAILED ==========');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $st');
      if (e is AnalysisException) {
        rethrow;
      } else {
        throw AnalysisException('unknown_error', 'Bilinmeyen analiz hatası', originalError: e, stackTrace: st);
      }
    }
  }

  String _mealTypeToName(String type) {
    switch (type) {
      case 'breakfast': return 'Kahvaltı';
      case 'lunch': return 'Öğle Yemeği';
      case 'dinner': return 'Akşam Yemeği';
      case 'snack': return 'Ara Öğün';
      default: return 'Öğün';
    }
  }

  String _buildCombinedSummary(
    DietAnalysisResult diet,
    BloodAnalysisResult? blood,
    HealthRuleEngineResult rules,
  ) {
    final parts = <String>[];
    parts.add('Diyet listeniz ve sağlık profiliniz kural tabanlı olarak analiz edildi.');

    if (diet.breakfast != null || diet.lunch != null || diet.dinner != null) {
      final mealCount = [
        if (diet.breakfast != null) 1,
        if (diet.lunch != null) 1,
        if (diet.dinner != null) 1,
      ].length;
      parts.add('Diyet listenizde $mealCount ana öğün tespit edildi.');
    }

    if (blood != null && blood.markers.isNotEmpty) {
      final abnormal = blood.markers.where((m) => m.status == 'low' || m.status == 'high').length;
      if (abnormal > 0) {
        parts.add('Kan değerlerinizde $abnormal değer referans aralığı dışında.');
      } else {
        parts.add('Kan değerleriniz referans aralığında görünüyor.');
      }
    }

    if (rules.recipeTags.isNotEmpty) {
      parts.add('Size özel önerilen beslenme odağı: ${rules.recipeTags.take(3).join(", ")}.');
    }

    parts.add('Bu değerlendirme tıbbi tavsiye niteliği taşımaz. Lütfen doktorunuza danışın.');

    return parts.join(' ');
  }

  String? _normalizeMarkerName(String name) {
    final lower = name.toLowerCase().trim();
    const map = {
      'b12': 'b12', 'b 12': 'b12', 'vitamin b12': 'b12',
      'vitamin d': 'vitamin_d', 'd vitamini': 'vitamin_d',
      'ferritin': 'ferritin',
      'demir': 'iron', 'iron': 'iron',
      'ldl': 'ldl',
      'hdl': 'hdl',
      'total kolesterol': 'total_cholesterol',
      'trigliserid': 'triglyceride',
      'glukoz': 'glucose', 'glucose': 'glucose',
      'hba1c': 'hba1c',
      'tsh': 'tsh',
      'alt': 'alt',
      'ast': 'ast',
      'kreatinin': 'creatinine',
      'üre': 'urea',
      'crp': 'crp',
      'hemoglobin': 'hemoglobin', 'hgb': 'hemoglobin',
      'wbc': 'wbc', 'lökosit': 'wbc',
      'rbc': 'rbc', 'eritrosit': 'rbc',
      'plt': 'plt', 'trombosit': 'plt',
    };
    return map[lower];
  }
}
