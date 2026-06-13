import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Simple confetti effect using custom painter.
class ConfettiEffect extends StatefulWidget {
  const ConfettiEffect({super.key});

  @override
  State<ConfettiEffect> createState() => _ConfettiEffectState();
}

class _ConfettiEffectState extends State<ConfettiEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Confetti> _pieces;

  @override
  void initState() {
    super.initState();
    final rng = math.Random(42);
    _pieces = List.generate(
      40,
      (_) => _Confetti(
        x: rng.nextDouble(),
        speed: 0.3 + rng.nextDouble() * 0.7,
        size: 4 + rng.nextDouble() * 6,
        color: [
          const Color(0xFF2DFF88),
          const Color(0xFFFFA726),
          const Color(0xFF5BC0EB),
          const Color(0xFFFF6B6B),
          const Color(0xFFB388FF),
          const Color(0xFFFFD54F),
        ][rng.nextInt(6)],
        drift: (rng.nextDouble() - 0.5) * 0.3,
      ),
    );
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => CustomPaint(
        size: Size.infinite,
        painter: _ConfettiPainter(_pieces, _ctrl.value),
      ),
    );
  }
}

class _Confetti {
  final double x, speed, size, drift;
  final Color color;
  const _Confetti({
    required this.x,
    required this.speed,
    required this.size,
    required this.color,
    required this.drift,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Confetti> pieces;
  final double t;
  _ConfettiPainter(this.pieces, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final y = ((p.speed * t * 1.5) % 1.2) * size.height - size.height * 0.1;
      final x = (p.x + p.drift * math.sin(t * math.pi * 2)) * size.width;
      final rotation = t * math.pi * 4 * p.speed;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.6,
          ),
          Radius.circular(1.5),
        ),
        Paint()
          ..color = p.color.withValues(
            alpha: (1 - (y / size.height).clamp(0, 1)) * 0.8,
          ),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}
