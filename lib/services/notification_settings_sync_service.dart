import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationSettingsSyncService {
  static final NotificationSettingsSyncService _instance =
      NotificationSettingsSyncService._internal();
  factory NotificationSettingsSyncService() => _instance;
  NotificationSettingsSyncService._internal();

  static NotificationSettingsSyncService get instance => _instance;

  final SupabaseClient _client = Supabase.instance.client;

  /// Supabase'den ayarları çeker, varsa lokale yazar; yoksa lokaldekileri Supabase'e yazar.
  Future<void> syncLocalToSupabase() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        if (kDebugMode)
          debugPrint('Notification settings sync skipped: User not logged in.');
        return;
      }

      if (kDebugMode)
        debugPrint('Notification settings sync started for user: ${user.id}');

      final prefs = await SharedPreferences.getInstance();

      // 1. Supabase'den mevcut ayarları çekmeyi dene
      final response = await _client
          .from('user_notification_settings')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null) {
        // 2. Supabase'de ayar var -> SharedPreferences'i güncelle (Supabase verisi Master kabul edilir)
        await prefs.setBool(
          'water_reminders',
          response['water_reminder_enabled'] ?? true,
        );
        await prefs.setBool(
          'calorie_reminders',
          response['calorie_reminder_enabled'] ?? true,
        );
        await prefs.setBool(
          'protein_reminders',
          response['protein_reminder_enabled'] ?? true,
        );
        await prefs.setBool(
          'movement_reminders',
          response['activity_reminder_enabled'] ?? true,
        );
        await prefs.setBool(
          'weight_reminders',
          response['weight_reminder_enabled'] ?? true,
        );
        await prefs.setBool(
          'analysis_reminders',
          response['analysis_reminder_enabled'] ?? true,
        );

        if (kDebugMode)
          debugPrint('Loaded notification settings from Supabase to local.');
      } else {
        // 3. Supabase'de ayar yok -> Mevcut local ayarları Supabase'e yaz
        final waterEnabled = prefs.getBool('water_reminders') ?? true;
        final calorieEnabled = prefs.getBool('calorie_reminders') ?? true;
        final proteinEnabled = prefs.getBool('protein_reminders') ?? true;
        final activityEnabled = prefs.getBool('movement_reminders') ?? true;
        final weightEnabled = prefs.getBool('weight_reminders') ?? true;
        final analysisEnabled = prefs.getBool('analysis_reminders') ?? true;

        await _client.from('user_notification_settings').upsert({
          'user_id': user.id,
          'water_reminder_enabled': waterEnabled,
          'calorie_reminder_enabled': calorieEnabled,
          'protein_reminder_enabled': proteinEnabled,
          'activity_reminder_enabled': activityEnabled,
          'weight_reminder_enabled': weightEnabled,
          'analysis_reminder_enabled': analysisEnabled,
          'quiet_start_hour': 22,
          'quiet_end_hour': 9,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id');

        if (kDebugMode)
          debugPrint('Pushed local notification settings to Supabase.');
      }
    } catch (e) {
      if (kDebugMode)
        debugPrint('Notification settings sync error details: $e');
    }
  }

  /// Tek bir ayar değiştiğinde Supabase'i günceller.
  Future<void> updateSingleSetting(String prefsKey, bool value) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null)
        return; // Login değilse sessizce dön, sadece SharedPreferences güncellenir

      // SharedPreferences key'ini Supabase kolonuna eşle
      String? columnName;
      switch (prefsKey) {
        case 'water_reminders':
          columnName = 'water_reminder_enabled';
          break;
        case 'calorie_reminders':
          columnName = 'calorie_reminder_enabled';
          break;
        case 'protein_reminders':
          columnName = 'protein_reminder_enabled';
          break;
        case 'movement_reminders':
          columnName = 'activity_reminder_enabled';
          break;
        case 'weight_reminders':
          columnName = 'weight_reminder_enabled';
          break;
        case 'analysis_reminders':
          columnName = 'analysis_reminder_enabled';
          break;
        case 'daily_reminders':
          // daily_reminders genel bir switch ise bunu ayrı bir kolonda
          // veya mevcut yapıda tutabiliriz. Verilen şemada yok.
          // Bu yüzden es geçiyoruz.
          return;
      }

      if (columnName != null) {
        await _client.from('user_notification_settings').upsert({
          'user_id': user.id,
          columnName: value,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id');

        if (kDebugMode) {
          debugPrint(
            'Notification setting updated on Supabase: $columnName = $value',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Notification single setting update error: $e');
      }
    }
  }
}
