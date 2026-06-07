import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/recipe_model.dart';
import '../../widgets/recipe/ingredient_label.dart';
import '../../widgets/common/primary_button.dart';
import '../../animations/exploded_animation_controller.dart';
import '../../services/translation/recipe_translation_service.dart';

class ExplodedRecipeScreen extends StatefulWidget {
  final RecipeModel? recipe;
  const ExplodedRecipeScreen({super.key, this.recipe});

  @override
  State<ExplodedRecipeScreen> createState() => _ExplodedRecipeScreenState();
}

class _ExplodedRecipeScreenState extends State<ExplodedRecipeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  double _portion = 1.0;
  late final RecipeModel _recipe;

  @override
  void initState() {
    super.initState();
    // Ensure recipe content is Turkish
    final raw = widget.recipe ?? RecipeMockData.primary;
    _recipe = RecipeTranslationService.translateRecipe(raw);

    _ctrl = AnimationController(
      vsync: this,
      duration: ExplodedAnimationConfig.totalDuration,
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  int _scaled(int v) => (v * _portion).round();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final t = _ctrl.value;
          final sep = ExplodedAnimationConfig.phaseProgress(
              t, ExplodedAnimationConfig.separateStart, ExplodedAnimationConfig.separateEnd);
          final lbl = ExplodedAnimationConfig.phaseProgress(
              t, ExplodedAnimationConfig.labelsStart, ExplodedAnimationConfig.labelsEnd);
          final scan = ExplodedAnimationConfig.phaseProgress(
              t, ExplodedAnimationConfig.scanStart, ExplodedAnimationConfig.scanEnd);

          return Column(
            children: [
              // Header
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle,
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark, size: 20),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle,
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: const Icon(Icons.favorite_border_rounded, color: AppColors.textDark, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle,
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: const Icon(Icons.ios_share_rounded, color: AppColors.textDark, size: 20),
                      ),
                    ],
                  ),
                ),
              ),

              // Exploded composition area
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availW = constraints.maxWidth;
                    final availH = constraints.maxHeight;
                    final ingredientCount = _recipe.ingredients.length.clamp(0, 6);

                    return Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Scan beam
                        if (scan > 0 && scan < 1)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: _ScanLine(progress: scan),
                            ),
                          ),

                        // Green glow behind plate
                        Positioned(
                          bottom: 80,
                          child: Opacity(
                            opacity: sep,
                            child: Container(
                              width: availW * 0.6, height: 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    blurRadius: 40, spreadRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Dynamic Ingredients with safe positioning
                        ...List.generate(ingredientCount, (i) {
                          final ing = _recipe.ingredients[i];
                          final isLeft = i % 2 == 0;

                          // Spread ingredients vertically across the available space
                          final verticalSpacing = availH / (ingredientCount + 2);
                          final baseBottom = 40.0 + (i * verticalSpacing * 0.35);

                          // Label positioning — safely within bounds
                          final labelTop = (availH * 0.15) + (i * verticalSpacing * 0.7);
                          final clampedLabelTop = labelTop.clamp(10.0, availH - 80.0);

                          // Scale label width for small screens
                          final labelMaxWidth = (availW * 0.42).clamp(100.0, 180.0);

                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Food image/emoji
                              Positioned(
                                bottom: baseBottom + sep * (60 + i * 15),
                                left: isLeft ? availW * 0.12 : null,
                                right: isLeft ? null : availW * 0.12,
                                child: _FoodEmoji('🥘', 36, sep, imageUrl: ing.imageUrl),
                              ),
                              // Label — constrained width, safe position
                              Positioned(
                                right: isLeft ? 8 : null,
                                left: isLeft ? null : 8,
                                top: clampedLabelTop,
                                child: Opacity(
                                  opacity: lbl,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(maxWidth: labelMaxWidth),
                                    child: IngredientLabel(
                                      name: ing.name,
                                      amount: ing.amount,
                                      calories: _scaled(ing.calories > 0 ? ing.calories : 50),
                                      tag: ing.nutrientTag,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),

                        // Left info pills
                        Positioned(
                          left: 16, top: availH * 0.32,
                          child: Opacity(
                            opacity: lbl,
                            child: _InfoPill(Icons.schedule_rounded, '${_recipe.timeMinutes} dk', 'Hazırlık Süresi'),
                          ),
                        ),
                        Positioned(
                          left: 16, top: availH * 0.40,
                          child: Opacity(
                            opacity: lbl,
                            child: _InfoPill(Icons.local_fire_department_rounded, '${_scaled(_recipe.calories)} kcal', 'Toplam Kalori'),
                          ),
                        ),

                        // Title overlay (top left)
                        Positioned(
                          left: 24, top: 10,
                          child: Opacity(
                            opacity: lbl,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('⭐', style: TextStyle(fontSize: 10)),
                                      const SizedBox(width: 4),
                                      Text('En Uygun Tarif',
                                          style: AppTextStyles.labelSmall.copyWith(
                                              color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 10)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: availW * 0.45,
                                  child: Text(_recipe.shownTitle,
                                      style: AppTextStyles.h1.copyWith(fontSize: 20, height: 1.25),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  width: availW * 0.42,
                                  child: Text(_recipe.description,
                                      style: AppTextStyles.bodySmall.copyWith(fontSize: 11, height: 1.35),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // ── Bottom card ──────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, -4))],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nutrition row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _NutrientCol(Icons.local_fire_department_rounded, '${_scaled(_recipe.calories)}', 'kcal\nToplam'),
                          _NutrientCol(Icons.fitness_center_rounded, '${_scaled(_recipe.protein)}g', 'Protein'),
                          _NutrientCol(Icons.grain_rounded, '${_scaled(_recipe.carbs)}g', 'Karb.'),
                          _NutrientCol(Icons.water_drop_rounded, '${_scaled(_recipe.fat)}g', 'Yağ'),
                          Column(
                            children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.restaurant_rounded, size: 18, color: AppColors.primary),
                              ),
                              const SizedBox(height: 4),
                              Text('Dengeli\nÖğün', textAlign: TextAlign.center,
                                  style: AppTextStyles.labelSmall.copyWith(fontSize: 9, color: AppColors.primary)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Portion slider
                      Row(
                        children: [
                          Icon(Icons.restaurant_rounded, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Porsiyon', style: AppTextStyles.labelSmall),
                              Text('${_portion.toStringAsFixed(_portion == _portion.roundToDouble() ? 0 : 1)} Porsiyon',
                                  style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.textDark)),
                            ],
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () { if (_portion > 0.5) setState(() => _portion -= 0.5); },
                            child: Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.divider)),
                              child: const Icon(Icons.remove, size: 16, color: AppColors.textMedium),
                            ),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 4,
                                activeTrackColor: AppColors.primary,
                                inactiveTrackColor: AppColors.primary.withValues(alpha: 0.15),
                                thumbColor: AppColors.primary,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                              ),
                              child: Slider(
                                value: _portion, min: 0.5, max: 4.0, divisions: 7,
                                onChanged: (v) => setState(() => _portion = v),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () { if (_portion < 4) setState(() => _portion += 0.5); },
                            child: Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.divider)),
                              child: const Icon(Icons.add, size: 16, color: AppColors.textMedium),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${_portion.toStringAsFixed(_portion == _portion.roundToDouble() ? 0 : 1)}\nPorsiyon',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.labelSmall.copyWith(fontSize: 9)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // CTA
                      Row(
                        children: [
                          // Shopping list button
                          Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_cart_outlined, size: 18, color: AppColors.textMedium),
                                Text('Listeye\nEkle', textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 6, color: AppColors.textMedium)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: PrimaryButton(
                              text: 'Tarifi Gör',
                              onPressed: () => context.push('/recipe-detail', extra: _recipe),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Food emoji placeholder ─────────────────────────────────
class _FoodEmoji extends StatelessWidget {
  final String emoji;
  final double size;
  final double sep;
  final String? imageUrl;
  const _FoodEmoji(this.emoji, this.size, this.sep, {this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.7 + sep * 0.3,
      child: imageUrl != null
          ? ClipOval(
              child: Image.network(
                imageUrl!,
                width: size * 1.5,
                height: size * 1.5,
                fit: BoxFit.cover,
                errorBuilder: (_, e, st) => Text(emoji, style: TextStyle(fontSize: size)),
              ),
            )
          : Text(emoji, style: TextStyle(fontSize: size)),
    );
  }
}

// ── Info pill (left side) ──────────────────────────────────
class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _InfoPill(this.icon, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.textDark, fontSize: 13)),
              Text(label, style: AppTextStyles.labelSmall.copyWith(fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Nutrient column ────────────────────────────────────────
class _NutrientCol extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _NutrientCol(this.icon, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.h3.copyWith(fontSize: 16)),
        Text(label, textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(fontSize: 9, color: AppColors.primary)),
      ],
    );
  }
}

// ── Scan line ──────────────────────────────────────────────
class _ScanLine extends StatelessWidget {
  final double progress;
  const _ScanLine({required this.progress});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final y = progress * constraints.maxHeight;
        return Stack(
          children: [
            Positioned(
              left: 0, right: 0, top: y,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    AppColors.primary.withValues(alpha: 0),
                    AppColors.primary.withValues(alpha: 0.7),
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.7),
                    AppColors.primary.withValues(alpha: 0),
                  ]),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 14, spreadRadius: 3)],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
