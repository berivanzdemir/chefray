import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/health_profile_setup_provider.dart';

import 'widgets/setup_progress_bar.dart';
import 'widgets/setup_option_card.dart';
import 'widgets/setup_multi_select_chip.dart';
import 'widgets/setup_navigation_buttons.dart';

import '../../models/user_health_profile.dart';

class HealthProfileSetupScreen extends StatefulWidget {
  final bool isEditMode;
  final UserHealthProfile? existingProfile;

  const HealthProfileSetupScreen({
    super.key,
    this.isEditMode = false,
    this.existingProfile,
  });

  @override
  State<HealthProfileSetupScreen> createState() =>
      _HealthProfileSetupScreenState();
}

class _HealthProfileSetupScreenState extends State<HealthProfileSetupScreen>
    with TickerProviderStateMixin {
  final _provider = HealthProfileSetupProvider();
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  late final AnimationController _fadeCtrl;
  late final AnimationController _slideCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  final _stepDirection = ValueNotifier<int>(1);

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _fadeCtrl.forward();
        _slideCtrl.forward();
      }
    });

    if (widget.isEditMode && widget.existingProfile != null) {
      _provider.initializeForEdit(widget.existingProfile!);
      if (widget.existingProfile!.age != null)
        _ageCtrl.text = widget.existingProfile!.age.toString();
      if (widget.existingProfile!.heightCm != null)
        _heightCtrl.text = widget.existingProfile!.heightCm.toString();
      if (widget.existingProfile!.weightKg != null)
        _weightCtrl.text = widget.existingProfile!.weightKg.toString();
    }

    _ageCtrl.addListener(() => _provider.setAge(_ageCtrl.text));
    _heightCtrl.addListener(() => _provider.setHeight(_heightCtrl.text));
    _weightCtrl.addListener(() => _provider.setWeight(_weightCtrl.text));
    _provider.addListener(_onProviderChanged);
  }

  void _onProviderChanged() {
    if (_provider.errorMessage != null) {
      _showErrorSnackbar(_provider.errorMessage!);
      _provider.errorMessage = null;
    }
    // CRITICAL: rebuild UI so buttons, step content, and validation update.
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _stepDirection.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _provider.removeListener(_onProviderChanged);
    _provider.dispose();
    super.dispose();
  }

  void _goNext() {
    final msg = _provider.validateCurrentStepMessage();
    if (msg != null) {
      _showErrorSnackbar(msg);
      return;
    }
    if (_provider.currentStep < HealthProfileSetupProvider.totalSteps - 1) {
      _stepDirection.value = 1;
      _provider.nextStep();
    } else {
      _handleSubmit();
    }
  }

  void _goBack() {
    if (_provider.currentStep > 0) {
      _stepDirection.value = -1;
      _provider.previousStep();
    }
  }

  Future<void> _handleSubmit() async {
    final success = await _provider.submit();
    if (!mounted) return;
    if (success) {
      if (widget.isEditMode) {
        context.pop(true);
      } else {
        context.go('/home');
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.splashGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildTopBar(),
                    const SizedBox(height: 20),
                    _buildHeaderCard(),
                    const SizedBox(height: 20),
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
                        child: _buildQuestionCard(
                          key: ValueKey(_provider.currentStep),
                        ),
                      ),
                    ),
                    SetupNavigationButtons(
                      isEditMode: widget.isEditMode,
                      canGoBack: _provider.currentStep > 0,
                      isLastStep:
                          _provider.currentStep ==
                          HealthProfileSetupProvider.totalSteps - 1,
                      isValid: _provider.validateCurrentStep(),
                      isLoading: _provider.isLoading,
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

  // ── Top bar ──────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: _goBack,
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
        Text(
          'Adım ${_provider.currentStep + 1} / ${HealthProfileSetupProvider.totalSteps}',
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textLight),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SetupProgressBar(
            currentStep: _provider.currentStep,
            totalSteps: HealthProfileSetupProvider.totalSteps,
          ),
        ),
      ],
    );
  }

  // ── Header card ──────────────────────────────────────────────────────

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Image.asset(
                'assets/mascot/ray_default.png',
                width: 32,
                height: 32,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.restaurant_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seni Tanıyalım',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Birkaç bilgiyle sana daha uygun tarifler önereceğiz.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMedium,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Question card ────────────────────────────────────────────────────

  Widget _buildQuestionCard({Key? key}) {
    return SingleChildScrollView(
      key: key,
      physics: const BouncingScrollPhysics(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            switch (_provider.currentStep) {
              0 => _buildAgeStep(),
              1 => _buildGenderStep(),
              2 => _buildHeightStep(),
              3 => _buildWeightStep(),
              4 => _buildGoalTypeStep(),
              5 => _buildHealthConditionsStep(),
              6 => _buildAllergiesStep(),
              7 => _buildDietPreferencesStep(),
              8 => _buildActivityLevelStep(),
              9 => _buildSummaryStep(),
              _ => const SizedBox(),
            },
            const SizedBox(height: 24),
            _buildRayInfoNote(),
          ],
        ),
      ),
    );
  }

  // ── Ray info note ────────────────────────────────────────────────────

  Widget _buildRayInfoNote() {
    String noteText =
        'Bu bilgiler sadece önerileri kişiselleştirmek için kullanılır. ChefRay verilerini üçüncü taraflarla paylaşmaz.';
    if (_provider.currentStep == 0) {
      noteText =
          'Ray, yaş bilgini kalori ve öğün önerilerini kişiselleştirmek için kullanır.';
    } else if (_provider.currentStep == 2) {
      noteText =
          'Boy ve kilo bilgilerini birlikte değerlendirerek daha isabetli öneriler sunabiliriz.';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFFF5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            'assets/mascot/ray_default.png',
            width: 24,
            height: 24,
            errorBuilder: (_, _, _) => const Icon(
              Icons.info_outline_rounded,
              size: 20,
              color: Color(0xFF008F4C),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              noteText,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF5F7373),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // Steps
  // ══════════════════════════════════════════════════════════════════════

  // ── Step 0: Age ──────────────────────────────────────────────────────

  Widget _buildAgeStep() {
    return _StepQuestion(
      title: 'Kaç yaşındasın?',
      subtitle:
          'Yaş bilgisi günlük ihtiyaçlarını ve tarif önerilerini daha doğru kişiselleştirmemize yardımcı olur.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NumberInput(
            controller: _ageCtrl,
            unit: 'yaş',
            hint: '22',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),
          const Text(
            'Bu bilgiyi daha sonra profilinden değiştirebilirsin.',
            style: TextStyle(fontSize: 12, color: Color(0xFF5F7373)),
          ),
        ],
      ),
    );
  }

  // ── Step 1: Gender ───────────────────────────────────────────────────

  Widget _buildGenderStep() {
    return _StepQuestion(
      title: 'Cinsiyetini seç',
      subtitle:
          'Bu bilgi beslenme ihtiyaçlarını daha dengeli yorumlamamıza yardımcı olur.',
      child: Column(
        children: [
          SetupOptionCard(
            icon: Icons.female_rounded,
            title: 'Kadın',
            isSelected: _provider.gender == 'Kadın',
            onTap: () => _provider.setGender('Kadın'),
          ),
          const SizedBox(height: 12),
          SetupOptionCard(
            icon: Icons.male_rounded,
            title: 'Erkek',
            isSelected: _provider.gender == 'Erkek',
            onTap: () => _provider.setGender('Erkek'),
          ),
          const SizedBox(height: 12),
          SetupOptionCard(
            icon: Icons.help_outline_rounded,
            title: 'Belirtmek istemiyorum',
            isSelected: _provider.gender == 'Belirtmek istemiyorum',
            onTap: () => _provider.setGender('Belirtmek istemiyorum'),
          ),
        ],
      ),
    );
  }

  // ── Step 2: Height ───────────────────────────────────────────────────

  Widget _buildHeightStep() {
    return _StepQuestion(
      title: 'Boyun kaç cm?',
      subtitle: 'Boy bilgisi hedef ve öneri hesaplamalarında kullanılır.',
      child: _NumberInput(
        controller: _heightCtrl,
        unit: 'cm',
        hint: '170',
        keyboardType: const TextInputType.numberWithOptions(decimal: false),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      ),
    );
  }

  // ── Step 3: Weight ───────────────────────────────────────────────────

  Widget _buildWeightStep() {
    return _StepQuestion(
      title: 'Kilon kaç kg?',
      subtitle:
          'Kilo bilgisi günlük enerji ihtiyacını daha doğru hesaplamamıza yardımcı olur.',
      child: _NumberInput(
        controller: _weightCtrl,
        unit: 'kg',
        hint: '70',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
      ),
    );
  }

  // ── Step 4: Goal type ────────────────────────────────────────────────

  Widget _buildGoalTypeStep() {
    const goals = [
      (
        Icons.trending_down_rounded,
        'Kilo vermek',
        'Daha hafif ve dengeli öğünler önerelim.',
      ),
      (
        Icons.balance_rounded,
        'Kilo korumak',
        'Günlük dengen için uygun tarifler sunalım.',
      ),
      (
        Icons.fitness_center_rounded,
        'Kas kazanmak',
        'Protein ağırlıklı öneriler hazırlayalım.',
      ),
      (
        Icons.restaurant_menu_rounded,
        'Daha dengeli beslenmek',
        'Öğünlerini daha dengeli planlayalım.',
      ),
      (
        Icons.explore_rounded,
        'Sağlıklı tarifler keşfetmek',
        'Yeni ve sağlıklı tarifleri öne çıkaralım.',
      ),
    ];

    return _StepQuestion(
      title: 'ChefRay\'i hangi hedef için\nkullanmak istiyorsun?',
      subtitle: 'Hedefine göre tarifleri ve porsiyonları kişiselleştirelim.',
      child: Column(
        children: goals.map((g) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SetupOptionCard(
              icon: g.$1,
              title: g.$2,
              subtitle: g.$3,
              isSelected: _provider.goalType == g.$2,
              onTap: () => _provider.setGoalType(g.$2),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Step 5: Health conditions ────────────────────────────────────────

  Widget _buildHealthConditionsStep() {
    const conditions = [
      'Diyabet',
      'Tansiyon',
      'Kolesterol',
      'Tiroid',
      'İnsülin direnci',
      'Sindirim hassasiyeti',
      'Yok',
      'Belirtmek istemiyorum',
    ];

    return _StepQuestion(
      title: 'Dikkate almamızı istediğin\nbir sağlık durumun var mı?',
      subtitle: 'Varsa seç, tariflerini buna göre filtreleyelim.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: conditions.map((c) {
              return SetupMultiSelectChip(
                label: c,
                isSelected: _provider.healthConditions.contains(c),
                onTap: () => _provider.toggleHealthCondition(c),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8F3ED)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 20,
                  color: Color(0xFF5F7373),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ChefRay tıbbi tanı koymaz veya tedavi önermez. Bu bilgiler yalnızca genel beslenme önerilerini kişiselleştirmek için kullanılır.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF5F7373),
                      height: 1.5,
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

  // ── Step 6: Allergies ────────────────────────────────────────────────

  Widget _buildAllergiesStep() {
    const allergies = [
      'Gluten',
      'Laktoz',
      'Kuruyemiş',
      'Deniz ürünü',
      'Yumurta',
      'Soya',
      'Yok',
    ];

    return _StepQuestion(
      title: 'Alerjin veya kaçındığın\nbesinler var mı?',
      subtitle:
          'Tarif önerilerinde riskli içerikleri filtrelemek için kullanılır.',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: allergies.map((a) {
          return SetupMultiSelectChip(
            label: a,
            isSelected: _provider.allergies.contains(a),
            onTap: () => _provider.toggleAllergy(a),
          );
        }).toList(),
      ),
    );
  }

  // ── Step 7: Diet preferences ─────────────────────────────────────────

  Widget _buildDietPreferencesStep() {
    const diets = [
      'Normal',
      'Vejetaryen',
      'Vegan',
      'Glutensiz',
      'Laktozsuz',
      'Düşük karbonhidrat',
      'Yüksek protein',
    ];

    return _StepQuestion(
      title: 'Beslenme tercihin nedir?',
      subtitle: 'Tarifleri yaşam tarzına daha uygun hale getirelim.',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: diets.map((d) {
          return SetupMultiSelectChip(
            label: d,
            isSelected: _provider.dietPreferences.contains(d),
            onTap: () => _provider.toggleDietPreference(d),
          );
        }).toList(),
      ),
    );
  }

  // ── Step 8: Activity level ───────────────────────────────────────────

  Widget _buildActivityLevelStep() {
    const levels = [
      (Icons.weekend_rounded, 'Düşük', 'Günün çoğu oturarak geçiyor.'),
      (
        Icons.directions_walk_rounded,
        'Orta',
        'Haftada birkaç kez hareket ediyorsun.',
      ),
      (Icons.run_circle_rounded, 'Yüksek', 'Düzenli egzersiz yapıyorsun.'),
      (
        Icons.fitness_center_rounded,
        'Çok aktif',
        'Yoğun fiziksel aktiviten var.',
      ),
    ];

    return _StepQuestion(
      title: 'Günlük aktivite seviyen nasıl?',
      subtitle: 'Hareket düzeyin günlük enerji ihtiyacını etkiler.',
      child: Column(
        children: levels.map((l) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SetupOptionCard(
              icon: l.$1,
              title: l.$2,
              subtitle: l.$3,
              isSelected: _provider.activityLevel == l.$2,
              onTap: () => _provider.setActivityLevel(l.$2),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Step 9: Summary ──────────────────────────────────────────────────

  Widget _buildSummaryStep() {
    return _StepQuestion(
      title: 'Profilin Hazır',
      subtitle: 'Seçimlerini kaydedip ChefRay\'i kişiselleştirelim.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8F3ED)),
            ),
            child: Column(
              children: [
                _SummaryRow(label: 'Yaş', value: '${_provider.age}'),
                const Divider(color: Color(0xFFE8F3ED), height: 16),
                _SummaryRow(label: 'Cinsiyet', value: _provider.gender ?? '-'),
                const Divider(color: Color(0xFFE8F3ED), height: 16),
                _SummaryRow(
                  label: 'Boy',
                  value: '${_provider.heightCm?.toInt()} cm',
                ),
                const Divider(color: Color(0xFFE8F3ED), height: 16),
                _SummaryRow(label: 'Kilo', value: '${_provider.weightKg} kg'),
                const Divider(color: Color(0xFFE8F3ED), height: 16),
                _SummaryRow(label: 'Hedef', value: _provider.goalType ?? '-'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFFFF5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/mascot/ray_default.png',
                  width: 24,
                  height: 24,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 20,
                    color: Color(0xFF008F4C),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Harika! Bu bilgilerle tarif önerilerini çok daha kişisel hale getireceğim.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF5F7373),
                      height: 1.5,
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
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Color(0xFF5F7373)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF102B2B),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// Internal sub-widgets
// ══════════════════════════════════════════════════════════════════════════

class _StepQuestion extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _StepQuestion({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF102B2B),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF5F7373),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        child,
      ],
    );
  }
}

class _NumberInput extends StatelessWidget {
  final TextEditingController controller;
  final String unit;
  final String hint;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _NumberInput({
    required this.controller,
    required this.unit,
    required this.hint,
    required this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8F7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8F3ED)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: Color(0xFF102B2B),
              ),
              inputFormatters: inputFormatters,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: Color(0xFF8A9B9B),
                  fontSize: 32,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFFFF5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              unit,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF008F4C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
