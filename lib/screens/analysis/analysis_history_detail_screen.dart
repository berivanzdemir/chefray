import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/analysis/analysis_history_item.dart';
import '../../models/ai/analysis_results.dart';
import '../../models/recipe_model.dart';
import '../../models/recipes/recommended_recipe_view_model.dart';
import '../../models/user_health_profile.dart';
import '../../repositories/user_health_profile_repository.dart';
import '../../services/spoonacular_service.dart';
import '../../services/ai/combined_analysis_service.dart';
import '../../widgets/common/soft_card.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/mascot/ray_message_card.dart';

class AnalysisHistoryDetailScreen extends StatefulWidget {
  final AnalysisHistoryItem? historyItem;
  const AnalysisHistoryDetailScreen({super.key, this.historyItem});

  @override
  State<AnalysisHistoryDetailScreen> createState() => _AnalysisHistoryDetailScreenState();
}

class _AnalysisHistoryDetailScreenState extends State<AnalysisHistoryDetailScreen> {
  bool _isRankingRecipes = false;

  String _formatDate(DateTime dt) {
    final months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // ── Rank Recipes On the Fly for this specific history item ────────
  Future<void> _viewRecommendedRecipes(AnalysisHistoryItem item) async {
    if (item.dietAnalysis == null) return;

    try {
      setState(() {
        _isRankingRecipes = true;
      });

      // 1. Fetch user health profile
      final profileRepo = UserHealthProfileRepository.instance;
      UserHealthProfile? userProfile = await profileRepo.getCurrentUserHealthProfile();
      userProfile ??= const UserHealthProfile(
        age: 25, gender: 'Erkek', heightCm: 175, weightKg: 70, goalType: 'Sağlıklı Yaşam'
      );

      // 2. Fetch recipes from Spoonacular
      final spoonService = SpoonacularService();
      final candidateRecipes = await spoonService.getRecipes(query: 'healthy', number: 10);

      // 3. Rank them using CombinedAnalysisService
      final recommendations = await CombinedAnalysisService().rankRecipes(
        candidateRecipes: candidateRecipes,
        userHealthProfile: userProfile,
        dietAnalysis: item.dietAnalysis!,
        bloodAnalysis: item.bloodAnalysis ?? BloodAnalysisResult.empty(),
        combinedAnalysis: item.combinedAnalysis ?? CombinedHealthAnalysis.empty(),
      );

      // 4. Build RecommendedRecipeViewModels
      final List<RecommendedRecipeViewModel> recommendedVMs = [];
      for (final rec in recommendations) {
        final recipe = candidateRecipes.firstWhere(
          (r) => r.id.toString() == rec.recipeId.toString(),
          orElse: () => RecipeModel(
            id: rec.recipeId,
            title: rec.recipeTitle,
            description: rec.matchReason,
            calories: 0, protein: 0, carbs: 0, fat: 0, imageUrl: null,
            timeMinutes: 20, ingredients: [], steps: [], tags: [], mealType: 'Diğer'
          ),
        );
        if (rec.isSafeForUser) {
          recommendedVMs.add(
            RecommendedRecipeViewModel(recipe: recipe, recommendation: rec),
          );
        }
      }
      recommendedVMs.sort((a, b) => b.recommendation.matchScore.compareTo(a.recommendation.matchScore));

      if (mounted) {
        context.push('/recipe-list', extra: recommendedVMs);
      }
    } catch (e) {
      debugPrint('Error ranking recipes on the fly: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tarif önerileri hazırlanırken bir sorun oluştu. Lütfen tekrar deneyiniz.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRankingRecipes = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.historyItem;
    if (item == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text('Analiz detayı bulunamadı.', style: AppTextStyles.bodyMedium),
        ),
      );
    }

    final hasDiet = item.dietAnalysis != null;
    final hasBlood = item.bloodAnalysis != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark),
          onPressed: () => context.pop(),
        ),
        title: Text('Analiz Detayı', style: AppTextStyles.h2),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Date & Status Header ─────────────────────
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textLight),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(item.createdAt),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textMedium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── AI Message Comment Card ──────────────────
              RayMessageCard(
                title: "Ray'in Değerlendirmesi",
                message: item.summary,
                imagePath: 'assets/mascot/ray_default.png',
              ),
              const SizedBox(height: 20),

              // ── Nutrition Priorities ─────────────────────
              if (item.nutritionPriorities.isNotEmpty) ...[
                Text('Beslenme Önceliklerin', style: AppTextStyles.h3.copyWith(fontSize: 14)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: item.nutritionPriorities.map((p) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      p,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 24),
              ],

              // ── Diet Analysis Details ────────────────────
              if (hasDiet) ...[
                Text('Diyet Analiz Detayları', style: AppTextStyles.h3.copyWith(fontSize: 14)),
                const SizedBox(height: 10),
                SoftCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.dietAnalysis!.dailyCalorieTarget != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.local_fire_department_rounded, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text('Günlük Kalori Hedefi: ', style: AppTextStyles.bodySmall),
                            Text('${item.dietAnalysis!.dailyCalorieTarget} kcal', 
                                style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ],
                        ),
                        const Divider(height: 20, color: AppColors.divider),
                      ],
                      
                      // Macros Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _macroItem('Protein', '${item.dietAnalysis!.proteinGrams ?? 0}g', AppColors.protein),
                          _macroItem('K.hidrat', '${item.dietAnalysis!.carbsGrams ?? 0}g', AppColors.carbs),
                          _macroItem('Yağ', '${item.dietAnalysis!.fatGrams ?? 0}g', AppColors.fat),
                        ],
                      ),

                      if (item.dietAnalysis!.avoidedFoods.isNotEmpty) ...[
                        const Divider(height: 20, color: AppColors.divider),
                        Text('Sınırlanması Gereken Besinler:', 
                            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textDark, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        ...item.dietAnalysis!.avoidedFoods.map((food) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.remove_circle_outline_rounded, size: 12, color: AppColors.error),
                              const SizedBox(width: 6),
                              Text(food, style: AppTextStyles.bodySmall.copyWith(fontSize: 12)),
                            ],
                          ),
                        )),
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ── Blood Test Markers Details ────────────────
              if (hasBlood && item.bloodAnalysis!.markers.isNotEmpty) ...[
                Text('Kan Tahlili Önemli Değerleri', style: AppTextStyles.h3.copyWith(fontSize: 14)),
                const SizedBox(height: 10),
                SoftCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: item.bloodAnalysis!.markers.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.divider),
                    itemBuilder: (context, idx) {
                      final m = item.bloodAnalysis!.markers[idx];
                      final isIrregular = m.status == 'low' || m.status == 'high';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.name, style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.bold, fontSize: 12)),
                                  if (m.referenceRange != null)
                                    Text('Ref: ${m.referenceRange}', style: TextStyle(fontSize: 9, color: AppColors.textLight)),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${m.value ?? '-'} ${m.unit ?? ''}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isIrregular
                                    ? AppColors.error.withValues(alpha: 0.1)
                                    : AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                m.status == 'low' 
                                    ? 'Düşük 📉' 
                                    : (m.status == 'high' ? 'Yüksek 📈' : 'Normal ✅'),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: isIrregular ? AppColors.error : AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ── Safety Warnings ──────────────────────────
              if (item.safetyNotes.isNotEmpty) ...[
                Text('Dikkat Edilmesi Gerekenler ⚠️', style: AppTextStyles.h3.copyWith(fontSize: 14)),
                const SizedBox(height: 10),
                ...item.safetyNotes.map((note) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          note,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 11,
                            color: AppColors.warning,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 24),
              ],

              // ── Call to Action Recommendation Button ─────
              if (hasDiet) ...[
                _isRankingRecipes
                    ? const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 12),
                            Text('Tarifleriniz analizine göre sıralanıyor...', style: TextStyle(fontSize: 12, color: AppColors.textMedium)),
                          ],
                        ),
                      )
                    : PrimaryButton(
                        text: 'Önerilen Tarifleri Gör',
                        trailingIcon: Icons.arrow_forward_rounded,
                        onPressed: () => _viewRecommendedRecipes(item),
                      ),
              ] else ...[
                Center(
                  child: Text(
                    'Bu analiz için kayıtlı tarif önerisi bulunamadı.',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _macroItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(value, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.labelSmall.copyWith(fontSize: 9, color: AppColors.textLight)),
      ],
    );
  }
}
