import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/user_profile_provider.dart';
import '../repositories/recipes/supabase_recipe_repository.dart';
import '../models/recipe_model.dart';
import '../services/daily_nutrition_service.dart';
import '../services/calculations/health_calculation_service.dart';

enum RayAssistantIntent {
  water,
  calorie,
  protein,
  activity,
  general,
  recipeGeneral,
  recipeBreakfast,
  recipeLunch,
  recipeDinner,
  recipeSnack,
  recipeHighProtein,
  recipeLowCalorie,
  notifications,
  unknown,
}

class RayAssistantService {
  static final RayAssistantService _instance = RayAssistantService._internal();
  factory RayAssistantService() => _instance;
  RayAssistantService._internal();

  final _recipeRepo = SupabaseRecipeRepository();

  Future<String> generateResponse(
    BuildContext context,
    RayAssistantIntent intent, {
    required String staticFallback,
  }) async {
    debugPrint('RayAssistant generateResponse: intent=${intent.name}');

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        debugPrint('RayAssistant: userExists=false, returning fallback');
        return _getFallbackForIntent(intent, staticFallback);
      }

      debugPrint('RayAssistant: userId=${user.id}');

      if (intent == RayAssistantIntent.unknown) {
        return staticFallback;
      }

      // Handle Notifications
      if (intent == RayAssistantIntent.notifications) {
        return await _handleNotificationsIntent(staticFallback);
      }

      // Handle Recipes
      if (_isRecipeIntent(intent)) {
        return await _handleRecipeIntent(intent, staticFallback);
      }

