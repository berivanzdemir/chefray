import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/user_health_profile.dart';

/// Summary strip showing key profile metrics in two compact rows.
class BodySummaryStrip extends StatelessWidget {
  final UserHealthProfile? healthProfile;

  const BodySummaryStrip({
    super.key,
    this.healthProfile,
  });

  @override
  Widget build(BuildContext context) {
    final profile = healthProfile;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // First row: Yaş, Cinsiyet, Boy, Kilo
          _stripContainer(
            children: [
              _metricItem(
                icon: Icons.cake_outlined,
                label: 'Yaş',
                value: profile?.age?.toString() ?? '-',
              ),
              _divider(),
              _metricItem(
                icon: Icons.person_outline_rounded,
                label: 'Cinsiyet',
                value: profile?.gender ?? '-',
              ),
              _divider(),
              _metricItem(
                icon: Icons.height_rounded,
                label: 'Boy',
                value: profile?.heightCm != null
                    ? '${profile!.heightCm!.toStringAsFixed(0)} cm'
                    : '-',
              ),
              _divider(),
              _metricItem(
                icon: Icons.monitor_weight_outlined,
                label: 'Kilo',
                value: profile?.weightKg != null
                    ? '${profile!.weightKg!.toStringAsFixed(1)} kg'
                    : '-',
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Second row: Hedef, Aktivite
          _stripContainer(
            children: [
              _metricItem(
                icon: Icons.flag_outlined,
                label: 'Hedef',
                value: profile?.goalType ?? '-',
              ),
              _divider(),
              _metricItem(
                icon: Icons.directions_run_rounded,
                label: 'Aktivite',
                value: profile?.activityLevel ?? '-',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stripContainer({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: children,
      ),
    );
  }

  Widget _metricItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.textLight),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textLight),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.divider,
    );
  }
}
