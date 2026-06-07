import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/recipe_model.dart';
import '../../models/user_health_profile.dart';
import '../../models/ai/analysis_results.dart';
import '../../models/recipes/recommended_recipe_view_model.dart';
import 'gemini_service.dart';

class RecipeRecommendationService {
  final _gemini = GeminiService();

  /// Recommend recipes based on user profile, diet, and blood analysis.
  ///
  /// IMPORTANT: Only anonymized summary data is sent to AI.
  /// Raw documents, OCR text, and personal identifiers are NEVER sent.
  Future<List<RecommendedRecipeViewModel>> recommendRecipes({
    required UserHealthProfile userProfile,
    required DietAnalysisResult dietAnalysis,
    required BloodAnalysisResult? bloodAnalysis,
    required CombinedHealthAnalysis? combinedAnalysis,
    required List<RecipeModel> candidateRecipes,
    // Anonymized rule engine output
    List<String> labFlags = const [],
    List<String> recipeTags = const [],
    List<String> avoidTags = const [],
    List<String> dietGaps = const [],
    Map<String, List<String>> dietPlanSummary = const {},
  }) async {
    debugPrint('RECOMMENDATION SERVICE START: ${candidateRecipes.length} candidates');

    // 1. Local Pre-filtering (Allergies & Diet Preferences)
    final userAllergies = userProfile.allergies.map((e) => e.toLowerCase().trim()).toList();
    final userPrefs = userProfile.dietPreferences.map((e) => e.toLowerCase().trim()).toList();

    List<RecipeModel> locallyFiltered = [];
    for (var recipe in candidateRecipes) {
      bool isExcluded = false;

      // 1a. Allergies Filter
      final recipeAllergens = recipe.allergens.map((e) => e.toLowerCase().trim()).toList();
      for (var allergy in userAllergies) {
        if (recipeAllergens.contains(allergy)) {
          isExcluded = true;
          break;
        }
        final titleLower = recipe.title.toLowerCase();
        if (allergy.contains('gluten') &&
            (recipeAllergens.contains('gluten') || titleLower.contains('un ') || titleLower.contains('buğday'))) {
          isExcluded = true;
          break;
        }
        if ((allergy.contains('laktoz') || allergy.contains('süt')) &&
            (recipeAllergens.contains('laktoz') || recipeAllergens.contains('süt ürünleri') ||
                titleLower.contains('süt') || titleLower.contains('yoğurt') || titleLower.contains('peynir'))) {
          isExcluded = true;
          break;
        }
      }
      if (isExcluded) continue;

      // 1b. Avoid tags filter (from rule engine)
      if (avoidTags.isNotEmpty) {
        final recipeText = '${recipe.title} ${recipe.ingredients.map((i) => i.name).join(" ")} ${recipe.tags.join(" ")}'.toLowerCase();
        for (final avoidTag in avoidTags) {
          final normalTag = avoidTag.toLowerCase().replaceAll('_', ' ');
          if (_tagConflicts(normalTag, recipeText, recipe.tags)) {
            isExcluded = true;
            break;
          }
        }
        if (isExcluded) continue;
      }

      // 1c. Diet Preferences Filter
      final recipeDietTypes = recipe.dietTypes.map((e) => e.toLowerCase().trim()).toList();
      for (var pref in userPrefs) {
        if (pref.contains('vegan') && !recipeDietTypes.contains('vegan')) {
          isExcluded = true;
          break;
        }
        if (pref.contains('vejetaryen') && !recipeDietTypes.contains('vejetaryen')) {
          isExcluded = true;
          break;
        }
        if (pref.contains('glutensiz') && !recipeDietTypes.contains('glutensiz')) {
          isExcluded = true;
          break;
        }
        if (pref.contains('laktozsuz') && !recipeDietTypes.contains('laktozsuz')) {
          isExcluded = true;
          break;
        }
      }
      if (isExcluded) continue;

      locallyFiltered.add(recipe);
    }

    debugPrint('After local filtering: ${locallyFiltered.length} candidates');

    // Take top 35 candidates for context limit
    final candidateSubset = locallyFiltered.take(35).toList();
    if (candidateSubset.isEmpty) {
      debugPrint('No candidates left after filtering!');
      return [];
    }

    // 2. Serialize Candidate Recipes to Minimal JSON
    final List<Map<String, dynamic>> minimalCandidates = candidateSubset.map((r) {
      return {
        "recipeId": r.id.toString(),
        "title": r.title,
        "calories": r.calories,
        "protein": r.protein,
        "carbs": r.carbs,
        "fat": r.fat,
        "ingredients": r.ingredients.map((i) => i.name).toList(),
        "tags": r.tags,
        "allergens": r.allergens,
        "dietTypes": r.dietTypes,
      };
    }).toList();

    // 3. Build anonymized prompt
    // NEVER send raw documents, blood values, or personal identifiers.
    final prompt = _buildAnonymizedPrompt(
      userProfile: userProfile,
      dietAnalysis: dietAnalysis,
      labFlags: labFlags,
      recipeTags: recipeTags,
      avoidTags: avoidTags,
      dietGaps: dietGaps,
      dietPlanSummary: dietPlanSummary,
      candidateRecipes: minimalCandidates,
      combinedAnalysis: combinedAnalysis,
      bloodAnalysis: bloodAnalysis,
    );

    try {
      final rawResponse = await _gemini.generateText(prompt: prompt);
      debugPrint('Gemini recommendations response received: ${rawResponse.length} chars');

      if (rawResponse.trim().isEmpty) {
        throw Exception('Empty response from Gemini');
      }

      final List<dynamic> jsonList = _gemini.extractAndParseJsonList(rawResponse);
      final List<RecipeRecommendationResult> recommendations = jsonList
          .map((item) => RecipeRecommendationResult.fromJson(item as Map<String, dynamic>))
          .toList();

      final List<RecommendedRecipeViewModel> viewModels = [];
      for (var rec in recommendations) {
        final matchingRecipe = candidateSubset.firstWhere(
          (r) => r.id.toString() == rec.recipeId.toString(),
          orElse: () => const RecipeModel(
            id: '', title: '', description: '', calories: 0, protein: 0, carbs: 0, fat: 0,
            timeMinutes: 0, tags: [], ingredients: [], steps: [], mealType: '',
          ),
        );

        if (matchingRecipe.id.isNotEmpty) {
          viewModels.add(RecommendedRecipeViewModel(
            recipe: matchingRecipe,
            recommendation: rec,
          ));
        }
      }

      viewModels.sort((a, b) => b.recommendation.matchScore.compareTo(a.recommendation.matchScore));
      if (viewModels.isNotEmpty) return viewModels;
    } catch (e, st) {
      debugPrint('Error generating recipe recommendations: $e');
      debugPrint('Stack trace: $st');
    }

    // ── LOCAL FALLBACK ──
    return _localFallback(locallyFiltered, userProfile, dietAnalysis, recipeTags);
  }

