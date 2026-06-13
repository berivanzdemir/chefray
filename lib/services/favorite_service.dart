import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipe_model.dart';

class FavoriteService {
  static final _supabase = Supabase.instance.client;
  static final ValueNotifier<int> favoriteUpdateNotifier = ValueNotifier(0);

  /// Check if a recipe is a favorite for the current user
  static Future<bool> isFavorite(String recipeId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final response = await _supabase
          .from('favorites')
          .select('id')
          .eq('user_id', user.id)
          .eq('recipe_id', recipeId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      debugPrint('Error checking favorite: $e');
      return false;
    }
  }

  /// Get the set of all favorite recipe IDs for the current user
  static Future<Set<String>> getFavoriteRecipeIds() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return {};

    try {
      final response = await _supabase
          .from('favorites')
          .select('recipe_id')
          .eq('user_id', user.id);

      final ids = (response as List)
          .map((row) => row['recipe_id']?.toString())
          .whereType<String>()
          .toSet();
      return ids;
    } catch (e) {
      debugPrint('Error fetching favorite recipe IDs: $e');
      return {};
    }
  }

  /// Add a recipe to favorites
  static Future<void> addFavorite(String recipeId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.from('favorites').insert({
        'user_id': user.id,
        'recipe_id': recipeId,
      });
      favoriteUpdateNotifier.value++;
    } catch (e) {
      debugPrint('Error adding favorite: $e');
    }
  }

  /// Remove a recipe from favorites
  static Future<void> removeFavorite(String recipeId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase
          .from('favorites')
          .delete()
          .eq('user_id', user.id)
          .eq('recipe_id', recipeId);
      favoriteUpdateNotifier.value++;
    } catch (e) {
      debugPrint('Error removing favorite: $e');
    }
  }

  /// Toggle favorite status of a recipe
  static Future<bool> toggleFavorite(String recipeId) async {
    final isFav = await isFavorite(recipeId);
    if (isFav) {
      await removeFavorite(recipeId);
      return false;
    } else {
      await addFavorite(recipeId);
      return true;
    }
  }

  /// Get list of favorite RecipeModels for the current user
  static Future<List<RecipeModel>> getFavoriteRecipes() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      // First try nested select (join)
      final response = await _supabase
          .from('favorites')
          .select('recipe_id, created_at, recipes(*)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final List<RecipeModel> recipes = [];
      for (var row in response as List) {
        final recipeData = row['recipes'];
        if (recipeData != null) {
          if (recipeData is Map<String, dynamic>) {
            recipes.add(RecipeModel.fromSupabaseJson(recipeData));
          } else if (recipeData is List && recipeData.isNotEmpty) {
            recipes.add(
              RecipeModel.fromSupabaseJson(
                recipeData.first as Map<String, dynamic>,
              ),
            );
          }
        }
      }

      if (recipes.isNotEmpty) return recipes;

      // Fallback if nested select returns empty but IDs exist
      final ids = (response)
          .map((row) => row['recipe_id']?.toString())
          .whereType<String>()
          .toList();

      if (ids.isEmpty) return [];

      final recipesResponse = await _supabase
          .from('recipes')
          .select()
          .inFilter('id', ids);

      final List<RecipeModel> fallbackRecipes = (recipesResponse as List)
          .map(
            (row) => RecipeModel.fromSupabaseJson(row as Map<String, dynamic>),
          )
          .toList();

      // Sort by the order in the favorites list
      fallbackRecipes.sort(
        (a, b) => ids.indexOf(a.id).compareTo(ids.indexOf(b.id)),
      );
      return fallbackRecipes;
    } catch (e) {
      debugPrint('Error getting favorite recipes: $e');
      return [];
    }
  }
}
