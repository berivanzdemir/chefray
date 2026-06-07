import 'package:flutter/material.dart';

/// Placeholder for exploded ingredient layer positioning.
/// Each layer has a position offset, scale, and opacity controlled by animation.
class ExplodedIngredientLayer extends StatelessWidget {
  final Widget child;
  final double dx;
  final double dy;
  final double scale;
  final double opacity;

  const ExplodedIngredientLayer({
    super.key,
    required this.child,
    required this.dx,
    required this.dy,
    this.scale = 1.0,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: child,
        ),
      ),
    );
  }
}
