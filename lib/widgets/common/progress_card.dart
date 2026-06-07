import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../core/constants/app_text_styles.dart';

/// Hero calorie progress card with dark green gradient background.
class ProgressCard extends StatelessWidget {
  final int current;
  final int target;
  final double percentage;
  final int remaining;

  const ProgressCard({
    super.key,
    required this.current,
    required this.target,
    required this.percentage,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F3D2E), Color(0xFF1A5C3F)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F3D2E).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Günlük Kalori Özeti',
            style: AppTextStyles.labelMedium.copyWith(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Calorie numbers
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: _formatNum(current),
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.surface,
                            letterSpacing: -1,
                          ),
                        ),
                        TextSpan(
                          text: ' / ${_formatNum(target)} kcal',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: percentage,
                        minHeight: 8,
                        backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.local_fire_department_rounded,
                            size: 14, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          '$remaining kcal kaldı',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Circular percentage
              SizedBox(
                width: 72,
                height: 72,
                child: CustomPaint(
                  painter: _PercentRingPainter(percentage, context),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(percentage * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Text(
                          'Tamamlandı',
                          style: TextStyle(
                            fontSize: 8,
                            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNum(int n) {
    if (n >= 1000) {
      return '${n ~/ 1000}.${(n % 1000) ~/ 100}${(n % 100) ~/ 10}0';
    }
    return '$n';
  }
}

class _PercentRingPainter extends CustomPainter {
  final double pct;
  final BuildContext context;
  _PercentRingPainter(this.pct, this.context);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 5;
    const sw = 6.0;
    canvas.drawCircle(
      c, r,
      Paint()
        ..color = Theme.of(context).colorScheme.surface.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw,
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * pct,
      false,
      Paint()
        ..color = Theme.of(context).colorScheme.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _PercentRingPainter old) => old.pct != pct;
}