  String _buildAnonymizedPrompt({
    required UserHealthProfile userProfile,
    required DietAnalysisResult dietAnalysis,
    required List<String> labFlags,
    required List<String> recipeTags,
    required List<String> avoidTags,
    required List<String> dietGaps,
    required Map<String, List<String>> dietPlanSummary,
    required List<Map<String, dynamic>> candidateRecipes,
    CombinedHealthAnalysis? combinedAnalysis,
    BloodAnalysisResult? bloodAnalysis,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('Sen ChefRay asistanısın. Görevin, verilen aday tarif listesini kullanıcının sağlık profili, diyet listesi ve beslenme ihtiyaçlarına göre değerlendirmek, her birini 0-100 arasında puanlamak ve en uygun olanları sıralamaktır.');

    // Only anonymized summary data — no raw documents, no PII
    buffer.writeln('\nKullanıcı Sağlık Profili (Anonim):');
    buffer.writeln('- Yaş: ${userProfile.age ?? "Belirtilmemiş"}');
    buffer.writeln('- Cinsiyet: ${userProfile.gender ?? "Belirtilmemiş"}');
    buffer.writeln('- Hedef: ${userProfile.goalType ?? "Dengeli Beslenme"}');
    buffer.writeln('- Alerjiler: ${userProfile.allergies.isEmpty ? "Yok" : userProfile.allergies.join(", ")}');
    buffer.writeln('- Beslenme Tercihleri: ${userProfile.dietPreferences.isEmpty ? "Belirtilmedi" : userProfile.dietPreferences.join(", ")}');

    // Anonymized diet plan summary (meal structure, not raw text)
    if (dietPlanSummary.isNotEmpty) {
      buffer.writeln('\nDiyet Planı Özeti (Anonim):');
      for (final entry in dietPlanSummary.entries) {
        buffer.writeln('- ${entry.key}: ${entry.value.join(", ")}');
      }
    } else {
      buffer.writeln('\nDiyet Planı:');
      buffer.writeln('- Kalori Hedefi: ${dietAnalysis.dailyCalorieTarget ?? "Belirtilmemiş"} kcal');
      buffer.writeln('- Kaçınılan Besinler: ${dietAnalysis.avoidedFoods.isEmpty ? "Yok" : dietAnalysis.avoidedFoods.join(", ")}');
    }

    // Rule engine flags — anonymized lab indicators, NOT raw values
    if (labFlags.isNotEmpty) {
      buffer.writeln('\nSağlık Durumu Göstergeleri (Anonim):');
      buffer.writeln('- lab_flags: ${labFlags.join(", ")}');
    }
    if (recipeTags.isNotEmpty) {
      buffer.writeln('- Önerilen Beslenme Odağı: ${recipeTags.join(", ")}');
    }
    if (avoidTags.isNotEmpty) {
      buffer.writeln('- Sınırlanması Gerekenler: ${avoidTags.join(", ")}');
    }
    if (dietGaps.isNotEmpty) {
      buffer.writeln('- Beslenme Destek İhtiyaçları: ${dietGaps.join(", ")}');
    }

    buffer.writeln('\nDeğerlendirilecek Aday Tarif Listesi:');
    buffer.writeln(jsonEncode(candidateRecipes));

    buffer.writeln('\nKESİN KURALLAR:');
    buffer.writeln('1. YENİ TARİF ÜRETMEYİN. Sadece listedeki tarifleri değerlendirin.');
    buffer.writeln('2. recipeId alanını tam olarak listedeki id ile eşleştirin.');
    buffer.writeln('3. SADECE geçerli JSON array döndürün. Markdown ```json kullanmayın.');
    buffer.writeln('4. Her tarif için Türkçe kısa matchReason yazın.');
    buffer.writeln('5. Tıbbi tanı koymayın, ilaç veya tedavi önermeyin.');
    buffer.writeln('6. "Doktorunuza/diyetisyeninize danışın" uyarısını uygun şekilde ekleyin.');

    buffer.writeln('\nÇIKTI JSON FORMATI (Sadece bu formatta bir JSON Array):');
    buffer.writeln('[');
    buffer.writeln('  {');
    buffer.writeln('    "recipeId": "string",');
    buffer.writeln('    "recipeTitle": "string",');
    buffer.writeln('    "matchScore": 0,');
    buffer.writeln('    "suggestedMealType": "Kahvaltı | Öğle Yemeği | Akşam Yemeği | Ara Öğün",');
    buffer.writeln('    "matchReason": "Neden uygun olduğunu açıklayan Türkçe kısa cümle",');
    buffer.writeln('    "healthNotes": ["Öne çıkan sağlık faydası"],');
    buffer.writeln('    "warnings": ["varsa dikkat edilmesi gereken nokta"],');
    buffer.writeln('    "allergenWarnings": ["varsa alerjen uyarısı"],');
    buffer.writeln('    "priorityTags": ["Protein Kaynağı", "Düşük Sodyum" vb],');
    buffer.writeln('    "isSafeForUser": true');
    buffer.writeln('  }');
    buffer.writeln(']');

    return buffer.toString();
  }

  bool _tagConflicts(String avoidTag, String recipeText, List<String> recipeTags) {
    final recipeTextLower = recipeText;
    final recipeTagsLower = recipeTags.map((t) => t.toLowerCase()).toList();

    final conflictMap = {
      'fried': ['kızart', 'kizart', 'fried', 'tava'],
      'high_saturated_fat': ['tereyağı', 'tereyagi', 'krema', 'kaymak', 'kuyruk yağı'],
      'refined_carbs': ['beyaz ekmek', 'beyaz un', 'şeker', 'seker', 'beyaz pirinç'],
      'sugar': ['şeker', 'seker', 'reçel', 'recel', 'pekmez', 'bal', 'çikolata', 'cikolata'],
      'high_glycemic': ['beyaz ekmek', 'patates püresi', 'patates puresi', 'mısır gevreği'],
      'processed_food': ['sosis', 'salam', 'hazır', 'paket', 'cips'],
      'processed_meat': ['sosis', 'salam', 'sucuk', 'pastırma', 'pastirma'],
      'alcohol': ['şarap', 'sarap', 'bira', 'rakı', 'raki', 'votka'],
    };

    final keywords = conflictMap[avoidTag] ?? [];
    for (final kw in keywords) {
      if (recipeTextLower.contains(kw)) return true;
      for (final rt in recipeTagsLower) {
        if (rt.contains(kw)) return true;
      }
    }
    return false;
  }

  List<RecommendedRecipeViewModel> _localFallback(
    List<RecipeModel> filtered,
    UserHealthProfile userProfile,
    DietAnalysisResult dietAnalysis,
    List<String> recipeTags,
  ) {
    debugPrint('Using local fallback for recommendations...');
    final fallbackList = <RecommendedRecipeViewModel>[];

    final isHighProtein = userProfile.goalType?.toLowerCase().contains('protein') == true;
    final isLowCalorie = userProfile.goalType?.toLowerCase().contains('kilo ver') == true ||
        (dietAnalysis.dailyCalorieTarget != null && dietAnalysis.dailyCalorieTarget! < 1500);

    filtered.sort((a, b) {
      if (isHighProtein) return b.protein.compareTo(a.protein);
      if (isLowCalorie) return a.calories.compareTo(b.calories);
      return 0;
    });

    final fallbackSubset = filtered.take(10).toList();
    for (var recipe in fallbackSubset) {
      fallbackList.add(RecommendedRecipeViewModel(
        recipe: recipe,
        recommendation: RecipeRecommendationResult(
          recipeId: recipe.id.toString(),
          recipeTitle: recipe.title,
          matchScore: 85,
          suggestedMealType: 'Öğle / Akşam Yemeği',
          matchReason: 'Beslenme profilinize uygun olarak filtrelendi.',
          healthNotes: ['Güvenli ve uyumlu tarif'],
          warnings: [],
          allergenWarnings: [],
          priorityTags: recipeTags.isNotEmpty ? recipeTags : ['Önerilen'],
          isSafeForUser: true,
        ),
      ));
    }
    return fallbackList;
  }
}
