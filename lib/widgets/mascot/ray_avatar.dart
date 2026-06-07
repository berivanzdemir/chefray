import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class RayAvatar extends StatelessWidget {
  final double size;
  final String imagePath;

  const RayAvatar({
    super.key,
    this.size = 64,
    this.imagePath = 'assets/mascot/ray_default.png',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGlow.withValues(alpha: 0.2),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Image.asset(
          imagePath,
          width: size * 0.8,
          height: size * 0.8,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
