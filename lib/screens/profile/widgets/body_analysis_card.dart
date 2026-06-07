import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class BodyAnalysisCard extends StatelessWidget {
  final double bmi;
  final String bmiStatus;
  final double bmr;
  final double dailyCalories;
  final ({double min, double max}) idealRange;

  const BodyAnalysisCard({
    super.key,
    required this.bmi,
    required this.bmiStatus,
    required this.bmr,
    required this.dailyCalories,
    required this.idealRange,
  });

  void _showInfoBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Vücut Analizi Hakkında',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'BMI (Vücut Kitle İndeksi)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              'Kilonuzun boyunuza göre oranını gösterir. Kategoriler:',
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(
              '• <18.5: Zayıf\n• 18.5 - 24.9: Normal\n• 25.0 - 29.9: Fazla Kilolu\n• 30.0+: Obez',
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Text(
              'BMR & Günlük Kalori',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              'BMR (Bazal Metabolizma Hızı), dinlenme halindeki enerji harcamanızdır. Mifflin-St Jeor formülü ile hesaplanmıştır. Günlük kalori ihtiyacınız, BMR değerinizin aktivite faktörünüz ile çarpılmasıyla bulunur.',
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.menu_book_rounded, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hesaplamalarımız Dünya Sağlık Örgütü (WHO) ve Hastalık Kontrol ve Önleme Merkezleri (CDC) standartlarına göre yapılmaktadır.',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                  Icon(Icons.monitor_weight_outlined, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    'Vücut Analizi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _showInfoBottomSheet(context),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(Icons.info_outline, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _BodyMetricItem(
                  label: 'BMI',
                  value: bmi.toStringAsFixed(1),
                  subValue: bmiStatus,
                  subValueColor: _getBmiColor(context, bmiStatus),
                ),
              ),
              _buildVerticalDivider(),
              Expanded(
                child: _BodyMetricItem(
                  label: 'BMR',
                  value: bmr.toInt().toString(),
                  subValue: 'kcal/gün',
                ),
              ),
              _buildVerticalDivider(),
              Expanded(
                child: _BodyMetricItem(
                  label: 'Günlük\nKalori',
                  value: dailyCalories.toInt().toString(),
                  subValue: 'kcal',
                ),
              ),
              _buildVerticalDivider(),
              Expanded(
                child: _BodyMetricItem(
                  label: 'İdeal Kilo\nAralığı',
                  value: '${idealRange.min.toInt()} - ${idealRange.max.toInt()}',
                  subValue: 'kg',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 12),
          Center(
            child: Column(
              children: [
                Text(
                  'Vücut Durumu',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _BodyStatusBar(bmiStatus: bmiStatus, bmi: bmi),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    bmiStatus,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey.shade200,
      margin: const EdgeInsets.symmetric(horizontal: 2),
    );
  }

  Color _getBmiColor(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'zayıf':
        return Colors.orange;
      case 'normal':
        return Colors.green;
      case 'kilolu':
      case 'fazla kilolu':
        return Colors.orange.shade700;
      case 'obez':
        return Colors.red;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }
}

class _BodyMetricItem extends StatelessWidget {
  final String label;
  final String value;
  final String subValue;
  final Color? subValueColor;

  const _BodyMetricItem({
    required this.label,
    required this.value,
    required this.subValue,
    this.subValueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.1,
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            subValue,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: subValueColor ?? Colors.grey.shade500,
            ),
          ),
        ),
      ],
    );
  }
}

class _BodyStatusBar extends StatelessWidget {
  final String bmiStatus;
  final double bmi;

  const _BodyStatusBar({required this.bmiStatus, required this.bmi});

  /// Maps a BMI value to a bar position [0.0, 1.0] using category segments:
  /// 0.00 – 0.20 → Underweight  (BMI < 18.5)
  /// 0.20 – 0.55 → Normal       (18.5 ≤ BMI < 25)
  /// 0.55 – 0.75 → Overweight   (25 ≤ BMI < 30)
  /// 0.75 – 1.00 → Obese        (BMI ≥ 30)
  double _getBmiPosition(double bmi) {
    if (bmi < 18.5) {
      return _mapRange(bmi.clamp(15.0, 18.5), 15.0, 18.5, 0.0, 0.20);
    } else if (bmi < 25.0) {
      return _mapRange(bmi, 18.5, 25.0, 0.20, 0.55);
    } else if (bmi < 30.0) {
      return _mapRange(bmi, 25.0, 30.0, 0.55, 0.75);
    } else {
      return _mapRange(bmi.clamp(30.0, 40.0), 30.0, 40.0, 0.75, 1.0);
    }
  }

  double _mapRange(
      double value, double inMin, double inMax, double outMin, double outMax) {
    return outMin + ((value - inMin) / (inMax - inMin)) * (outMax - outMin);
  }

  @override
  Widget build(BuildContext context) {
    final double position = _getBmiPosition(bmi).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double barWidth = constraints.maxWidth;
        // Centered pin width is 12px, half is 6
        final double pinLeft =
            ((barWidth * position) - 6).clamp(0.0, barWidth - 12.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 18,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: pinLeft,
                    bottom: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        CustomPaint(
                          size: const Size(6, 4),
                          painter: _TrianglePainter(color: Theme.of(context).colorScheme.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            // Gradient stops aligned to segment boundaries:
            // 0.00 = red (underweight start)
            // 0.20 = orange (underweight end / normal start transition)
            // 0.375 = green (mid-normal)
            // 0.55 = orange (normal end / overweight start transition)
            // 0.75 = red (overweight end / obese start)
            // 1.00 = dark red (obese)
            Container(
              height: 6,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFE53935), // deep red — underweight
                    Color(0xFFFF7043), // orange — underweight boundary
                    Color(0xFF66BB6A), // green — normal zone
                    Color(0xFF66BB6A), // green — normal zone
                    Color(0xFFFF7043), // orange — overweight boundary
                    Color(0xFFE53935), // deep red — obese
                  ],
                  stops: [0.0, 0.20, 0.30, 0.55, 0.75, 1.0],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;

  const _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width / 2, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
