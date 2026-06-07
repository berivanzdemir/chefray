import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/user_health_profile.dart';

/// Top profile header card with avatar, name, badges, goal, and streak info.
class ProfileHeaderCard extends StatelessWidget {
  final UserHealthProfile? healthProfile;
  final String displayName;
  final String avatarInitial;
  final VoidCallback? onSettingsTap;

  const ProfileHeaderCard({
    super.key,
    this.healthProfile,
    required this.displayName,
    required this.avatarInitial,
    this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final goal = healthProfile?.goalType ?? 'Hedef belirle';
    final streak = healthProfile?.streakDays ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar badge with camera overlay
          Stack(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    avatarInitial,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.surface,
                      fontWeight: FontWeight.w800,
                      fontSize: 30,
                    ),
                  ),
                ),
              ),
              // Camera/edit icon overlay
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    size: 12,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          // Name + badges + goal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        style: AppTextStyles.h1.copyWith(fontSize: 22),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Pro badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.diamond_rounded,
                              size: 10, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 3),
                          Text(
                            'Pro',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Goal row
                Row(
                  children: [
                    Icon(Icons.track_changes_rounded,
                        size: 14, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Hedef: $goal',
                        style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Motivation row
                Row(
                  children: [
                    Icon(Icons.emoji_events_rounded,
                        size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Daha sağlıklı bir sen için buradayız!',
                        style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Settings + streak column
          Column(
            children: [
              // Settings button
              GestureDetector(
                onTap: onSettingsTap,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Icon(Icons.settings_rounded,
                      size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 8),
              // Streak card
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Icon(Icons.local_fire_department_rounded,
                        size: 18, color: Theme.of(context).colorScheme.primary),
                    Text(
                      '$streak',
                      style: AppTextStyles.h3.copyWith(
                          fontSize: 14, color: Theme.of(context).colorScheme.primary),
                    ),
                    Text(
                      'Seri Gün',
                      style: AppTextStyles.labelSmall.copyWith(
                          fontSize: 7, color: Theme.of(context).colorScheme.primary),
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
