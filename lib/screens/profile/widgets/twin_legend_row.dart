import 'package:flutter/material.dart';

/// Horizontal legend capsule showing aura color meanings.
/// Renders as a single-line pill with all 4 items side by side.
/// Falls back to FittedBox scaling if the container is narrow.
class TwinLegendRow extends StatelessWidget {
  const TwinLegendRow({super.key});

  @override
  Widget build(BuildContext context) {
    final legendTextStyle = TextStyle(
      fontSize: 12.0,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurface,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          children: [
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: _LegendDot(
                    color: const Color(0xFF22C55E),
                    label: 'Normal',
                    textStyle: legendTextStyle,
                  ),
                ),
                _LegendDot(
                  color: const Color(0xFF2D9CDB),
                  label: 'Su Az',
                  textStyle: legendTextStyle,
                ),
              ],
            ),
            const TableRow(
              children: [SizedBox(height: 6), SizedBox(height: 6)],
            ),
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: _LegendDot(
                    color: const Color(0xFFFF8A00),
                    label: 'Kalori Az',
                    textStyle: legendTextStyle,
                  ),
                ),
                _LegendDot(
                  color: const Color(0xFF7B61FF),
                  label: 'Aktivite Az',
                  textStyle: legendTextStyle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final TextStyle textStyle;

  const _LegendDot({
    required this.color,
    required this.label,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: textStyle, maxLines: 1),
      ],
    );
  }
}
