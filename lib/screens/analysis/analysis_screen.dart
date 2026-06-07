import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/analysis_model.dart';
import '../../models/meal_model.dart';
import '../../models/macro_model.dart';
import '../../widgets/common/soft_card.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/progress_card.dart';
import '../../widgets/common/macro_chip.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/mascot/ray_message_card.dart';
import '../../models/ai/analysis_results.dart';
import '../../models/user_health_profile.dart';
import '../../models/recipe_model.dart';
import '../../models/recipes/recommended_recipe_view_model.dart';

class AnalysisScreen extends StatefulWidget {
  final Map<String, dynamic>? analysisData;
  const AnalysisScreen({super.key, this.analysisData});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with SingleTickerProviderStateMixin {
  late final DietAnalysisResult _dietResult;
  late final BloodAnalysisResult? _bloodResult;
  late final CombinedHealthAnalysis? _combinedResult;
  late final List<RecommendedRecipeViewModel> _recommendedRecipes;
  late final UserHealthProfile _profile;

  late final AnimationController _staggerCtrl;

  bool get _hasCalories => _dietResult.dailyCalorieTarget != null;
  
  bool get _hasMacros => 
      _dietResult.proteinGrams != null || 
      _dietResult.carbsGrams != null || 
      _dietResult.fatGrams != null;

  int? _parseCal(String? calStr) {
    if (calStr == null) return null;
    final clean = calStr.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(clean);
  }

  @override
  void initState() {
    super.initState();
    
    final extra = widget.analysisData;
    if (extra != null) {
      _dietResult = extra['dietAnalysisResult'] as DietAnalysisResult? ?? DietAnalysisResult.empty();
      _bloodResult = extra['bloodAnalysisResult'] as BloodAnalysisResult?;
      _combinedResult = extra['combinedAnalysisResult'] as CombinedHealthAnalysis?;
      _profile = extra['userHealthProfile'] as UserHealthProfile? ?? const UserHealthProfile();

      final candidates = List<RecipeModel>.from(extra['candidateRecipes'] ?? []);
      
      final rawRecs = extra['recommendedRecipes'] as List? ?? [];
      final List<RecommendedRecipeViewModel> tempVMs = [];
      
      if (rawRecs.isNotEmpty) {
        if (rawRecs.first is RecommendedRecipeViewModel) {
          tempVMs.addAll(List<RecommendedRecipeViewModel>.from(rawRecs));
        } else if (rawRecs.first is RecipeRecommendationResult) {
          final recommendations = List<RecipeRecommendationResult>.from(rawRecs);
          for (final rec in recommendations) {
            final recipe = candidates.firstWhere(
              (r) => r.id.toString() == rec.recipeId.toString(),
              orElse: () => RecipeModel(
                id: rec.recipeId,
                title: rec.recipeTitle,
                description: rec.matchReason,
                calories: 0,
                protein: 0,
                carbs: 0,
                fat: 0,
                imageUrl: null,
                timeMinutes: 20,
                ingredients: [],
                steps: [],
                tags: [],
                mealType: rec.suggestedMealType.isNotEmpty ? rec.suggestedMealType : 'Diğer',
              ),
            );
            if (rec.isSafeForUser) {
              tempVMs.add(
                RecommendedRecipeViewModel(
                  recipe: recipe,
                  recommendation: rec,
                ),
              );
            }
          }
        }
      }
      _recommendedRecipes = tempVMs;
      _recommendedRecipes.sort((a, b) => b.recommendation.matchScore.compareTo(a.recommendation.matchScore));
    } else {
      _dietResult = DietAnalysisResult.empty();
      _bloodResult = null;
      _combinedResult = null;
      _recommendedRecipes = [];
      _profile = const UserHealthProfile();
    }

    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  Widget _staggered(int index, Widget child) {
    final start = (index * 0.1).clamp(0.0, 0.7);
    final end = (start + 0.4).clamp(0.0, 1.0);
    final curve = CurvedAnimation(
      parent: _staggerCtrl,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
    return AnimatedBuilder(
      animation: curve,
      builder: (context, ch) => Opacity(
        opacity: curve.value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - curve.value)),
          child: ch,
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate current calories from meals if available
    int currentCal = 0;
    if (_dietResult.breakfast != null) currentCal += _parseCal(_dietResult.breakfast!.calories) ?? 350;
    if (_dietResult.lunch != null) currentCal += _parseCal(_dietResult.lunch!.calories) ?? 550;
    if (_dietResult.dinner != null) currentCal += _parseCal(_dietResult.dinner!.calories) ?? 600;
    for (var snack in _dietResult.snacks) {
      currentCal += _parseCal(snack.calories) ?? 150;
    }

    final targetCal = _dietResult.dailyCalorieTarget ?? 0;
    final remainingCal = math.max(0, targetCal - currentCal);
    final calPct = targetCal > 0 ? (currentCal / targetCal).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/home'),
                    child: Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle,
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.textDark, size: 20),
                    ),
                  ),
                  const Spacer(),
                  Text('Analiz Sonucu', style: AppTextStyles.h2),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle,
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: const Icon(Icons.ios_share_rounded,
                          color: AppColors.textDark, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Success badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text('Diyet başarıyla analiz edildi!',
                      style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.primary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Scrollable Content ─────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Hero calorie card
                    if (_hasCalories)
                      _staggered(0, ProgressCard(
                        current: currentCal,
                        target: targetCal,
                        percentage: calPct,
                        remaining: remainingCal,
                      ))
                    else
                      _staggered(0, Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF0F3D2E), Color(0xFF1A5C3F)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F3D2E).withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.white, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Günlük Kalori Özeti',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: Colors.white.withValues(alpha: 0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Belgede kalori hedefi belirtilmemiş.',
                                    style: AppTextStyles.h3.copyWith(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                    const SizedBox(height: 20),

                    // Grid: Makro + Hedef
                    _staggered(1, Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _hasMacros 
                              ? _buildMacroCard() 
                              : Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: AppColors.divider),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.donut_small_rounded, size: 16, color: AppColors.textMedium),
                                          const SizedBox(width: 6),
                                          Text('Makro Dağılımı', style: AppTextStyles.h3.copyWith(fontSize: 13, color: AppColors.textMedium)),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Makro bilgisi belgede net olarak bulunamadı.',
                                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMedium),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: _buildGoalCard()),
                      ],
                    )),
                    const SizedBox(height: 12),

                    // Grid: Öğün + Alerjen
                    _staggered(2, Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildDistributionCard(currentCal)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildAllergenCard()),
                      ],
                    )),
                    const SizedBox(height: 24),

                    // Detected meals
                    _staggered(3, Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          title: 'Tespit Edilen Öğünler',
                          actionText: 'Tümünü Gör',
                          onAction: () {},
                        ),
                        const SizedBox(height: 14),
                        ..._buildMealResultCards(),
                      ],
                    )),
                    const SizedBox(height: 16),

                    // AI Comment
                    _staggered(4, _buildAiComment()),
                    const SizedBox(height: 20),

                    // CTA
                    PrimaryButton(
                      text: 'Tarif Önerilerini Gör',
                      trailingIcon: Icons.arrow_forward_rounded,
                      onPressed: () {
                        context.push('/recipe-list', extra: _recommendedRecipes);
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.schedule_rounded, size: 13, color: AppColors.textLight),
                        const SizedBox(width: 5),
                        Text('Son analiz: Bugün', style: AppTextStyles.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Macro Distribution Card ────────────────────────────
  Widget _buildMacroCard() {
    final List<MacroModel> macros = [
      MacroModel(
        name: 'Protein',
        current: _dietResult.proteinGrams ?? 0,
        target: 120,
        percentage: ((_dietResult.proteinGrams ?? 0) / 120).clamp(0.0, 1.0),
      ),
      MacroModel(
        name: 'Karbonhidrat',
        current: _dietResult.carbsGrams ?? 0,
        target: 200,
        percentage: ((_dietResult.carbsGrams ?? 0) / 200).clamp(0.0, 1.0),
      ),
      MacroModel(
        name: 'Yağ',
        current: _dietResult.fatGrams ?? 0,
        target: 70,
        percentage: ((_dietResult.fatGrams ?? 0) / 70).clamp(0.0, 1.0),
      ),
    ];

    const macroColors = [AppColors.protein, AppColors.carbs, AppColors.fat];
    const macroLetters = ['P', 'K', 'Y'];

    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.donut_small_rounded, size: 16,
                  color: AppColors.primary.withValues(alpha: 0.6)),
              const SizedBox(width: 6),
              Text('Makro Dağılımı', style: AppTextStyles.h3.copyWith(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(macros.length, (i) => MacroChip(
            letter: macroLetters[i],
            color: macroColors[i],
            name: macros[i].name,
            current: macros[i].current,
            target: macros[i].target,
            percentage: (macros[i].percentage * 100).toInt(),
          )),
        ],
      ),
    );
  }

  // ── Goal Compliance Card ───────────────────────────────
  Widget _buildGoalCard() {
    final List<GoalStatus> goals = [];
    
    if (_profile.allergies.isNotEmpty) {
      goals.add(GoalStatus(
        name: 'Alerjen Filtresi',
        status: 'uygun',
        label: '${_profile.allergies.length} Alerjen elendi',
      ));
    } else {
      goals.add(const GoalStatus(
        name: 'Alerjen Filtresi',
        status: 'uygun',
        label: 'Riskli besin bulunmuyor',
      ));
    }

    if (_dietResult.avoidedFoods.isNotEmpty) {
      goals.add(GoalStatus(
        name: 'Diyet Kısıtları',
        status: 'kismen',
        label: '${_dietResult.avoidedFoods.length} besin sınırlı',
      ));
    }

    if (_bloodResult != null && _bloodResult.markers.isNotEmpty) {
      final abnormal = _bloodResult.markers.where((m) => m.status == 'low' || m.status == 'high').length;
      if (abnormal > 0) {
        goals.add(GoalStatus(
          name: 'Kan Tahlili',
          status: 'kismen',
          label: '$abnormal değer uyumsuz',
        ));
      } else {
        goals.add(const GoalStatus(
          name: 'Kan Tahlili',
          status: 'uygun',
          label: 'Kan değerleriyle uyumlu',
        ));
      }
    } else {
      goals.add(const GoalStatus(
        name: 'Kan Tahlili',
        status: 'kismen',
        label: 'Tahlil eklenmedi',
      ));
    }

    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_rounded, size: 16,
                  color: AppColors.primary.withValues(alpha: 0.6)),
              const SizedBox(width: 6),
              Text('Hedef Uyumu', style: AppTextStyles.h3.copyWith(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 14),
          ...goals.map((g) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Icon(
                  g.status == 'uygun'
                      ? Icons.check_circle_rounded
                      : g.status == 'kismen'
                          ? Icons.warning_rounded
                          : Icons.cancel_rounded,
                  size: 18,
                  color: g.status == 'uygun'
                      ? AppColors.primary
                      : g.status == 'kismen'
                          ? AppColors.warning
                          : AppColors.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(g.name, style: AppTextStyles.labelMedium.copyWith(
                          fontSize: 12, color: AppColors.textDark, fontWeight: FontWeight.w600)),
                      Text(g.label, style: AppTextStyles.labelSmall.copyWith(fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ── Meal Distribution Card ─────────────────────────────
  Widget _buildDistributionCard(int totalCal) {
    int breakfastCal = _parseCal(_dietResult.breakfast?.calories) ?? 300;
    int lunchCal = _parseCal(_dietResult.lunch?.calories) ?? 500;
    int dinnerCal = _parseCal(_dietResult.dinner?.calories) ?? 550;
    int snackCal = 0;
    for (var snack in _dietResult.snacks) {
      snackCal += _parseCal(snack.calories) ?? 150;
    }
    
    int sum = breakfastCal + lunchCal + dinnerCal + snackCal;
    if (sum == 0) sum = 1;

    final breakfastPct = (breakfastCal * 100 ~/ sum).clamp(5, 95);
    final lunchPct = (lunchCal * 100 ~/ sum).clamp(5, 95);
    final dinnerPct = (dinnerCal * 100 ~/ sum).clamp(5, 95);
    final snackPct = (snackCal * 100 ~/ sum).clamp(5, 95);

    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_rounded, size: 16,
                  color: AppColors.primary.withValues(alpha: 0.6)),
              const SizedBox(width: 6),
              Text('Öğün Dağılımı', style: AppTextStyles.h3.copyWith(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 14),
          Center(
            child: SizedBox(
              width: 70, height: 70,
              child: CustomPaint(
                painter: _DonutPainter(
                  values: [breakfastPct / 100, lunchPct / 100, dinnerPct / 100, snackPct / 100],
                  colors: const [
                    AppColors.primary,
                    Color(0xFF5BC0EB),
                    AppColors.carbs,
                    AppColors.fat,
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _distRow('●', 'Kahvaltı', '%$breakfastPct', AppColors.primary),
          _distRow('●', 'Öğle Yemeği', '%$lunchPct', const Color(0xFF5BC0EB)),
          _distRow('●', 'Akşam Yemeği', '%$dinnerPct', AppColors.carbs),
          _distRow('●', 'Ara Öğün', '%$snackPct', AppColors.fat),
        ],
      ),
    );
  }

  Widget _distRow(String dot, String label, String pct, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Expanded(child: Text(label, style: AppTextStyles.labelSmall.copyWith(fontSize: 10))),
          Text(pct, style: AppTextStyles.labelSmall.copyWith(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  // ── Allergen Card ──────────────────────────────────────
  Widget _buildAllergenCard() {
    final List<AllergenStatus> allergens = [];

    // Checked profile allergies
    for (var allergy in _profile.allergies) {
      allergens.add(AllergenStatus(name: allergy, detected: true));
    }

    // Checked blood marker concerns
    if (_bloodResult != null) {
      for (var marker in _bloodResult.markers) {
        if (marker.status == 'low' || marker.status == 'high') {
          allergens.add(AllergenStatus(name: marker.name, detected: true));
        }
      }
    }

    // Fallbacks if clean
    if (allergens.isEmpty) {
      allergens.add(const AllergenStatus(name: 'Gluten', detected: false));
      allergens.add(const AllergenStatus(name: 'Laktoz', detected: false));
      allergens.add(const AllergenStatus(name: 'Fıstık', detected: false));
    }

    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 16,
                  color: AppColors.error.withValues(alpha: 0.6)),
              const SizedBox(width: 6),
              Text('Alerjen & Riskler', style: AppTextStyles.h3.copyWith(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 14),
          ...allergens.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Icon(
                  a.detected ? Icons.cancel_rounded : Icons.check_circle_rounded,
                  size: 18,
                  color: a.detected ? AppColors.error : AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.name, style: AppTextStyles.labelMedium.copyWith(
                          fontSize: 12, color: AppColors.textDark, fontWeight: FontWeight.w600)),
                      Text(a.detected ? 'Riskli/Gözetim altında' : 'Risk tespit edilmedi',
                          style: AppTextStyles.labelSmall.copyWith(fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ── Build Detected Meal Cards ─────────────────────────────
  List<Widget> _buildMealResultCards() {
    final List<MealModel> mealsList = [];
    
    if (_dietResult.breakfast != null) {
      mealsList.add(MealModel(
        name: 'Kahvaltı',
        time: '08:30',
        mealType: _dietResult.breakfast!.items.join(', '),
        calories: _parseCal(_dietResult.breakfast!.calories) ?? 350,
        protein: 15,
        carbs: 40,
        fat: 12,
      ));
    }
    
    if (_dietResult.lunch != null) {
      mealsList.add(MealModel(
        name: 'Öğle Yemeği',
        time: '13:00',
        mealType: _dietResult.lunch!.items.join(', '),
        calories: _parseCal(_dietResult.lunch!.calories) ?? 550,
        protein: 30,
        carbs: 55,
        fat: 15,
      ));
    }
    
    if (_dietResult.dinner != null) {
      mealsList.add(MealModel(
        name: 'Akşam Yemeği',
        time: '19:30',
        mealType: _dietResult.dinner!.items.join(', '),
        calories: _parseCal(_dietResult.dinner!.calories) ?? 600,
        protein: 35,
        carbs: 50,
        fat: 16,
      ));
    }
    
    int index = 1;
    for (var snack in _dietResult.snacks) {
      mealsList.add(MealModel(
        name: 'Ara Öğün $index',
        time: '16:30',
        mealType: snack.items.join(', '),
        calories: _parseCal(snack.calories) ?? 150,
        protein: 5,
        carbs: 20,
        fat: 4,
      ));
      index++;
    }

    if (mealsList.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text('Öğün bilgisi bulunamadı.', style: AppTextStyles.bodySmall),
          ),
        )
      ];
    }

    return mealsList.map((m) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _MealResultCard(meal: m),
    )).toList();
  }

  // ── AI Comment Card ────────────────────────────────────
  Widget _buildAiComment() {
    final comment = _combinedResult?.combinedSummary ?? _dietResult.dietSummary;
    return Column(
      children: [
        RayMessageCard(
          title: "Ray'in Yorumu",
          message: comment.isNotEmpty ? comment : "Diyet listenizin ve sağlık profilinizin analizi başarıyla tamamlandı. Hedeflerinize uygun tarifleri inceleyebilirsiniz.",
          imagePath: 'assets/mascot/ray_default.png',
        ),
        if (_bloodResult != null && _bloodResult.safetyWarning.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.healing_rounded, color: AppColors.warning, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _bloodResult.safetyWarning,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )
        ]
      ],
    );
  }
}

// ── Meal Result Card ─────────────────────────────────────
class _MealResultCard extends StatelessWidget {
  final MealModel meal;
  const _MealResultCard({required this.meal});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.restaurant_rounded,
                color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meal.name,
                    style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(meal.mealType,
                    style: AppTextStyles.labelSmall.copyWith(fontSize: 10),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    _macroPill('🔥 ${meal.calories} kcal', AppColors.primary),
                    _macroPill('P ${meal.protein}g', AppColors.protein),
                    _macroPill('K ${meal.carbs}g', AppColors.carbs),
                    _macroPill('Y ${meal.fat}g', AppColors.fat),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
        ],
      ),
    );
  }

  Widget _macroPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ── Donut Chart Painter ──────────────────────────────────
class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  _DonutPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 6;
    const sw = 10.0;
    const gap = 0.06;
    double start = -math.pi / 2;

    for (int i = 0; i < values.length; i++) {
      final sweep = values[i] * 2 * math.pi - gap;
      if (sweep <= 0) continue;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r), start, sweep, false,
        Paint()
          ..color = colors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw
          ..strokeCap = StrokeCap.round,
      );
      start += values[i] * 2 * math.pi;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => false;
}
