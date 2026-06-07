import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Compact white card: circular health score on left, status badge on right.
/// Target height ~120px.
class HealthScoreSummaryCard extends StatelessWidget {
  final int score;
  final int maxScore;
  final String statusText;

  const HealthScoreSummaryCard({
    super.key,
    this.score = 82,
    this.maxScore = 100,
    this.statusText = 'dengeli',
  });

  @override
  Widget build(BuildContext context) {
    final double progress = (score / maxScore).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Icon(Icons.monitor_heart_rounded,
                  size: 13, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                'Sağlık Skoru',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Score + status row
          Row(
            children: [
              // Circular progress
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 5,
                        strokeCap: StrokeCap.round,
                        backgroundColor: const Color(0xFFF0F0F0),
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$score',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          '/$maxScore',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status badge
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundMint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sentiment_satisfied_rounded,
                          color: Theme.of(context).colorScheme.primary, size: 18),
                      const SizedBox(height: 3),
                      Text(
                        'Bugünkü durumun',
                        style: TextStyle(
                          fontSize: 8,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        statusText,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
