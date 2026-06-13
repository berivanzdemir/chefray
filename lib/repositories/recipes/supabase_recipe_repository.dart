import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../models/recipe_model.dart';

class SupabaseRecipeRepository {
  final _client = Supabase.instance.client;

  Future<List<RecipeModel>> getAllRecipes() async {
    try {
      final response = await _client
          .from('recipes')
          .select()
          .order('title', ascending: true);

      return (response as List)
          .map((json) => RecipeModel.fromSupabaseJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting all recipes from Supabase: $e');
      return [];
    }
  }

  Future<List<RecipeModel>> getRecommendedRecipes(
    String selectedMealType, {
    String sortFilter = 'En Uygun',
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      final columns =
          'id, title, display_title, description, image_url, category, prep_time, cook_time, total_time_min, calories_kcal, protein_g, meal_type, meal_type_v2, dish_type, dish_type_v2, is_recommendable, is_diet_friendly, is_gluten_free, is_high_protein, is_low_calorie, gluten_status, calorie_status, protein_status, recommendation_ready, blocked_reason, exclude_reason_v2, servings, source_url, created_at';

      var query = _client
          .from('recipes')
          .select(columns)
          .eq('recommendation_ready', true)
          .eq('is_recommendable', true)
          .eq('is_diet_friendly', true)
          .eq('meal_type', selectedMealType);

      if (sortFilter == 'Yüksek Protein' || sortFilter == 'En Yüksek Protein') {
        query = query.eq('protein_status', 'high');
      } else if (sortFilter == 'Düşük Kalori') {
        query = query.eq('calorie_status', 'low');
      } else if (sortFilter == 'Glutensiz') {
        query = query.eq('gluten_status', 'gluten_free');
      }

      // baby_food / unsuitable olmayanlar (blocked_reason null veya bos)
      query = query.or('blocked_reason.is.null,blocked_reason.eq.');

      final rangeStart = page * pageSize;
      final rangeEnd = rangeStart + pageSize - 1;

      final response = await query.range(rangeStart, rangeEnd);

      final recipes = (response as List)
          .map((json) => RecipeModel.fromSupabaseJson(json))
          .toList();

      return recipes;
    } catch (e) {
      debugPrint('Recipe query error in getRecommendedRecipes: $e');
      return [];
    }
  }

  Future<List<RecipeModel>> getRecipesByMealType(String mealType) async {
    try {
      final all = await getAllRecipes();
      return all
          .where((r) => r.mealType.toLowerCase() == mealType.toLowerCase())
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<RecipeModel>> searchRecipes(String query) async {
    if (query.trim().isEmpty) return getAllRecipes();
    try {
      final response = await _client
          .from('recipes')
          .select()
          .ilike('title', '%$query%');

      return (response as List)
          .map((json) => RecipeModel.fromSupabaseJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error searching recipes in Supabase: $e');
      return [];
    }
  }

  Future<List<RecipeModel>> searchRecipesDetailed(
    String query,
    String selectedMealType,
  ) async {
    if (query.trim().isEmpty) return [];
    try {
      var q = _client
          .from('recipes')
          .select('*, ingredients_text')
          .eq('recommendation_ready', true)
          .eq('is_recommendable', true)
          .eq('is_diet_friendly', true)
          .eq('meal_type', selectedMealType);

      final qStr = '%$query%';
      q = q.or(
        'title.ilike.$qStr,description.ilike.$qStr,category.ilike.$qStr',
      );

      q = q.or('blocked_reason.is.null,blocked_reason.eq.');

      final response = await q.limit(50);

      return (response as List)
          .map((json) => RecipeModel.fromSupabaseJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error searching detailed recipes in Supabase: $e');
      return [];
    }
  }

  Future<List<RecipeModel>> getRecipesByCategory(String category) async {
    try {
      final response = await _client
          .from('recipes')
          .select()
          .ilike('category', '%$category%');

      return (response as List)
          .map((json) => RecipeModel.fromSupabaseJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error filtering recipes by category: $e');
      return [];
    }
  }

  /// Home screen "Sana Özel Öneriler" — gerçek tariflerden gelir.
  Future<List<RecipeModel>> getHomeRecommendations({int limit = 10}) async {
    try {
      final response = await _client
          .from('recipes')
          .select('*, ingredients_text')
          .eq('recommendation_ready', true)
          .eq('is_recommendable', true)
          .eq('is_diet_friendly', true)
          .not('meal_type', 'is', null)
          .limit(limit);

      return (response as List)
          .map((json) => RecipeModel.fromSupabaseJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting home recommendations: $e');
      return [];
    }
  }

  Future<RecipeModel?> getRecipeById(String id) async {
    try {
      final response = await _client
          .from('recipes')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return RecipeModel.fromSupabaseJson(response);
    } catch (e) {
      debugPrint('Error getting recipe by ID from Supabase: $e');
      return null;
    }
  }
}
