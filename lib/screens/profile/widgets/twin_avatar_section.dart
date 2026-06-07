import 'package:flutter/material.dart';
import 'breathing_aura.dart';
import 'twin_avatar_display.dart';
import 'twin_metric_circle.dart';

/// Left column avatar section: LayoutBuilder-driven responsive avatar
/// surrounded by 4 metric icons, with proportional breathing aura.
class TwinAvatarSection extends StatelessWidget {
  final String avatarPath;
  final Color auraColor;

  const TwinAvatarSection({
    super.key,
    required this.avatarPath,
    required this.auraColor,
  });

  @override
  Widget build(BuildContext context) {
    // Fixed height for the avatar area — tall enough for a large avatar + icons
    const double stackHeight = 350;

    return SizedBox(
      height: stackHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Avatar fills ~78% of available height
          final double avatarH =
              (constraints.maxHeight * 0.78).clamp(230.0, 285.0);
          // Aura proportional to avatar: ~1.15x width, ~1.05x height
          final double auraW = avatarH * 0.52; // roughly body width * 1.15
          final double auraH = avatarH * 0.85; // slightly taller than torso

          return Stack(
            alignment: Alignment.center,
            children: [
              // Breathing aura + avatar
              BreathingAura(
                auraColor: auraColor,
                auraWidth: auraW,
                auraHeight: auraH,
                child: TwinAvatarDisplay(
                  avatarPath: avatarPath,
                  height: avatarH,
                ),
              ),
              // Su – top left
              const Positioned(
                top: 20,
                left: 0,
                child: TwinMetricCircle(
                  icon: Icons.water_drop_rounded,
                  color: Color(0xFF2D9CDB),
                  label: 'Su',
                ),
              ),
              // Kalori – top right
              const Positioned(
                top: 20,
                right: 0,
                child: TwinMetricCircle(
                  icon: Icons.local_fire_department_rounded,
                  color: Color(0xFFFF8A00),
                  label: 'Kalori',
                ),
              ),
              // Protein – bottom left
              const Positioned(
                bottom: 20,
                left: 0,
                child: TwinMetricCircle(
                  icon: Icons.eco_rounded,
                  color: Color(0xFF22C55E),
                  label: 'Protein',
                ),
              ),
              // Aktivite – bottom right
              const Positioned(
                bottom: 20,
                right: 0,
                child: TwinMetricCircle(
                  icon: Icons.directions_run_rounded,
                  color: Color(0xFF7B61FF),
                  label: 'Aktivite',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
