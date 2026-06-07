import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import '../../widgets/common/bottom_nav_bar.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/calculations/health_calculation_service.dart';
import '../../services/calculations/health_score_service.dart';
import '../../services/daily_nutrition_service.dart';

import 'widgets/profile_header.dart';
import 'widgets/digital_twin_card.dart';
import 'widgets/profile_basic_info_card.dart';
import 'widgets/weight_goal_tracker_card.dart';
import 'widgets/weekly_progress_card.dart';
import 'widgets/daily_goals_card.dart';
import 'widgets/body_analysis_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with WidgetsBindingObserver {
  DailyNutritionTotals _nutritionTotals = DailyNutritionTotals.zero();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchNutrition();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProfileProvider>().refreshAll();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchNutrition();
      context.read<UserProfileProvider>().refreshAll();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchNutrition();
  }

  Future<void> _fetchNutrition() async {
    final totals = await DailyNutritionService.getTodayNutritionTotals();
    if (mounted) {
      setState(() {
        _nutritionTotals = totals;
      });
    }
  }

  String _generateSuggestion(double water, double cal, double prot, double act) {
    if (water < 0.50) return "Bugün biraz daha su içmeyi hedefleyebilirsin.";
    if (cal < 0.45) return "Enerjin düşük kalmış olabilir. Dengeli bir ara öğün ekleyebilirsin.";
    if (prot < 0.55) return "Akşam öğününde protein ağırlıklı bir tarif tercih edebilirsin.";
    if (act < 0.50) return "Bugün 15-20 dakikalık hafif tempolu yürüyüş iyi olabilir.";
    return "Bugün dengeli ilerliyorsun. Mevcut planını koruyabilirsin.";
  }

  void _showSuggestionDialog(String suggestion) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text('Günlük Öneri', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16)),
          ],
        ),
        content: Text(suggestion, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Tamam', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Çok açık gri/beyaz arka plan
      body: SafeArea(
        bottom: false,
        child: Consumer<UserProfileProvider>(
          builder: (context, provider, _) {
            // -- 1. Dynamic User Name & Avatar --
            final authUser = Supabase.instance.client.auth.currentUser;
            final authName = authUser?.userMetadata?['name'] as String?;
            final authFullName = authUser?.userMetadata?['full_name'] as String?;
            final profileName = provider.profile?['name'] as String?;
            final avatarUrl = provider.profile?['avatar_url'] as String?;
            final email = authUser?.email;

            String displayName = 'Kullanıcı';
            if (authFullName != null && authFullName.isNotEmpty) {
              displayName = authFullName;
            } else if (profileName != null && profileName.isNotEmpty) {
              displayName = profileName;
            } else if (authName != null && authName.isNotEmpty) {
              displayName = authName;
            } else if (email != null && email.isNotEmpty) {
              displayName = email.split('@').first;
            }

            String avatarInitial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'K';

            // -- 2. Health Profile & Calculations --
            final hp = provider.healthProfile;
            final hasData = hp != null && hp.weightKg != null && hp.heightCm != null;

            final double bmi = hasData ? HealthCalculationService.calculateBMI(hp.weightKg!, hp.heightCm!) : 22.0;
            final String bmiStatus = hasData ? HealthCalculationService.getBMIStatus(bmi) : 'Normal';
            final double bmr = hasData ? HealthCalculationService.calculateBMR(hp.weightKg!, hp.heightCm!, hp.age ?? 22, hp.gender ?? 'Kadın') : 1410.0;
            final double dailyCal = hasData ? HealthCalculationService.calculateDailyCalories(bmr, hp.activityLevel) : 1650.0;
            final idealRange = hasData ? HealthCalculationService.calculateIdealWeightRange(hp.heightCm!) : (min: 56.0, max: 66.0);
            
            // -- 3. Daily Goals --
            final todayGoals = provider.todayGoals;
            final calorieTarget = todayGoals?.caloriesTarget ?? dailyCal;
            final proteinTarget = todayGoals?.proteinTarget ?? (hasData ? hp.weightKg! * 1.6 : 100.0);
            final waterTargetMl = todayGoals?.waterTarget ?? 2000.0;
            final activityTarget = todayGoals?.activityTarget ?? 60.0;
            
            final waterTargetLiters = waterTargetMl / 1000.0;
            final waterConsumedLiters = (todayGoals?.waterConsumed ?? 0) / 1000.0;

            // For backward compatibility: if todayGoals consumed is 0 but we have nutrition logs, use the logs.
            final double currentCalories = (todayGoals?.caloriesConsumed ?? 0.0) > 0 
                ? todayGoals!.caloriesConsumed 
                : _nutritionTotals.calories;
            
            final double currentProtein = (todayGoals?.proteinConsumed ?? 0.0) > 0 
                ? todayGoals!.proteinConsumed 
                : _nutritionTotals.protein;

            final double waterPercent = (todayGoals?.waterConsumed ?? 0) / (waterTargetMl > 0 ? waterTargetMl : 2000.0);
            final double caloriePercent = currentCalories / (calorieTarget > 0 ? calorieTarget : 2000);
            final double proteinPercent = currentProtein / (proteinTarget > 0 ? proteinTarget : 100);
            final double activityPercent = (todayGoals?.activityCompleted ?? 0) / (activityTarget > 0 ? activityTarget : 60);

            debugPrint('Digital Twin recalculated:');
            debugPrint('currentCalories: $currentCalories');
            debugPrint('calorieGoal: $calorieTarget');
            debugPrint('calorieProgress: $caloriePercent');
            debugPrint('currentProtein: $currentProtein');
            debugPrint('proteinGoal: $proteinTarget');
            debugPrint('proteinProgress: $proteinPercent');

            // -- 4. Health Score --
            final int healthScore = HealthScoreService.calculateHealthScore(
              waterPercent: waterPercent,
              caloriePercent: caloriePercent,
              proteinPercent: proteinPercent,
              activityPercent: activityPercent,
            );
            final String healthStatusText = HealthScoreService.getHealthScoreStatus(healthScore);

            final suggestion = _generateSuggestion(waterPercent, caloriePercent, proteinPercent, activityPercent);

            return SingleChildScrollView(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProfileHeader(
                    displayName: displayName,
                    avatarInitial: avatarInitial,
                    avatarUrl: avatarUrl,
                    goalText: hp?.goalType ?? 'Sağlıklı tarifler keşfetmek',
                    streakDays: provider.streakDays,
                    onNotificationTap: () => context.push('/notifications'),
                  ),
                  const SizedBox(height: 24),
                  DigitalTwinCard(
                    selectedGender: hp?.gender ?? 'Kadın',
                    waterPercent: waterPercent,
                    caloriePercent: caloriePercent,
                    proteinPercent: proteinPercent,
                    activityPercent: activityPercent,
                    healthScore: healthScore,
                    healthStatusText: healthStatusText,
                    onSuggestionTap: () => _showSuggestionDialog(suggestion),
                    waterCurrentStr: waterConsumedLiters.toStringAsFixed(1),
                    waterGoalStr: waterTargetLiters.toStringAsFixed(1),
                    calorieCurrentStr: currentCalories.toInt().toString(),
                    calorieGoalStr: calorieTarget.toInt().toString(),
                    proteinCurrentStr: currentProtein.toInt().toString(),
                    proteinGoalStr: proteinTarget.toInt().toString(),
                    activityCurrentStr: (todayGoals?.activityCompleted.toInt() ?? 0).toString(),
                    activityGoalStr: activityTarget.toInt().toString(),
                  ),
                  const SizedBox(height: 16),
                  WeightGoalTrackerCard(
                    fallbackWeight: hp?.weightKg ?? 85.0,
                  ),
                  const SizedBox(height: 16),
                  ProfileBasicInfoCard(
                    age: hp?.age ?? 22,
                    gender: hp?.gender ?? 'Kadın',
                    height: hp?.heightCm ?? 155.0,
                    weight: hp?.weightKg ?? 50.0,
                    activity: hp?.activityLevel ?? 'Orta',
                    goal: hp?.goalType ?? 'Sağlıklı tarifler keşfetmek',
                  ),
                  const SizedBox(height: 16),
                  WeeklyProgressCard(activeWeekdays: provider.activeWeekdays),
                  const SizedBox(height: 16),
                  DailyGoalsCard(
                    currentCalories: currentCalories,
                    targetCalories: calorieTarget,
                    currentProtein: currentProtein,
                    targetProtein: proteinTarget,
                    currentWater: todayGoals?.waterConsumed ?? 0.0,
                    targetWater: waterTargetMl,
                    currentActivity: todayGoals?.activityCompleted ?? 0.0,
                    targetActivity: activityTarget,
                  ),
                  const SizedBox(height: 16),
                  BodyAnalysisCard(
                    bmi: bmi,
                    bmiStatus: bmiStatus,
                    bmr: bmr,
                    dailyCalories: dailyCal,
                    idealRange: idealRange,
                  ),
                  const SizedBox(height: 32),
                  _buildLogoutButton(context),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: ChefRayBottomNavBar(
        currentIndex: 4,
        onTap: (i) {
          if (i == 0) context.go('/home');
          if (i == 1) context.push('/analysis-history');
          if (i == 2) context.push('/diet-upload');
          if (i == 3) context.push('/recipe-list');
        },
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        await Supabase.instance.client.auth.signOut();
        if (context.mounted) {
          context.go('/');
        }
      },
      icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
      label: const Text(
        'Çıkış Yap',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade400,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
    );
  }
}
