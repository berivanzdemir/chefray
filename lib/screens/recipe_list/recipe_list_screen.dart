import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_text_styles.dart';
import '../../models/recipe_model.dart';
import '../../models/recipes/recommended_recipe_view_model.dart';
import '../../repositories/recipes/supabase_recipe_repository.dart';
import '../../widgets/recipe/recipe_card.dart';
import '../../widgets/recipe/meal_filter_chip.dart';
import '../../widgets/common/bottom_nav_bar.dart';
import '../../services/favorite_service.dart';

class RecipeListScreen extends StatefulWidget {
  final List<RecipeModel>? preloadedRecipes;
  final List<RecommendedRecipeViewModel>? recommendedRecipes;
  final String? initialMealType;

  const RecipeListScreen({
    super.key,
    this.preloadedRecipes,
    this.recommendedRecipes,
    this.initialMealType,
  });

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen>
    with SingleTickerProviderStateMixin {
  int _selectedMeal = 1;
  String _selectedSort = 'En Uygun';
  final int _navIndex = 3; // Tarifler tab
  late final AnimationController _fadeCtrl;

  // Search Variables
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;
  List<RecipeModel> _searchResults = [];
  bool _isSearching = false;
  int _searchRequestId = 0;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _error = '';

  int _page = 0;
  final int _pageSize = 20;
  bool _hasMore = true;
  int _requestId = 0;
  final ScrollController _scrollCtrl = ScrollController();

  List<RecipeModel> _allRecommendedRecipes = [];
  List<RecipeModel> _filteredRecipes = [];
  Set<String> _favoriteRecipeIds = {};

  static const _meals = ['Kahvaltı', 'Öğle Yemeği', 'Akşam Yemeği', 'Ara Öğün'];
  static const _mealKeys = ['breakfast', 'lunch', 'dinner', 'snack'];
  static const _mealIcons = [
    Icons.wb_sunny_outlined,
    Icons.wb_sunny_rounded,
    Icons.nightlight_round,
    Icons.cookie_outlined,
  ];
  static const _sortOptions = [
    'En Uygun',
    'Yüksek Protein',
    'Düşük Kalori',
    'Glutensiz',
    'En Kısa Süre',
  ];

  List<RecipeModel> get _displayedRecipes =>
      _searchQuery.isNotEmpty ? _searchResults : _filteredRecipes;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scrollCtrl.addListener(_onScroll);

    if (widget.initialMealType != null) {
      final index = _mealKeys.indexWhere(
        (m) => m == widget.initialMealType!.toLowerCase(),
      );
      if (index != -1) {
        _selectedMeal = index;
      }
    } else if (widget.preloadedRecipes != null &&
        widget.preloadedRecipes!.isNotEmpty) {
      final firstMealType = widget.preloadedRecipes!.first.mealType;
      // Map Turkish to English keys if necessary
      final mapping = {
        'kahvaltı': 0,
        'öğle yemeği': 1,
        'akşam yemeği': 2,
        'ara öğün': 3,
      };
      final index = mapping[firstMealType.toLowerCase()] ?? -1;
      if (index != -1) {
        _selectedMeal = index;
      }
    }

    _fetchFavorites();
    _fetchRecipes();
  }

  Future<void> _fetchFavorites() async {
    try {
      final ids = await FavoriteService.getFavoriteRecipeIds();
      if (mounted) {
        setState(() {
          _favoriteRecipeIds = ids;
        });
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  Future<void> _toggleFavorite(RecipeModel recipe) async {
    final recipeId = recipe.id;
    final isFav = _favoriteRecipeIds.contains(recipeId);

    // Optimistic UI update
    setState(() {
      if (isFav) {
        _favoriteRecipeIds.remove(recipeId);
      } else {
        _favoriteRecipeIds.add(recipeId);
      }
    });

    try {
      if (isFav) {
        await FavoriteService.removeFavorite(recipeId);
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Favorilerden çıkarıldı')),
          );
        }
      } else {
        await FavoriteService.addFavorite(recipeId);
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Favorilere eklendi')));
        }
      }
    } catch (e) {
      // Revert if error
      setState(() {
        if (isFav) {
          _favoriteRecipeIds.add(recipeId);
        } else {
          _favoriteRecipeIds.remove(recipeId);
        }
      });
      debugPrint('Error toggling favorite: $e');
    }
  }

