import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../widgets/common/primary_button.dart';

/// Quick-edit bottom sheet for body metrics that affect body analysis calculations.
/// Shows only: weight, height, age, gender, goal, activity level.
class EditBodyMetricsSheet extends StatefulWidget {
  final double? currentWeightKg;
  final double? currentHeightCm;
  final int? currentAge;
  final String? currentGender;
  final String? currentGoalType;
  final String? currentActivityLevel;

  /// Called with the updated values when the user saves.
  final void Function({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
    required String goalType,
    required String activityLevel,
  })
  onSave;

  const EditBodyMetricsSheet({
    super.key,
    this.currentWeightKg,
    this.currentHeightCm,
    this.currentAge,
    this.currentGender,
    this.currentGoalType,
    this.currentActivityLevel,
    required this.onSave,
  });

  static void show(
    BuildContext context, {
    double? currentWeightKg,
    double? currentHeightCm,
    int? currentAge,
    String? currentGender,
    String? currentGoalType,
    String? currentActivityLevel,
    required void Function({
      required double weightKg,
      required double heightCm,
      required int age,
      required String gender,
      required String goalType,
      required String activityLevel,
    })
    onSave,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditBodyMetricsSheet(
        currentWeightKg: currentWeightKg,
        currentHeightCm: currentHeightCm,
        currentAge: currentAge,
        currentGender: currentGender,
        currentGoalType: currentGoalType,
        currentActivityLevel: currentActivityLevel,
        onSave: onSave,
      ),
    );
  }

  @override
  State<EditBodyMetricsSheet> createState() => _EditBodyMetricsSheetState();
}

class _EditBodyMetricsSheetState extends State<EditBodyMetricsSheet> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _ageCtrl;
  late String? _gender;
  late String? _goalType;
  late String? _activityLevel;
  bool _isSaving = false;

  static const _genderOptions = ['Erkek', 'Kadın'];
  static const _goalOptions = [
    'Kilo vermek',
    'Kilo korumak',
    'Kas kazanmak',
    'Daha dengeli beslenmek',
  ];
  static const _activityOptions = ['Düşük', 'Orta', 'Yüksek'];

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(
      text: widget.currentWeightKg?.toString() ?? '',
    );
    _heightCtrl = TextEditingController(
      text: widget.currentHeightCm?.toString() ?? '',
    );
    _ageCtrl = TextEditingController(text: widget.currentAge?.toString() ?? '');
    _gender = widget.currentGender;
    _goalType = widget.currentGoalType;
    _activityLevel = widget.currentActivityLevel;
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final w = double.tryParse(_weightCtrl.text.replaceAll(',', '.'));
    final h = double.tryParse(_heightCtrl.text.replaceAll(',', '.'));
    final a = int.tryParse(_ageCtrl.text);

    if (w == null ||
        h == null ||
        a == null ||
        _gender == null ||
        _goalType == null ||
        _activityLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen tüm alanları doldurun.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    widget.onSave(
      weightKg: w,
      heightCm: h,
      age: a,
      gender: _gender!,
      goalType: _goalType!,
      activityLevel: _activityLevel!,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Bilgileri Güncelle', style: AppTextStyles.h2),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundMint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Bu bilgiler vücut analizi hesaplamalarında kullanılır.',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textLight,
              ),
            ),
            // Scrollable form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Column(
                  children: [
                    _textField(
                      controller: _weightCtrl,
                      label: 'Kilo (kg)',
                      icon: Icons.monitor_weight_outlined,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _textField(
                      controller: _heightCtrl,
                      label: 'Boy (cm)',
                      icon: Icons.height_rounded,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    _textField(
                      controller: _ageCtrl,
                      label: 'Yaş',
                      icon: Icons.cake_outlined,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    _dropdown(
                      label: 'Cinsiyet',
                      value: _gender,
                      options: _genderOptions,
                      onChanged: (v) => setState(() => _gender = v),
                    ),
                    const SizedBox(height: 12),
                    _dropdown(
                      label: 'Hedef',
                      value: _goalType,
                      options: _goalOptions,
                      onChanged: (v) => setState(() => _goalType = v),
                    ),
                    const SizedBox(height: 12),
                    _dropdown(
                      label: 'Aktivite Seviyesi',
                      value: _activityLevel,
                      options: _activityOptions,
                      onChanged: (v) => setState(() => _activityLevel = v),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      text: _isSaving ? 'Kaydediliyor...' : 'Kaydet ve Hesapla',
                      trailingIcon: Icons.check_rounded,
                      onPressed: _isSaving ? null : _save,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
        labelStyle: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textLight,
        ),
        prefixIcon: Icon(icon, color: AppColors.textLight, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: options.contains(value) ? value : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textLight,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      items: options
          .map(
            (o) => DropdownMenuItem(
              value: o,
              child: Text(o, style: AppTextStyles.bodyMedium),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
