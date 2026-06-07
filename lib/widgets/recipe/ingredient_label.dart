import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// Floating ingredient label for exploded view — white rounded pill with connector.
/// Fixed: constrained width, text overflow handling, safe for small screens.
class IngredientLabel extends StatelessWidget {
  final String name;
  final String amount;
  final int calories;
  final String? tag;
  final Alignment alignment;

  const IngredientLabel({
    super.key,
    required this.name,
    required this.amount,
    required this.calories,
    this.tag,
    this.alignment = Alignment.centerRight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 170),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 2)),
        ],
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name, style: AppTextStyles.labelMedium.copyWith(
              fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textDark),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text('$amount — $calories kcal',
              style: AppTextStyles.labelSmall.copyWith(fontSize: 9, color: AppColors.textMedium),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          if (tag != null && tag!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(tag!, style: AppTextStyles.labelSmall.copyWith(
                fontSize: 8, color: AppColors.primary, fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}
