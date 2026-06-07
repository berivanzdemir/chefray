import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/recipe_model.dart';

/// Recipe list card matching ChefRay reference — horizontal layout.
class RecipeCard extends StatelessWidget {
  final RecipeModel recipe;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    this.isFavorite = false,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // Image placeholder
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  recipe.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            recipe.imageUrl!,
                            width: 100, height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(child: Text('🍽️', style: TextStyle(fontSize: 36))),
                          ),
                        )
                      : const Center(child: Text('🍽️', style: TextStyle(fontSize: 36))),
                  // Favorite
                  Positioned(
                    top: 6, right: 6,
                    child: GestureDetector(
                      onTap: onFavoriteTap,
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 14,
                          color: isFavorite ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(recipe.shownTitle,
                      style: AppTextStyles.h3.copyWith(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(recipe.description,
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (recipe.caloriesKcal != null || recipe.proteinG != null) ...[
                    const SizedBox(height: 8),
                    // Macros row
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        if (recipe.caloriesKcal != null)
                          _pill(context, '🔥 ${recipe.caloriesKcal} kcal', Theme.of(context).colorScheme.primary),
                        if (recipe.proteinG != null)
                          _pill(context, 'P ${recipe.proteinG}g', Colors.purple.shade400),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  // Tags
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (recipe.proteinStatus == 'high' || recipe.isHighProtein) _featureTag(context, 'Yüksek Protein'),
                      if (recipe.calorieStatus == 'low' || recipe.isLowCalorie) _featureTag(context, 'Düşük Kalori'),
                      if ((recipe.glutenStatus == 'gluten_free' || recipe.isGlutenFree) &&
                          recipe.glutenStatus != 'unknown' &&
                          recipe.glutenStatus != 'contains_gluten')
                        _featureTag(context, 'Glutensiz'),
                    ],
                  ),
                ],
              ),
            ),
            // Time
            if (recipe.displayTime != null) ...[
              const SizedBox(width: 8),
              Column(
                children: [
                  Icon(Icons.schedule_rounded, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 2),
                  Text(recipe.displayTime!,
                      style: AppTextStyles.labelSmall.copyWith(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _pill(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _featureTag(BuildContext context, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 5, height: 5,
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(text, style: AppTextStyles.labelSmall.copyWith(fontSize: 9, color: Theme.of(context).colorScheme.onSurface)),
      ],
    );
  }
}
