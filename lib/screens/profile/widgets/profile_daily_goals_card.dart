import 'package:flutter/material.dart';


class ProfileDailyGoalsCard extends StatelessWidget {
  final double caloriePercent;
  final double proteinPercent;
  final double waterPercent;
  final double activityPercent;

  final String calorieText;
  final String proteinText;
  final String waterText;
  final String activityText;

  final VoidCallback onEditTap;

  const ProfileDailyGoalsCard({
    super.key,
    required this.caloriePercent,
    required this.proteinPercent,
    required this.waterPercent,
    required this.activityPercent,
    required this.calorieText,
    required this.proteinText,
    required this.waterText,
    required this.activityText,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
                  Icon(Icons.track_changes_rounded, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    'Günlük Hedefler',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onEditTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        'Hedefleri düzenle',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 2 Sütunlu Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildGoalBar(
                      context: context,
                      icon: Icons.local_fire_department_rounded,
                      color: const Color(0xFFFF8A00),
                      label: 'Kalori',
                      value: calorieText,
                      percent: caloriePercent,
                    ),
                    const SizedBox(height: 16),
                    _buildGoalBar(
                      context: context,
                      icon: Icons.water_drop_rounded,
                      color: const Color(0xFF2D9CDB),
                      label: 'Su',
                      value: waterText,
                      percent: waterPercent,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _buildGoalBar(
                      context: context,
                      icon: Icons.eco_rounded,
                      color: const Color(0xFF2ECC71),
                      label: 'Protein',
                      value: proteinText,
                      percent: proteinPercent,
                    ),
                    const SizedBox(height: 16),
                    _buildGoalBar(
                      context: context,
                      icon: Icons.directions_run_rounded,
                      color: const Color(0xFF7B61FF),
                      label: 'Aktivite',
                      value: activityText,
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

  Widget _buildGoalBar({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required double percent,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurfaceVariant),
              maxLines: 1,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
