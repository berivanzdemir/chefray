import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/recipe_model.dart';
import '../../widgets/common/soft_card.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/mascot/ray_avatar.dart';
import '../../animations/confetti_effect.dart';

class CompletionScreen extends StatefulWidget {
  final RecipeModel? recipe;
  const CompletionScreen({super.key, this.recipe});

  @override
  State<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends State<CompletionScreen>
    with SingleTickerProviderStateMixin {
  late final RecipeModel _recipe;
  int _rating = 5;
  late final AnimationController _countCtrl;

  @override
  void initState() {
    super.initState();
    _recipe = widget.recipe ?? RecipeMockData.primary;
    _countCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }

  @override
  void dispose() {
    _countCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Confetti
          const Positioned.fill(child: IgnorePointer(child: ConfettiEffect())),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.go('/home'),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle,
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: const Icon(Icons.arrow_back_rounded, size: 20, color: AppColors.textDark),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle,
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: const Icon(Icons.ios_share_rounded, size: 20, color: AppColors.textDark),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),

                        // Hero area
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: double.infinity, height: 180,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('🐟🥦🍋', style: TextStyle(fontSize: 48)),
                                  const SizedBox(height: 8),
                                  Text('Afiyet Olsun! 🎉',
                                      style: AppTextStyles.h1.copyWith(fontSize: 26)),
                                ],
                              ),
                            ),
                            // Checkmark
                            Positioned(
                              bottom: -4, right: -4,
                              child: Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10)],
                                ),
                                child: const Icon(Icons.check_rounded, color: Colors.white, size: 24),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('${_recipe.displayTitle} tarifini\nbaşarıyla tamamladın.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(height: 1.4)),
                        const SizedBox(height: 20),

                        // Progress card
                        SoftCard(
                          hasGreenGlow: true,
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Calorie circle
                              AnimatedBuilder(
                                animation: _countCtrl,
                                builder: (context, child) {
                                  final v = (_countCtrl.value * _recipe.calories).round();
                                  return Container(
                                    width: 72, height: 72,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.primary, width: 4),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text('$v', style: AppTextStyles.h1.copyWith(fontSize: 22, color: AppColors.primary)),
                                        Text('kcal', style: AppTextStyles.labelSmall.copyWith(fontSize: 9, color: AppColors.primary)),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Harika iş çıkardın! 👏',
                                        style: AppTextStyles.h3.copyWith(fontSize: 14)),
                                    const SizedBox(height: 4),
                                    Text('Günlük hedefinin %20\'sini tamamladın.',
                                        style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
                                    const SizedBox(height: 8),
                                    // Progress bar
                                    AnimatedBuilder(
                                      animation: _countCtrl,
                                      builder: (context, child) => ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: 0.20 * _countCtrl.value,
                                          minHeight: 6,
                                          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                                          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('🔥 450 / 2250 kcal', style: AppTextStyles.labelSmall.copyWith(fontSize: 9)),
                                        Text('Kalan: 1800 kcal', style: AppTextStyles.labelSmall.copyWith(fontSize: 9)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('%20', style: AppTextStyles.h3.copyWith(color: AppColors.primary, fontSize: 16)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Macro summary row
                        Row(
                          children: [
                            _macroCard(Icons.fitness_center_rounded, '+${_recipe.protein}g', 'Protein', 'Hedefin %48\'i'),
                            const SizedBox(width: 8),
                            _macroCard(Icons.grain_rounded, '+${_recipe.carbs}g', 'Karbonhidrat', 'Hedefin %16\'sı'),
                            const SizedBox(width: 8),
                            _macroCard(Icons.water_drop_rounded, '+${_recipe.fat}g', 'Yağ', 'Hedefin %22\'si'),
                            const SizedBox(width: 8),
                            _macroCard(Icons.eco_rounded, '+8g', 'Lif', 'Hedefin %32\'si'),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // AI comment
                        SoftCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const RayAvatar(
                                size: 36,
                                imagePath: 'assets/mascot/ray_success.png',
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('ChefRay Yorumu',
                                        style: AppTextStyles.h3.copyWith(fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Bugünkü protein hedefin için harika bir seçim yaptın! 💪 Akşam için daha hafif ve sebze ağırlıklı bir öğün tercih edebilirsin.',
                                      style: AppTextStyles.bodySmall.copyWith(height: 1.4, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Rating
                        SoftCard(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            children: [
                              Text('Tarifi beğendin mi?',
                                  style: AppTextStyles.h3.copyWith(fontSize: 14)),
                              const SizedBox(height: 4),
                              Text('Deneyimini bizimle paylaş.',
                                  style: AppTextStyles.bodySmall),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(5, (i) => GestureDetector(
                                  onTap: () => setState(() => _rating = i + 1),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Icon(
                                      i < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                                      size: 36,
                                      color: i < _rating ? const Color(0xFFFFD54F) : AppColors.textHint,
                                    ),
                                  ),
                                )),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Quick actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _actionCol(Icons.bookmark_border_rounded, 'Favorilere Ekle'),
                            _actionCol(Icons.replay_rounded, 'Tekrar Yap'),
                            _actionCol(Icons.restaurant_rounded, 'Yemeğini Paylaş'),
                            _actionCol(Icons.shopping_cart_outlined, 'Alışveriş Listesine Ekle'),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Suggested recipes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Sana Önerilen Tarifler', style: AppTextStyles.h3.copyWith(fontSize: 14)),
                            GestureDetector(
                              onTap: () => context.push('/recipe-list'),
                              child: Text('Tümünü Gör',
                                  style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.primary, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 160,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _suggestedCard('🥗', 'Izgara Tavuklu\nKinoa Salatası', '420 kcal · 25 dk'),
                              _suggestedCard('🍲', 'Mercimek Çorbası\nve Avokado Tost', '380 kcal · 20 dk'),
                              _suggestedCard('🥩', 'Sebzeli Dana\nSote', '480 kcal · 30 dk'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Primary CTA
                        PrimaryButton(
                          text: 'Yeni Tarif Planla',
                          trailingIcon: Icons.restaurant_menu_rounded,
                          onPressed: () => context.push('/recipe-list'),
                        ),
                        const SizedBox(height: 12),
                        // Secondary
                        GestureDetector(
                          onTap: () => context.go('/home'),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.home_rounded, size: 18, color: AppColors.textMedium),
                              const SizedBox(width: 6),
                              Text('Ana Sayfaya Dön',
                                  style: AppTextStyles.labelMedium.copyWith(
                                      color: AppColors.textMedium, fontWeight: FontWeight.w600)),
                            ],
                          ),
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
    );
  }

  Widget _macroCard(IconData icon, String value, String label, String pct) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(value, style: AppTextStyles.h3.copyWith(fontSize: 14)),
            Text(label, style: AppTextStyles.labelSmall.copyWith(fontSize: 8), textAlign: TextAlign.center),
            const SizedBox(height: 2),
            Text(pct, style: AppTextStyles.labelSmall.copyWith(fontSize: 8, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }

  Widget _actionCol(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
          ),
          child: Icon(icon, size: 20, color: AppColors.textMedium),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 70,
          child: Text(label, textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall.copyWith(fontSize: 9)),
        ),
      ],
    );
  }

  Widget _suggestedCard(String emoji, String title, String info) {
    return Container(
      width: 140, margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity, height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Stack(
              children: [
                Center(child: Text(emoji, style: const TextStyle(fontSize: 36))),
                Positioned(
                  top: 6, right: 6,
                  child: Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.bookmark_border_rounded, size: 12, color: AppColors.textLight),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelMedium.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                const SizedBox(height: 4),
                Text(info, style: AppTextStyles.labelSmall.copyWith(fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