      // Handle Daily Progress (Water, Calorie, Protein, Activity, General)
      return await _handleDailyProgressIntent(context, intent, staticFallback);
    } catch (e) {
      debugPrint('RayAssistant error: $e');
      return _getFallbackForIntent(intent, staticFallback);
    }
  }

  bool _isRecipeIntent(RayAssistantIntent intent) {
    return [
      RayAssistantIntent.recipeGeneral,
      RayAssistantIntent.recipeBreakfast,
      RayAssistantIntent.recipeLunch,
      RayAssistantIntent.recipeDinner,
      RayAssistantIntent.recipeSnack,
      RayAssistantIntent.recipeHighProtein,
      RayAssistantIntent.recipeLowCalorie,
    ].contains(intent);
  }

  Future<String> _handleNotificationsIntent(String staticFallback) async {
    debugPrint(
      'RayAssistant: dataSourceUsed=SharedPreferences, notificationPrefsFound=attempted',
    );
    try {
      final prefs = await SharedPreferences.getInstance();

      final daily = prefs.getBool('daily_reminders') ?? false;
      final water = prefs.getBool('water_reminders') ?? false;
      final calorie = prefs.getBool('calorie_reminders') ?? false;
      final protein = prefs.getBool('protein_reminders') ?? false;
      final movement = prefs.getBool('movement_reminders') ?? false;
      final weight = prefs.getBool('weight_reminders') ?? false;
      final analysis = prefs.getBool('analysis_reminders') ?? false;

      debugPrint('RayAssistant: notificationPrefsFound=true');

      if (!daily) {
        return 'Bildirim ayarlarına baktım 🔔\nGünlük hatırlatmalar kapalı olduğu için diğer bildirim türleri açık olsa bile akıllı bildirimler gönderilmez.';
      }

      return 'Bildirim ayarlarına baktım 🔔\n'
          'Günlük hatırlatmalar: ${daily ? 'açık' : 'kapalı'}\n'
          'Su hatırlatmaları: ${water ? 'açık' : 'kapalı'}\n'
          'Kalori hatırlatmaları: ${calorie ? 'açık' : 'kapalı'}\n'
          'Protein hatırlatmaları: ${protein ? 'açık' : 'kapalı'}\n'
          'Hareket hatırlatmaları: ${movement ? 'açık' : 'kapalı'}\n'
          'Haftalık tartı hatırlatması: ${weight ? 'açık' : 'kapalı'}\n'
          'Analiz bildirimleri: ${analysis ? 'açık' : 'kapalı'}';
    } catch (e) {
      debugPrint('RayAssistant notification check error: $e');
      return 'Bildirim ayarlarını şu an okuyamadım. Bildirimler sayfasından kontrol edebilirsin.';
    }
  }

  Future<String> _handleRecipeIntent(
    RayAssistantIntent intent,
    String staticFallback,
  ) async {
    debugPrint(
      'Ray recipe query: intent=${intent.name}, dataSourceUsed=SupabaseRecipeRepository, recipeQueryUsed=true',
    );
    try {
      List<RecipeModel> recipes = [];

      switch (intent) {
        case RayAssistantIntent.recipeGeneral:
          recipes = await _recipeRepo.getHomeRecommendations(limit: 3);
          break;
        case RayAssistantIntent.recipeBreakfast:
          recipes = await _recipeRepo.getRecommendedRecipes(
            'breakfast',
            pageSize: 3,
          );
          break;
        case RayAssistantIntent.recipeLunch:
          recipes = await _recipeRepo.getRecommendedRecipes(
            'lunch',
            pageSize: 3,
          );
          break;
        case RayAssistantIntent.recipeDinner:
          recipes = await _recipeRepo.getRecommendedRecipes(
            'dinner',
            pageSize: 3,
          );
          break;
        case RayAssistantIntent.recipeSnack:
          recipes = await _recipeRepo.getRecommendedRecipes(
            'snack',
            pageSize: 3,
          );
          break;
        case RayAssistantIntent.recipeHighProtein:
          recipes = await _recipeRepo.getRecommendedRecipes(
            '',
            sortFilter: 'Yüksek Protein',
            pageSize: 3,
          );
          break;
        case RayAssistantIntent.recipeLowCalorie:
          recipes = await _recipeRepo.getRecommendedRecipes(
            '',
            sortFilter: 'Düşük Kalori',
            pageSize: 3,
          );
          break;
        default:
          break;
      }

      // If specific meal type search returned empty, fallback to general recommendable recipes
      if (recipes.isEmpty) {
        debugPrint(
          'Ray recipe query: initial empty, trying fallback recommendations',
        );
        recipes = await _recipeRepo.getHomeRecommendations(limit: 3);
      }

      debugPrint('Ray recipe query resultCount: ${recipes.length}');

      if (recipes.isEmpty) {
        debugPrint('RayAssistant: fallbackUsed=true');
        return _getFallbackForIntent(intent, staticFallback);
      }

      String mealWord = "Sana uygun";
      if (intent == RayAssistantIntent.recipeBreakfast)
        mealWord = "Kahvaltı için sana uygun";
      if (intent == RayAssistantIntent.recipeLunch)
        mealWord = "Öğle yemeği için sana uygun";
      if (intent == RayAssistantIntent.recipeDinner)
        mealWord = "Akşam yemeği için sana uygun";
      if (intent == RayAssistantIntent.recipeSnack)
        mealWord = "Ara öğün için sana uygun";

      final sb = StringBuffer('$mealWord birkaç tarif buldum:\n');
      for (int i = 0; i < recipes.length && i < 3; i++) {
        sb.writeln('${i + 1}. ${recipes[i].title}');
      }
      return sb.toString().trim();
    } catch (e) {
      debugPrint('Ray recipe query error: $e');
      debugPrint('RayAssistant: fallbackUsed=true');
      return _getFallbackForIntent(intent, staticFallback);
    }
  }

  Future<String> _handleDailyProgressIntent(
    BuildContext context,
    RayAssistantIntent intent,
    String staticFallback,
  ) async {
    debugPrint('RayAssistant: dataSourceUsed=UserProfileProvider');

    // Providers'i try catch ile sariyoruz ki herhangi bir Provider dispose durumunda crash yemeyelim
    try {
      final profileProvider = Provider.of<UserProfileProvider>(
        context,
        listen: false,
      );

      final todayGoals = profileProvider.todayGoals;
      final hp = profileProvider.healthProfile;
      final hasData = hp != null && hp.weightKg != null && hp.heightCm != null;

      final double bmr = hasData
          ? HealthCalculationService.calculateBMR(
              hp.weightKg!,
              hp.heightCm!,
              hp.age ?? 22,
              hp.gender ?? 'Kadın',
            )
          : 1410.0;
      final double dailyCal = hasData
          ? HealthCalculationService.calculateDailyCalories(
              bmr,
              hp.activityLevel,
            )
          : 1650.0;

      final calorieTarget = todayGoals?.caloriesTarget ?? dailyCal;
      final proteinTarget =
          todayGoals?.proteinTarget ?? (hasData ? hp.weightKg! * 1.6 : 100.0);
      final waterTargetMl = todayGoals?.waterTarget ?? 2000.0;
      final activityTarget = todayGoals?.activityTarget ?? 60.0;

      // Get current progress values exactly like ProfileScreen does
      double currentCalories = todayGoals?.caloriesConsumed ?? 0.0;
      double currentProtein = todayGoals?.proteinConsumed ?? 0.0;

      // Fallback to logs if goals table values are missing/0
      if (currentCalories <= 0 || currentProtein <= 0) {
        final nutritionTotals =
            await DailyNutritionService.getTodayNutritionTotals();
        if (currentCalories <= 0) currentCalories = nutritionTotals.calories;
        if (currentProtein <= 0) currentProtein = nutritionTotals.protein;
      }

      final currentWater = todayGoals?.waterConsumed ?? 0.0;
      final currentActivity = todayGoals?.activityCompleted ?? 0.0;

      final double waterGoal = waterTargetMl > 0 ? waterTargetMl : 2000.0;
      final double calorieGoal = calorieTarget > 0 ? calorieTarget : 2000.0;
      final double proteinGoal = proteinTarget > 0 ? proteinTarget : 100.0;
      final double activityGoal = activityTarget > 0 ? activityTarget : 60.0;

      // Logs required by user
      debugPrint('RayAssistant dailyProgressFound: true');
      debugPrint('RayAssistant goalsFound: true');
      debugPrint('RayAssistant water: $currentWater / $waterGoal');
      debugPrint('RayAssistant calories: $currentCalories / $calorieGoal');
      debugPrint('RayAssistant protein: $currentProtein / $proteinGoal');
      debugPrint('RayAssistant activity: $currentActivity / $activityGoal');

      // Create string formats
      final waterL = currentWater / 1000.0;
      final waterGoalL = waterGoal / 1000.0;

      final waterPct = ((currentWater / waterGoal) * 100).toStringAsFixed(0);
      final calPct = ((currentCalories / calorieGoal) * 100).toStringAsFixed(0);
      final protPct = ((currentProtein / proteinGoal) * 100).toStringAsFixed(0);

      String getProgressText(double current, double goal) {
        final pct = current / goal;
        if (pct < 0.3) return 'biraz geridesin';
        if (pct < 0.8) return 'dengeli ilerliyorsun';
        if (pct < 1.0) return 'hedefine yaklaştın';
        if (pct >= 1.0) return 'hedefini tamamlamışsın';
        return 'hedefini aşmışsın';
      }

      switch (intent) {
        case RayAssistantIntent.water:
          return 'Bugün ${waterL.toStringAsFixed(1)} / ${waterGoalL.toStringAsFixed(1)} L su içtin. Hedefinin %$waterPct\'sine ulaşmışsın; ${getProgressText(currentWater, waterGoal)}.';

        case RayAssistantIntent.calorie:
          return 'Bugün ${currentCalories.toStringAsFixed(0)} / ${calorieGoal.toStringAsFixed(0)} kcal aldın. Hedefinin %$calPct\'sine ulaşmışsın; ${getProgressText(currentCalories, calorieGoal)}.';

        case RayAssistantIntent.protein:
          return 'Bugün ${currentProtein.toStringAsFixed(0)} / ${proteinGoal.toStringAsFixed(0)} g protein aldın. Hedefinin %$protPct\'sine ulaşmışsın; ${getProgressText(currentProtein, proteinGoal)}.';

        case RayAssistantIntent.activity:
          return 'Bugün ${currentActivity.toStringAsFixed(0)} / ${activityGoal.toStringAsFixed(0)} dk hareket ettin. ${getProgressText(currentActivity, activityGoal).replaceAll('biraz geridesin', 'Kısa bir yürüyüş iyi gelebilir')}.';

        case RayAssistantIntent.general:
          return 'Bugünkü durumuna baktım ✨\n'
              'Su: ${waterL.toStringAsFixed(1)} / ${waterGoalL.toStringAsFixed(1)} L — ${getProgressText(currentWater, waterGoal)}.\n'
              'Kalori: ${currentCalories.toStringAsFixed(0)} / ${calorieGoal.toStringAsFixed(0)} kcal — ${getProgressText(currentCalories, calorieGoal)}.\n'
              'Protein: ${currentProtein.toStringAsFixed(0)} / ${proteinGoal.toStringAsFixed(0)} g — ${getProgressText(currentProtein, proteinGoal)}.\n'
              'Hareket: ${currentActivity.toStringAsFixed(0)} / ${activityGoal.toStringAsFixed(0)} dk — ${getProgressText(currentActivity, activityGoal).replaceAll('biraz geridesin', 'kısa bir yürüyüş iyi gelebilir')}.';

        default:
          return staticFallback;
      }
    } catch (e) {
      debugPrint('RayAssistant daily progress error: $e');
      debugPrint('RayAssistant: fallbackUsed=true');
      return _getFallbackForIntent(intent, staticFallback);
    }
  }

  String _getFallbackForIntent(
    RayAssistantIntent intent,
    String staticFallback,
  ) {
    if (_isRecipeIntent(intent)) {
      return 'Şu an tarif verilerine ulaşamadım. Tarifler sayfasından uygun seçenekleri inceleyebilirsin.';
    }
    if (intent == RayAssistantIntent.notifications) {
      return 'Bildirim ayarlarını şu an okuyamadım. Bildirimler sayfasından kontrol edebilirsin.';
    }

    switch (intent) {
      case RayAssistantIntent.water:
        return 'Su durumunu yorumlayabilmem için bugünkü su tüketimi ve hedef bilgilerinin kayıtlı olması gerekiyor.';
      case RayAssistantIntent.calorie:
        return 'Kalori durumunu görebilmem için günlük kalori hedefin ve bugünkü ilerleme verin gerekli.';
      case RayAssistantIntent.protein:
        return 'Protein durumunu yorumlayabilmem için protein hedefin ve bugünkü protein alımın kayıtlı olmalı.';
      case RayAssistantIntent.activity:
        return 'Hareket durumunu yorumlayabilmem için hareket hedefin ve bugünkü aktivite süren kayıtlı olmalı.';
      case RayAssistantIntent.general:
        return 'Genel durumunu yorumlayabilmem için günlük hedeflerinin ve ilerleme verilerinin kayıtlı olması gerekiyor.';
      default:
        return staticFallback;
    }
  }
}
