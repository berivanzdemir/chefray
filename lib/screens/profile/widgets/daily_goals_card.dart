import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/user_profile_provider.dart';
import '../../../models/daily_goals_model.dart';

class DailyGoalsCard extends StatelessWidget {
  final double currentCalories;
  final double targetCalories;
  final double currentProtein;
  final double targetProtein;
  final double currentWater;
  final double targetWater;
  final double currentActivity;
  final double targetActivity;

  const DailyGoalsCard({
    super.key,
    required this.currentCalories,
    required this.targetCalories,
    required this.currentProtein,
    required this.targetProtein,
    required this.currentWater,
    required this.targetWater,
    required this.currentActivity,
    required this.targetActivity,
  });

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _EditDailyGoalsDialog(
        currentCalories: currentCalories,
        targetCalories: targetCalories,
        currentProtein: currentProtein,
        targetProtein: targetProtein,
        currentWater: currentWater,
        targetWater: targetWater,
        currentActivity: currentActivity,
        targetActivity: targetActivity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double caloriePercent =
        currentCalories / (targetCalories > 0 ? targetCalories : 2000);
    final double proteinPercent =
        currentProtein / (targetProtein > 0 ? targetProtein : 100);
    final double waterPercent =
        currentWater / (targetWater > 0 ? targetWater : 2000);
    final double activityPercent =
        currentActivity / (targetActivity > 0 ? targetActivity : 60);

    final String calorieText =
        '${currentCalories.toInt()} / ${targetCalories.toInt()} kcal';
    final String proteinText =
        '${currentProtein.toInt()} / ${targetProtein.toInt()} g';
    final String waterText =
        '${(currentWater / 1000).toStringAsFixed(1)} / ${(targetWater / 1000).toStringAsFixed(1)} L';
    final String activityText =
        '${currentActivity.toInt()} / ${targetActivity.toInt()} dk';
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.track_changes_outlined,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Günlük Hedefler',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _showEditDialog(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Hedefleri düzenle',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _GoalProgressItem(
                      icon: Icons.local_fire_department,
                      color: Colors.orange,
                      label: 'Kalori',
                      valueText: calorieText,
                      percent: caloriePercent,
                    ),
                    const SizedBox(height: 20),
                    _GoalProgressItem(
                      icon: Icons.water_drop,
                      color: Colors.blue,
                      label: 'Su',
                      valueText: waterText,
                      percent: waterPercent,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _GoalProgressItem(
                      icon: Icons.eco,
                      color: Colors.green,
                      label: 'Protein',
                      valueText: proteinText,
                      percent: proteinPercent,
                    ),
                    const SizedBox(height: 20),
                    _GoalProgressItem(
                      icon: Icons.directions_run,
                      color: Colors.deepPurple,
                      label: 'Aktivite',
                      valueText: activityText,
                      percent: activityPercent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalProgressItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String valueText;
  final double percent;

  const _GoalProgressItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.valueText,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  valueText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            backgroundColor: color.withValues(alpha: 0.15),
            color: color,
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _EditDailyGoalsDialog extends StatefulWidget {
  final double currentCalories;
  final double targetCalories;
  final double currentProtein;
  final double targetProtein;
  final double currentWater;
  final double targetWater;
  final double currentActivity;
  final double targetActivity;

  const _EditDailyGoalsDialog({
    required this.currentCalories,
    required this.targetCalories,
    required this.currentProtein,
    required this.targetProtein,
    required this.currentWater,
    required this.targetWater,
    required this.currentActivity,
    required this.targetActivity,
  });

  @override
  State<_EditDailyGoalsDialog> createState() => _EditDailyGoalsDialogState();
}

class _EditDailyGoalsDialogState extends State<_EditDailyGoalsDialog> {
  late TextEditingController calTargetCtrl;
  late TextEditingController calConsCtrl;

  late TextEditingController protTargetCtrl;
  late TextEditingController protConsCtrl;

  late TextEditingController waterTargetCtrl;
  late TextEditingController waterConsCtrl;

  late TextEditingController actTargetCtrl;
  late TextEditingController actConsCtrl;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    calTargetCtrl = TextEditingController(
      text: widget.targetCalories.toStringAsFixed(0),
    );
    calConsCtrl = TextEditingController(
      text: widget.currentCalories.toStringAsFixed(0),
    );

    protTargetCtrl = TextEditingController(
      text: widget.targetProtein.toStringAsFixed(0),
    );
    protConsCtrl = TextEditingController(
      text: widget.currentProtein.toStringAsFixed(0),
    );

    waterTargetCtrl = TextEditingController(
      text: widget.targetWater.toStringAsFixed(0),
    );
    waterConsCtrl = TextEditingController(
      text: widget.currentWater.toStringAsFixed(0),
    );

    actTargetCtrl = TextEditingController(
      text: widget.targetActivity.toStringAsFixed(0),
    );
    actConsCtrl = TextEditingController(
      text: widget.currentActivity.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    calTargetCtrl.dispose();
    calConsCtrl.dispose();
    protTargetCtrl.dispose();
    protConsCtrl.dispose();
    waterTargetCtrl.dispose();
    waterConsCtrl.dispose();
    actTargetCtrl.dispose();
    actConsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final provider = context.read<UserProfileProvider>();
    DailyGoals? goals = provider.todayGoals;

    if (goals != null) {
      goals = goals.copyWith(
        caloriesTarget: double.tryParse(calTargetCtrl.text),
        caloriesConsumed: double.tryParse(calConsCtrl.text),
        proteinTarget: double.tryParse(protTargetCtrl.text),
        proteinConsumed: double.tryParse(protConsCtrl.text),
        waterTarget: double.tryParse(waterTargetCtrl.text),
        waterConsumed: double.tryParse(waterConsCtrl.text),
        activityTarget: double.tryParse(actTargetCtrl.text),
        activityCompleted: double.tryParse(actConsCtrl.text),
      );
    } else {
      goals = DailyGoals(
        userId: 'temp',
        targetDate: DateTime.now(),
        caloriesTarget: double.tryParse(calTargetCtrl.text) ?? 2000,
        caloriesConsumed: double.tryParse(calConsCtrl.text) ?? 0,
        proteinTarget: double.tryParse(protTargetCtrl.text) ?? 100,
        proteinConsumed: double.tryParse(protConsCtrl.text) ?? 0,
        waterTarget: double.tryParse(waterTargetCtrl.text) ?? 2000,
        waterConsumed: double.tryParse(waterConsCtrl.text) ?? 0,
        activityTarget: double.tryParse(actTargetCtrl.text) ?? 60,
        activityCompleted: double.tryParse(actConsCtrl.text) ?? 0,
      );
    }

    await provider.updateDailyGoals(goals);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Widget _buildEditRow(
    String title,
    TextEditingController consumedCtrl,
    TextEditingController targetCtrl,
    String unit,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: consumedCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Gerçekleşen',
                  suffixText: unit,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '/',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ),
            Expanded(
              child: TextField(
                controller: targetCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Hedef',
                  suffixText: unit,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Günlük İlerleme & Hedefler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildEditRow('Kalori', calConsCtrl, calTargetCtrl, 'kcal'),
                    _buildEditRow('Protein', protConsCtrl, protTargetCtrl, 'g'),
                    _buildEditRow('Su', waterConsCtrl, waterTargetCtrl, 'ml'),
                    _buildEditRow('Aktivite', actConsCtrl, actTargetCtrl, 'dk'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'İptal',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _isSaving
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(),
                      )
                    : ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          'Kaydet',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.surface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
