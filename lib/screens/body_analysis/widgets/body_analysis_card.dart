import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../widgets/common/soft_card.dart';

/// Card displaying BMI, BMR, daily calories, and ideal weight analysis.
class BodyAnalysisCard extends StatelessWidget {
  final double bmi;
  final String bmiStatus;
  final double bmr;
  final double dailyCalories;
  final ({double min, double max}) idealRange;
  final double currentWeight;
  final String? activityLevel;
  final String? goalType;
  final VoidCallback? onDetailTap;

  const BodyAnalysisCard({
    super.key,
    required this.bmi,
    required this.bmiStatus,
    required this.bmr,
    required this.dailyCalories,
    required this.idealRange,
    required this.currentWeight,
    this.activityLevel,
    this.goalType,
    this.onDetailTap,
  });

  Color _bmiColor(String status) {
    switch (status) {
      case 'Zayıf':
        return AppColors.info;
      case 'Normal':
        return AppColors.primary;
      case 'Fazla kilolu':
        return AppColors.warning;
      case 'Obez':
        return AppColors.error;
      default:
        return AppColors.textMedium;
    }
  }

  ({String label, Color color}) get _weightStatus {
    if (currentWeight < idealRange.min) {
      return (label: 'Altında', color: AppColors.info);
    }
    if (currentWeight <= idealRange.max) {
      return (label: 'İdeal', color: AppColors.primary);
    }
    return (label: 'Üstünde', color: AppColors.warning);
  }

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
                    color: AppColors.carbs.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.analytics_rounded,
                    color: AppColors.carbs,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Vücut Analizi',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onDetailTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Detaylı Analiz',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Analysis rows
            _analysisRow(
              label: 'BMI',
              value: bmi > 0 ? bmi.toStringAsFixed(1) : '-',
              chipLabel: bmiStatus,
              chipColor: _bmiColor(bmiStatus),
            ),
            _rowDivider(),
            _analysisRow(
              label: 'BMR',
              value: bmr > 0 ? '${bmr.toStringAsFixed(0)} kcal' : '-',
              chipLabel: 'Dinlenme',
              chipColor: AppColors.carbs,
            ),
            _rowDivider(),
            _analysisRow(
              label: 'Günlük Kalori',
              value: dailyCalories > 0
                  ? '${dailyCalories.toStringAsFixed(0)} kcal'
                  : '-',
              chipLabel: activityLevel ?? 'Belirtilmedi',
              chipColor: AppColors.primary,
            ),
            _rowDivider(),
            _analysisRow(
              label: 'İdeal Kilo',
              value: idealRange.min > 0
                  ? '${idealRange.min.toStringAsFixed(1)} - ${idealRange.max.toStringAsFixed(1)} kg'
                  : '-',
              chipLabel: _weightStatus.label,
              chipColor: _weightStatus.color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _analysisRow({
    required String label,
    required String value,
    required String chipLabel,
    required Color chipColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Label
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textLight,
              ),
            ),
          ),
          // Value
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Status chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: chipColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              chipLabel,
              style: AppTextStyles.labelSmall.copyWith(
                color: chipColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowDivider() {
    return const Divider(height: 1, thickness: 1, color: AppColors.divider);
  }
}
