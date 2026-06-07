import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_health_profile.dart';
import '../repositories/user_health_profile_repository.dart';

/// Manages the 9-step "Seni Tanıyalım" onboarding form state.
enum HealthProfileSetupMode { create, edit }

class HealthProfileSetupProvider extends ChangeNotifier {
  final UserHealthProfileRepository _repo =
      UserHealthProfileRepository.instance;

  int currentStep = 0;
  static const int totalSteps = 10;
  HealthProfileSetupMode mode = HealthProfileSetupMode.create;

  // ── Form values ──────────────────────────────────────────────────────

  int? age;
  String? gender;
  double? heightCm;
  double? weightKg;
  String? goalType;
  final Set<String> healthConditions = {};
  final Set<String> allergies = {};
  final Set<String> dietPreferences = {};
  String? activityLevel;

  bool isLoading = false;
  String? errorMessage;

  // ── Navigation ───────────────────────────────────────────────────────
  
  void initializeForEdit(UserHealthProfile profile) {
    mode = HealthProfileSetupMode.edit;
    age = profile.age;
    gender = profile.gender;
    heightCm = profile.heightCm;
    weightKg = profile.weightKg;
    goalType = profile.goalType;
    healthConditions.addAll(profile.healthConditions);
    allergies.addAll(profile.allergies);
    dietPreferences.addAll(profile.dietPreferences);
    activityLevel = profile.activityLevel;
    notifyListeners();
  }

  void nextStep() {
    if (currentStep < totalSteps - 1) {
      currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (currentStep > 0) {
      currentStep--;
      notifyListeners();
    }
  }

  // ── Setters ──────────────────────────────────────────────────────────

  void setAge(String value) {
    age = int.tryParse(value);
    notifyListeners();
  }

  void setGender(String value) {
    gender = value;
    notifyListeners();
  }

  void setHeight(String value) {
    heightCm = double.tryParse(value);
    notifyListeners();
  }

  void setWeight(String value) {
    weightKg = double.tryParse(value);
    notifyListeners();
  }

  void setGoalType(String value) {
    goalType = value;
    notifyListeners();
  }

  void toggleHealthCondition(String value) {
    _toggleMulti(value, healthConditions,
        noneKeys: {'Yok', 'Belirtmek istemiyorum'});
    notifyListeners();
  }

  void toggleAllergy(String value) {
    _toggleMulti(value, allergies,
        noneKeys: {'Yok', 'Belirtmek istemiyorum'});
    notifyListeners();
  }

  void toggleDietPreference(String value) {
    _toggleMulti(value, dietPreferences, noneKeys: {'Yok'});
    notifyListeners();
  }

  void setActivityLevel(String value) {
    activityLevel = value;
    notifyListeners();
  }

  // ── Multi-select logic ───────────────────────────────────────────────
  //
  // If a "none" key is selected, clear all other selections.
  // If another option is selected, remove any "none" keys.

  void _toggleMulti(String value, Set<String> targetSet,
      {Set<String> noneKeys = const {}}) {
    if (noneKeys.contains(value)) {
      targetSet.clear();
      targetSet.add(value);
    } else {
      targetSet.removeAll(noneKeys);
      if (targetSet.contains(value)) {
        targetSet.remove(value);
      } else {
        targetSet.add(value);
      }
    }
  }

  bool get isLastStep => currentStep == totalSteps - 1;

  // ── Validation ───────────────────────────────────────────────────────

  bool validateCurrentStep() {
    return validateCurrentStepMessage() == null;
  }

  /// Returns a Turkish validation message for the current step,
  /// or null if the step is valid.
  String? validateCurrentStepMessage() {
    switch (currentStep) {
      case 0:
        if (age == null) return 'Lütfen yaşını gir.';
        if (age! < 10 || age! > 100) return 'Yaş 10-100 arasında olmalı.';
        return null;
      case 1:
        if (gender == null || gender!.isEmpty) return 'Lütfen cinsiyetini seç.';
        return null;
      case 2:
        if (heightCm == null) return 'Lütfen boyunu gir.';
        if (heightCm! < 100 || heightCm! > 230) return 'Boy 100-230 cm arasında olmalı.';
        return null;
      case 3:
        if (weightKg == null) return 'Lütfen kilonu gir.';
        if (weightKg! < 30 || weightKg! > 250) return 'Kilo 30-250 kg arasında olmalı.';
        return null;
      case 4:
        if (goalType == null || goalType!.isEmpty) return 'Lütfen bir hedef seç.';
        return null;
      case 5:
        if (healthConditions.isEmpty) return 'Lütfen en az bir seçenek işaretle.';
        return null;
      case 6:
        if (allergies.isEmpty) return 'Lütfen en az bir seçenek işaretle.';
        return null;
      case 7:
        if (dietPreferences.isEmpty) return 'Lütfen en az bir seçenek işaretle.';
        return null;
      case 8:
        if (activityLevel == null || activityLevel!.isEmpty) return 'Lütfen aktivite seviyeni seç.';
        return null;
      case 9:
        return null;
      default:
        return 'Geçersiz adım.';
    }
  }

  // ── Submit ───────────────────────────────────────────────────────────

  Future<bool> submit() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final profile = UserHealthProfile(
        age: age,
        gender: gender,
        heightCm: heightCm,
        weightKg: weightKg,
        goalType: goalType,
        healthConditions: healthConditions.toList(),
        allergies: allergies.toList(),
        dietPreferences: dietPreferences.toList(),
        activityLevel: activityLevel,
      );

      await _repo.upsertCurrentUserHealthProfile(profile);
      if (mode == HealthProfileSetupMode.create) {
        await _repo.markProfileSetupCompleted();
      }

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        final client = Supabase.instance.client;
        final userId = client.auth.currentUser?.id;
        final sessionExists = client.auth.currentSession != null;
        
        final testProfile = UserHealthProfile(
          age: age,
          gender: gender,
          heightCm: heightCm,
          weightKg: weightKg,
          goalType: goalType,
          healthConditions: healthConditions.toList(),
          allergies: allergies.toList(),
          dietPreferences: dietPreferences.toList(),
          activityLevel: activityLevel,
        );
        final payloadKeys = testProfile.toJson().keys.toList();

        debugPrint('==================================================');
        debugPrint('HEALTH PROFILE SETUP SUBMIT ERROR DETECTED');
        debugPrint('Current User ID: $userId');
        debugPrint('Session Exists: $sessionExists');
        debugPrint('Payload Keys: $payloadKeys');
        
        if (e is PostgrestException) {
          debugPrint('Exception Type: PostgrestException');
          debugPrint('Message: ${e.message}');
          debugPrint('Status Code: ${e.code}');
          debugPrint('Details: ${e.details}');
          debugPrint('Hint: ${e.hint}');
          debugPrint('Table Name: user_health_profiles');
        } else {
          debugPrint('Exception Type: ${e.runtimeType}');
          debugPrint('Error Details: $e');
        }
        debugPrint('==================================================');
      }

      isLoading = false;
      errorMessage = 'Profil bilgilerin kaydedilemedi. Lütfen tekrar dene.';
      notifyListeners();
      return false;
    }
  }
}
