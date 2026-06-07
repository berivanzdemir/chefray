import 'package:flutter/material.dart';
import 'dart:math' as math;


class HydrationCard extends StatelessWidget {
  final int currentMl;
  final int targetMl;
  final VoidCallback onAddSmall;
  final VoidCallback onAddLarge;
  final VoidCallback? onDecreaseSmall;
  final VoidCallback? onDecreaseLarge;

  const HydrationCard({
    super.key,
    required this.currentMl,
    required this.targetMl,
    required this.onAddSmall,
    required this.onAddLarge,
    this.onDecreaseSmall,
    this.onDecreaseLarge,
  });

  @override
  Widget build(BuildContext context) {
    final safeCurrent = currentMl.clamp(0, 99999);
    final safeTarget = targetMl > 0 ? targetMl : 2500;
    final progress = (safeCurrent / safeTarget).clamp(0.0, 1.0);
    final int pct = (progress * 100).toInt();
    final double displayLiters = safeCurrent / 1000;
    final double targetLiters = safeTarget / 1000;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        // Show glass image only when there is enough space
        final bool showGlass = availableWidth > 320;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: Circular Progress
                SizedBox(
                  width: 68,
                  height: 68,
                  child: CustomPaint(
                    painter: _WaterRingPainter(progress: progress),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.water_drop_rounded,
                              color: Color(0xFF4DB8E8), size: 14),
                          const SizedBox(height: 1),
                          FittedBox(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                '${displayLiters.toStringAsFixed(1)} / ${targetLiters.toStringAsFixed(1)} L',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontFamily: 'SF Pro Display',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Middle: Text & Progress Bar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Su Tüketimi',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.onSurface,
                                fontFamily: 'SF Pro Display',
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.water_drop_outlined,
                              size: 14, color: Color(0xFF4DB8E8)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Bugünkü hedefinin %$pct\'ünü tamamladın',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontFamily: 'SF Pro Display',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 5,
                          backgroundColor: Theme.of(context).brightness == Brightness.dark 
                              ? const Color(0xFF4DB8E8).withValues(alpha: 0.3)
                              : const Color(0xFF4DB8E8).withValues(alpha: 0.15),
                          valueColor: const AlwaysStoppedAnimation(
                              Color(0xFF4DB8E8)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Right Buttons
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SmallActionBtn(text: '+250 ml', onTap: onAddSmall),
                    const SizedBox(height: 6),
                    _SmallActionBtn(text: '+500 ml', onTap: onAddLarge),
                  ],
                ),

                // End Right: Glass Asset (only if space allows)
                if (showGlass) ...[
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 48,
                    height: 68,
                    child: Image.asset(
                      'assets/subardagi.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.centerRight,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.local_drink,
                        color: const Color(0xFF4DB8E8).withValues(alpha: 0.4),
                        size: 36,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SmallActionBtn extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _SmallActionBtn({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
              color: const Color(0xFF4DB8E8).withValues(alpha: 0.25),
              width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_drink_outlined,
                size: 11, color: const Color(0xFF4DB8E8)),
            const SizedBox(width: 3),
            Text(
              text,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4DB8E8),
                fontFamily: 'SF Pro Display',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaterRingPainter extends CustomPainter {
  final double progress;
  _WaterRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 3;
    const sw = 6.0;

    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = const Color(0xFF4DB8E8).withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw,
    );

    final rect = Rect.fromCircle(center: center, radius: r);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = const Color(0xFF4DB8E8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _WaterRingPainter old) =>
      old.progress != progress;
}
