import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/common/bottom_nav_bar.dart';
import '../../services/calculations/health_calculation_service.dart';
import '../../models/user_health_profile.dart';
import '../../repositories/user_health_profile_repository.dart';
import '../../providers/user_profile_provider.dart';
import 'widgets/body_status_header.dart';
import 'widgets/body_summary_strip.dart';
import 'widgets/body_status_card.dart';
import 'widgets/body_analysis_card.dart';
import 'widgets/daily_goals_card.dart';
import 'widgets/improvement_suggestions_card.dart';
import 'widgets/body_analysis_detail_sheet.dart';
import 'widgets/edit_body_metrics_sheet.dart';

class BodyAnalysisScreen extends StatefulWidget {
  const BodyAnalysisScreen({super.key});

  @override
  State<BodyAnalysisScreen> createState() => _BodyAnalysisScreenState();
}

class _BodyAnalysisScreenState extends State<BodyAnalysisScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProfileProvider>().refreshAll();
    });
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Consumer<UserProfileProvider>(
          builder: (context, provider, _) {
            final hp = provider.healthProfile;
            final hasData = hp != null && hp.weightKg != null && hp.heightCm != null;

            // Pre-calculate values if data exists
            final double bmi;
            final String bmiStatus;
            final double bmr;
            final double dailyCal;
            final ({double min, double max}) ideal;
            final ({double calories, double proteinG, double waterMl}) goals;
            final List<String> suggestions;

            if (hasData) {
              final w = hp.weightKg!;
              final h = hp.heightCm!;
              final a = hp.age ?? 0;
              final g = hp.gender ?? 'Kadın';

              bmi = HealthCalculationService.calculateBMI(w, h);
              bmiStatus = HealthCalculationService.getBMIStatus(bmi);
              bmr = HealthCalculationService.calculateBMR(w, h, a, g);
              dailyCal = HealthCalculationService.calculateDailyCalories(bmr, hp.activityLevel);
              ideal = HealthCalculationService.calculateIdealWeightRange(h);
              goals = HealthCalculationService.calculateDailyGoals(dailyCal, w, hp.goalType);
              suggestions = HealthCalculationService.getSuggestions(hp.goalType, bmi, bmiStatus);
            } else {
              bmi = 0;
              bmiStatus = 'Bilinmiyor';
              bmr = 0;
              dailyCal = 0;
              ideal = (min: 0.0, max: 0.0);
              goals = (calories: 0.0, proteinG: 0.0, waterMl: 0.0);
              suggestions = const [
                'Boy ve kilo bilgilerini girerek sana özel öneriler al.',
                'Beslenme hedefini belirleyerek daha iyi sonuçlar elde et.',
                'Aktivite seviyeni güncelleyerek doğru kalori hesaplaması yap.',
              ];
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                children: [
                  // ── Header ──────────────────────────────────
                  BodyStatusHeader(
                    onUpdateTap: () => _openEditSheet(hp),
                  ),
                  const SizedBox(height: 14),
                  // ── Summary Strip ───────────────────────────
                  BodySummaryStrip(healthProfile: hp),
                  const SizedBox(height: 16),
                  // ── Body Status Card ────────────────────────
                  BodyStatusCard(
                    currentWeight: hp?.weightKg,
                    idealRange: hasData ? ideal : null,
                    onEnterData: () => _openEditSheet(hp),
                  ),
                  const SizedBox(height: 12),
                  // ── Body Analysis Card ──────────────────────
                  if (hasData)
                    BodyAnalysisCard(
                      bmi: bmi,
                      bmiStatus: bmiStatus,
                      bmr: bmr,
                      dailyCalories: dailyCal,
                      idealRange: ideal,
                      currentWeight: hp.weightKg!,
                      activityLevel: hp.activityLevel,
                      goalType: hp.goalType,
                      onDetailTap: () {
                        final bmiDetail = HealthCalculationService.getBMIDetail(bmi);
                        BodyAnalysisDetailSheet.show(
                          context,
                          bmi: bmi,
                          bmiStatus: bmiStatus,
                          bmiDescription: bmiDetail.description,
                          bmr: bmr,
                          dailyCalories: dailyCal,
                          idealWeightMin: ideal.min,
                          idealWeightMax: ideal.max,
                          currentWeight: hp.weightKg!,
                          goalType: hp.goalType,
                        );
                      },
                    ),
                  const SizedBox(height: 12),
                  // ── Info Banner ─────────────────────────────
                  _buildInfoBanner(),
                  const SizedBox(height: 12),
                  // ── Daily Goals Card ────────────────────────
                  if (hasData)
                    DailyGoalsCard(
                      calorieGoal: goals.calories,
                      proteinGoal: goals.proteinG,
                      waterGoalMl: goals.waterMl,
                    ),
                  const SizedBox(height: 12),
                  // ── Suggestions Card ────────────────────────
                  ImprovementSuggestionsCard(suggestions: suggestions),
                  const SizedBox(height: 12),
                  // ── Disclaimer ──────────────────────────────
                  _buildDisclaimer(),
                  const SizedBox(height: 20),
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
          if (i == 4) context.go('/profile');
        },
      ),
    );
  }

  // ── Info Banner ────────────────────────────────────────────

  Widget _buildInfoBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.backgroundMint,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Bu değerler; kilo, boy, yaş, hedef ve aktivite bilgilerini güncellediğinde otomatik olarak yeniden hesaplanır.',
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMedium),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Disclaimer ─────────────────────────────────────────────

  Widget _buildDisclaimer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        'Bu veriler tıbbi tavsiye yerine geçmez.',
        textAlign: TextAlign.center,
        style: AppTextStyles.labelSmall.copyWith(fontSize: 9, color: AppColors.textHint),
      ),
    );
  }

  // ── Edit Sheet ─────────────────────────────────────────────

  void _openEditSheet(UserHealthProfile? hp) {
    EditBodyMetricsSheet.show(
      context,
      currentWeightKg: hp?.weightKg,
      currentHeightCm: hp?.heightCm,
      currentAge: hp?.age,
      currentGender: hp?.gender,
      currentGoalType: hp?.goalType,
      currentActivityLevel: hp?.activityLevel,
      onSave: ({
        required double weightKg,
        required double heightCm,
        required int age,
        required String gender,
        required String goalType,
        required String activityLevel,
      }) => _handleMetricsSave(
        weightKg: weightKg,
        heightCm: heightCm,
        age: age,
        gender: gender,
        goalType: goalType,
        activityLevel: activityLevel,
      ),
    );
  }

  Future<void> _handleMetricsSave({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
    required String goalType,
    required String activityLevel,
  }) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final hp = UserHealthProfile(
        userId: userId,
        age: age,
        gender: gender,
        heightCm: heightCm,
        weightKg: weightKg,
        goalType: goalType,
        activityLevel: activityLevel,
        updatedAt: DateTime.now(),
      );
      await UserHealthProfileRepository.instance.upsertCurrentUserHealthProfile(hp);

      if (mounted) {
        await context.read<UserProfileProvider>().refreshAll();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Bilgiler güncellendi, analiz yeniden hesaplandı.'),
            ]),
            backgroundColor: AppColors.primary.withValues(alpha: 0.9),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Güncelleme sırasında bir hata oluştu.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
