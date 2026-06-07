import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../widgets/common/soft_card.dart';

/// Beslenme Tercihi card with chip display for diet preferences.
class NutritionPreferenceCard extends StatelessWidget {
  final List<String> dietPreferences;

  const NutritionPreferenceCard({
    super.key,
    required this.dietPreferences,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = dietPreferences
        .where((p) => p != 'Normal')
        .toList();
    final hasPrefs = filtered.isNotEmpty;

    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with restaurant icon
          Row(
            children: [
              Icon(Icons.restaurant_rounded,
                  size: 16, color: AppColors.carbs),
              const SizedBox(width: 6),
              Text('Beslenme Tercihi',
                  style: AppTextStyles.h3.copyWith(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          if (hasPrefs)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: filtered
                  .map((item) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.carbs.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.carbs,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ))
                  .toList(),
            )
          else
            _buildEmptyState(context, 'Standart beslenme'),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundMint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 14, color: AppColors.textHint),
          const SizedBox(width: 8),
          Text(text,
              style: AppTextStyles.labelSmall
                  .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
