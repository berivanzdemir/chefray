import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/recipe_model.dart';
import '../../services/daily_nutrition_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/user_profile_provider.dart';
import 'package:share_plus/share_plus.dart';

class RecipeCompletionScreen extends StatefulWidget {
  final RecipeModel recipe;
  final double servingMultiplier;

  const RecipeCompletionScreen({
    super.key,
    required this.recipe,
    this.servingMultiplier = 1.0,
  });

  @override
  State<RecipeCompletionScreen> createState() => _RecipeCompletionScreenState();
}

class _RecipeCompletionScreenState extends State<RecipeCompletionScreen> with SingleTickerProviderStateMixin {
  bool _hasLoggedCompletion = false;
  DailyNutritionTotals _todayTotals = DailyNutritionTotals.zero();
  
  bool _isFavorite = false;
  
  // Fallback Goals
  final double dailyCalorieGoal = 2250;
  final double dailyProteinGoal = 80;
  
  int _rating = 0;
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack));
    
    _checkFavorite();
    _logAndFetchNutrition();
    _animCtrl.forward();
  }

  Future<void> _checkFavorite() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }
    try {
      final response = await Supabase.instance.client
          .from('favorite_recipes')
          .select('id')
          .eq('user_id', user.id)
          .eq('recipe_id', widget.recipe.id)
          .maybeSingle();
          
      if (mounted) {
        setState(() {
          _isFavorite = response != null;
        });
      }
    } catch (e) {
      debugPrint('Favori kontrol hatası: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    
    final wasFavorite = _isFavorite;
    setState(() => _isFavorite = !_isFavorite);
    
    try {
      if (_isFavorite) {
        await Supabase.instance.client.from('favorite_recipes').insert({'user_id': user.id, 'recipe_id': widget.recipe.id});
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Favorilere eklendi')));
      } else {
        await Supabase.instance.client.from('favorite_recipes').delete().eq('user_id', user.id).eq('recipe_id', widget.recipe.id);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Favorilerden çıkarıldı')));
      }
    } catch (e) {
      setState(() => _isFavorite = wasFavorite);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Favori işlemi tamamlanamadı.')));
    }
  }
  
  void _shareRecipe() {
    final title = widget.recipe.shownTitle;
    final text = 'ChefRay\'de $title tarifini tamamladım! 🎉\nBu öğün: ${scaledCalories.toInt()} kcal, ${scaledProtein.toInt()}g protein.';
    Share.share(text);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _logAndFetchNutrition() async {
    if (_hasLoggedCompletion) return;
    
    final success = await DailyNutritionService.logCompletedRecipe(widget.recipe, widget.servingMultiplier);
    if (success) {
      _hasLoggedCompletion = true;
    }
    
    final totals = await DailyNutritionService.getTodayNutritionTotals();
    
    if (mounted) {
      final provider = context.read<UserProfileProvider>();
      final currentGoals = provider.todayGoals;
      
      if (currentGoals != null) {
        double newCalories = totals.calories;
        double newProtein = totals.protein;
        
        // If the user has manually overridden the values, we add to their override
        if (currentGoals.caloriesConsumed > 0) {
          newCalories = currentGoals.caloriesConsumed + scaledCalories;
        }
        if (currentGoals.proteinConsumed > 0) {
          newProtein = currentGoals.proteinConsumed + scaledProtein;
        }
        
        final updatedGoals = currentGoals.copyWith(
          caloriesConsumed: newCalories,
          proteinConsumed: newProtein,
        );
        
        // Fire and forget update
        provider.updateDailyGoals(updatedGoals);
      }

      setState(() {
        _todayTotals = totals;
      });
    }
  }

  double get scaledCalories => (double.tryParse(widget.recipe.calories.toString()) ?? 0.0) * widget.servingMultiplier;
  double get scaledProtein => (double.tryParse(widget.recipe.protein.toString()) ?? 0.0) * widget.servingMultiplier;
  double get scaledCarbs => (double.tryParse(widget.recipe.carbs.toString()) ?? 0.0) * widget.servingMultiplier;
  double get scaledFat => (double.tryParse(widget.recipe.fat.toString()) ?? 0.0) * widget.servingMultiplier;
  
  String _getChefRayComment() {
    if (_todayTotals.calories > dailyCalorieGoal * 1.1) {
      return 'Bugün kalori hedefinin üzerine çıktın. Akşam için daha hafif ve sebze ağırlıklı seçimler iyi olabilir.';
    } else if (_todayTotals.protein < dailyProteinGoal * 0.5) {
      return 'Bugünkü protein hedefin için iyi bir katkı yaptın! Günün kalanında protein odaklı hafif seçimler tercih edebilirsin.';
    } else {
      return 'Bugünkü hedeflerine dengeli şekilde ilerliyorsun. Harika bir seçim yaptın! 💪';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.ios_share_rounded, color: Theme.of(context).colorScheme.onSurface),
            onPressed: _shareRecipe,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          children: [
            _buildSuccessHeader(),
            const SizedBox(height: 24),
            _buildNutritionSummaryCard(),
            const SizedBox(height: 16),
            _buildMacrosRow(),
            const SizedBox(height: 24),
            _buildChefRayComment(),
            const SizedBox(height: 24),
            _buildRatingCard(),
            const SizedBox(height: 24),
            _buildActionRow(),
            const SizedBox(height: 40),
            _buildMainCTA(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessHeader() {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3), blurRadius: 20, offset: Offset(0, 10)),
                ],
              ),
              child: Icon(Icons.check_rounded, color: Theme.of(context).colorScheme.surface, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              'Afiyet Olsun! 🎉',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 28, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.recipe.shownTitle} tarifini başarıyla tamamladın.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionSummaryCard() {
    final progress = (_todayTotals.calories / dailyCalorieGoal).clamp(0.0, 1.0);
    final percent = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          // Circular Calorie Indicator
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  color: Theme.of(context).colorScheme.primary,
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(scaledCalories.toInt().toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Theme.of(context).colorScheme.onSurface)),
                      Text('kcal', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                Positioned(
                  top: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
                    child: Icon(Icons.local_fire_department_rounded, color: Theme.of(context).colorScheme.surface, size: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Harika iş çıkardın! 💪', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Günlük hedefine eklendi.', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    Text('%$percent', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text('🔥 ${_todayTotals.calories.toInt()} / ${dailyCalorieGoal.toInt()} kcal', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text('Kalan: ${(dailyCalorieGoal - _todayTotals.calories).clamp(0, 9999).toInt()} kcal', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacrosRow() {
    return Row(
      children: [
        Expanded(child: _buildMacroItem('Protein', scaledProtein, Icons.fitness_center_rounded, dailyProteinGoal)),
        const SizedBox(width: 12),
        Expanded(child: _buildMacroItem('Karb.', scaledCarbs, Icons.grass_rounded, 250)),
        const SizedBox(width: 12),
        Expanded(child: _buildMacroItem('Yağ', scaledFat, Icons.water_drop_rounded, 70)),
      ],
    );
  }

  Widget _buildMacroItem(String label, double amount, IconData icon, double goal) {
    int pct = goal > 0 ? ((amount / goal) * 100).toInt() : 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
          const SizedBox(height: 8),
          Text('+${amount.toInt()}g', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
          Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text('Hedefin %$pct\'si', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildChefRayComment() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Image.asset(
                  'assets/mascot/ray_happy.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('Mascot asset not found, fallback icon used.');
                    return Icon(Icons.smart_toy_rounded, color: Theme.of(context).colorScheme.primary, size: 28);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('ChefRay Yorumu ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
                    Icon(Icons.auto_awesome_rounded, color: Theme.of(context).colorScheme.primary, size: 16),
                  ],
                ),
                const SizedBox(height: 8),
                Text(_getChefRayComment(), style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text('Tarifi beğendin mi?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 4),
          Text('Deneyimini bizimle paylaş.', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final isSelected = index < _rating;
              return GestureDetector(
                onTap: () async {
                  setState(() => _rating = index + 1);
                  final success = await DailyNutritionService.rateRecipe(widget.recipe.id, _rating);
                  if (!mounted) return;
                  if (success) {
                    String msg = '';
                    if (_rating == 5) {
                      msg = 'Harika! Beğenmene çok sevindik 🌟';
                    } else if (_rating == 4) {
                      msg = 'Geri bildirimin için teşekkürler 💚';
                    } else if (_rating == 3) {
                      msg = 'Teşekkürler, deneyimini geliştirmeye devam edeceğiz.';
                    } else {
                      msg = 'Geri bildirimin bizim için değerli. Bu tarifi iyileştireceğiz.';
                    }
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Puan kaydedilemedi, tekrar deneyin.')));
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                    color: isSelected ? Colors.amber : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    size: 36,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow() {
    return Row(
      children: [
        Expanded(
          child: _actionBtn(
            icon: _isFavorite ? Icons.favorite_rounded : Icons.bookmark_border_rounded,
            iconColor: _isFavorite ? Colors.redAccent : Theme.of(context).colorScheme.primary,
            label: _isFavorite ? 'Favorilerde' : 'Favorilere Ekle',
            onTap: _toggleFavorite,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionBtn(
            icon: Icons.refresh_rounded,
            label: 'Tekrar Yap',
            onTap: () => context.pop(), // Pop goes back to cooking mode
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionBtn(
            icon: Icons.share_rounded,
            label: 'Paylaş',
            onTap: _shareRecipe,
          ),
        ),
      ],
    );
  }

  Widget _actionBtn({required IconData icon, required String label, required VoidCallback onTap, Color? iconColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.35), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.primary, size: 24),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCTA() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => context.go('/recipes'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            padding: const EdgeInsets.symmetric(vertical: 18),
            minimumSize: const Size(double.infinity, 56),
            elevation: 8,
            shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Yeni Tarif Planla', style: TextStyle(color: Theme.of(context).colorScheme.surface, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Icon(Icons.restaurant_menu_rounded, color: Theme.of(context).colorScheme.surface, size: 20),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => context.go('/home'),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.home_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 18),
              const SizedBox(width: 8),
              Text('Ana Sayfaya Dön', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}
