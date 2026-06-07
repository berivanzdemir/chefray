import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../widgets/common/soft_card.dart';

/// Sağlık Durumu card with chip display for health conditions.
class HealthStatusCard extends StatelessWidget {
  final List<String> healthConditions;

  const HealthStatusCard({
    super.key,
    required this.healthConditions,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = healthConditions
        .where((c) => c != 'Yok' && c != 'Belirtmek istemiyorum')
        .toList();
    final hasConditions = filtered.isNotEmpty;

    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with heart icon
          Row(
            children: [
              Icon(Icons.favorite_rounded,
                  size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 6),
              Text('Sağlık Durumu',
                  style: AppTextStyles.h3.copyWith(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          if (hasConditions)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: filtered
                  .map((item) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ))
                  .toList(),
            )
          else
            _buildEmptyState(context, 'Henüz eklenmedi'),
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
