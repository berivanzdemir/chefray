import '../recipe_model.dart';
import 'analysis_results.dart';
import '../recipes/recommended_recipe_view_model.dart';
import '../user_health_profile.dart';

class FullAnalysisResult {
  final DietAnalysisResult dietAnalysis;
  final BloodAnalysisResult? bloodAnalysis;
  final CombinedHealthAnalysis combinedAnalysis;
  final List<RecommendedRecipeViewModel> recommendations;
  final UserHealthProfile userHealthProfile;
  final List<RecipeModel> candidateRecipes;
  final bool savedToHistory;

  const FullAnalysisResult({
    required this.dietAnalysis,
    required this.bloodAnalysis,
    required this.combinedAnalysis,
    required this.recommendations,
    required this.userHealthProfile,
    required this.candidateRecipes,
    required this.savedToHistory,
  });
}
