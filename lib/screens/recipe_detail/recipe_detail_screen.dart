import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/recipe_model.dart';

import '../../services/translation/recipe_translation_service.dart';
import '../../services/ingredient_resolver_service.dart';
import '../../services/serving_scaler_service.dart';
import '../../services/favorite_service.dart';

class RecipeDetailScreen extends StatefulWidget {
  final RecipeModel? recipe;
  const RecipeDetailScreen({super.key, this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  int _selectedTab = 0;
  bool _isFavorite = false;
  bool _isLoadingFavorite = true;
  bool _isLoadingRecipe = false;
  late RecipeModel _recipe;
  Map<String, dynamic> _rawJson = {};
  List<ParsedIngredient> _parsedIngredients = [];
  int _currentServings = 1;
  int _originalServings = 1;
  double _servingMultiplier = 1.0;

  @override
  void initState() {
    super.initState();
    final raw = widget.recipe ?? RecipeMockData.primary;
    _recipe = RecipeTranslationService.translateRecipe(raw);
    _rawJson = _recipe.rawJson ?? {};
    _initData();
  }

  Future<void> _initData() async {
    setState(() => _isLoadingRecipe = true);

    await IngredientResolverService.init();

    // Check if we need to fetch full recipe from Supabase
    final textVal = _rawJson['ingredients_text']?.toString() ?? '';
    if (textVal.isEmpty &&
        _recipe.id.isNotEmpty &&
        _recipe.id != 'salmon-quinoa') {
      try {
        final res = await Supabase.instance.client
            .from('recipes')
            .select('*')
            .eq('id', _recipe.id)
            .maybeSingle();
        if (res != null) {
          _rawJson = res;
          _recipe = RecipeModel.fromSupabaseJson(res);
          _recipe = RecipeTranslationService.translateRecipe(_recipe);
        }
      } catch (e) {
        debugPrint('RecipeDetailScreen: Error fetching full recipe: $e');
      }
    }

    // Parse servings
    _originalServings = ServingScalerService.getOriginalServings(_rawJson);
    _currentServings = _originalServings;
    _servingMultiplier = 1.0;

    // Parse ingredients from ingredients_text
    _parsedIngredients = _parseIngredientsWithAmounts();

    // Debug logs
    debugPrint('RecipeDetailScreen [DEBUG] recipe id: ${_recipe.id}');
    debugPrint(
      'RecipeDetailScreen [DEBUG] recipe title: ${_recipe.shownTitle}',
    );
    debugPrint(
      'RecipeDetailScreen [DEBUG] ingredients_text raw: ${_rawJson['ingredients_text']}',
    );
    debugPrint(
      'RecipeDetailScreen [DEBUG] parsed ingredient count: ${_parsedIngredients.length}',
    );
    debugPrint(
      'RecipeDetailScreen [DEBUG] servings source: $_originalServings',
    );
    debugPrint(
      'RecipeDetailScreen [DEBUG] instructions source: ${_recipe.steps.length} steps',
    );
    debugPrint(
      'RecipeDetailScreen [DEBUG] parsed steps count: ${_recipe.steps.length}',
    );

    _checkFavorite();

    if (mounted) {
      setState(() => _isLoadingRecipe = false);
    }
  }

  List<ParsedIngredient> _parseIngredientsWithAmounts() {
    List<dynamic> rawIngredientsList = [];
    if (_rawJson['ingredients'] is List) {
      rawIngredientsList = _rawJson['ingredients'] as List;
    }

    final List<ParsedIngredient> result = [];

    // 1. Try parsing directly from JSON objects if available
    if (rawIngredientsList.isNotEmpty && rawIngredientsList.first is Map) {
      for (var item in rawIngredientsList) {
        if (item is! Map) continue;

        final name = item['name']?.toString().trim() ?? '';
        if (name.isEmpty ||
            name.contains('[object Object]') ||
            name.contains('object Object') ||
            name.contains('Object'))
          continue;

        String amount = item['display']?.toString().trim() ?? '';

        if (amount.isEmpty) {
          final quantity =
              item['quantity']?.toString() ?? item['amount']?.toString() ?? '';
          final unit =
              item['unit']?.toString() ?? item['measure']?.toString() ?? '';
          final note = item['note']?.toString() ?? '';

          final List<String> parts = [];
          if (quantity.isNotEmpty) parts.add(quantity);
          if (unit.isNotEmpty) parts.add(unit);
          if (note.isNotEmpty) parts.add('($note)');
          amount = parts.join(' ').trim();
        }

        result.add(
          ParsedIngredient(
            name: name,
            amount: amount,
            originalRaw: name, // Used for image resolution
          ),
        );
      }
      if (result.isNotEmpty) return result;
    }

    // 2. Fallback to parsing ingredients_text
    final textVal = _rawJson['ingredients_text']?.toString() ?? '';
    if (textVal.isEmpty) return [];

    final nameParts = textVal.split(',');
    int validIngredientIndex = 0;

    debugPrint('\nRecipe title: ${_recipe.shownTitle}');
    debugPrint('ingredients raw: ${_rawJson['ingredients']}');
    debugPrint('ingredients_text raw: ${_rawJson['ingredients_text']}');

    for (int i = 0; i < nameParts.length; i++) {
      final cleanedName = nameParts[i].trim();
      if (cleanedName.isEmpty) continue;
      if (cleanedName.toLowerCase().contains('bulunamadı')) continue;
      if (cleanedName.contains('[object Object]') ||
          cleanedName.contains('object Object') ||
          cleanedName.contains('Object'))
        continue;
      if (IngredientResolverService.isGroupLabel(cleanedName.toLowerCase()))
        continue;

      // First try to parse amount from the name itself (e.g. "1 adet soğan")
      ParsedIngredient parsed = ServingScalerService.parseIngredientAmount(
        cleanedName,
      );

      String rawAmountLog = "null";
      String inferredUnitLog = "null";

      // If no amount was found in the name, try to fetch from the ingredients list
      if (parsed.amount.isEmpty &&
          validIngredientIndex < rawIngredientsList.length) {
        final rawAmountStr =
            rawIngredientsList[validIngredientIndex]?.toString() ?? '';
        rawAmountLog = rawAmountStr;
        final amountMatch = RegExp(
          r'^\s*([0-9]+(?:[.,][0-9]+)?|[0-9]+/[0-9]+)',
        ).firstMatch(rawAmountStr);

        if (amountMatch != null) {
          String extractedAmount = amountMatch.group(1)!.trim();
          final amountVal = ServingScalerService.parseFraction(extractedAmount);
          final inferredUnit = ServingScalerService.inferDefaultUnit(
            parsed.name,
            amountVal,
          );
          inferredUnitLog = inferredUnit ?? "null";

          if (inferredUnit != null) {
            extractedAmount = '$extractedAmount $inferredUnit';
          }

          parsed = ParsedIngredient(
            name: parsed.name,
            amount: extractedAmount,
            originalRaw: parsed.originalRaw,
          );
        }
      } else if (parsed.amount.isNotEmpty) {
        rawAmountLog = "from text: ${parsed.amount}";
        if (!RegExp(r'[a-zA-ZçğıöşüÇĞİÖŞÜ]').hasMatch(parsed.amount)) {
          final amountVal = ServingScalerService.parseFraction(
            parsed.amount.trim(),
          );
          final inferredUnit = ServingScalerService.inferDefaultUnit(
            parsed.name,
            amountVal,
          );
          inferredUnitLog = inferredUnit ?? "null";
          if (inferredUnit != null) {
            parsed = ParsedIngredient(
              name: parsed.name,
              amount: '${parsed.amount.trim()} $inferredUnit',
              originalRaw: parsed.originalRaw,
            );
          }
        }
      }

      result.add(parsed);

      debugPrint('\nrawName: $cleanedName');
      debugPrint('parsedName: ${parsed.name}');
      debugPrint('rawAmount: $rawAmountLog');
      debugPrint('inferredUnit: $inferredUnitLog');
      debugPrint(
        'finalDisplayAmount: ${parsed.amount.isEmpty ? "Göz kararı" : parsed.amount}',
      );

      validIngredientIndex++;
    }
    debugPrint('\n');

    return result;
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
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Favoriye eklemek için giriş yapmalısınız.'),
        ),
      );
      return;
    }

