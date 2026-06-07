import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/common/primary_button.dart';
import '../../models/user_health_profile.dart';
import 'widgets/option_card.dart';

class HealthProfileScreen extends StatefulWidget {
  const HealthProfileScreen({super.key});

  @override
  State<HealthProfileScreen> createState() => _HealthProfileScreenState();
}

class _HealthProfileScreenState extends State<HealthProfileScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  static const int _totalSteps = 9;

  // ── Controllers ──────────────────────────────────────────────────
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  // ── Answers ──────────────────────────────────────────────────────
  String? _gender;
  String? _goalType;
  final Set<String> _healthConditions = {};
  final Set<String> _allergies = {};
  String? _dietPreferences;
  String? _activityLevel;

  // ── Animation ────────────────────────────────────────────────────
  late final AnimationController _entryFadeCtrl;
  late final AnimationController _entrySlideCtrl;
  late final Animation<double> _entryFadeAnim;
  late final Animation<Offset> _entrySlideAnim;

  // ── Step transition ──────────────────────────────────────────────
  final _stepDirection = ValueNotifier<int>(1); // 1 = forward, -1 = backward

  @override
  void initState() {
    super.initState();
    _entryFadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _entrySlideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entryFadeAnim = CurvedAnimation(
      parent: _entryFadeCtrl,
      curve: Curves.easeOut,
    );
    _entrySlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entrySlideCtrl, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _entryFadeCtrl.forward();
        _entrySlideCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _entryFadeCtrl.dispose();
    _entrySlideCtrl.dispose();
    _stepDirection.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  // ── Validation ───────────────────────────────────────────────────

  bool _isCurrentStepValid() {
    switch (_currentStep) {
      case 0:
        final age = int.tryParse(_ageCtrl.text);
        return age != null && age > 0 && age < 120;
      case 1:
        return _gender != null;
      case 2:
        final h = double.tryParse(_heightCtrl.text);
        return h != null && h > 50 && h < 300;
      case 3:
        final w = double.tryParse(_weightCtrl.text);
        return w != null && w > 20 && w < 500;
      case 4:
        return _goalType != null;
      case 5:
        return true; // optional
      case 6:
        return true; // optional
      case 7:
        return _dietPreferences != null;
      case 8:
        return _activityLevel != null;
      default:
        return false;
    }
  }

  void _goNext() {
    if (!_isCurrentStepValid()) {
      _showErrorSnackbar('Lütfen geçerli bir cevap seçin.');
      return;
    }
    if (_currentStep < _totalSteps - 1) {
      _stepDirection.value = 1;
      setState(() => _currentStep++);
    } else {
      _submitProfile();
    }
  }

  void _goBack() {
    if (_currentStep > 0) {
      _stepDirection.value = -1;
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  void _submitProfile() {
    final profile = UserHealthProfile(
      age: int.tryParse(_ageCtrl.text),
      gender: _gender,
      heightCm: double.tryParse(_heightCtrl.text),
      weightKg: double.tryParse(_weightCtrl.text),
      goalType: _goalType,
      healthConditions: _healthConditions.toList(),
      allergies: _allergies.toList(),
      dietPreferences: _dietPreferences != null ? [_dietPreferences!] : [],
      activityLevel: _activityLevel,
    );

    _showSuccessSnackbar('Beslenme profilin oluşturuldu!');
    context.pop(profile);
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.error.withValues(alpha: 0.92),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.success.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Multi-select toggle ──────────────────────────────────────────

  void _toggleMulti(String value, Set<String> targetSet, {String? noneKey}) {
    setState(() {
      if (value == noneKey) {
        targetSet.clear();
        targetSet.add(value);
      } else {
        targetSet.remove(noneKey);
        if (targetSet.contains(value)) {
          targetSet.remove(value);
        } else {
          targetSet.add(value);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.splashGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _entryFadeAnim,
            child: SlideTransition(
              position: _entrySlideAnim,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // ── Top bar: back + progress ──────────────────
                    _TopBar(
                      currentStep: _currentStep,
                      totalSteps: _totalSteps,
                      onBack: _goBack,
                    ),
                    const SizedBox(height: 36),

                    // ── Step content ──────────────────────────────
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          final offset = Tween<Offset>(
                            begin: Offset(_stepDirection.value * 0.1, 0),
                            end: Offset.zero,
                          ).animate(animation);
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: offset,
                              child: child,
                            ),
                          );
                        },
                        child: _buildStepContent(key: ValueKey(_currentStep)),
                      ),
                    ),

                    // ── Bottom buttons ────────────────────────────
                    _BottomNav(
                      canGoBack: _currentStep > 0,
                      isLastStep: _currentStep == _totalSteps - 1,
                      isValid: _isCurrentStepValid(),
                      onBack: _goBack,
                      onNext: _goNext,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Step content builder ──────────────────────────────────────────

  Widget _buildStepContent({Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            switch (_currentStep) {
              0 => _buildAgeStep(),
              1 => _buildGenderStep(),
              2 => _buildHeightStep(),
              3 => _buildWeightStep(),
              4 => _buildNutritionGoalStep(),
              5 => _buildHealthConditionsStep(),
              6 => _buildAllergiesStep(),
              7 => _buildDietPreferenceStep(),
              8 => _buildActivityLevelStep(),
              _ => const SizedBox(),
            },
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Step 0: Age ──────────────────────────────────────────────────

  Widget _buildAgeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kaç yaşındasın?', style: AppTextStyles.displayMedium),
        const SizedBox(height: 8),
        Text(
          'Yaşına uygun kalori ve besin hedefleri belirleyelim.',
          style: AppTextStyles.bodyLarge.copyWith(height: 1.5),
        ),
        const SizedBox(height: 40),
        _NumberInput(
          controller: _ageCtrl,
          unit: 'yaş',
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  // ── Step 1: Gender ───────────────────────────────────────────────

  Widget _buildGenderStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cinsiyetin nedir?', style: AppTextStyles.displayMedium),
        const SizedBox(height: 8),
        Text(
          'Metabolizma hızın ve besin ihtiyaçların için gerekli.',
          style: AppTextStyles.bodyLarge.copyWith(height: 1.5),
        ),
        const SizedBox(height: 36),
        Row(
          children: [
            Expanded(
              child: _GenderCard(
                icon: Icons.female_rounded,
                label: 'Kadın',
                isSelected: _gender == 'female',
                onTap: () => setState(() => _gender = 'female'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _GenderCard(
                icon: Icons.male_rounded,
                label: 'Erkek',
                isSelected: _gender == 'male',
                onTap: () => setState(() => _gender = 'male'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Step 2: Height ───────────────────────────────────────────────

  Widget _buildHeightStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Boyun kaç cm?', style: AppTextStyles.displayMedium),
        const SizedBox(height: 8),
        Text(
          'Bazal metabolizma hızını doğru hesaplamak için önemli.',
          style: AppTextStyles.bodyLarge.copyWith(height: 1.5),
        ),
        const SizedBox(height: 40),
        _NumberInput(
          controller: _heightCtrl,
          unit: 'cm',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  // ── Step 3: Weight ───────────────────────────────────────────────

  Widget _buildWeightStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kilon kaç kg?', style: AppTextStyles.displayMedium),
        const SizedBox(height: 8),
        Text(
          'Günlük kalori ihtiyacını ve ideal porsiyonlarını belirleyelim.',
          style: AppTextStyles.bodyLarge.copyWith(height: 1.5),
        ),
        const SizedBox(height: 40),
        _NumberInput(
          controller: _weightCtrl,
          unit: 'kg',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  // ── Step 4: Nutrition Goal ───────────────────────────────────────

  Widget _buildNutritionGoalStep() {
    const goals = [
      (
        icon: Icons.trending_down_rounded,
        title: 'Kilo Vermek',
        subtitle: 'Kalori açığı odaklı tarifler',
        value: 'lose_weight',
      ),
      (
        icon: Icons.balance_rounded,
        title: 'Kilo Korumak',
        subtitle: 'Dengeli ve sürdürülebilir beslenme',
        value: 'maintain',
      ),
      (
        icon: Icons.fitness_center_rounded,
        title: 'Kas Yapmak',
        subtitle: 'Yüksek proteinli tarifler',
        value: 'gain_muscle',
      ),
      (
        icon: Icons.favorite_border_rounded,
        title: 'Daha Sağlıklı Beslenmek',
        subtitle: 'Genel sağlık ve enerji için',
        value: 'improve_health',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Beslenme hedefin ne?', style: AppTextStyles.displayMedium),
        const SizedBox(height: 8),
        Text(
          'Hedefine göre tarifleri ve porsiyonları kişiselleştirelim.',
          style: AppTextStyles.bodyLarge.copyWith(height: 1.5),
        ),
        const SizedBox(height: 32),
        ...goals.map(
          (g) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OptionCard(
              icon: g.icon,
              title: g.title,
              subtitle: g.subtitle,
              isSelected: _goalType == g.value,
              onTap: () => setState(() => _goalType = g.value),
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 5: Health Conditions ────────────────────────────────────

  Widget _buildHealthConditionsStep() {
    const conditions = [
      ('Diyabet', 'diabetes'),
      ('Hipertansiyon', 'hypertension'),
      ('Tiroid', 'thyroid'),
      ('Çölyak', 'celiac'),
      ('Kolesterol', 'cholesterol'),
      ('Kalp Rahatsızlığı', 'heart_disease'),
      ('Böbrek Rahatsızlığı', 'kidney_disease'),
      ('Hiçbiri', 'none'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Herhangi bir sağlık\nsorunun var mı?',
          style: AppTextStyles.displayMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Varsa seç, tariflerini buna göre filtreleyelim. Birden fazla seçebilirsin.',
          style: AppTextStyles.bodyLarge.copyWith(height: 1.5),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: conditions.map((c) {
            final selected = _healthConditions.contains(c.$2);
            return _ChipToggle(
              label: c.$1,
              isSelected: selected,
              onTap: () =>
                  _toggleMulti(c.$2, _healthConditions, noneKey: 'none'),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Step 6: Allergies ────────────────────────────────────────────

  Widget _buildAllergiesStep() {
    const allergies = [
      ('Süt / Laktoz', 'dairy'),
      ('Yumurta', 'egg'),
      ('Gluten', 'gluten'),
      ('Kuruyemiş', 'nuts'),
      ('Deniz Ürünleri', 'seafood'),
      ('Soya', 'soy'),
      ('Hiçbiri', 'none'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Alerjin var mı?', style: AppTextStyles.displayMedium),
        const SizedBox(height: 8),
        Text(
          'Alerjenleri tariflerden çıkaralım ki güvenle yiyebilesin.',
          style: AppTextStyles.bodyLarge.copyWith(height: 1.5),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: allergies.map((a) {
            final selected = _allergies.contains(a.$2);
            return _ChipToggle(
              label: a.$1,
              isSelected: selected,
              onTap: () => _toggleMulti(a.$2, _allergies, noneKey: 'none'),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Step 7: Diet Preference ──────────────────────────────────────

  Widget _buildDietPreferenceStep() {
    const diets = [
      (
        icon: Icons.restaurant_menu_rounded,
        title: 'Hepçil',
        subtitle: 'Her şeyi yerim',
        value: 'omnivore',
      ),
      (
        icon: Icons.eco_rounded,
        title: 'Vejetaryen',
        subtitle: 'Et yok, süt/ yumurta var',
        value: 'vegetarian',
      ),
      (
        icon: Icons.spa_rounded,
        title: 'Vegan',
        subtitle: 'Hiçbir hayvansal ürün',
        value: 'vegan',
      ),
      (
        icon: Icons.waves_rounded,
        title: 'Pesketaryen',
        subtitle: 'Balık var, et yok',
        value: 'pescatarian',
      ),
      (
        icon: Icons.egg_rounded,
        title: 'Ketojenik',
        subtitle: 'Düşük karbonhidrat, yüksek yağ',
        value: 'keto',
      ),
      (
        icon: Icons.wb_sunny_rounded,
        title: 'Akdeniz',
        subtitle: 'Zeytinyağlı, sebze ağırlıklı',
        value: 'mediterranean',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Beslenme tercihin\nnedir?', style: AppTextStyles.displayMedium),
        const SizedBox(height: 8),
        Text(
          'Sana en uygun tarifleri seçebilmemiz için.',
          style: AppTextStyles.bodyLarge.copyWith(height: 1.5),
        ),
        const SizedBox(height: 28),
        ...diets.map(
          (d) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OptionCard(
              icon: d.icon,
              title: d.title,
              subtitle: d.subtitle,
              isSelected: _dietPreferences == d.value,
              onTap: () => setState(() => _dietPreferences = d.value),
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 8: Activity Level ───────────────────────────────────────

  Widget _buildActivityLevelStep() {
    const levels = [
      (
        icon: Icons.weekend_rounded,
        title: 'Hareketsiz',
        subtitle: 'Masa başı iş, az hareket',
        value: 'sedentary',
      ),
      (
        icon: Icons.directions_walk_rounded,
        title: 'Hafif Aktif',
        subtitle: 'Haftada 1-2 gün hafif egzersiz',
        value: 'light',
      ),
      (
        icon: Icons.run_circle_rounded,
        title: 'Orta Derece Aktif',
        subtitle: 'Haftada 3-5 gün egzersiz',
        value: 'moderate',
      ),
      (
        icon: Icons.fitness_center_rounded,
        title: 'Çok Aktif',
        subtitle: 'Haftada 6-7 gün yoğun egzersiz',
        value: 'very_active',
      ),
      (
        icon: Icons.emoji_events_rounded,
        title: 'Sporcu',
        subtitle: 'Günde 2 kez yoğun antrenman',
        value: 'athlete',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Aktivite seviyen\nnedir?', style: AppTextStyles.displayMedium),
        const SizedBox(height: 8),
        Text(
          'Günlük kalori ihtiyacını hesaplamak için son adım.',
          style: AppTextStyles.bodyLarge.copyWith(height: 1.5),
        ),
        const SizedBox(height: 28),
        ...levels.map(
          (l) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OptionCard(
              icon: l.icon,
              title: l.title,
              subtitle: l.subtitle,
              isSelected: _activityLevel == l.value,
              onTap: () => setState(() => _activityLevel = l.value),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Internal sub-widgets
// ═══════════════════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback onBack;

  const _TopBar({
    required this.currentStep,
    required this.totalSteps,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── Back button ──────────────────────────────────────────
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: AppColors.textDark,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // ── Step label ───────────────────────────────────────────
        Text(
          'Adım ${currentStep + 1} / $totalSteps',
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textLight),
        ),
        const SizedBox(width: 12),
        // ── Progress bar ─────────────────────────────────────────
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: AnimatedLinearProgress(
              value: (currentStep + 1) / totalSteps,
            ),
          ),
        ),
      ],
    );
  }
}

class AnimatedLinearProgress extends StatelessWidget {
  final double value;
  const AnimatedLinearProgress({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              height: 4,
              width: constraints.maxWidth * value,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BottomNav extends StatelessWidget {
  final bool canGoBack;
  final bool isLastStep;
  final bool isValid;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _BottomNav({
    required this.canGoBack,
    required this.isLastStep,
    required this.isValid,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          if (canGoBack) ...[
            Expanded(
              child: PrimaryButton(
                text: 'Geri',
                onPressed: onBack,
                outlined: true,
                height: 52,
              ),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: PrimaryButton(
              text: isLastStep ? 'Profili Tamamla' : 'Devam',
              onPressed: isValid ? onNext : null,
              trailingIcon: isLastStep
                  ? Icons.check_rounded
                  : Icons.arrow_forward_rounded,
              height: 52,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Number input with unit ────────────────────────────────────────────

class _NumberInput extends StatelessWidget {
  final TextEditingController controller;
  final String unit;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;

  const _NumberInput({
    required this.controller,
    required this.unit,
    required this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              textAlign: TextAlign.center,
              style: AppTextStyles.calorie.copyWith(fontSize: 32),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: '--',
                hintStyle: AppTextStyles.calorie.copyWith(
                  fontSize: 32,
                  color: AppColors.textHint,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.backgroundMint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              unit,
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Gender card (vertical layout for 2 options) ──────────────────────

class _GenderCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 6),
                spreadRadius: -4,
              )
            else
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.backgroundMint,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28,
                color: isSelected ? AppColors.primary : AppColors.textLight,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              label,
              style: AppTextStyles.labelLarge.copyWith(
                color: isSelected ? AppColors.textDark : AppColors.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Multi-select chip toggle ─────────────────────────────────────────

class _ChipToggle extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChipToggle({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textMedium,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
