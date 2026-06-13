import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../widgets/common/soft_card.dart';

/// Card showing current weight vs ideal range with a visual indicator bar.
class BodyStatusCard extends StatelessWidget {
  final double? currentWeight;
  final ({double min, double max})? idealRange;
  final VoidCallback? onEnterData;

  const BodyStatusCard({
    super.key,
    this.currentWeight,
    this.idealRange,
    this.onEnterData,
  });

  bool get _hasData =>
      currentWeight != null &&
      currentWeight! > 0 &&
      idealRange != null &&
      idealRange!.min > 0;

  Color get _indicatorColor {
    if (!_hasData) return AppColors.textLight;
    if (currentWeight! < idealRange!.min) return AppColors.info;
    if (currentWeight! > idealRange!.max) return AppColors.warning;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SoftCard(child: _hasData ? _buildContent() : _buildEmptyState()),
    );
  }

  Widget _buildContent() {
    final weight = currentWeight!;
    final range = idealRange!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.monitor_heart_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vücut Durumu',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Son güncelleme: bugün',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Weight columns
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Güncel Kilo', style: AppTextStyles.labelSmall),
                  const SizedBox(height: 4),
                  Text(
                    '${weight.toStringAsFixed(1)} kg',
                    style: AppTextStyles.h1.copyWith(fontSize: 28),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('İdeal Kilo Aralığı', style: AppTextStyles.labelSmall),
                  const SizedBox(height: 4),
                  Text(
                    '${range.min.toStringAsFixed(1)} - ${range.max.toStringAsFixed(1)} kg',
                    style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Weight indicator bar
        _buildWeightBar(weight, range),
        const SizedBox(height: 8),
        // Range labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${range.min.toStringAsFixed(0)} kg',
              style: AppTextStyles.labelSmall,
            ),
            Text(
              '${range.max.toStringAsFixed(0)} kg',
              style: AppTextStyles.labelSmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeightBar(double weight, ({double min, double max}) range) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth;
        // Determine the visible range for the bar
        final margin = (range.max - range.min) * 0.5;
        final barMin = range.min - margin;
        final barMax = range.max + margin;
        final totalSpan = barMax - barMin;

        // Ideal zone positions
        final idealStart = ((range.min - barMin) / totalSpan) * barWidth;
        final idealEnd = ((range.max - barMin) / totalSpan) * barWidth;

        // Current weight dot position (clamped to bar bounds)
        final clampedWeight = weight.clamp(barMin, barMax);
        final dotPosition = ((clampedWeight - barMin) / totalSpan) * barWidth;

        return SizedBox(
          height: 40,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Gray track
              Positioned(
                top: 24,
                left: 0,
                right: 0,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              // Green ideal zone
              Positioned(
                top: 24,
                left: idealStart,
                width: idealEnd - idealStart,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              // Dot indicator
              Positioned(
                top: 4,
                left: dotPosition - 20,
                child: Column(
                  children: [
                    // Weight label above dot
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _indicatorColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        weight.toStringAsFixed(1),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Dot
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _indicatorColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: _indicatorColor.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Icon(Icons.monitor_heart_outlined, size: 48, color: AppColors.textHint),
        const SizedBox(height: 12),
        Text(
          'Vücut durumunuzu görmek için\nbilgilerinizi girin',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onEnterData,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Bilgilerimi Gir',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
