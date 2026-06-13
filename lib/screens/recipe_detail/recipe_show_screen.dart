import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/recipe_model.dart';
import '../../models/ingredient_model.dart';
import '../../services/translation/recipe_translation_service.dart';
import '../../services/ingredient_resolver_service.dart';
import '../../services/favorite_service.dart';

enum LabelSide { left, right }

class RecipeShowScreen extends StatefulWidget {
  final RecipeModel? recipe;
  const RecipeShowScreen({super.key, this.recipe});

  @override
  State<RecipeShowScreen> createState() => _RecipeShowScreenState();
}

class _RecipeShowScreenState extends State<RecipeShowScreen> {
  bool _isFavorite = false;
  bool _isLoadingFavorite = true;
  bool _isLoadingRecipe = true;
  late RecipeModel _recipe;
  List<IngredientModel> _ingredients = [];

  // Stages
  bool _showIntro = true;
  bool _startShow = false;
  bool _showBottomPanel = false;

  @override
  void initState() {
    super.initState();
    final raw = widget.recipe ?? RecipeMockData.primary;
    _recipe = RecipeTranslationService.translateRecipe(raw);

    _loadIngredients();
    _checkFavorite();
    FavoriteService.favoriteUpdateNotifier.addListener(_checkFavorite);
  }

  @override
  void dispose() {
    FavoriteService.favoriteUpdateNotifier.removeListener(_checkFavorite);
    super.dispose();
  }

  Future<void> _loadIngredients() async {
    await IngredientResolverService.init();

    final textVal = _recipe.rawJson?['ingredients_text']?.toString() ?? '';
    Map<String, dynamic> rawJson = _recipe.rawJson ?? {};

    if (textVal.isEmpty && _recipe.id.isNotEmpty && _recipe.id != '1') {
      try {
        final res = await Supabase.instance.client
            .from('recipes')
            .select('*')
            .eq('id', _recipe.id)
            .maybeSingle();
        if (res != null) rawJson = res;
      } catch (e) {
        debugPrint('Error fetching full recipe: $e');
      }
    }

    if (!mounted) return;

    final all = IngredientResolverService.getDisplayIngredients(
      rawJson,
      _recipe.shownTitle,
      _recipe.id,
    );
    final resolved = all.take(6).toList();

    setState(() {
      _ingredients = resolved;
      _isLoadingRecipe = false;
    });

    // Precache all ingredient images before starting animation
    await _precacheIngredientImages(resolved);

    if (!mounted) return;
    _startTimers();
  }

  /// Precaches all ingredient images with a 3-second per-image timeout.
  /// Images that fail to load or time out are logged and the placeholder
  /// will be used instead, but the animation won't be delayed.
  Future<void> _precacheIngredientImages(
    List<IngredientModel> ingredients,
  ) async {
    final futures = <Future<void>>[];

    for (final ing in ingredients) {
      final url = ing.imageUrl ?? '';
      if (url.isEmpty || url.contains('default_ingredient')) {
        debugPrint(
          'Precache [SKIP] "${ing.name}" → placeholder (no image URL)',
        );
        continue;
      }

      futures.add(
        precacheImage(CachedNetworkImageProvider(url), context)
            .timeout(const Duration(seconds: 3))
            .then((_) {
              debugPrint('Precache [OK] "${ing.name}" → $url');
            })
            .catchError((e) {
              debugPrint('Precache [FAIL] "${ing.name}" → $url | error: $e');
            }),
      );
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
    debugPrint(
      'Precache [DONE] All ${ingredients.length} ingredient images processed.',
    );
  }

  void _startTimers() {
    // Stage 1: Recipe Intro (0s to 2.2s)
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      setState(() {
        _showIntro = false; // Trigger fade out
      });

      // Stage 2: Ingredients Show starts slightly after intro begins fading
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        setState(() {
          _startShow = true;
        });
      });

