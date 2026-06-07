import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_health_profile.dart';
import '../models/daily_goals_model.dart';
import '../repositories/user_health_profile_repository.dart';
import '../services/api/daily_goals_service.dart';
import '../services/api/weekly_activity_service.dart';
import '../services/smart_notification_service.dart';

class UserProfileProvider extends ChangeNotifier {
  Map<String, dynamic>? profile;
  UserHealthProfile? healthProfile;
  DailyGoals? todayGoals;
  List<int> activeWeekdays = [];
  int streakDays = 0;

  bool isLoading = false;
  String? errorMessage;

  final SupabaseClient _client = Supabase.instance.client;
  final DailyGoalsService _goalsService = DailyGoalsService();
  final WeeklyActivityService _activityService = WeeklyActivityService();

  Future<void> loadProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;
      final data = await _client.from('profiles').select().eq('id', user.id).maybeSingle();
      profile = data;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
    }
  }

  Future<void> loadHealthProfile() async {
    try {
      healthProfile = await UserHealthProfileRepository.instance.getCurrentUserHealthProfile();
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
    }
  }

  Future<void> loadDailyGoalsAndActivity() async {
    try {
      await _activityService.logAppOpen();
      activeWeekdays = await _activityService.getActiveDaysThisWeek();
      streakDays = await _activityService.getStreakDays();
      todayGoals = await _goalsService.getGoalsForDate(DateTime.now());
      notifyListeners();
    } catch (e) {
      debugPrint("loadDailyGoalsAndActivity error: $e");
    }
  }

  /// Updates health profile in Supabase and refreshes local state.
  Future<bool> updateHealthProfile(UserHealthProfile updatedProfile) async {
    try {
      await UserHealthProfileRepository.instance.upsertCurrentUserHealthProfile(updatedProfile);
      await refreshAll();
      return true;
    } catch (e) {
      debugPrint('UserProfileProvider updateHealthProfile error: $e');
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateDailyGoals(DailyGoals updatedGoals) async {
    // Optimistic update for immediate UI refresh
    todayGoals = updatedGoals;
    notifyListeners();

    debugPrint('Daily Progress Save Pressed\n');
    debugPrint('Inputs:');
    debugPrint('currentCalories input: ${updatedGoals.caloriesConsumed}');
    debugPrint('calorieGoal input: ${updatedGoals.caloriesTarget}');
    debugPrint('currentProtein input: ${updatedGoals.proteinConsumed}');
    debugPrint('proteinGoal input: ${updatedGoals.proteinTarget}');
    debugPrint('currentWater input: ${updatedGoals.waterConsumed}');
    debugPrint('waterGoal input: ${updatedGoals.waterTarget}');
    debugPrint('currentActivity input: ${updatedGoals.activityCompleted}');
    debugPrint('activityGoal input: ${updatedGoals.activityTarget}\n');
    
    debugPrint('After save state:');
    debugPrint('currentCalories: ${todayGoals?.caloriesConsumed}');
    debugPrint('calorieGoal: ${todayGoals?.caloriesTarget}');
    debugPrint('currentProtein: ${todayGoals?.proteinConsumed}');
    debugPrint('proteinGoal: ${todayGoals?.proteinTarget}');
    debugPrint('currentWater: ${todayGoals?.waterConsumed}');
    debugPrint('waterGoal: ${todayGoals?.waterTarget}');
    debugPrint('currentActivity: ${todayGoals?.activityCompleted}');
    debugPrint('activityGoal: ${todayGoals?.activityTarget}\n');
    
    debugPrint('Widgets should rebuild with updated daily progress.\n');

    // Update notifications based on new goals
    SmartNotificationService().checkSmartNotifications(
      goals: todayGoals,
      healthProfile: healthProfile,
    );

    try {
      final res = await _goalsService.upsertGoals(updatedGoals);
      if (res != null) {
        todayGoals = res;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('UserProfileProvider updateDailyGoals error: $e');
      // Intentionally not reverting optimistic update here so the UI still works
      // despite Supabase schema errors, per user request.
      return false;
    }
  }

  /// Uploads a new profile picture and updates avatar_url
  Future<bool> uploadProfilePicture(File imageFile) async {
    try {
      debugPrint('--- Profile Picture Upload Started ---');
      final user = _client.auth.currentUser;
      debugPrint('Current user ID: ${user?.id}');
      
      if (user == null) {
        debugPrint('Error: User is null');
        return false;
      }

      final fileExists = await imageFile.exists();
      debugPrint('File exists: $fileExists');
      debugPrint('File path: ${imageFile.path}');
      
      if (fileExists) {
        final fileSize = await imageFile.length();
        debugPrint('File size: $fileSize bytes');
      }

      final fileExt = imageFile.path.split('.').last;
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '${user.id}/$fileName';
      const bucketName = 'profile-photos';
      
      debugPrint('Bucket name: $bucketName');
      debugPrint('Upload path: $filePath');

      debugPrint('Starting storage upload...');
      await _client.storage.from(bucketName).upload(filePath, imageFile);
      debugPrint('Storage upload successful.');
      
      final imageUrl = _client.storage.from(bucketName).getPublicUrl(filePath);
      debugPrint('Public URL generated: $imageUrl');

      debugPrint('Updating profile table...');
      await _client.from('profiles').upsert({
        'id': user.id,
        'avatar_url': imageUrl,
      });
      debugPrint('Profile table updated successfully.');

      await loadProfile();
      debugPrint('--- Profile Picture Upload Finished ---');
      return true;
    } catch (e) {
      debugPrint('UserProfileProvider uploadProfilePicture error: $e');
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshAll() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    await Future.wait([
      loadProfile(),
      loadHealthProfile(),
      loadDailyGoalsAndActivity(),
    ]);

    isLoading = false;
    notifyListeners();

    // Check smart notifications after full profile/goals refresh
    SmartNotificationService().checkSmartNotifications(
      goals: todayGoals,
      healthProfile: healthProfile,
    );
  }
}
