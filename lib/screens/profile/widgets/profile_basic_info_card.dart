import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/user_profile_provider.dart';

class ProfileBasicInfoCard extends StatelessWidget {
  final int age;
  final String gender;
  final double height;
  final double weight;
  final String activity;
  final String goal;

  const ProfileBasicInfoCard({
    super.key,
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
    required this.activity,
    required this.goal,
  });

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _EditBasicInfoDialog(
        initialAge: age,
        initialGender: gender,
        initialHeight: height,
        initialWeight: weight,
        initialActivity: activity,
        initialGoal: goal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Temel Bilgiler',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.edit_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _showEditDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 1. Satır: Yaş & Cinsiyet
          Row(
            children: [
              Expanded(
                child: _buildIconInfoCell(
                  context: context,
                  icon: Icons.calendar_today_outlined,
                  iconColor: Colors.teal,
                  iconBgColor: Colors.teal.shade50,
                  label: 'Yaş',
                  value: '$age',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildIconInfoCell(
                  context: context,
                  icon: Icons.wc_outlined,
                  iconColor: Colors.blue,
                  iconBgColor: Colors.blue.shade50,
                  label: 'Cinsiyet',
                  value: gender,
                ),
              ),
            ],
          ),
          _buildHorizontalDivider(),
          // 2. Satır: Boy & Kilo
          Row(
            children: [
              Expanded(
                child: _buildIconInfoCell(
                  context: context,
                  icon: Icons.height,
                  iconColor: Colors.orange,
                  iconBgColor: Colors.orange.shade50,
                  label: 'Boy',
                  value: '${height.toStringAsFixed(1)} cm',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildIconInfoCell(
                  context: context,
                  icon: Icons.monitor_weight_outlined,
                  iconColor: Colors.pink,
                  iconBgColor: Colors.pink.shade50,
                  label: 'Kilo',
                  value: '${weight.toStringAsFixed(1)} kg',
                ),
              ),
            ],
          ),
          _buildHorizontalDivider(),
          // 3. Satır: Hedef & Aktivite
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildIconInfoCell(
                  context: context,
                  icon: Icons.flag_outlined,
                  iconColor: Colors.green,
                  iconBgColor: Colors.green.shade50,
                  label: 'Hedef',
                  value: goal,
                  multiLine: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildIconInfoCell(
                  context: context,
                  icon: Icons.directions_run_outlined,
                  iconColor: Colors.deepOrange,
                  iconBgColor: Colors.deepOrange.shade50,
                  label: 'Aktivite',
                  value: activity,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconInfoCell({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    required String value,
    bool multiLine = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
    );
  }
}

class _EditBasicInfoDialog extends StatefulWidget {
  final int initialAge;
  final String initialGender;
  final double initialHeight;
  final double initialWeight;
  final String initialActivity;
  final String initialGoal;

  const _EditBasicInfoDialog({
    required this.initialAge,
    required this.initialGender,
    required this.initialHeight,
    required this.initialWeight,
    required this.initialActivity,
    required this.initialGoal,
  });

  @override
  State<_EditBasicInfoDialog> createState() => _EditBasicInfoDialogState();
}

class _EditBasicInfoDialogState extends State<_EditBasicInfoDialog> {
  late TextEditingController ageCtrl;
  late TextEditingController heightCtrl;
  late TextEditingController weightCtrl;

  late String selectedGender;
  late String selectedActivity;
  late String selectedGoal;

  bool _isSaving = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    ageCtrl = TextEditingController(text: widget.initialAge.toString());
    heightCtrl = TextEditingController(text: widget.initialHeight.toString());
    weightCtrl = TextEditingController(text: widget.initialWeight.toString());
    selectedGender = widget.initialGender;
    selectedActivity = widget.initialActivity;
    selectedGoal = widget.initialGoal;
  }

  @override
  void dispose() {
    ageCtrl.dispose();
    heightCtrl.dispose();
    weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final age = int.tryParse(ageCtrl.text) ?? 0;
    final height = double.tryParse(heightCtrl.text) ?? 0.0;
    final weight = double.tryParse(weightCtrl.text) ?? 0.0;

    if (age < 13 || age > 100) {
      setState(() => _errorMsg = 'Yaş 13–100 arasında olmalıdır.');
      return;
    }
    if (height < 120 || height > 230) {
      setState(() => _errorMsg = 'Boy 120–230 cm arasında olmalıdır.');
      return;
    }
    if (weight < 30 || weight > 250) {
      setState(() => _errorMsg = 'Kilo 30–250 kg arasında olmalıdır.');
      return;
    }

    setState(() {
      _errorMsg = null;
      _isSaving = true;
    });
    final provider = context.read<UserProfileProvider>();
    final currentProfile = provider.healthProfile;
    if (currentProfile != null) {
      final updated = currentProfile.copyWith(
        age: age,
        heightCm: height,
        weightKg: weight,
        gender: selectedGender,
        activityLevel: selectedActivity,
        goalType: selectedGoal,
      );
      await provider.updateHealthProfile(updated);
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Temel Bilgileri Düzenle',
        style: TextStyle(fontSize: 18),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_errorMsg != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMsg!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            TextField(
              controller: ageCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Yaş'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: heightCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Boy (cm)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: weightCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Kilo (kg)'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: ['Kadın', 'Erkek', 'Diğer'].contains(selectedGender)
                  ? selectedGender
                  : 'Kadın',
              items: [
                'Kadın',
                'Erkek',
                'Diğer',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => selectedGender = v ?? 'Kadın'),
              decoration: const InputDecoration(labelText: 'Cinsiyet'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue:
                  ['Düşük', 'Orta', 'Yüksek'].contains(selectedActivity)
                  ? selectedActivity
                  : 'Orta',
              items: [
                'Düşük',
                'Orta',
                'Yüksek',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => selectedActivity = v ?? 'Orta'),
              decoration: const InputDecoration(labelText: 'Aktivite'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue:
                  [
                    'Kilo vermek',
                    'Kas kazanmak',
                    'Kilo korumak',
                    'Daha dengeli beslenmek',
                    'Sağlıklı tarifler keşfetmek',
                  ].contains(selectedGoal)
                  ? selectedGoal
                  : 'Daha dengeli beslenmek',
              items: [
                'Kilo vermek',
                'Kas kazanmak',
                'Kilo korumak',
                'Daha dengeli beslenmek',
                'Sağlıklı tarifler keşfetmek',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) =>
                  setState(() => selectedGoal = v ?? 'Daha dengeli beslenmek'),
              decoration: const InputDecoration(labelText: 'Hedef'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal', style: TextStyle(color: Colors.grey)),
        ),
        _isSaving
            ? const Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(),
              )
            : ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
                child: Text(
                  'Kaydet',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
              ),
      ],
    );
  }
}
