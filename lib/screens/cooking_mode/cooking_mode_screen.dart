import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/recipe_model.dart';
import '../../services/serving_scaler_service.dart';
import '../../services/ingredient_resolver_service.dart';
import '../../services/tts_service.dart';
import 'recipe_completion_screen.dart';
import 'widgets/voice_read_card.dart';
import 'widgets/ray_note_card.dart';
import 'widgets/step_items_chips.dart';

class CookingModeScreen extends StatefulWidget {
  final RecipeModel? recipe;
  final double servingMultiplier;
  const CookingModeScreen({super.key, this.recipe, this.servingMultiplier = 1.0});

  @override
  State<CookingModeScreen> createState() => _CookingModeScreenState();
}

class _CookingModeScreenState extends State<CookingModeScreen> {
  late final RecipeModel _recipe;
  int _currentStep = 0;
  final ScrollController _stepperScrollController = ScrollController();
  
  late final TtsService _ttsService;

  @override
  void initState() {
    super.initState();
    _recipe = widget.recipe ?? RecipeMockData.primary;
    _ttsService = TtsService();
    // Add listener to rebuild UI when TTS state changes
    _ttsService.addListener(_onTtsStateChanged);
  }

  void _onTtsStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _nextStep() {
    _ttsService.stop();
    if (_currentStep >= _recipe.steps.length - 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (ctx) => RecipeCompletionScreen(
            recipe: _recipe,
            servingMultiplier: widget.servingMultiplier,
          ),
        ),
      );
      return;
    }
    setState(() {
      _currentStep++;
    });
    _scrollToStep();
  }

  void _prevStep() {
    _ttsService.stop();
    if (_currentStep <= 0) return;
    setState(() {
      _currentStep--;
    });
    _scrollToStep();
  }

  void _scrollToStep() {
    if (_stepperScrollController.hasClients) {
      double offset = (_currentStep * 40.0) - (MediaQuery.of(context).size.width / 2) + 20.0;
      if (offset < 0) offset = 0;
      final maxScroll = _stepperScrollController.position.maxScrollExtent;
      if (offset > maxScroll) offset = maxScroll;
      _stepperScrollController.animateTo(offset, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  void dispose() {
    _ttsService.removeListener(_onTtsStateChanged);
    _ttsService.dispose();
    _stepperScrollController.dispose();
    super.dispose();
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Pişirme modundan çıkılsın mı?', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: const Text('İlerlemen kaydedilmeden bu ekrandan ayrılacaksın.', textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Vazgeç', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              _ttsService.stop();
              Navigator.pop(ctx);
              context.pop(); 
            },
            child: Text('Çık', style: TextStyle(color: Theme.of(context).colorScheme.surface)),
          ),
        ],
      ),
    );
  }

  void _showIngredientsSheet() {
    final textVal = _recipe.rawJson?['ingredients_text']?.toString() ?? '';
    List<ParsedIngredient> ingredients = [];
    if (textVal.isNotEmpty) {
      final parts = textVal.split(',');
      for (var part in parts) {
        final cleaned = part.trim();
        if (cleaned.isEmpty) continue;
        if (cleaned.toLowerCase().contains('bulunamadı')) continue;
        if (cleaned.contains('[object Object]') || cleaned.contains('object Object') || cleaned.contains('Object')) continue;
        if (IngredientResolverService.isGroupLabel(cleaned.toLowerCase())) continue;
        
        ingredients.add(ServingScalerService.parseIngredientAmount(cleaned));
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text('Malzemeler', style: AppTextStyles.h2.copyWith(color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 16),
            if (ingredients.isEmpty)
              const Expanded(child: Center(child: Text('Malzeme listesi bulunamadı.')))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: ingredients.length,
                  itemBuilder: (ctx, i) {
                    final ing = ingredients[i];
                    String displayAmount = ing.amount;
                    if (widget.servingMultiplier != 1.0 && ing.amount.isNotEmpty) {
                      displayAmount = ServingScalerService.scaleIngredientAmount(ing.amount, widget.servingMultiplier);
                    }
                    if (displayAmount.isEmpty) displayAmount = 'Göz kararı';

                    final fileName = IngredientResolverService.resolveIngredientFileName(ing.originalRaw);
                    final imageUrl = IngredientResolverService.buildIngredientImageUrl(fileName);
                    final isDefault = fileName == 'default_ingredient.png';

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: isDefault
                            ? Icon(Icons.eco_rounded, color: Theme.of(context).colorScheme.primary)
                            : Image.network(imageUrl, fit: BoxFit.contain, errorBuilder: (c,e,s) => Icon(Icons.eco_rounded, color: Theme.of(context).colorScheme.primary)),
                      ),
                      title: Text(ing.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      trailing: Text(displayAmount, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- Helpers for Smart Card ---
  String _generateShortTitle(String text) {
    String lowerText = text.toLowerCase();
    if (lowerText.contains('doğra') || lowerText.contains('kıy') || lowerText.contains('kes')) return 'Malzemeleri doğra';
    if (lowerText.contains('kavur') || lowerText.contains('sotele')) return 'Kavur';
    if (lowerText.contains('karıştır') || lowerText.contains('harmanla')) return 'Karıştır';
    if (lowerText.contains('ekle') || lowerText.contains('ilave et')) return 'Malzemeleri ekle';
    if (lowerText.contains('pişir') || lowerText.contains('kaynat')) return 'Pişir';
    if (lowerText.contains('fırınla')) return 'Fırına ver';
    if (lowerText.contains('dinlendir') || lowerText.contains('beklet')) return 'Dinlendir';
    if (lowerText.contains('servis et')) return 'Servis et';
    if (lowerText.contains('blender') || lowerText.contains('çek')) {
      if (!lowerText.contains('çekilmiş')) return 'Blenderdan geçir';
    }
    if (lowerText.contains('yoğur') && !lowerText.contains('yoğurt')) return 'Yoğur';
    if (lowerText.contains('süz') && !lowerText.contains('süzme')) return 'Süz';
    return 'Bu adımı tamamla';
  }

  String _extractTime(String text, String? fallbackDuration) {
    RegExp exp = RegExp(r'(\d+)\s*(dk|dakika|saat)', caseSensitive: false);
    Match? match = exp.firstMatch(text);
    if (match != null) {
      return '${match.group(1)} ${match.group(2) == 'saat' ? 'saat' : 'dk'}';
    }
    
    if (fallbackDuration != null && fallbackDuration.isNotEmpty) {
      if (fallbackDuration.contains(RegExp(r'\d'))) return fallbackDuration;
    }
    
    String action = _extractAction(text);
    if (action == 'Doğrama') return '3-5 dk';
    if (action == 'Karıştırma') return '2-3 dk';
    if (action == 'Kavurma') return '4-6 dk';
    if (action == 'Pişirme') return '10-20 dk';
    if (action == 'Dinlendirme' && text.contains(RegExp(r'\d'))) {
      return ''; 
    } else if (action == 'Dinlendirme') {
      return '';
    }
    
    return '~5 dk';
  }

  String _extractHeat(String text) {
    String lowerText = text.toLowerCase();
    if (lowerText.contains('kısık ateş')) return 'Kısık';
    if (lowerText.contains('orta ateş')) return 'Orta';
    if (lowerText.contains('yüksek ateş')) return 'Yüksek';
    return 'Normal';
  }

  String _extractAction(String text) {
    String lowerText = text.toLowerCase();
    if (lowerText.contains('karıştır')) return 'Karıştırma';
    if (lowerText.contains('kavur')) return 'Kavurma';
    if (lowerText.contains('doğra')) return 'Doğrama';
    if (lowerText.contains('haşla')) return 'Haşlama';
    if (lowerText.contains('pişir')) return 'Pişirme';
    if (lowerText.contains('dinlendir')) return 'Dinlendirme';
    return 'Hazırlık';
  }

  String _extractUtensil(String text) {
    String lowerText = text.toLowerCase();
    if (lowerText.contains('fırın')) return 'Fırın';
    if (lowerText.contains('tencere')) return 'Tencere';
    if (lowerText.contains('tava')) return 'Tava';
    if (lowerText.contains('kase')) return 'Kase';
    if (lowerText.contains('blender')) return 'Blender';
    return 'Mutfak';
  }

  String _generateTip(String action) {
    if (action == 'Kavurma') return 'Orta ateşte kavurmak lezzeti artırır.';
    if (action == 'Pişirme') return 'Kapağı kapalı tutmak pişirmeyi hızlandırabilir.';
    if (action == 'Karıştırma') return 'Malzemeleri homojen karıştırmaya dikkat et.';
    if (action == 'Doğrama') return 'Benzer boyutta doğramak daha eşit pişirme sağlar.';
    if (action == 'Dinlendirme') return 'Dinlendirme aşaması lezzetin oturmasına yardımcı olur.';
    if (action == 'Servis') return 'Sıcak servis etmek lezzeti artırabilir.';
    return 'Bu adımı dikkatlice tamamladıktan sonra sonraki adıma geçebilirsin.';
  }

  @override
  Widget build(BuildContext context) {
    if (_recipe.steps.isEmpty || (_recipe.steps.length == 1 && _recipe.steps[0].description.contains('bulunamadı'))) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pişirme Modu'), leading: BackButton(onPressed: () => context.pop())),
        body: const Center(child: Text('Adım bilgisi bulunamadı.')),
      );
    }

    final step = _recipe.steps[_currentStep];
    final total = _recipe.steps.length;
    final isFirst = _currentStep == 0;
    final isLast = _currentStep == total - 1;

    final scaledDescription = ServingScalerService.scaleQuantitiesInText(step.description, widget.servingMultiplier);
    
    // Smart values
    final stepTitle = _generateShortTitle(scaledDescription);
    final timeBadge = _extractTime(scaledDescription, step.duration);
    final heatVal = _extractHeat(scaledDescription);
    final actionVal = _extractAction(scaledDescription);
    final utensilVal = _extractUtensil(scaledDescription);
    final tipVal = step.tip ?? _generateTip(actionVal);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFBF9), 
      body: SafeArea(
        child: Column(
          children: [
            // 1. HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _circleBtn(Icons.arrow_back_rounded, () => context.pop()),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _recipe.shownTitle,
                      style: AppTextStyles.labelLarge.copyWith(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w700, fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _circleBtn(Icons.more_horiz_rounded, () {}),
                ],
              ),
            ),
            
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          
                          // 2. STEPPER
                          Text(
                            'Adım ${_currentStep + 1} / $total',
                            style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          _buildStepper(total),
                          const SizedBox(height: 24),
                          
                          // 3. MAIN STEP CARD
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 5)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'ŞİMDİ',
                                              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            stepTitle,
                                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            width: 40,
                                            height: 3,
                                            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(2)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (timeBadge.isNotEmpty) ...[
                                      const SizedBox(width: 12),
                                      Column(
                                        children: [
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3), width: 3),
                                            ),
                                            child: Center(
                                              child: Text(
                                                timeBadge,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text('Tahmini süre', style: TextStyle(color: Colors.grey.shade500, fontSize: 9)),
                                        ],
                                      ),
                                    ]
                                  ],
                                ),
                                const SizedBox(height: 12),
                                
                                // Description
                                Text(
                                  scaledDescription,
                                  style: TextStyle(fontSize: 15, color: Colors.black87.withValues(alpha: 0.7), height: 1.5),
                                ),
                                const SizedBox(height: 24),
                                
                                // 3 Info Badges
                                Row(
                                  children: [
                                    Expanded(child: _infoBadge(Icons.local_fire_department_outlined, 'Ateş seviyesi', heatVal)),
                                    Container(width: 1, height: 30, color: Colors.grey.shade200),
                                    Expanded(child: _infoBadge(Icons.blender_outlined, 'İşlem', actionVal)),
                                    Container(width: 1, height: 30, color: Colors.grey.shade200),
                                    Expanded(child: _infoBadge(Icons.soup_kitchen_outlined, 'Gereç', utensilVal)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // 4. TTS CARD
                          VoiceReadCard(
                            ttsService: _ttsService,
                            // Başlık eklenmiyor, sadece açıklama ve gerekirse not
                            narrationText: scaledDescription,
                          ),
                          const SizedBox(height: 16),
                          
                          // 5. RAY'S NOTE CARD
                          RayNoteCard(tipText: tipVal),
                          const SizedBox(height: 24),
                          
                          // 6. INGREDIENTS CHIPS
                          StepItemsChips(
                            stepDescription: scaledDescription,
                            recipeIngredients: _recipe.ingredients,
                          ),
                          
                          // 7. BOTTOM NAV BUTTONS
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: isFirst ? null : _prevStep,
                                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                                  label: const Text('Önceki Adım', style: TextStyle(fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.black87,
                                    side: BorderSide(color: Colors.grey.shade300),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    backgroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _nextStep,
                                  icon: isLast ? const SizedBox.shrink() : const Icon(Icons.arrow_forward_rounded, size: 18),
                                  label: Text(
                                    isLast ? 'Tarifi Tamamla' : 'Sonraki Adım', 
                                    style: const TextStyle(fontWeight: FontWeight.bold)
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: const Color(0xFF1B4D3E),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // 8. STOP RECIPE / SHOW INGREDIENTS
                          Row(
                            children: [
                              Expanded(
                                child: _actionCard(
                                  title: 'Malzemeleri Gör',
                                  icon: Icons.shopping_basket_outlined,
                                  iconColor: Theme.of(context).colorScheme.primary,
                                  iconBgColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                  onTap: _showIngredientsSheet,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _actionCard(
                                  title: 'Tarifi Durdur',
                                  icon: Icons.pause_rounded,
                                  iconColor: Colors.red,
                                  iconBgColor: Colors.red.withValues(alpha: 0.1),
                                  onTap: _showExitDialog,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper(int total) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dotSize = 24.0;
        final minLineWidth = 12.0;
        final requiredWidth = (total * dotSize) + ((total - 1) * minLineWidth);
        final requiresScroll = requiredWidth > constraints.maxWidth;

        List<Widget> children = [];
        for (int i = 0; i < total; i++) {
          final isDone = i < _currentStep;
          final isActive = i == _currentStep;
          
          children.add(
            Container(
              width: isActive ? 28 : dotSize,
              height: isActive ? 28 : dotSize,
              decoration: BoxDecoration(
                color: isDone ? Theme.of(context).colorScheme.primary : (isActive ? Colors.white : Colors.grey.shade200),
                shape: BoxShape.circle,
                border: isActive ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null,
              ),
              child: Center(
                child: isDone
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey.shade500,
                        fontWeight: FontWeight.bold,
                        fontSize: isActive ? 12 : 11,
                      ),
                    ),
              ),
            ),
          );
          
          if (i < total - 1) {
            Widget line = Container(
              height: 2,
              color: (i < _currentStep) ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
            );
            if (requiresScroll) {
              children.add(SizedBox(width: minLineWidth, child: line));
            } else {
              children.add(Expanded(child: line));
            }
          }
        }
        
        if (requiresScroll) {
          return SingleChildScrollView(
            controller: _stepperScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(children: children),
          );
        }
        
        return Row(children: children);
      },
    );
  }

  Widget _infoBadge(IconData icon, String label, String value) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _actionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
          ],
        ),
        child: Icon(icon, color: Colors.black87, size: 20),
      ),
    );
  }
}