  Future<void> _navigateToFavorites() async {
    await context.push('/favorites');
    _fetchFavorites();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      if (!_isLoading && !_isLoadingMore && _hasMore) {
        _fetchRecipes(isLoadMore: true);
      }
    }
  }

  Future<void> _fetchRecipes({bool isLoadMore = false}) async {
    final selectedMealLabel = _meals[_selectedMeal];
    final selectedMealType = _mealKeys[_selectedMeal];
    final currentRequestId = ++_requestId;

    debugPrint('\nRecipe fetch started:');
    debugPrint('selectedMealLabel: $selectedMealLabel');
    debugPrint('selectedMealType: $selectedMealType');
    debugPrint('page: $_page');
    debugPrint('pageSize: $_pageSize');
    debugPrint('rangeStart: ${_page * _pageSize}');
    debugPrint('rangeEnd: ${_page * _pageSize + _pageSize - 1}');

    if (!isLoadMore) {
      setState(() {
        _isLoading = true;
        _error = '';
        _page = 0;
        _hasMore = true;
      });
      debugPrint('Filter changed: resetPagination: true');
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final repo = SupabaseRecipeRepository();

      final recipes = await repo.getRecommendedRecipes(
        selectedMealType,
        sortFilter: _selectedSort,
        page: _page,
        pageSize: _pageSize,
      );

      if (!mounted) return;
      if (currentRequestId != _requestId) {
        debugPrint(
          'Race check: requestId $currentRequestId is NOT latest, discarding',
        );
        return;
      }
      debugPrint(
        'Race check: requestId $currentRequestId isLatestRequest: true',
      );

      debugPrint('\nRecipe fetch result:');
      debugPrint('selectedMealType: $selectedMealType');
      debugPrint('resultCount: ${recipes.length}');

      if (selectedMealType == 'snack') {
        debugPrint('\nAra Öğün için özellikle:');
        debugPrint('selectedMealLabel: $selectedMealLabel');
        debugPrint('selectedMealType: $selectedMealType');
        debugPrint('resultCount: ${recipes.length}');
      }

      setState(() {
        if (!isLoadMore) {
          _allRecommendedRecipes = recipes;
          debugPrint('Filter changed: clearedOldResults: true');
        } else {
          for (var r in recipes) {
            if (!_allRecommendedRecipes.any(
              (existing) => existing.id == r.id,
            )) {
              _allRecommendedRecipes.add(r);
            }
          }
        }

        if (recipes.length < _pageSize) {
          _hasMore = false;
        } else {
          _page++;
        }

        debugPrint('totalLoadedCount: ${_allRecommendedRecipes.length}');
        debugPrint('hasMore: $_hasMore');
        debugPrint('error: None');

        _isLoading = false;
        _isLoadingMore = false;
      });

      _applyFilters();

      if (!isLoadMore) {
        _fadeCtrl.forward(from: 0);
      }
    } catch (e) {
      if (!mounted) return;
      if (currentRequestId != _requestId) return;

      debugPrint('\nRecipe fetch result: error: $e');
      setState(() {
        _error =
            "Tarifler yüklenirken bir sorun oluştu. Lütfen tekrar deneyiniz.";
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _applyFilters() {
    if (_allRecommendedRecipes.isEmpty) {
      setState(() {
        _filteredRecipes = [];
      });
      return;
    }

    var filtered = List<RecipeModel>.from(_allRecommendedRecipes);
    final selectedMealType = _mealKeys[_selectedMeal];

    // Double-layer local strict recommendation and meal type security
    filtered = filtered.where((r) {
      final recommendMatch =
          r.recommendationReady == true &&
          r.isRecommendable == true &&
          r.isDietFriendly == true;
      final blockedMatch = r.blockedReason == null || r.blockedReason!.isEmpty;

      if (!recommendMatch || !blockedMatch) {
        if (selectedMealType == 'snack') {
          debugPrint(
            'Local filter excluded snack recipe ${r.id} due to recommendMatch:$recommendMatch, blockedMatch:$blockedMatch',
          );
        }
      }

      return recommendMatch && blockedMatch;
    }).toList();

    // Double-layer robust local boolean filtering
    if (_selectedSort == 'Yüksek Protein' ||
        _selectedSort == 'En Yüksek Protein') {
      filtered = filtered
          .where((r) => r.proteinStatus == 'high' || r.isHighProtein)
          .toList();
      filtered.sort((a, b) => (b.proteinG ?? 0).compareTo(a.proteinG ?? 0));
    } else if (_selectedSort == 'Düşük Kalori') {
      filtered = filtered
          .where((r) => r.calorieStatus == 'low' || r.isLowCalorie)
          .toList();
      filtered.sort(
        (a, b) => (a.caloriesKcal ?? 0).compareTo(b.caloriesKcal ?? 0),
      );
    } else if (_selectedSort == 'Glutensiz') {
      filtered = filtered
          .where(
            (r) =>
                (r.glutenStatus == 'gluten_free' || r.isGlutenFree) &&
                r.glutenStatus != 'unknown' &&
                r.glutenStatus != 'contains_gluten',
          )
          .toList();
    } else if (_selectedSort == 'En Kısa Süre') {
      // Sort by calculatedTotalMinutes ascending, null values go to the end
      filtered.sort((a, b) {
        final aTime = a.calculatedTotalMinutes ?? 999999;
        final bTime = b.calculatedTotalMinutes ?? 999999;
        return aTime.compareTo(bTime);
      });
    }

    if (selectedMealType == 'snack' &&
        filtered.isEmpty &&
        _allRecommendedRecipes.isNotEmpty) {
      debugPrint(
        '\nAra Öğün için tüm sonuçlar (_allRecommendedRecipes:${_allRecommendedRecipes.length}) yerel filtreler ($_selectedSort) tarafından sıfırlandı!',
      );
    }

    setState(() {
      _filteredRecipes = filtered;
    });
  }

  Future<void> _performSearch(String query) async {
    final currentRequestId = ++_searchRequestId;
    final selectedMealType = _mealKeys[_selectedMeal];

    setState(() {
      _isSearching = true;
    });

    final repo = SupabaseRecipeRepository();
    final results = await repo.searchRecipesDetailed(query, selectedMealType);

    if (!mounted) return;
    if (currentRequestId != _searchRequestId) {
      debugPrint(
        'RecipeSearch:\n mode: search\n rawQuery: ${_searchCtrl.text}\n normalizedQuery: $query\n selectedMealType: $selectedMealType\n ignoredOldRequest: true',
      );
      return;
    }

    // Client-side validation to remove false positives
    final validatedResults = results.where((r) {
      final t = _normalizeTurkish(r.title);
      final cTitle = _normalizeTurkish(r.displayTitle ?? '');
      final d = _normalizeTurkish(r.description);
      final c = _normalizeTurkish(r.category ?? '');
      final dt = _normalizeTurkish(r.dietTypes.join(' '));
      final ht = _normalizeTurkish(r.tags.join(' '));
      final i = _normalizeTurkish(r.ingredients.map((e) => e.name).join(' '));

      final searchableText = '$t $cTitle $d $c $i $dt $ht';
      return searchableText.contains(query);
    }).toList();

    debugPrint(
      'RecipeSearch:\n mode: search\n rawQuery: ${_searchCtrl.text}\n normalizedQuery: $query\n selectedMealType: $selectedMealType\n requestId: $currentRequestId\n supabaseResultCount: ${results.length}\n clientValidatedCount: ${validatedResults.length}\n displayedCount: ${validatedResults.length}\n ignoredOldRequest: false',
    );

    setState(() {
      _searchResults = validatedResults;
      _isSearching = false;
    });
  }

  void _clearFilters() {
    _searchCtrl.clear();
    setState(() {
      _selectedSort = 'En Uygun';
      _searchQuery = '';
    });
    _fetchRecipes();
  }

  String _normalizeTurkish(String text) {
    var result = text.toLowerCase().trim();
    result = result
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u');
    return result;
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final normalized = _normalizeTurkish(query);
      setState(() {
        _searchQuery = normalized;
      });
      if (normalized.isEmpty) {
        setState(() {
          _searchResults.clear();
          _isSearching = false;
        });
      } else {
        _performSearch(normalized);
      }
    });
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() {
      _searchQuery = '';
      _searchResults.clear();
      _isSearching = false;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _showSortFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
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
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sıralama ve Filtre',
                          style: AppTextStyles.h3.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setModalState(() => _selectedSort = 'En Uygun');
                            setState(() => _selectedSort = 'En Uygun');
                            _fetchRecipes();
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Temizle',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 12,
                      children: _sortOptions.map((option) {
                        final isSelected = option == _selectedSort;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() => _selectedSort = option);
                            setState(() => _selectedSort = option);
                            _fetchRecipes();
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).scaffoldBackgroundColor,
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).dividerColor,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              option,
                              style: AppTextStyles.labelMedium.copyWith(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.surface
                                    : Theme.of(context).colorScheme.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 20,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Tarif Önerileri',
                    style: AppTextStyles.h2.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tooltip(
                        message: 'Favorilerim',
                        child: GestureDetector(
                          onTap: _navigateToFavorites,
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.favorite_border,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _showSortFilterBottomSheet,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            color: Theme.of(context).colorScheme.onSurface,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Analizine göre sana özel tarifler ',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const Text('✨', style: TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tarif, malzeme veya kategori ara...',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    suffixIcon:
                        _searchQuery.isNotEmpty || _searchCtrl.text.isNotEmpty
                        ? GestureDetector(
                            onTap: _clearSearch,
                            child: Icon(
                              Icons.close_rounded,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Meal filters
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _meals.length,
                separatorBuilder: (_, i) => const SizedBox(width: 8),
                itemBuilder: (_, i) => MealFilterChip(
                  label: _meals[i],
                  icon: _mealIcons[i],
                  isSelected: i == _selectedMeal,
                  onTap: () {
                    if (_selectedMeal != i) {
                      setState(() => _selectedMeal = i);
                      if (_searchQuery.isNotEmpty) {
                        _performSearch(_searchQuery);
                      } else {
                        _fetchRecipes();
                      }
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Sort row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _showSortFilterBottomSheet,
                    child: Row(
                      children: [
                        Text(
                          'Sıralama: ',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          _selectedSort,
                          style: AppTextStyles.labelSmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${_displayedRecipes.length} tarif bulundu',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Recipe list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error.isNotEmpty
                  ? Center(child: Text(_error))
                  : _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : _displayedRecipes.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                      itemCount:
                          _displayedRecipes.length +
                          (_isLoadingMore && _searchQuery.isEmpty ? 1 : 0),
                      separatorBuilder: (_, i) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        if (i == _displayedRecipes.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        final start = (i * 0.15).clamp(0.0, 0.7);
                        final end = (start + 0.4).clamp(0.0, 1.0);
                        final curve = CurvedAnimation(
                          parent: _fadeCtrl,
                          curve: Interval(start, end, curve: Curves.easeOut),
                        );
                        final recipe = _displayedRecipes[i];
                        return AnimatedBuilder(
                          animation: curve,
                          builder: (ctx, ch) => Opacity(
                            opacity: curve.value,
                            child: Transform.translate(
                              offset: Offset(0, 16 * (1 - curve.value)),
                              child: ch,
                            ),
                          ),
                          child: RecipeCard(
                            recipe: recipe,
                            onTap: () =>
                                context.push('/recipe-show', extra: recipe),
                            isFavorite: _favoriteRecipeIds.contains(recipe.id),
                            onFavoriteTap: () => _toggleFavorite(recipe),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ChefRayBottomNavBar(
        currentIndex: _navIndex,
        onTap: (i) {
          if (i == 0) {
            context.go('/home');
          } else if (i == 1) {
            context.go('/analysis-history');
          } else if (i == 2) {
            context.go('/diet-upload?uploadType=dietPdf');
          } else if (i == 3) {
            // Already here
          } else if (i == 4) {
            context.go('/profile');
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.search_off_rounded,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Aradığın tarif bulunamadı',
                  style: AppTextStyles.h3.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Farklı bir kelime deneyebilir veya filtreleri temizleyebilirsin.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _clearFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Filtreleri Temizle',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
