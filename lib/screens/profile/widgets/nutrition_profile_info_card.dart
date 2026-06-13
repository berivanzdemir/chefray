import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/user_health_profile.dart';
import '../../../widgets/common/soft_card.dart';

/// Temel Bilgiler & Hedef card with 2x3 grid layout.
class NutritionProfileInfoCard extends StatelessWidget {
  final UserHealthProfile healthProfile;

  const NutritionProfileInfoCard({super.key, required this.healthProfile});

  @override
  Widget build(BuildContext context) {
    final items = [
      _InfoItem(
        icon: Icons.cake_rounded,
        label: 'Yaş',
        value: healthProfile.age != null ? '${healthProfile.age}' : '-',
        color: Theme.of(context).colorScheme.primary,
      ),
      _InfoItem(
        icon: healthProfile.gender == 'Erkek'
            ? Icons.male_rounded
            : Icons.female_rounded,
        label: 'Cinsiyet',
        value: healthProfile.gender ?? '-',
        color: AppColors.info,
      ),
      _InfoItem(
        icon: Icons.straighten_rounded,
        label: 'Boy',
        value: healthProfile.heightCm != null
            ? '${healthProfile.heightCm} cm'
            : '-',
        color: AppColors.carbs,
      ),
      _InfoItem(
        icon: Icons.monitor_weight_rounded,
        label: 'Kilo',
        value: healthProfile.weightKg != null
            ? '${healthProfile.weightKg} kg'
            : '-',
        color: AppColors.error,
      ),
      _InfoItem(
        icon: Icons.track_changes_rounded,
        label: 'Hedef',
        value: healthProfile.goalType ?? '-',
        color: Theme.of(context).colorScheme.primary,
      ),
      _InfoItem(
        icon: Icons.fitness_center_rounded,
        label: 'Aktivite',
        value: healthProfile.activityLevel ?? '-',
        color: AppColors.carbs,
      ),
    ];

    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Temel Bilgiler & Hedef',
                style: AppTextStyles.h3.copyWith(fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 2x3 grid
          for (int row = 0; row < 3; row++) ...[
            if (row > 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Divider(height: 1),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: _buildInfoCell(context, items[row * 2])),
                  const SizedBox(width: 12),
                  Expanded(child: _buildInfoCell(context, items[row * 2 + 1])),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCell(BuildContext context, _InfoItem item) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(item.icon, color: item.color, size: 15),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
              Text(
                item.value,
                style: AppTextStyles.labelMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}
