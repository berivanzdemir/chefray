import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class CompactBodyAnalysisWidget extends StatelessWidget {
  final double bmi;
  final String bmiStatus;
  final double bmr;
  final double dailyCalories;
  final ({double min, double max}) idealRange;

  const CompactBodyAnalysisWidget({
    super.key,
    required this.bmi,
    required this.bmiStatus,
    required this.bmr,
    required this.dailyCalories,
    required this.idealRange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.scale_rounded, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    'Vücut Analizi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                ],
              ),
              Icon(Icons.info_outline_rounded, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(flex: 3, child: _buildMetricItem(context, 'BMI', bmi.toStringAsFixed(1), bmiStatus, _getBmiColor(bmi))),
              _buildVerticalDivider(),
              Expanded(flex: 3, child: _buildMetricItem(context, 'BMR', '${bmr.toInt()}', 'kcal/gün', Theme.of(context).colorScheme.onSurface)),
              _buildVerticalDivider(),
              Expanded(flex: 3, child: _buildMetricItem(context, 'Günlük Kalori', '${dailyCalories.toInt()}', 'kcal', Theme.of(context).colorScheme.onSurface)),
              _buildVerticalDivider(),
              Expanded(flex: 4, child: _buildMetricItem(context, 'İdeal Kilo Aralığı', '${idealRange.min.toInt()} - ${idealRange.max.toInt()}', 'kg', Theme.of(context).colorScheme.onSurface)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Spacer(),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Vücut Durumu', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    _buildStatusSlider(bmi),
                    const SizedBox(height: 4),
                    Text(bmiStatus, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _getBmiColor(bmi))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(BuildContext context, String title, String value, String subtitle, Color subtitleColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 9, color: Theme.of(context).colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
          maxLines: 1,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
        ),
        Text(
          subtitle,
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: subtitleColor),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 40,
      color: const Color(0xFFF0F0F0),
    );
  }

  Widget _buildStatusSlider(double bmi) {
    double percent = 0.5;
    if (bmi < 18.5) {
      percent = 0.1;
    } else if (bmi < 25) {
      percent = 0.4;
    } else if (bmi < 30) {
      percent = 0.7;
    } else {
      percent = 0.9;
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(
                  colors: [
                    Colors.red,
                    Colors.orange,
                    Colors.yellow,
                    Colors.green,
                    Colors.red,
                  ],
                ),
              ),
            ),
            Positioned(
              left: (constraints.maxWidth * percent) - 6,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black26, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getBmiColor(double bmi) {
    if (bmi < 18.5) {
      return Colors.blue;
    }
    if (bmi < 25) {
      return AppColors.primaryDark;
    }
    if (bmi < 30) {
      return Colors.orange;
    }
    return Colors.red;
  }
}
