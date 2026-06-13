import 'package:flutter/material.dart';

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
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Kilonuzun boyunuza göre oranını gösterir. Kategoriler:',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '• <18.5: Zayıf\n• 18.5 - 24.9: Normal\n• 25.0 - 29.9: Fazla Kilolu\n• 30.0+: Obez',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'BMR & Günlük Kalori',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'BMR (Bazal Metabolizma Hızı), dinlenme halindeki enerji harcamanızdır. Mifflin-St Jeor formülü ile hesaplanmıştır. Günlük kalori ihtiyacınız, BMR değerinizin aktivite faktörünüz ile çarpılmasıyla bulunur.',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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
                  const Icon(
                    Icons.menu_book_rounded,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hesaplamalarımız Dünya Sağlık Örgütü (WHO) ve Hastalık Kontrol ve Önleme Merkezleri (CDC) standartlarına göre yapılmaktadır.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade800,
                      ),
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
                  Icon(
                    Icons.monitor_weight_outlined,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
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
                  child: Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
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
                  value:
                      '${idealRange.min.toInt()} - ${idealRange.max.toInt()}',
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
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF0B3D35),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _BodyStatusBar(bmiStatus: bmiStatus, bmi: bmi),
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

  @override
  Widget build(BuildContext context) {
    // Toplam görsel bar aralığı 16 - 40 olarak düşünüldü (toplam 24 birim)
    final double clampedBmi = bmi.clamp(16.0, 40.0);
    final double positionPercent = (clampedBmi - 16.0) / 24.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double barWidth = constraints.maxWidth;
        final double pinLeft = positionPercent * barWidth;

        return Padding(
          padding: const EdgeInsets.only(top: 65, bottom: 10),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. BMI Segmentli Bar
              Container(
                height: 12,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Row(
                    children: [
                      // Zayıf: 16 - 18.5 (2.5 birim = ~10.4%) -> 25 flex
                      Expanded(
                        flex: 25,
                        child: Container(color: const Color(0xFF64B5F6)),
                      ),
                      Container(width: 1.5, color: Colors.white),
                      // Normal: 18.5 - 25 (6.5 birim = ~27.1%) -> 65 flex
                      Expanded(
                        flex: 65,
                        child: Container(color: const Color(0xFF5BCB75)),
                      ),
                      Container(width: 1.5, color: Colors.white),
                      // Fazla Kilolu: 25 - 30 (5 birim = ~20.8%) -> 50 flex
                      Expanded(
                        flex: 50,
                        child: Container(color: const Color(0xFFF6D65B)),
                      ),
                      Container(width: 1.5, color: Colors.white),
                      // Obez I: 30 - 35 (5 birim = ~20.8%) -> 50 flex
                      Expanded(
                        flex: 50,
                        child: Container(color: const Color(0xFFFF9F43)),
                      ),
                      Container(width: 1.5, color: Colors.white),
                      // Obez II: 35 - 40 (5 birim = ~20.8%) -> 50 flex
                      Expanded(
                        flex: 50,
                        child: Container(color: const Color(0xFFF45B5B)),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Alt Ölçekler (Tick ve yazılar)
              _buildScaleTick(0.0, '16', barWidth),
              _buildScaleTick(2.5 / 24.0, '18.5', barWidth),
              _buildScaleTick(9.0 / 24.0, '25', barWidth),
              _buildScaleTick(14.0 / 24.0, '30', barWidth),
              _buildScaleTick(19.0 / 24.0, '35+', barWidth),

              // 3. Pin Marker ve Etiket
              Positioned(
                left: pinLeft - 40, // 80 genisligindeki widgeti ortala
                bottom: 14, // Barın üstüne yerleşsin
                child: SizedBox(
                  width: 80,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Durum Etiketi
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F8EE),
                          border: Border.all(color: const Color(0xFFBFEACF)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            bmiStatus,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF22A65A),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // BMI Marker Pin
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF16A34A,
                              ).withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          bmi.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      // Noktalı/Kesik dikey çizgi
                      Container(
                        width: 2,
                        height: 6,
                        margin: const EdgeInsets.only(top: 2),
                        color: const Color(0xFF6BBF7A),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScaleTick(double percent, String label, double barWidth) {
    return Positioned(
      left: (percent * barWidth) - 15,
      top: 14, // bar height (12) + gap
      child: SizedBox(
        width: 30,
        child: Column(
          children: [
            Container(width: 1, height: 4, color: const Color(0xFFDDE7E4)),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF7A8B87),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
