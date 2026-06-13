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
  const CookingModeScreen({
    super.key,
    this.recipe,
    this.servingMultiplier = 1.0,
  });

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
      double offset =
          (_currentStep * 40.0) -
          (MediaQuery.of(context).size.width / 2) +
          20.0;
      if (offset < 0) offset = 0;
      final maxScroll = _stepperScrollController.position.maxScrollExtent;
      if (offset > maxScroll) offset = maxScroll;
      _stepperScrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
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
        title: const Text(
          'Pişirme modundan çıkılsın mı?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'İlerlemen kaydedilmeden bu ekrandan ayrılacaksın.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Vazgeç',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              _ttsService.stop();
              Navigator.pop(ctx);
              context.pop();
            },
            child: Text(
              'Çık',
              style: TextStyle(color: Theme.of(context).colorScheme.surface),
            ),
          ),
        ],
      ),
    );
  }

  void _showIngredientsSheet() {
    List<ParsedIngredient> ingredients = [];

    // Fallback: Use parsed ingredients from RecipeModel directly
    for (var ing in _recipe.ingredients) {
      final name = ing.name.trim();
      if (name.isEmpty) continue;
      if (name.toLowerCase().contains('bulunamadı')) continue;
      if (name.contains('[object Object]') ||
          name.contains('object Object') ||
          name.contains('Object'))
        continue;
      if (IngredientResolverService.isGroupLabel(name.toLowerCase())) continue;

      ingredients.add(
        ParsedIngredient(originalRaw: name, amount: ing.amount, name: name),
      );
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
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Malzemeler',
              style: AppTextStyles.h2.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            if (ingredients.isEmpty)
              const Expanded(
                child: Center(child: Text('Malzeme listesi bulunamadı.')),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: ingredients.length,
                  itemBuilder: (ctx, i) {
                    final ing = ingredients[i];
                    String displayAmount = ing.amount;
                    if (widget.servingMultiplier != 1.0 &&
                        ing.amount.isNotEmpty &&
                        ing.amount != 'Göz kararı / İsteğe bağlı') {
                      displayAmount =
                          ServingScalerService.scaleIngredientAmount(
                            ing.amount,
                            widget.servingMultiplier,
                          );
                    }
                    if (displayAmount.isEmpty) displayAmount = 'Göz kararı';

                    final fileName =
                        IngredientResolverService.resolveIngredientFileName(
                          ing.name,
                        );
                    final imageUrl =
                        IngredientResolverService.buildIngredientImageUrl(
                          fileName,
                        );
                    final isDefault = fileName == 'default_ingredient.png';

                    return ListTile(
                      contentPadding: const EdgeInsets.only(bottom: 16),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: isDefault
                            ? Icon(
                                Icons.eco_rounded,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : Image.network(
                                imageUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (c, e, s) => Icon(
                                  Icons.eco_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                      ),
                      title: Text(
                        ing.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          displayAmount,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ),
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
    if (lowerText.contains('kavur') || lowerText.contains('sotele'))
      return 'Kavur';
    if (lowerText.contains('haşla') || lowerText.contains('kaynat'))
      return 'Haşla';
    if (lowerText.contains('doğra') ||
        lowerText.contains('kıy') ||
        lowerText.contains('kes'))
      return 'Doğra';
    if (lowerText.contains('karıştır') || lowerText.contains('harmanla'))
      return 'Karıştır';
    if (lowerText.contains('ekle') || lowerText.contains('ilave et'))
      return 'Malzemeleri Ekle';
    if (lowerText.contains('pişir')) return 'Pişir';
    if (lowerText.contains('fırınla')) return 'Fırınla';
    if (lowerText.contains('dinlendir') || lowerText.contains('beklet'))
      return 'Dinlendir';
    if (lowerText.contains('servis et')) return 'Servis Et';
    if (lowerText.contains('blender') || lowerText.contains('çek')) {
      if (!lowerText.contains('çekilmiş')) return 'Blenderdan Geçir';
    }
    if (lowerText.contains('yoğur') && !lowerText.contains('yoğurt'))
      return 'Yoğur';
    if (lowerText.contains('süz') && !lowerText.contains('süzme')) return 'Süz';

    // Fallback: Use the first 3 words of the description if it's very short, otherwise 'İşlemi Uygula'
    List<String> words = text.split(' ');
    if (words.length <= 4) return text;
    return 'İşlemi Uygula';
  }

  String _extractHeat(String text) {
    String lowerText = text.toLowerCase();

    // No heat actions
    if (lowerText.contains('doğra') ||
        lowerText.contains('kes') ||
        lowerText.contains('kıy') ||
        lowerText.contains('rendele') ||
        lowerText.contains('yıka') ||
        lowerText.contains('ayıkla') ||
        lowerText.contains('karıştır') ||
        lowerText.contains('ekle') ||
        lowerText.contains('ilave et') ||
        lowerText.contains('servis') ||
        lowerText.contains('süsle') ||
        lowerText.contains('dinlendir') ||
        lowerText.contains('soğut') ||
        lowerText.contains('süz') ||
        lowerText.contains('harmanla')) {
      return 'Yok';
    }

    if (lowerText.contains('kısık ateş')) return 'Kısık';
    if (lowerText.contains('orta ateş')) return 'Orta';
    if (lowerText.contains('yüksek ateş')) return 'Yüksek';

    // Heat actions
    if (lowerText.contains('kızart') ||
        lowerText.contains('kavur') ||
        lowerText.contains('pişir') ||
        lowerText.contains('haşla') ||
        lowerText.contains('fırınla') ||
        lowerText.contains('kaynat')) {
      return 'Normal';
    }

    return 'Yok';
  }

  String _extractAction(String text) {
    String lowerText = text.toLowerCase();
    if (lowerText.contains('doğra') ||
        lowerText.contains('kes') ||
        lowerText.contains('kıy'))
      return 'Doğrama';
    if (lowerText.contains('karıştır') ||
        lowerText.contains('çırp') ||
        lowerText.contains('harmanla'))
      return 'Karıştırma';
    if (lowerText.contains('pişir') ||
        lowerText.contains('kavur') ||
        lowerText.contains('kızart') ||
        lowerText.contains('haşla') ||
        lowerText.contains('fırınla') ||
        lowerText.contains('kaynat'))
      return 'Pişirme';
    if (lowerText.contains('ekle') || lowerText.contains('ilave et'))
      return 'Ekleme';
    if (lowerText.contains('servis')) return 'Servis';
    if (lowerText.contains('dinlendir') ||
        lowerText.contains('soğut') ||
        lowerText.contains('beklet'))
      return 'Dinlendirme';
    return 'Hazırlık';
  }

  String _extractUtensil(String text) {
    String lowerText = text.toLowerCase();
    if (lowerText.contains('doğra') ||
        lowerText.contains('kes') ||
        lowerText.contains('kıy'))
      return 'Bıçak / Kesme Tahtası';
    if (lowerText.contains('tencere') ||
        lowerText.contains('haşla') ||
        lowerText.contains('kaynat'))
      return 'Tencere';
    if (lowerText.contains('tava') ||
        lowerText.contains('kavur') ||
        lowerText.contains('sotele'))
      return 'Tava';
    if (lowerText.contains('fırın')) return 'Fırın';
    if (lowerText.contains('blender') ||
        lowerText.contains('mikser') ||
        lowerText.contains('çek'))
      return 'Blender / Mikser';
    if (lowerText.contains('kase') || lowerText.contains('kap')) return 'Kase';
    return 'Mutfak Gereçleri';
  }

  String _generateTip(String stepTitle, String stepDescription) {
    final titleMatch = _getTipMatch(stepTitle);
    if (titleMatch != null) return titleMatch;

    final descMatch = _getTipMatch(stepDescription);
    if (descMatch != null) return descMatch;

    return 'Bu adımda malzemelerin kıvamını ve görünümünü kontrol ederek ilerleyebilirsin.';
  }

  String? _getTipMatch(String text) {
    final lower = text
        .toLowerCase()
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u');

    if (lower.contains('firin')) {
      return 'Fırın adımlarında süre ve sıcaklığı kontrol etmek daha dengeli sonuç verir.';
    }
    if (lower.contains('kavur') || lower.contains('sotele')) {
      return 'Kavururken malzemeleri ara ara karıştırmak yanmayı önler ve lezzeti dengeler.';
    }
    if (lower.contains('kizdir') ||
        (lower.contains('isit') && lower.contains('yag'))) {
      return 'Yağı çok yakmadan ısıtmak yemeğin lezzetini korur.';
    }
    if (lower.contains('hasla') || lower.contains('kaynat')) {
      return 'Haşlama sırasında malzemelerin fazla yumuşamaması için kıvamını kontrol edebilirsin.';
    }
    if (lower.contains('pisir')) {
      return 'Pişirme sırasında ara ara kontrol ederek kıvamı dengede tutabilirsin.';
    }
    if (lower.contains('dogra') ||
        lower.contains('kes') ||
        lower.contains('kiy') ||
        lower.contains('rendele')) {
      return 'Sebzeleri benzer boyutta hazırlamak daha dengeli pişmesini sağlar.';
    }
    if (lower.contains('karistir') ||
        lower.contains('cirp') ||
        lower.contains('harmanla')) {
      return 'Malzemeleri nazikçe karıştırmak dokunun bozulmasını önler.';
    }
    if (lower.contains('ekle') || lower.contains('ilave et')) {
      return 'Malzemeleri sırayla eklemek lezzetin daha dengeli dağılmasına yardımcı olur.';
    }
    if (lower.contains('dinlendir') ||
        lower.contains('sogut') ||
        lower.contains('beklet')) {
      return 'Kısa süre dinlendirmek lezzetin oturmasına yardımcı olur.';
    }
    if (lower.contains('servis')) {
      return 'Servisten önce son kıvamı ve tadı kontrol edebilirsin.';
    }
    if (lower.contains('salata') || lower.contains('soguk')) {
      return 'Soğuk tariflerde malzemeleri taze ve dengeli karıştırmak lezzeti artırır.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_recipe.steps.isEmpty ||
        (_recipe.steps.length == 1 &&
            _recipe.steps[0].description.contains('bulunamadı'))) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Pişirme Modu'),
          leading: BackButton(onPressed: () => context.pop()),
        ),
        body: const Center(child: Text('Adım bilgisi bulunamadı.')),
      );
    }

    final step = _recipe.steps[_currentStep];
    final total = _recipe.steps.length;
    final isFirst = _currentStep == 0;
    final isLast = _currentStep == total - 1;

    final scaledDescription = ServingScalerService.scaleQuantitiesInText(
      step.description,
      widget.servingMultiplier,
    );

    // Smart values
    final stepTitle = _generateShortTitle(scaledDescription);
    final heatVal = _extractHeat(scaledDescription);
    final actionVal = _extractAction(scaledDescription);
    final utensilVal = _extractUtensil(scaledDescription);
    final tipVal = _generateTip(stepTitle, scaledDescription);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? const Color(0xFF0F241E) : const Color(0xFFFAFBF9);
    final cardBg = isDark ? const Color(0xFF17332B) : Colors.white;
    final titleColor = isDark ? const Color(0xFFF3FFF9) : Colors.black87;
    final descColor = isDark
        ? const Color(0xFFC7D8D2)
        : Colors.black87.withValues(alpha: 0.7);

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: Column(
          children: [
            // 1. HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _circleBtn(
                    Icons.arrow_back_rounded,
                    () => context.pop(),
                    isDark,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _recipe.shownTitle,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: isDark
                            ? const Color(0xFFF3FFF9)
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(
                    width: 44,
                  ), // To balance the back button so title is centered
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
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildStepper(total),
                          const SizedBox(height: 24),

                          // 3. MAIN STEP CARD
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'ŞİMDİ',
                                              style: TextStyle(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            stepTitle,
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: titleColor,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            width: 40,
                                            height: 3,
                                            decoration: BoxDecoration(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Description
                                Text(
                                  scaledDescription,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: descColor,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // 3 Info Badges
                                Row(
                                  children: [
                                    Expanded(
                                      child: _infoBadge(
                                        Icons.local_fire_department_outlined,
                                        'Ateş seviyesi',
                                        heatVal,
                                        isDark,
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 30,
                                      color: isDark
                                          ? const Color(0xFF2B4A40)
                                          : Colors.grey.shade200,
                                    ),
                                    Expanded(
                                      child: _infoBadge(
                                        Icons.blender_outlined,
                                        'İşlem',
                                        actionVal,
                                        isDark,
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 30,
                                      color: isDark
                                          ? const Color(0xFF2B4A40)
                                          : Colors.grey.shade200,
                                    ),
                                    Expanded(
                                      child: _infoBadge(
                                        Icons.soup_kitchen_outlined,
                                        'Gereç',
                                        utensilVal,
                                        isDark,
                                      ),
                                    ),
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

                          // 7. STOP RECIPE / SHOW INGREDIENTS (Action Cards)
                          Row(
                            children: [
                              Expanded(
                                child: _actionCard(
                                  title: 'Malzemeler',
                                  subtitle: 'Tüm malzemeleri gör',
                                  icon: Icons.shopping_basket_outlined,
                                  iconColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  iconBgColor: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.1),
                                  onTap: _showIngredientsSheet,
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _actionCard(
                                  title: 'Tarifi Durdur',
                                  subtitle: 'Pişirme modunu kapat',
                                  icon: Icons.stop_rounded,
                                  iconColor: Colors.red,
                                  iconBgColor: Colors.red.withValues(
                                    alpha: 0.1,
                                  ),
                                  onTap: _showExitDialog,
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // 8. BOTTOM NAV BUTTONS
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: isFirst ? null : _prevStep,
                                  icon: const Icon(
                                    Icons.arrow_back_rounded,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'Önceki Adım',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: isDark
                                        ? const Color(0xFFF3FFF9)
                                        : Colors.black87,
                                    side: const BorderSide(
                                      color: Color(0xFF1B4D3E),
                                      width: 1.5,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    backgroundColor: isDark
                                        ? const Color(0xFF17332B)
                                        : Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _nextStep,
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: const Color(0xFF0D9B5E),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        isLast
                                            ? 'Tarifi Tamamla'
                                            : 'Sonraki Adım',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (!isLast) ...[
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 18,
                                        ),
                                      ],
                                    ],
                                  ),
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
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: isDone
                    ? Theme.of(context).colorScheme.primary
                    : (isActive ? Colors.white : const Color(0xFFF1F5F9)),
                shape: BoxShape.circle,
                border: isActive
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      )
                    : (isDone
                          ? null
                          : Border.all(color: Colors.grey.shade300, width: 1)),
              ),
              child: Center(
                child: isDone
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                    : Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: isActive
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade500,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
              ),
            ),
          );

          if (i < total - 1) {
            Widget line = Container(
              height: 2,
              color: (i < _currentStep)
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade200,
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

  Widget _infoBadge(IconData icon, String label, String value, bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? const Color(0xFFB7CCC5) : Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFF3FFF9) : Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _actionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E3A31) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? const Color(0xFFF3FFF9) : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark
                          ? const Color(0xFFB7CCC5)
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? const Color(0xFFB7CCC5) : Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF17332B) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isDark ? const Color(0xFFF3FFF9) : Colors.black87,
          size: 20,
        ),
      ),
    );
  }
}
