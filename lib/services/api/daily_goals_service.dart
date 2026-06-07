import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/daily_goals_model.dart';

class DailyGoalsService {
  final SupabaseClient _client = Supabase.instance.client;

  String _getCacheKey(String userId, String dateStr) => 'daily_goals_${userId}_$dateStr';

  Future<DailyGoals?> getGoalsForDate(DateTime date) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;
      
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      
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
            .eq('target_date', dateStr)
            .maybeSingle();

        if (response != null) {
          final fetched = DailyGoals.fromJson(response);
          // Update cache
          await prefs.setString(cacheKey, jsonEncode(fetched.toJson()));
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

  Future<DailyGoals?> upsertGoals(DailyGoals goals) async {
    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        final dateStr = "${goals.targetDate.year}-${goals.targetDate.month.toString().padLeft(2, '0')}-${goals.targetDate.day.toString().padLeft(2, '0')}";
        final prefs = await SharedPreferences.getInstance();
        final cacheKey = _getCacheKey(user.id, dateStr);
        await prefs.setString(cacheKey, jsonEncode(goals.toJson()));
      }

      try {
        final response = await _client
            .from('user_daily_goals')
            .upsert(goals.toJson())
            .select()
            .maybeSingle();
        
        if (response != null) {
          return DailyGoals.fromJson(response);
        }
      } catch (e) {
        debugPrint("DailyGoalsService Supabase upsert error: $e");
        return goals; // Return local copy gracefully
      }
      return goals;
    } catch (e) {
      debugPrint("DailyGoalsService upsertGoals error: $e");
      return goals; // Return local copy so UI doesn't crash
    }
  }
}
