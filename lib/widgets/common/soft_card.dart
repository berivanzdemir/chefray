import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Premium card with soft shadow and rounded corners.
/// Matches ChefRay's glassmorphism-inspired card design.
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? backgroundColor;
  final bool hasGreenGlow;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const SoftCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 24,
    this.backgroundColor,
    this.hasGreenGlow = false,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor ?? Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 20,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            if (hasGreenGlow)
              BoxShadow(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.08),
                blurRadius: 30,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
          ],
          border: Border.all(
            color: hasGreenGlow
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
            width: 1,
          ),
        ),
        child: child,
      ),
    );
  }
}
