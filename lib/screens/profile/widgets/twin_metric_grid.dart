import 'package:flutter/material.dart';


/// 2x2 metric grid inside a single white card with thin divider lines.
/// Each cell: icon+label top, circular progress center, unit below.
/// Circular progress shows SHORT values to avoid overflow.
class TwinMetricGrid extends StatelessWidget {
  final double waterPercent;
  final double caloriePercent;
  final double proteinPercent;
  final double activityPercent;

  final String waterCurrentStr;
  final String waterGoalStr;
  final String calorieCurrentStr;
  final String calorieGoalStr;
  final String proteinCurrentStr;
  final String proteinGoalStr;
  final String activityCurrentStr;
  final String activityGoalStr;

  const TwinMetricGrid({
    super.key,
    required this.waterPercent,
    required this.caloriePercent,
    required this.proteinPercent,
    required this.activityPercent,
    required this.waterCurrentStr,
    required this.waterGoalStr,
    required this.calorieCurrentStr,
    required this.calorieGoalStr,
    required this.proteinCurrentStr,
    required this.proteinGoalStr,
    required this.activityCurrentStr,
    required this.activityGoalStr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
        children: [
          // Top row: Su | Kalori
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    icon: Icons.water_drop_rounded,
                    label: 'Su',
                    color: const Color(0xFF2D9CDB),
                    mainValue: '$waterCurrentStr/$waterGoalStr',
                    unit: 'L',
                    percent: waterPercent,
                  ),
                ),
                Container(width: 1, color: const Color(0xFFF0F0F0)),
                Expanded(
                  child: _MetricTile(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Kalori',
                    color: const Color(0xFFFF8A00),
                    mainValue: calorieCurrentStr,
                    unit: 'kcal',
                    percent: caloriePercent,
                    subText: '$calorieGoalStr hedef',
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFF0F0F0)),
          // Bottom row: Protein | Aktivite
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    icon: Icons.eco_rounded,
                    label: 'Protein',
                    color: const Color(0xFF22C55E),
                    mainValue: '$proteinCurrentStr/$proteinGoalStr',
                    unit: 'g',
                    percent: proteinPercent,
                  ),
                ),
                Container(width: 1, color: const Color(0xFFF0F0F0)),
                Expanded(
                  child: _MetricTile(
                    icon: Icons.directions_run_rounded,
                    label: 'Aktivite',
                    color: const Color(0xFF7B61FF),
                    mainValue: '$activityCurrentStr/$activityGoalStr',
                    unit: 'dk',
                    percent: activityPercent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Single cell inside the 2x2 metric grid.
class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String mainValue; // Short value shown inside ring
  final String unit; // Shown below ring
  final double percent;
  final String? subText; // Optional small text below unit (e.g. "2000 hedef")

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.mainValue,
    required this.unit,
    required this.percent,
    this.subText,
  });

  @override
  Widget build(BuildContext context) {
    final double clampedPercent = percent.clamp(0.0, 1.0);
    const double ringSize = 48;
    const double strokeWidth = 4.5;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon + Label
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 13),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Circular progress
          SizedBox(
            width: ringSize,
            height: ringSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: ringSize,
                  height: ringSize,
                  child: CircularProgressIndicator(
                    value: clampedPercent,
                    strokeWidth: strokeWidth,
                    strokeCap: StrokeCap.round,
                    backgroundColor: color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                // Value inside ring – short text only
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          mainValue,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                            height: 1.1,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                        ),
                        Text(
                          unit,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1.3,
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
          ),
          // Optional sub-text below ring (e.g. "2000 hedef" for kalori)
          if (subText != null) ...[
            const SizedBox(height: 2),
            Text(
              subText!,
              style: TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ],
        ],
      ),
    );
  }
}
