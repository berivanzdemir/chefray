import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/ingredient_model.dart';

/// Cooking-show style vertical ingredient stack.
///
/// A plate sits fixed at the bottom; ingredients are stacked vertically
/// above it along a single central axis with alternating left/right labels.
/// Clean, premium, cinematic composition — no scattered cards.
class FloatingIngredientsShowcase extends StatefulWidget {
  final List<IngredientModel> ingredients;
  final Widget? plateWidget;

  const FloatingIngredientsShowcase({
    super.key,
    required this.ingredients,
    this.plateWidget,
  });

  @override
  State<FloatingIngredientsShowcase> createState() =>
      _FloatingIngredientsShowcaseState();
}

class _FloatingIngredientsShowcaseState
    extends State<FloatingIngredientsShowcase>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final List<Animation<double>> _itemAnimations;

  @override
  void initState() {
    super.initState();
    final displayItems = widget.ingredients.take(8).toList();
    final count = displayItems.length;

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 120 + count * 80),
    );

    _itemAnimations = List.generate(count, (i) {
      return CurvedAnimation(
        parent: _entranceCtrl,
        curve: Interval(
          (i * 0.08).clamp(0.0, 1.0),
          (i * 0.08 + 0.35).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      );
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _entranceCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayItems = widget.ingredients.take(8).toList();
    final showPlate = widget.plateWidget ?? const _DefaultPlate();

    return AnimatedBuilder(
      animation: _entranceCtrl,
      builder: (context, _) {
        return Container(
          constraints: const BoxConstraints(minHeight: 520),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFFFFF),
                Color(0xFFFDFDFD),
                Color(0xFFF9FCFA),
                Color(0xFFF4FAF7),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Central vertical guide line
              const Center(child: _CenterGuideLine()),

              // Ingredient stack
              Positioned.fill(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(
                    top: 36,
                    bottom: 180,
                    left: 16,
                    right: 16,
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < displayItems.length; i++)
                        _IngredientStackItem(
                          ingredient: displayItems[i],
                          index: i,
                          animation: _itemAnimations[i],
                        ),
                    ],
                  ),
                ),
              ),

              // Bottom fade
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 130,
                child: IgnorePointer(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0xCCF4FAF7),
                          Color(0xFFF4FAF7),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Plate
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 120,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: showPlate,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Ingredient stack item — one row in the vertical stack
// ═══════════════════════════════════════════════════════════════════════════════

class _IngredientStackItem extends StatelessWidget {
  final IngredientModel ingredient;
  final int index;
  final Animation<double> animation;

  const _IngredientStackItem({
    required this.ingredient,
    required this.index,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final isLeft = index.isEven;
    final progress = animation.value;
    final offsetY = (1.0 - progress) * 24.0;
    final opacity = progress.clamp(0.0, 1.0);

    return Transform.translate(
      offset: Offset(0, offsetY),
      child: Opacity(
        opacity: opacity,
        child: SizedBox(
          height: 64,
          child: isLeft ? _buildLeftLayout() : _buildRightLayout(),
        ),
      ),
    );
  }

  Widget _buildLeftLayout() {
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _IngredientLabel(ingredient: ingredient, alignRight: true),
            ),
          ),
        ),
        _ConnectorLine(isLeft: true),
        const SizedBox(width: 6),
        _IngredientCircle(ingredient: ingredient),
        const Expanded(child: SizedBox()),
      ],
    );
  }

  Widget _buildRightLayout() {
    return Row(
      children: [
        const Expanded(child: SizedBox()),
        _IngredientCircle(ingredient: ingredient),
        const SizedBox(width: 6),
        _ConnectorLine(isLeft: false),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: _IngredientLabel(
                ingredient: ingredient,
                alignRight: false,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Ingredient circle — 54px centered visual with category-based fallback icon
// ═══════════════════════════════════════════════════════════════════════════════

class _IngredientCircle extends StatelessWidget {
  final IngredientModel ingredient;

  const _IngredientCircle({required this.ingredient});

  @override
  Widget build(BuildContext context) {
    final hasImage =
        ingredient.imageUrl != null && ingredient.imageUrl!.isNotEmpty;

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 3),
            spreadRadius: -3,
          ),
        ],
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.18),
          width: 1.5,
        ),
      ),
      child: hasImage
          ? ClipOval(
              child: Image.network(
                ingredient.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => _buildFallbackIcon(),
              ),
            )
          : _buildFallbackIcon(),
    );
  }

  Widget _buildFallbackIcon() {
    return Center(
      child: Icon(
        _iconForCategory(ingredient.category),
        size: 22,
        color: AppColors.primary.withValues(alpha: 0.85),
      ),
    );
  }

  IconData _iconForCategory(IngredientCategory category) {
    switch (category) {
      case IngredientCategory.vegetable:
        return Icons.eco_rounded;
      case IngredientCategory.meat:
        return Icons.restaurant_rounded;
      case IngredientCategory.spice:
        return Icons.grain_rounded;
      case IngredientCategory.liquid:
        return Icons.water_drop_rounded;
      case IngredientCategory.grain:
        return Icons.grass_rounded;
      case IngredientCategory.dairy:
        return Icons.egg_rounded;
      case IngredientCategory.seafood:
        return Icons.set_meal_rounded;
      case IngredientCategory.fruit:
        return Icons.local_florist_rounded;
      case IngredientCategory.other:
        return Icons.lunch_dining_rounded;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Ingredient label — subtle glass pill with name + amount
// ═══════════════════════════════════════════════════════════════════════════════

class _IngredientLabel extends StatelessWidget {
  final IngredientModel ingredient;
  final bool alignRight;

  const _IngredientLabel({required this.ingredient, required this.alignRight});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: alignRight
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            ingredient.amount,
            style: AppTextStyles.labelSmall.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary.withValues(alpha: 0.9),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            ingredient.name,
            style: AppTextStyles.labelSmall.copyWith(
              fontSize: 11,
              color: AppColors.textDark.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Connector line — thin line + dot between circle and label
// ═══════════════════════════════════════════════════════════════════════════════

class _ConnectorLine extends StatelessWidget {
  final bool isLeft;

  const _ConnectorLine({required this.isLeft});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 2,
      child: CustomPaint(painter: _ConnectorPainter(isLeft: isLeft)),
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  final bool isLeft;

  _ConnectorPainter({required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.25)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final y = size.height / 2;

    canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    canvas.drawCircle(Offset(0, y), 2.5, dotPaint);
    canvas.drawCircle(Offset(size.width, y), 2.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Center guide line — subtle dashed vertical line
// ═══════════════════════════════════════════════════════════════════════════════

class _CenterGuideLine extends StatelessWidget {
  const _CenterGuideLine();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(1, double.infinity),
      painter: _GuideLinePainter(),
    );
  }
}

class _GuideLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.08)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const dashHeight = 6.0;
    const gapHeight = 10.0;
    var y = 0.0;

    while (y < size.height) {
      final end = (y + dashHeight).clamp(0.0, size.height);
      canvas.drawLine(Offset(0, y), Offset(0, end), paint);
      y += dashHeight + gapHeight;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Default plate widget — programmatic ceramic plate
// ═══════════════════════════════════════════════════════════════════════════════

class _DefaultPlate extends StatelessWidget {
  const _DefaultPlate();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer shadow
        Container(
          width: 200,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 28,
                offset: const Offset(0, 14),
                spreadRadius: -4,
              ),
            ],
          ),
        ),
        // Plate rim
        Container(
          width: 190,
          height: 190,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              center: Alignment(0, 0.15),
              colors: [
                Color(0xFFFCFCFC),
                Color(0xFFF2F2F2),
                Color(0xFFE8E8E8),
                Color(0xFFDDDDDD),
              ],
              stops: [0.0, 0.65, 0.85, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        // Inner plate
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              center: Alignment(0, 0.12),
              colors: [Color(0xFFFAFAFA), Color(0xFFF0F0F0)],
            ),
            border: Border.all(color: const Color(0xFFE4E4E4), width: 1.5),
          ),
        ),
        // Center highlight
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              center: Alignment(-0.2, -0.2),
              colors: [Color(0xFFFFFFFF), Color(0xFFF5F5F5)],
            ),
          ),
        ),
        // Small brand dot
        Positioned(
          bottom: 40,
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.35),
            ),
          ),
        ),
      ],
    );
  }
}
