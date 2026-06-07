import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/ai/analysis_results.dart';
import '../../models/user_health_profile.dart';
import '../../models/recipe_model.dart';
import 'gemini_service.dart';
import 'recipe_recommendation_service.dart';

/// Combines diet + blood analysis with user profile to produce:
/// 1. A CombinedHealthAnalysis summary.
/// 2. Ranked recipe recommendations from candidate recipes.
class CombinedAnalysisService {
  final GeminiService _gemini = GeminiService();

  // ── Combined Summary ─────────────────────────────────────────────────────

  Future<CombinedHealthAnalysis> analyzeDietAndBloodTogether({
    required DietAnalysisResult dietAnalysis,
    required BloodAnalysisResult bloodAnalysis,
    required UserHealthProfile userHealthProfile,
  }) async {
    debugPrint('Combined analysis started');
    try {
      final profileCtx = _buildProfileContext(userHealthProfile);
      final dietCtx = _buildDietContext(dietAnalysis);
      final bloodCtx = _buildBloodContext(bloodAnalysis);

      final prompt = '''
Sen ChefRay asistanısın. Görevin diyet analiz sonucu ile kan tahlili sonucunu birleştirip genel bir sağlık özeti oluşturmaktır.

Kullanıcı Profili:
$profileCtx

Diyet Analizi:
$dietCtx

Kan Tahlili:
$bloodCtx

KURALLAR:
1. Türkçe dilinde samimi ve profesyonel yaz.
2. Tıbbi tanı koyma, ilaç önerme.
3. Çıktıyı SADECE JSON objesi olarak döndür. Markdown ```json kullanma.

JSON Formatı:
{
  "generalSummary": "Genel birleştirilmiş sağlık ve diyet özeti",
  "nutritionPriorities": ["Protein artışı", "Demir takviyesi" vb],
  "avoidOrLimit": ["İşlenmiş şeker", "Tuz" vb],
  "waterTargetLiters": 2.5,
  "additionalHealthTips": ["Günde 30 dk yürüyüş", "C vitamini tüketimi" vb]
}
''';

      final responseText = await _gemini.generateText(prompt: prompt);
      
      String clean = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      final startIdx = clean.indexOf('{');
      final endIdx = clean.lastIndexOf('}');
      if (startIdx == -1 || endIdx == -1) return CombinedHealthAnalysis.empty();

      final jsonStr = clean.substring(startIdx, endIdx + 1);
      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
      
      return CombinedHealthAnalysis.fromJson(parsed);
    } catch (e) {
      debugPrint('CombinedAnalysisService error: $e');
      return CombinedHealthAnalysis.empty();
    }
  }

  // ── Recipe Ranking ────────────────────────────────────────────────────────

  Future<List<RecipeRecommendationResult>> rankRecipes({
    required List<RecipeModel> candidateRecipes,
    required UserHealthProfile userHealthProfile,
    required DietAnalysisResult dietAnalysis,
    required BloodAnalysisResult bloodAnalysis,
    required CombinedHealthAnalysis combinedAnalysis,
  }) async {
    try {
      final recService = RecipeRecommendationService();
      final viewModels = await recService.recommendRecipes(
        userProfile: userHealthProfile,
        dietAnalysis: dietAnalysis,
        bloodAnalysis: bloodAnalysis,
        combinedAnalysis: combinedAnalysis,
        candidateRecipes: candidateRecipes,
      );
      return viewModels.map((vm) => vm.recommendation).toList();
    } catch (e) {
      debugPrint('Redirected rankRecipes failed: $e');
      return _fallbackRanking(candidateRecipes);
    }
  }

  // ── Context Builders ──────────────────────────────────────────────────────

  String _buildProfileContext(UserHealthProfile p) => '''
Kullanıcı Profili:
- Yaş: ${p.age ?? 'Belirtilmedi'}
- Cinsiyet: ${p.gender ?? 'Belirtilmedi'}
- Boy: ${p.heightCm != null ? '${p.heightCm} cm' : 'Belirtilmedi'}
- Kilo: ${p.weightKg != null ? '${p.weightKg} kg' : 'Belirtilmedi'}
- Hedef: ${p.goalType ?? 'Belirtilmedi'}
- Aktivite Seviyesi: ${p.activityLevel ?? 'Belirtilmedi'}
- Sağlık Durumları: ${p.healthConditions.isEmpty ? 'Yok' : p.healthConditions.join(', ')}
- Alerjiler: ${p.allergies.isEmpty ? 'Yok' : p.allergies.join(', ')}
- Beslenme Tercihleri: ${p.dietPreferences.isEmpty ? 'Belirtilmedi' : p.dietPreferences.join(', ')}''';

  String _buildDietContext(DietAnalysisResult d) => '''
Diyet Analizi:
- Günlük Kalori Hedefi: ${d.dailyCalorieTarget ?? 'Belirtilmedi'}
- Protein: ${d.proteinGrams != null ? '${d.proteinGrams}g' : 'Belirtilmedi'}
- Karbonhidrat: ${d.carbsGrams != null ? '${d.carbsGrams}g' : 'Belirtilmedi'}
- Yağ: ${d.fatGrams != null ? '${d.fatGrams}g' : 'Belirtilmedi'}
- Kaçınılan Besinler: ${d.avoidedFoods.isEmpty ? 'Belirtilmedi' : d.avoidedFoods.join(', ')}
- Özet: ${d.dietSummary}''';

  String _buildBloodContext(BloodAnalysisResult b) {
    final markerStr = b.markers
        .map((m) => '${m.name}: ${m.value ?? '?'} ${m.unit ?? ''} (${m.status})')
        .join(', ');
    return '''
Kan Değerleri:
- Markerlar: ${markerStr.isEmpty ? 'Belirtilmedi' : markerStr}
- Genel Not: ${b.generalNote}''';
  }

  List<RecipeRecommendationResult> _fallbackRanking(
      List<RecipeModel> recipes) {
    return recipes
        .map((r) => RecipeRecommendationResult(
              recipeId: r.id,
              recipeTitle: r.title,
              matchScore: 75,
              suggestedMealType: r.mealType,
              matchReason: 'Genel beslenme açısından uygun görünüyor.',
              isSafeForUser: true,
            ))
        .toList();
  }
}