    final wasFavorite = _isFavorite;
    setState(() => _isFavorite = !_isFavorite);

    try {
      final newStatus = await FavoriteService.toggleFavorite(_recipe.id);
      if (mounted) {
        setState(() => _isFavorite = newStatus);
        if (newStatus) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Favorilere eklendi')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Favorilerden çıkarıldı')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      if (mounted) {
        setState(() => _isFavorite = wasFavorite);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Favori işlemi başarısız oldu.')),
        );
      }
    }
  }

  void _showServingsSheet() {
    final options = {1, 2, 4, 6, _originalServings}.toList()..sort();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Porsiyon Seç',
                  style: AppTextStyles.h2.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                ...(options.map(
                  (s) => ListTile(
                    title: Text(
                      '$s porsiyon',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: _currentServings == s
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: _currentServings == s
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                    trailing: _currentServings == s
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        _currentServings = s;
                        _servingMultiplier =
                            ServingScalerService.calculateMultiplier(
                              _originalServings,
                              s,
                            );
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  String get _servingsText {
    if (_originalServings > 1) return '$_currentServings kişilik';
    return '$_currentServings porsiyon için';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoadingRecipe
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // Hero Image
                      SliverToBoxAdapter(child: _buildHeroImage(context)),
                      // Title + Description
                      SliverToBoxAdapter(child: _buildTitleSection()),
                      // Nutrition strip
                      SliverToBoxAdapter(child: _buildNutritionStrip()),
                      // Tab bar
                      SliverToBoxAdapter(child: _buildTabBar()),
                      // Tab content
                      SliverToBoxAdapter(child: _buildTabContent()),
                      // Bottom padding
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    ],
                  ),
                ),
                // Bottom CTA
                _buildBottomCTA(context),
              ],
            ),
    );
  }

  Widget _buildHeroImage(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          if (_recipe.imageUrl != null && _recipe.imageUrl!.isNotEmpty)
            CachedNetworkImage(
              imageUrl: _recipe.imageUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  Container(color: AppColors.backgroundMint),
              errorWidget: (context, url, error) => _buildFallbackBg(),
            )
          else
            _buildFallbackBg(),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.0),
                  Colors.black.withValues(alpha: 0.5),
                ],
              ),
            ),
          ),

          // Top action buttons
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CircleBtn(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => context.pop(),
                    ),
                    if (!_isLoadingFavorite)
                      _CircleBtn(
                        icon: _isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        iconColor: _isFavorite ? Colors.red : null,
                        onTap: _toggleFavorite,
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Badge
          if (_recipe.recommendationReady)
            Positioned(
              left: 20,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 12,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'En Uygun Tarif',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.surface,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFallbackBg() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D3B34), Color(0xFF1A241F)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.restaurant_rounded,
          size: 48,
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _recipe.shownTitle,
            style: AppTextStyles.h1.copyWith(
              fontSize: 22,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionStrip() {
    final scaledCalories = ServingScalerService.scaleNutritionValue(
      _recipe.calories,
      _servingMultiplier,
    );
    final scaledProtein = ServingScalerService.scaleNutritionValue(
      _recipe.protein,
      _servingMultiplier,
    );
    final scaledCarbs = ServingScalerService.scaleNutritionValue(
      _recipe.carbs,
      _servingMultiplier,
    );
    final scaledFat = ServingScalerService.scaleNutritionValue(
      _recipe.fat,
      _servingMultiplier,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildNutrientItem(
            Icons.local_fire_department_rounded,
            const Color(0xFFFF6B6B),
            scaledCalories,
            'kcal',
          ),
          _buildNutrientItem(
            Icons.fitness_center_rounded,
            Theme.of(context).colorScheme.primary,
            '${scaledProtein}g',
            'Protein',
          ),
          _buildNutrientItem(
            Icons.grain_rounded,
            AppColors.carbs,
            '${scaledCarbs}g',
            'Karb.',
          ),
          _buildNutrientItem(
            Icons.water_drop_rounded,
            AppColors.fat,
            '${scaledFat}g',
            'Yağ',
          ),
          _buildNutrientItem(
            Icons.schedule_rounded,
            Theme.of(context).colorScheme.onSurfaceVariant,
            '${_recipe.timeMinutes} dk',
            'Süre',
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientItem(
    IconData icon,
    Color color,
    String value,
    String label,
  ) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.labelLarge.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = ['Özet', 'Malzemeler', 'Yapılış'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isSelected = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    tabs[i],
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildOzetTab();
      case 1:
        return _buildMalzemelerTab();
      case 2:
        return _buildYapilisTab();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── ÖZET TAB ──
  Widget _buildOzetTab() {
    String desc = '';
    final summary = _rawJson['summary']?.toString();
    final cleanDesc = _rawJson['clean_description']?.toString();

    if (summary != null && summary.isNotEmpty) {
      desc = summary;
    } else if (_recipe.description.isNotEmpty &&
        _recipe.description.length > 10) {
      desc = _recipe.description;
    } else if (cleanDesc != null && cleanDesc.isNotEmpty) {
      desc = cleanDesc;
    } else {
      desc = 'Bu tarif dengeli ve lezzetli bir seçenek olarak hazırlandı.';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Özet',
            style: AppTextStyles.h2.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              desc,
              style: AppTextStyles.bodyMedium.copyWith(
                height: 1.6,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── MALZEMELER TAB ──
  Widget _buildMalzemelerTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Malzemeler',
                      style: AppTextStyles.h2.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _servingsText,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _showServingsSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.restaurant_rounded,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Porsiyon Değiştir',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Ingredient list
          if (_parsedIngredients.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Malzeme bilgisi hazırlanıyor',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...List.generate(_parsedIngredients.length, (i) {
              final ing = _parsedIngredients[i];
              final fileName =
                  IngredientResolverService.resolveIngredientFileName(
                    ing.originalRaw,
                  );
              final imageUrl =
                  IngredientResolverService.buildIngredientImageUrl(fileName);
              final isDefault = fileName == 'default_ingredient.png';

              // Scale amount if servings changed
              String displayAmount = ing.amount;
              if (_servingMultiplier != 1.0 && ing.amount.isNotEmpty) {
                displayAmount = ServingScalerService.scaleIngredientAmount(
                  ing.amount,
                  _servingMultiplier,
                );
              }
              if (displayAmount.isEmpty) displayAmount = 'Göz kararı';

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cardShadow,
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Ingredient image
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: isDefault
                              ? Center(
                                  child: Icon(
                                    Icons.eco_rounded,
                                    size: 20,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                )
                              : CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) => Center(
                                    child: SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Center(
                                    child: Icon(
                                      Icons.eco_rounded,
                                      size: 20,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Texts
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              ing.name,
                              style: AppTextStyles.labelLarge.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              displayAmount,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontSize: 13,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  // ── YAPILIŞ TAB ──
  Widget _buildYapilisTab() {
    final steps = _recipe.steps;

    if (steps.isEmpty ||
        (steps.length == 1 && steps[0].description.contains('bulunamadı'))) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Yapılış adımları hazırlanıyor.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(steps.length, (i) {
          final step = steps[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step number badge
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${step.step}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.surface,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Step icon
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.restaurant_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: AppTextStyles.h3.copyWith(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ServingScalerService.scaleQuantitiesInText(
                            step.description,
                            _servingMultiplier,
                          ),
                          style: AppTextStyles.bodySmall.copyWith(
                            height: 1.5,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomCTA(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: () => context.push(
            '/cooking-mode',
            extra: {'recipe': _recipe, 'servingMultiplier': _servingMultiplier},
          ),
          child: Container(
            height: 54,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Pişirme Modunu Başlat',
                        style: AppTextStyles.button.copyWith(
                          color: Theme.of(context).colorScheme.surface,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.play_arrow_rounded,
                        color: Theme.of(context).colorScheme.surface,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Circle button ──
class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  const _CircleBtn({required this.icon, required this.onTap, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: iconColor ?? Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
