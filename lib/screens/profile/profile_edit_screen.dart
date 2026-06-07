import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/common/soft_card.dart';
import '../../widgets/common/primary_button.dart';
import '../../models/user_health_profile.dart';
import '../../repositories/user_health_profile_repository.dart';
import '../../providers/user_profile_provider.dart';

/// Standalone profile edit screen — NOT the onboarding "Seni Tanıyalım" flow.
/// Loads existing profile data and allows editing in a single scrollable form.
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseClient _client = Supabase.instance.client;

  // Basic profile
  final _nameCtrl = TextEditingController();

  // Health profile fields
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  String? _gender;
  String? _goalType;
  String? _activityLevel;
  final Set<String> _healthConditions = {};
  final Set<String> _allergies = {};
  final Set<String> _dietPreferences = {};

  bool _isSaving = false;
  bool _isLoading = true;

  // ── Options ────────────────────────────────────────────────────────────

  static const _genderOptions = ['Erkek', 'Kadın', 'Diğer'];
  static const _goalOptions = [
    'Kilo vermek',
    'Kilo korumak',
    'Kas kazanmak',
    'Daha dengeli beslenmek',
    'Sağlıklı tarifler keşfetmek',
  ];
  static const _activityOptions = [
    'Düşük',
    'Orta',
    'Yüksek',
    'Çok aktif',
  ];
  static const _healthConditionOptions = [
    'Diyabet',
    'Tansiyon',
    'Kolesterol',
    'Tiroid',
    'İnsülin direnci',
    'Sindirim hassasiyeti',
    'Yok',
    'Belirtmek istemiyorum',
  ];
  static const _allergyOptions = [
    'Gluten',
    'Laktoz',
    'Kuruyemiş',
    'Deniz ürünü',
    'Yumurta',
    'Soya',
    'Yok',
  ];
  static const _dietPrefOptions = [
    'Normal',
    'Vejetaryen',
    'Vegan',
    'Glutensiz',
    'Laktozsuz',
    'Düşük karbonhidrat',
    'Yüksek protein',
  ];

  // ── Lifecycle ──────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      // Load basic profile
      final profile = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (profile != null && mounted) {
        _nameCtrl.text = (profile['full_name'] as String?) ??
            (user.userMetadata?['full_name'] as String?) ??
            '';
      }

      // Load health profile
      final hp =
          await UserHealthProfileRepository.instance.getCurrentUserHealthProfile();
      if (hp != null && mounted) {
        _ageCtrl.text = hp.age?.toString() ?? '';
        _heightCtrl.text = hp.heightCm?.toString() ?? '';
        _weightCtrl.text = hp.weightKg?.toString() ?? '';
        _gender = hp.gender;
        _goalType = hp.goalType;
        _activityLevel = hp.activityLevel;
        _healthConditions.addAll(hp.healthConditions);
        _allergies.addAll(hp.allergies);
        _dietPreferences.addAll(hp.dietPreferences);
      }
    } catch (e) {
      debugPrint('ProfileEditScreen load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  // ── Save ───────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      // Update basic profile name
      if (_nameCtrl.text.trim().isNotEmpty) {
        await _client.from('profiles').upsert({
          'id': user.id,
          'full_name': _nameCtrl.text.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'id');
      }

      // Update health profile
      final hp = UserHealthProfile(
        userId: user.id,
        age: int.tryParse(_ageCtrl.text),
        gender: _gender,
        heightCm: double.tryParse(_heightCtrl.text),
        weightKg: double.tryParse(_weightCtrl.text),
        goalType: _goalType,
        healthConditions: _healthConditions.toList(),
        allergies: _allergies.toList(),
        dietPreferences: _dietPreferences.toList(),
        activityLevel: _activityLevel,
        updatedAt: DateTime.now(),
      );
      await UserHealthProfileRepository.instance.upsertCurrentUserHealthProfile(hp);

      if (mounted) {
        // Refresh provider
        context.read<UserProfileProvider>().refreshAll();
        _showSuccess();
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) context.pop();
      }
    } catch (e) {
      debugPrint('ProfileEditScreen save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kaydetme sırasında bir hata oluştu.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.surface),
            const SizedBox(width: 10),
            const Text('Profil güncellendi!'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  // ── Toggle helpers ─────────────────────────────────────────────────────

  void _toggleSet(String value, Set<String> set,
      {Set<String> noneKeys = const {}}) {
    setState(() {
      if (noneKeys.contains(value)) {
        set.clear();
        set.add(value);
      } else {
        set.removeAll(noneKeys);
        if (set.contains(value)) {
          set.remove(value);
        } else {
          set.add(value);
        }
      }
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Icon(Icons.arrow_back_rounded,
                color: Theme.of(context).colorScheme.onSurface, size: 20),
          ),
        ),
        title: Text('Profili Düzenle', style: AppTextStyles.h2),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      '👤 Temel Profil Bilgileri',
                      _buildBasicProfile(),
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      '📏 Beslenme Profilim',
                      _buildNutritionProfile(),
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      '🏥 Sağlık Bilgileri',
                      _buildHealthInfo(),
                    ),
                    const SizedBox(height: 32),
                    PrimaryButton(
                      text: _isSaving ? 'Kaydediliyor...' : 'Kaydet',
                      trailingIcon: Icons.save_rounded,
                      onPressed: _isSaving ? null : _save,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.h3),
        const SizedBox(height: 12),
        SoftCard(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ],
    );
  }

  Widget _buildBasicProfile() {
    return Column(
      children: [
        _textField(
          controller: _nameCtrl,
          label: 'Ad Soyad',
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 12),
        // E-mail read-only
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(Icons.email_outlined,
                  color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('E-posta',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    Text(
                      _client.auth.currentUser?.email ?? '-',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
              Text('(Değiştirilemez)',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionProfile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _textField(
            controller: _ageCtrl,
            label: 'Yaş',
            icon: Icons.cake_outlined,
            keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        _buildDropdown(
          label: 'Cinsiyet',
          value: _gender,
          options: _genderOptions,
          onChanged: (v) => setState(() => _gender = v),
        ),
        const SizedBox(height: 12),
        _textField(
            controller: _heightCtrl,
            label: 'Boy (cm)',
            icon: Icons.height_rounded,
            keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        _textField(
            controller: _weightCtrl,
            label: 'Kilo (kg)',
            icon: Icons.monitor_weight_outlined,
            keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        _buildDropdown(
          label: 'Beslenme Hedefi',
          value: _goalType,
          options: _goalOptions,
          onChanged: (v) => setState(() => _goalType = v),
        ),
        const SizedBox(height: 12),
        _buildDropdown(
          label: 'Aktivite Seviyesi',
          value: _activityLevel,
          options: _activityOptions,
          onChanged: (v) => setState(() => _activityLevel = v),
        ),
      ],
    );
  }

  Widget _buildHealthInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChipGroup(
          label: 'Sağlık Durumu',
          options: _healthConditionOptions,
          selected: _healthConditions,
          onToggle: (v) => _toggleSet(v, _healthConditions,
              noneKeys: {'Yok', 'Belirtmek istemiyorum'}),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppColors.error, size: 18),
            const SizedBox(width: 8),
            Text('Alerjiler ve Kaçınılan Besinler',
                style: AppTextStyles.labelMedium
                    .copyWith(color: Theme.of(context).colorScheme.onSurface)),
          ],
        ),
        const SizedBox(height: 8),
        _buildChipGroup(
          label: '',
          options: _allergyOptions,
          selected: _allergies,
          onToggle: (v) =>
              _toggleSet(v, _allergies, noneKeys: {'Yok'}),
          accentColor: AppColors.error,
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        _buildChipGroup(
          label: 'Beslenme Tercihleri',
          options: _dietPrefOptions,
          selected: _dietPreferences,
          onToggle: (v) =>
              _toggleSet(v, _dietPreferences, noneKeys: {'Normal'}),
        ),
      ],
    );
  }

  // ── Reusable Form Widgets ──────────────────────────────────────────────

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            AppTextStyles.labelSmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
        filled: true,
        fillColor: Theme.of(context).scaffoldBackgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: options.contains(value) ? value : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            AppTextStyles.labelSmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        filled: true,
        fillColor: Theme.of(context).scaffoldBackgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: options
          .map((o) =>
              DropdownMenuItem(value: o, child: Text(o, style: AppTextStyles.bodyMedium)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildChipGroup({
    required String label,
    required List<String> options,
    required Set<String> selected,
    required ValueChanged<String> onToggle,
    Color? accentColor,
  }) {
    final color = accentColor ?? Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label,
              style: AppTextStyles.labelMedium
                  .copyWith(color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 10),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            final isSelected = selected.contains(opt);
            return GestureDetector(
              onTap: () => onToggle(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.12)
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? color.withValues(alpha: 0.5)
                        : Theme.of(context).dividerColor,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  opt,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isSelected ? color : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
