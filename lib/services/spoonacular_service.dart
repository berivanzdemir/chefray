import 'package:flutter/foundation.dart';
import '../models/recipe_model.dart';
import '../repositories/recipes/supabase_recipe_repository.dart';

class SpoonacularService {
  Future<List<RecipeModel>> getRecipes({
    String query = '',
    int number = 10,
  }) async {
    // TODO: Spoonacular/External API disabled. All requests are routed to SupabaseRecipeRepository.
    debugPrint(
      'SpoonacularService.getRecipes: External API bypassed. Fetching from Supabase...',
    );
    try {
      final repo = SupabaseRecipeRepository();
      if (query.isNotEmpty) {
        return await repo.searchRecipes(query);
      }
      return await repo.getAllRecipes();
    } catch (e) {
      debugPrint('SpoonacularService Supabase redirect error: $e');
      return [];
    }
  }
}