      // Stage 3: Bottom Panel appears after ingredients finish animating
      Future.delayed(const Duration(milliseconds: 2800), () {
        if (!mounted) return;
        setState(() {
          _showBottomPanel = true;
        });
      });
    });
  }

  Future<void> _checkFavorite() async {
    final status = await FavoriteService.isFavorite(_recipe.id);
    if (mounted) {
      setState(() {
        _isFavorite = status;
        _isLoadingFavorite = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    debugPrint('RecipeIntro favorite tap:');
    debugPrint('- recipe.title: ${_recipe.shownTitle}');
    debugPrint('- recipe.id: ${_recipe.id}');
    debugPrint('- current favorite state: $_isFavorite');

    setState(() => _isFavorite = !_isFavorite);

    final newFav = await FavoriteService.toggleFavorite(_recipe.id);
    debugPrint('- toggle result: $newFav');

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newFav ? 'Favorilere eklendi' : 'Favorilerden çıkarıldı',
          ),
        ),
      );
      if (_isFavorite != newFav) {
        setState(() => _isFavorite = newFav);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [
                    Theme.of(context).scaffoldBackgroundColor,
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                    Theme.of(context).colorScheme.surface,
                  ]
                : [
                    const Color(0xFFF8FCFA),
                    const Color(0xFFF1FAF5),
                    Theme.of(context).colorScheme.surface,
                  ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              _buildTopBar(),

              if (_isLoadingRecipe)
                Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
              else ...[
                // The Show Stage
                Positioned.fill(
                  top: 80,
                  bottom: 120,
                  child: AnimatedOpacity(
                    opacity: _startShow ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 600),
                    child: _buildShowStage(),
                  ),
                ),

                // The Intro Stage (shows "Malzemeler hazırlanıyor..." while images load)
                AnimatedOpacity(
                  opacity: _showIntro ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 600),
                  child: IgnorePointer(
                    ignoring: !_showIntro,
                    child: _buildIntroStage(),
                  ),
                ),

                // Bottom Panel
                _buildBottomPanel(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 16,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _circleBtn(Icons.arrow_back_rounded, () => context.pop()),
          _isLoadingFavorite
              ? const SizedBox(width: 44, height: 44)
              : _circleBtn(
                  _isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  _toggleFavorite,
                  iconColor: _isFavorite
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
        ],
      ),
    );
  }

  Widget _buildIntroStage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _recipe.shownTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.1,
              ),
              maxLines: 2,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.15),
                  blurRadius: 40,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
              ],
              image: DecorationImage(
                image: CachedNetworkImageProvider(_recipe.imageUrl ?? ''),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Şov Başlıyor',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Malzemeler hazırlanıyor...',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowStage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final centerX = constraints.maxWidth / 2;
        final plateCenterY =
            constraints.maxHeight *
            0.74; // Approx center of the plate Align(0, 0.48)
        final plateTopY = plateCenterY - 45; // Top of the plate
        final itemGap = constraints.maxHeight < 700 ? 72.0 : 82.0;
        final maxItems = constraints.maxHeight < 700 ? 5 : 6;

        final displayIngredients = _ingredients.take(maxItems).toList();

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            const Align(alignment: Alignment(0, 0.48), child: _EmptyPlate()),
            ...List.generate(displayIngredients.length, (index) {
              final slotY = plateTopY - 20 - (index * itemGap);
              final isRight = index.isEven;

              return AnimatedVerticalIngredient(
                ingredient: displayIngredients[index],
                centerX: centerX,
                startY: plateCenterY,
                endY: slotY,
                labelSide: isRight ? LabelSide.right : LabelSide.left,
                delayMs: index * 180,
                startAnimation: _startShow,
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildBottomPanel() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      bottom: _showBottomPanel ? 0 : -300,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        opacity: _showBottomPanel ? 1.0 : 0.0,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.0),
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_recipe.recommendationReady)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'En Uygun Tarif',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _recipe.shownTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _infoItem(
                      Icons.schedule_rounded,
                      _recipe.displayTime ?? '30 dk',
                      'Süre',
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: Theme.of(context).dividerColor,
                    ),
                    _infoItem(Icons.bar_chart_rounded, 'Orta', 'Zorluk'),
                    Container(
                      width: 1,
                      height: 24,
                      color: Theme.of(context).dividerColor,
                    ),
                    _infoItem(
                      Icons.eco_outlined,
                      _getMealType(_recipe.mealTypeV2 ?? _recipe.mealType),
                      'Öğün',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: () => context.push('/recipe-detail', extra: _recipe),
                child: Container(
                  height: 56,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_circle_fill_rounded,
                        color: Theme.of(context).colorScheme.surface,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Tarifi Gör',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.surface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMealType(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast':
        return 'Kahvaltı';
      case 'lunch':
        return 'Öğle';
      case 'dinner':
        return 'Akşam';
      case 'snack':
        return 'Ara Öğün';
      default:
        return 'Sağlıklı';
    }
  }

  Widget _infoItem(IconData icon, String val, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              val,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap, {Color? iconColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: iconColor ?? Theme.of(context).colorScheme.onSurface,
          size: 20,
        ),
      ),
    );
  }
}

class _EmptyPlate extends StatelessWidget {
  const _EmptyPlate();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 90,
      child: CustomPaint(painter: _PlatePainter(context)),
    );
  }
}

