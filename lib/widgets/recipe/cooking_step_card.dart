import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// Cooking step card for recipe detail.
class CookingStepCard extends StatelessWidget {
  final int stepNumber;
  final String title;
  final String description;
  final String duration;
  final bool isExpanded;

  const CookingStepCard({
    super.key,
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.duration,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text('$stepNumber',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
          const SizedBox(width: 12),
          // Step image placeholder
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.restaurant_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.h3.copyWith(fontSize: 14)),
                const SizedBox(height: 4),
                Text(description,
                    style: AppTextStyles.bodySmall.copyWith(height: 1.4),
                    maxLines: isExpanded ? 10 : 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Duration
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule_rounded, size: 12, color: AppColors.textLight),
              const SizedBox(width: 3),
              Text(duration, style: AppTextStyles.labelSmall.copyWith(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
