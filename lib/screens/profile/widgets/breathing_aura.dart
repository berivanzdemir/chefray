import 'package:flutter/material.dart';

/// Soft breathing aura behind the avatar.
/// Accepts explicit width/height so it scales proportionally with the avatar.
class BreathingAura extends StatefulWidget {
  final Color auraColor;
  final Widget child;
  final double auraWidth;
  final double auraHeight;

  const BreathingAura({
    super.key,
    required this.auraColor,
    required this.child,
    this.auraWidth = 130,
    this.auraHeight = 210,
  });

  @override
  State<BreathingAura> createState() => _BreathingAuraState();
}

class _BreathingAuraState extends State<BreathingAura>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.97,
      end: 1.04,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _opacityAnimation = Tween<double>(
      begin: 0.10,
      end: 0.24,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Soft radial glow – proportional to avatar
            Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: widget.auraWidth,
                height: widget.auraHeight,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(widget.auraWidth * 0.55),
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.65,
                    colors: [
                      widget.auraColor.withValues(
                        alpha: _opacityAnimation.value,
                      ),
                      widget.auraColor.withValues(
                        alpha: _opacityAnimation.value * 0.3,
                      ),
                      widget.auraColor.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
            // Avatar
            widget.child,
          ],
        );
      },
    );
  }
}
