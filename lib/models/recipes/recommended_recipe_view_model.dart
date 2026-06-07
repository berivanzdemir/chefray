import '../recipe_model.dart';
import '../ai/analysis_results.dart';

class RecommendedRecipeViewModel {
  final RecipeModel recipe;
  final RecipeRecommendationResult recommendation;

  const RecommendedRecipeViewModel({
    required this.recipe,
    required this.recommendation,
  });
}
