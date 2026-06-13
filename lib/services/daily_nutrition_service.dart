import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipe_model.dart';

class DailyNutritionTotals {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;

  DailyNutritionTotals({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
  });

  factory DailyNutritionTotals.zero() {
    return DailyNutritionTotals(
      calories: 0,
      protein: 0,
      carbs: 0,
      fat: 0,
      fiber: 0,
    );
  }
}

class DailyNutritionService {
  static final _supabase = Supabase.instance.client;

  /// Log a completed recipe to daily_nutrition_logs
  static Future<bool> logCompletedRecipe(
    RecipeModel recipe,
    double servingMultiplier,
  ) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final calories =
          (double.tryParse(recipe.calories.toString()) ?? 0.0) *
          servingMultiplier;
      final protein =
          (double.tryParse(recipe.protein.toString()) ?? 0.0) *
          servingMultiplier;
      final carbs =
          (double.tryParse(recipe.carbs.toString()) ?? 0.0) * servingMultiplier;
      final fat =
          (double.tryParse(recipe.fat.toString()) ?? 0.0) * servingMultiplier;

      // We don't have fiber in basic recipe model usually, assume 0 if null
      final fiber = 0.0; // Extend RecipeModel if you have fiber_g

      await _supabase.from('daily_nutrition_logs').insert({
        'user_id': user.id,
        'recipe_id': recipe.id,
        'log_date': DateTime.now().toIso8601String().split(
          'T',
        )[0], // YYYY-MM-DD
        'source': 'recipe_completion',
        'meal_type': recipe.mealType.isNotEmpty ? recipe.mealType : 'healthy',
        'servings': servingMultiplier,
        'calories_kcal': calories,
        'protein_g': protein,
        'carbs_g': carbs,
        'fat_g': fat,
        'fiber_g': fiber,
      });
      return true;
    } catch (e) {
      debugPrint('Error logging daily nutrition: $e');
      return false;
    }
  }

  /// Get today's accumulated totals
  static Future<DailyNutritionTotals> getTodayNutritionTotals() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return DailyNutritionTotals.zero();

    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      final response = await _supabase
          .from('daily_nutrition_logs')
          .select('calories_kcal, protein_g, carbs_g, fat_g, fiber_g')
          .eq('user_id', user.id)
          .eq('log_date', today);

      if (response.isEmpty) return DailyNutritionTotals.zero();

      double totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;
      double totalFiber = 0;

      for (var row in response) {
        totalCalories += (row['calories_kcal'] as num?)?.toDouble() ?? 0;
        totalProtein += (row['protein_g'] as num?)?.toDouble() ?? 0;
        totalCarbs += (row['carbs_g'] as num?)?.toDouble() ?? 0;
        totalFat += (row['fat_g'] as num?)?.toDouble() ?? 0;
        totalFiber += (row['fiber_g'] as num?)?.toDouble() ?? 0;
      }

      return DailyNutritionTotals(
        calories: totalCalories,
        protein: totalProtein,
        carbs: totalCarbs,
        fat: totalFat,
        fiber: totalFiber,
      );
    } catch (e) {
      debugPrint('Error fetching today totals: $e');
      return DailyNutritionTotals.zero();
    }
  }

  /// Rate a recipe
  static Future<bool> rateRecipe(String recipeId, int rating) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      debugPrint('Rating save skipped: user not authenticated');
      return false;
    }

    if (recipeId.isEmpty) {
      debugPrint('Rating save failed: recipeId is null/empty');
      return false;
    }

    debugPrint(
      'Rating save started:\n- userId: ${user.id}\n- recipeId: $recipeId\n- rating: $rating\n- tableName: recipe_ratings',
    );

    try {
      await _supabase.from('recipe_ratings').upsert({
        'user_id': user.id,
        'recipe_id': recipeId,
        'rating': rating,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,recipe_id');

      debugPrint(
        'Rating save response:\n- success: true\n- errorCode: null\n- errorMessage: null\n- errorDetails: null\n- errorHint: null\n- upsertUsed: true',
      );
      return true;
    } catch (e) {
      String errCode = 'unknown';
      String errMsg = e.toString();
      String errDetails = '';
      String errHint = '';

      if (e is PostgrestException) {
        errCode = e.code ?? 'unknown';
        errMsg = e.message;
        errDetails = e.details?.toString() ?? '';
        errHint = e.hint ?? '';
      }

      debugPrint(
        'Rating save response:\n- success: false\n- errorCode: $errCode\n- errorMessage: $errMsg\n- errorDetails: $errDetails\n- errorHint: $errHint\n- upsertUsed: true',
      );
      return false;
    }
  }
}
