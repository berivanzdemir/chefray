import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Horizontal scan beam painter for exploded view animation.
class ScanBeam extends StatelessWidget {
  final double progress;

  const ScanBeam({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final y = progress * constraints.maxHeight;
        return Stack(
          children: [
            Positioned(
              left: 0, right: 0, top: y,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    AppColors.primary.withValues(alpha: 0),
                    AppColors.primary.withValues(alpha: 0.7),
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.7),
                    AppColors.primary.withValues(alpha: 0),
                  ]),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 16, spreadRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
