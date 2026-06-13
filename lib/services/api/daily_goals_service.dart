import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/daily_goals_model.dart';

class DailyGoalsService {
  final SupabaseClient _client = Supabase.instance.client;

  String _getCacheKey(String userId, String dateStr) =>
      'daily_goals_${userId}_$dateStr';

  Future<DailyGoals?> getGoalsForDate(DateTime date) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final dateStr =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

      // 1. Try fetching from local cache first (for offline/missing table tolerance)
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(user.id, dateStr);
      final cachedStr = prefs.getString(cacheKey);

      DailyGoals? cachedGoals;
      if (cachedStr != null) {
        try {
          cachedGoals = DailyGoals.fromJson(jsonDecode(cachedStr));
        } catch (e) {
          debugPrint("Local cache parse error: $e");
        }
      }

      // 2. Fetch from Supabase
      try {
        final response = await _client
            .from('user_daily_goals')
            .select()
            .eq('user_id', user.id)
            .eq('goal_date', dateStr)
            .maybeSingle();

        if (response != null) {
          DailyGoals fetched = DailyGoals.fromJson(response);

          // CRITICAL: Merge with local cache to prioritize local progress
          bool merged = false;
          if (cachedGoals != null &&
              cachedGoals.targetDate.year == date.year &&
              cachedGoals.targetDate.month == date.month &&
              cachedGoals.targetDate.day == date.day) {
            // ALWAYS preserve recipe-based consumptions from cache since Supabase doesn't store them
            fetched = fetched.copyWith(
              caloriesConsumed: cachedGoals.caloriesConsumed,
              proteinConsumed: cachedGoals.proteinConsumed,
            );

            if (cachedGoals.waterConsumed > fetched.waterConsumed ||
                cachedGoals.activityCompleted > fetched.activityCompleted) {
              fetched = fetched.copyWith(
                waterConsumed: cachedGoals.waterConsumed > fetched.waterConsumed
                    ? cachedGoals.waterConsumed
                    : fetched.waterConsumed,
                activityCompleted:
                    cachedGoals.activityCompleted > fetched.activityCompleted
                    ? cachedGoals.activityCompleted
                    : fetched.activityCompleted,
              );
              merged = true;
            }
          }

          // Update cache
          await prefs.setString(cacheKey, jsonEncode(fetched.toJson()));

          if (merged) {
            // Silently heal Supabase with the higher local progress
            upsertGoals(fetched);
          }

          return fetched;
        }
      } catch (e) {
        debugPrint("DailyGoalsService Supabase get error: $e");
        // Fallback to cache if table doesn't exist
        if (cachedGoals != null) return cachedGoals;
      }

      return cachedGoals;
    } catch (e) {
      debugPrint("DailyGoalsService getGoalsForDate error: $e");
      return null;
    }
  }

  Future<void> ensureTodayGoalsExists([DailyGoals? localGoals]) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final dateStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      // Check if it exists
      final existing = await _client
          .from('user_daily_goals')
          .select('id')
          .eq('user_id', user.id)
          .eq('goal_date', dateStr)
          .maybeSingle();

      if (existing == null) {
        // Insert default goals for today (or use local values if provided)
        await _client.from('user_daily_goals').insert({
          'user_id': user.id,
          'goal_date': dateStr,
          'water_goal_l': localGoals != null
              ? localGoals.waterTarget / 1000.0
              : 2.0,
          'calorie_goal': localGoals?.caloriesTarget.round() ?? 2000,
          'protein_goal_g': localGoals?.proteinTarget.round() ?? 100,
          'activity_goal_min': localGoals?.activityTarget.round() ?? 60,
          'water_consumed_l': localGoals != null
              ? localGoals.waterConsumed / 1000.0
              : 0,
          'activity_completed_min': localGoals?.activityCompleted.round() ?? 0,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
        debugPrint("Created default daily goals for today in Supabase.");
      }
    } catch (e) {
      debugPrint("DailyGoalsService ensureTodayGoalsExists error: $e");
    }
  }

  Future<DailyGoals?> upsertGoals(DailyGoals goals) async {
    try {
      final user = _client.auth.currentUser;
      final dateStr =
          "${goals.targetDate.year}-${goals.targetDate.month.toString().padLeft(2, '0')}-${goals.targetDate.day.toString().padLeft(2, '0')}";

      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        final cacheKey = _getCacheKey(user.id, dateStr);
        await prefs.setString(cacheKey, jsonEncode(goals.toJson()));
      }

      try {
        final dataToUpsert = goals.toSupabaseJson();
        dataToUpsert['user_id'] = user?.id ?? goals.userId;
        dataToUpsert['updated_at'] = DateTime.now().toUtc().toIso8601String();

        final response = await _client
            .from('user_daily_goals')
            .upsert(dataToUpsert, onConflict: 'user_id, goal_date')
            .select()
            .maybeSingle();

        if (response != null) {
          final fetched = DailyGoals.fromJson(response);
          // Supabase does not store caloriesConsumed and proteinConsumed,
          // so we must preserve them from the input goals object.
          return fetched.copyWith(
            caloriesConsumed: goals.caloriesConsumed,
            proteinConsumed: goals.proteinConsumed,
          );
        }
      } catch (e) {
        debugPrint("DailyGoalsService Supabase save error: $e");
        return goals; // Return local copy gracefully
      }
      return goals;
    } catch (e) {
      debugPrint("DailyGoalsService upsertGoals error: $e");
      return goals; // Return local copy so UI doesn't crash
    }
  }
}
