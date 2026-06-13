import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class WeeklyActivityService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Logs app open for today
  Future<void> logAppOpen() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final dateStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      await _client.from('user_daily_activity').upsert({
        'user_id': user.id,
        'activity_date': dateStr,
        'source': 'app_open',
      });
    } catch (e) {
      debugPrint("WeeklyActivityService logAppOpen error: $e");
    }
  }

  /// Returns a list of active weekdays for the current week (1 = Monday, 7 = Sunday)
  Future<List<int>> getActiveDaysThisWeek() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startStr =
          "${startOfWeek.year}-${startOfWeek.month.toString().padLeft(2, '0')}-${startOfWeek.day.toString().padLeft(2, '0')}";

      final response = await _client
          .from('user_daily_activity')
          .select('activity_date')
          .eq('user_id', user.id)
          .gte('activity_date', startStr);

      final Set<int> activeWeekdays = {};
      for (final row in response) {
        final date = DateTime.tryParse(row['activity_date'].toString());
        if (date != null) {
          activeWeekdays.add(date.weekday);
        }
      }
      return activeWeekdays.toList();
    } catch (e) {
      debugPrint("WeeklyActivityService getActiveDaysThisWeek error: $e");
      // Graceful fallback if table missing
      return [DateTime.now().weekday];
    }
  }

  /// Calculates the current streak of consecutive active days
  Future<int> getStreakDays() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return 0;

      final now = DateTime.now();
      // Look back up to 90 days to calculate streak
      final startStr = now
          .subtract(const Duration(days: 90))
          .toIso8601String()
          .split('T')[0];

      final response = await _client
          .from('user_daily_activity')
          .select('activity_date')
          .eq('user_id', user.id)
          .gte('activity_date', startStr)
          .order('activity_date', ascending: false);

      if (response.isEmpty) return 0;

      final Set<String> activeDates = {};
      for (final row in response) {
        activeDates.add(row['activity_date'].toString());
      }

      int streak = 0;
      DateTime checkDate = now;

      // Check if active today
      final todayStr =
          "${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}";
      if (activeDates.contains(todayStr)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        // If not active today, check if active yesterday (streak doesn't break if you just haven't logged in *yet* today)
        checkDate = checkDate.subtract(const Duration(days: 1));
        final yesterdayStr =
            "${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}";
        if (!activeDates.contains(yesterdayStr)) {
          return 0; // No streak
        }
      }

      // Keep counting backwards
      while (true) {
        final dateStr =
            "${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}";
        if (activeDates.contains(dateStr)) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }

      return streak;
    } catch (e) {
      debugPrint("WeeklyActivityService getStreakDays error: $e");
      return 1; // Fallback
    }
  }
}