class _PlatePainter extends CustomPainter {
  final BuildContext context;
  _PlatePainter(this.context);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCenter(
      center: center,
      width: size.width,
      height: size.height,
    );

    // 1. Zemin Gölgesi (Alt Drop Shadow)
    final shadowPath = Path()..addOval(rect.translate(0, 15));
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );

    // Hafif yeşil glow (ChefRay teması)
    final glowPath = Path()..addOval(rect.translate(0, 5));
    canvas.drawPath(
      glowPath,
      Paint()
        ..color = Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25),
    );

    // 2. Tabağın Dış Gövdesi (Ana Şekil)
    final platePaint = Paint()
      ..color = Theme.of(context).colorScheme.surface
      ..style = PaintingStyle.fill;
    canvas.drawOval(rect, platePaint);

    // 3. Tabağın Dış Çizgisi (İnce Kenar)
    final borderPaint = Paint()
      ..color = Theme.of(context).dividerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawOval(rect, borderPaint);

    // 4. İç Çukur Gövdesi (Perspektifli iç kısım)
    final innerRect = Rect.fromCenter(
      center: center.translate(0, 4), // Hafif aşağı kayık
      width: size.width * 0.75,
      height: size.height * 0.65,
    );

    final innerPlatePaint = Paint()
      ..color = Theme.of(context).scaffoldBackgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawOval(innerRect, innerPlatePaint);

    // 5. İç Çukur Gölgesi (İçeri doğru derinlik hissi)
    final innerShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(innerRect.translate(0, -2), innerShadowPaint);

    // 6. İç Çukur Çizgisi
    final innerBorderPaint = Paint()
      ..color = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawOval(innerRect, innerBorderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AnimatedVerticalIngredient extends StatefulWidget {
  final IngredientModel ingredient;
  final double centerX;
  final double startY;
  final double endY;
  final LabelSide labelSide;
  final int delayMs;
  final bool startAnimation;

  const AnimatedVerticalIngredient({
    super.key,
    required this.ingredient,
    required this.centerX,
    required this.startY,
    required this.endY,
    required this.labelSide,
    required this.delayMs,
    required this.startAnimation,
  });

  @override
  State<AnimatedVerticalIngredient> createState() =>
      _AnimatedVerticalIngredientState();
}

class _AnimatedVerticalIngredientState extends State<AnimatedVerticalIngredient>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _yAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;
  late Animation<double> _labelOpacityAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _yAnim = Tween<double>(begin: widget.startY, end: widget.endY).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnim = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _labelOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedVerticalIngredient oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startAnimation && !oldWidget.startAnimation) {
      Future.delayed(Duration(milliseconds: widget.delayMs), () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String imageUrl = widget.ingredient.imageUrl ?? '';
    final isLeft = widget.labelSide == LabelSide.left;
    final double itemSize = 62.0;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        if (_ctrl.value == 0) return const SizedBox.shrink();

        final animatedY = _yAnim.value;
        final imageLeft = widget.centerX - (itemSize / 2);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Image
            Positioned(
              left: imageLeft,
              top: animatedY,
              child: Transform.scale(
                scale: _scaleAnim.value,
                child: Opacity(
                  opacity: _opacityAnim.value,
                  child: _buildImage(imageUrl, itemSize),
                ),
              ),
            ),

            // Label & Connector
            if (isLeft) ...[
              Positioned(
                right:
                    MediaQuery.of(context).size.width -
                    widget.centerX +
                    (itemSize / 2) +
                    4,
                top: animatedY + (itemSize / 2) - 20,
                child: Opacity(
                  opacity: _labelOpacityAnim.value,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [_buildLabel(), _buildLine(isLeft: true)],
                  ),
                ),
              ),
            ] else ...[
              Positioned(
                left: widget.centerX + (itemSize / 2) + 4,
                top: animatedY + (itemSize / 2) - 20,
                child: Opacity(
                  opacity: _labelOpacityAnim.value,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [_buildLine(isLeft: false), _buildLabel()],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildImage(String imageUrl, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: imageUrl.isNotEmpty && !imageUrl.contains('default_ingredient')
              ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  errorWidget: (c, u, e) => Icon(
                    Icons.eco_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
              : Icon(
                  Icons.eco_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
        ),
      ),
    );
  }

  Widget _buildLabel() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 130),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            widget.ingredient.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLine({required bool isLeft}) {
    return Container(
      width: 14,
      height: 1.5,
      margin: EdgeInsets.only(left: isLeft ? 4 : 0, right: isLeft ? 0 : 4),
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
    );
  }
}
