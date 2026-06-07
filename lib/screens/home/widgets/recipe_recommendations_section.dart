import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_text_styles.dart';
import '../../../../widgets/common/section_header.dart';
import '../../../../repositories/recipes/supabase_recipe_repository.dart';
import '../../../../models/recipe_model.dart';
import '../../../../services/favorite_service.dart';

class RecipeRecommendationsSection extends StatefulWidget {
  const RecipeRecommendationsSection({super.key});

  @override
  State<RecipeRecommendationsSection> createState() => _RecipeRecommendationsSectionState();
}

class _RecipeRecommendationsSectionState extends State<RecipeRecommendationsSection> {
  final _repo = SupabaseRecipeRepository();
  late Future<List<RecipeModel>> _recipesFuture;
  Set<String> _favoriteIds = {};

  @override
  void initState() {
    super.initState();
    _recipesFuture = _repo.getHomeRecommendations(limit: 10);
    _loadFavorites();
    FavoriteService.favoriteUpdateNotifier.addListener(_loadFavorites);
  }

  @override
  void dispose() {
    FavoriteService.favoriteUpdateNotifier.removeListener(_loadFavorites);
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final ids = await FavoriteService.getFavoriteRecipeIds();
    if (mounted) {
      setState(() => _favoriteIds = ids);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SectionHeader(
            title: 'Sana Özel Öneriler',
            actionText: 'Tümü',
            onAction: () => context.push('/recipe-list'),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 230,
          child: FutureBuilder<List<RecipeModel>>(
            future: _recipesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_off_rounded, size: 32, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(height: 8),
                        Text(
                          'Tarifler yüklenirken hata oluştu',
                          style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final recipes = snapshot.data ?? [];

              if (recipes.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant_menu_rounded, size: 32, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(height: 8),
                        Text(
                          'Henüz öneri bulunmuyor',
                          style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  return _HomeRecipeCard(
                    recipe: recipe,
                    isFavorite: _favoriteIds.contains(recipe.id),
                    onFavoriteToggle: () async {
                      final isFav = _favoriteIds.contains(recipe.id);
                      debugPrint('Home Special Recommendation favorite tap:');
                      debugPrint('- recipe.title: ${recipe.shownTitle}');
                      debugPrint('- recipe.id: ${recipe.id}');
                      debugPrint('- current favorite state: $isFav');

                      setState(() {
                        if (isFav) {
                          _favoriteIds.remove(recipe.id);
                        } else {
                          _favoriteIds.add(recipe.id);
                        }
                      });

                      final newFav = await FavoriteService.toggleFavorite(recipe.id);
                      debugPrint('- toggle result: $newFav');

                      if (mounted) {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(newFav ? 'Favorilere eklendi' : 'Favorilerden çıkarıldı')),
                        );
                      }
                    },
                    onTap: () => context.push('/recipe-show', extra: recipe),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Ana sayfaya özel kompakt tarif kartı.
/// Gerçek RecipeModel verisi kullanır — hiçbir fake değer yok.
class _HomeRecipeCard extends StatelessWidget {
  final RecipeModel recipe;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const _HomeRecipeCard({
    required this.recipe,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final title = recipe.shownTitle;
    final hasImage = recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 195,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            SizedBox(
              height: 120,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: hasImage
                        ? Image.network(
                            recipe.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _buildPlaceholder(context),
                          )
                        : _buildPlaceholder(context),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onFavoriteToggle,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 16,
                          color: isFavorite ? Color(0xFFFF4B4B) : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        height: 1.2,
                      ),
                    ),
                    const Spacer(),
                    // Info row — sadece gerçek veriler gösterilir
                    Row(
                      children: [
                        if (recipe.caloriesKcal != null) ...[
                          Icon(Icons.local_fire_department_rounded, size: 14, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 3),
                          Text(
                            '${recipe.caloriesKcal} kcal',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ],
                        if (recipe.caloriesKcal != null && recipe.displayTime != null)
                          const Spacer(),
                        if (recipe.displayTime != null) ...[
                          Icon(Icons.schedule_rounded, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(width: 3),
                          Text(
                            recipe.displayTime!,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ),
                        ],
                        // Protein bilgisi varsa ve yer varsa
                        if (recipe.proteinG != null &&
                            recipe.caloriesKcal == null &&
                            recipe.displayTime == null) ...[
                          Icon(Icons.fitness_center_rounded, size: 13, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 3),
                          Text(
                            '${recipe.proteinG}g protein',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
      child: Center(
        child: Icon(
          Icons.restaurant_rounded,
          size: 36,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
    );
  }
}
