import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../widgets/common/soft_card.dart';

/// Card showing daily goal progress for calories, protein, water, and activity.
class DailyGoalsCard extends StatelessWidget {
  final double calorieGoal;
  final double proteinGoal;
  final double waterGoalMl;
  final double calorieProgress;
  final double proteinProgress;
  final double waterProgress;
  final double activityProgress;

  const DailyGoalsCard({
    super.key,
    required this.calorieGoal,
    required this.proteinGoal,
    required this.waterGoalMl,
    this.calorieProgress = 0.55,
    this.proteinProgress = 0.60,
    this.waterProgress = 0.45,
    this.activityProgress = 0.40,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.flag_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Günlük Hedefler',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Goal rows
            _goalRow(
              icon: Icons.local_fire_department_rounded,
              label: 'Kalori',
              color: AppColors.carbs,
              progress: calorieProgress,
              current: (calorieGoal * calorieProgress).toStringAsFixed(0),
              target: '${calorieGoal.toStringAsFixed(0)} kcal',
            ),
            const SizedBox(height: 14),
            _goalRow(
              icon: Icons.fitness_center_rounded,
              label: 'Protein',
              color: AppColors.primary,
              progress: proteinProgress,
              current: (proteinGoal * proteinProgress).toStringAsFixed(0),
              target: '${proteinGoal.toStringAsFixed(0)} g',
            ),
            const SizedBox(height: 14),
            _goalRow(
              icon: Icons.water_drop_rounded,
              label: 'Su',
              color: AppColors.info,
              progress: waterProgress,
              current: (waterGoalMl * waterProgress / 1000).toStringAsFixed(1),
              target: '${(waterGoalMl / 1000).toStringAsFixed(1)} L',
            ),
            const SizedBox(height: 14),
            _goalRow(
              icon: Icons.directions_run_rounded,
              label: 'Aktivite',
              color: AppColors.primary,
              progress: activityProgress,
              current: (30 * activityProgress).toStringAsFixed(0),
              target: '30 dk',
            ),
          ],
        ),
      ),
    );
  }

  Widget _goalRow({
    required IconData icon,
    required String label,
    required Color color,
    required double progress,
    required String current,
    required String target,
  }) {
    return Row(
      children: [
        // Icon
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        // Label + progress bar + text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textMedium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$current / $target',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: color.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
