import 'package:flutter/material.dart';
import 'breathing_aura.dart';

/// Thin wrapper around [BreathingAura] kept for backward-compatibility.
class AvatarGlow extends StatelessWidget {
  final Color glowColor;
  final Widget child;

  const AvatarGlow({
    super.key,
    required this.glowColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BreathingAura(
      auraColor: glowColor,
      child: child,
    );
  }
}
