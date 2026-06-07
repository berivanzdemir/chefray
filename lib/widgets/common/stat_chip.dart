import 'package:flutter/material.dart';

import '../../core/constants/app_text_styles.dart';

/// Small chip widget for displaying stats (e.g. macro values, kcal).
class StatChip extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String value;
  final Color? color;
  final double? progress;

  const StatChip({
    super.key,
    this.icon,
    required this.label,
    required this.value,
    this.color,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: chipColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: chipColor),
            const SizedBox(width: 6),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: chipColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: AppTextStyles.labelMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(width: 10),
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 3,
                backgroundColor: chipColor.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(chipColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
