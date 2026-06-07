import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// Detailed explanation sheet for BMI, BMR, ideal weight, and daily calories.
class BodyAnalysisDetailSheet extends StatelessWidget {
  final double bmi;
  final String bmiStatus;
  final String bmiDescription;
  final double bmr;
  final double dailyCalories;
  final double idealWeightMin;
  final double idealWeightMax;
  final double currentWeight;
  final String? goalType;

  const BodyAnalysisDetailSheet({
    super.key,
    required this.bmi,
    required this.bmiStatus,
    required this.bmiDescription,
    required this.bmr,
    required this.dailyCalories,
    required this.idealWeightMin,
    required this.idealWeightMax,
    required this.currentWeight,
    this.goalType,
  });

  static void show(
    BuildContext context, {
    required double bmi,
    required String bmiStatus,
    required String bmiDescription,
    required double bmr,
    required double dailyCalories,
    required double idealWeightMin,
    required double idealWeightMax,
    required double currentWeight,
    String? goalType,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BodyAnalysisDetailSheet(
        bmi: bmi,
        bmiStatus: bmiStatus,
        bmiDescription: bmiDescription,
        bmr: bmr,
        dailyCalories: dailyCalories,
        idealWeightMin: idealWeightMin,
        idealWeightMax: idealWeightMax,
        currentWeight: currentWeight,
        goalType: goalType,
      ),
    );
  }

  String get _goalLabel {
    switch (goalType?.toLowerCase()) {
      case 'kilo vermek': return 'Kilo vermek';
      case 'kas kazanmak': return 'Kas kazanmak';
      case 'kilo korumak': return 'Kilo korumak';
      default: return goalType ?? 'Belirtilmedi';
    }
  }

  String get _weightVsGoal {
    if (currentWeight <= 0 || idealWeightMin <= 0) return 'Hesaplanamadı';
    if (currentWeight < idealWeightMin) {
      return 'İdeal aralığın ${(idealWeightMin - currentWeight).toStringAsFixed(1)} kg altındasınız.';
    }
    if (currentWeight > idealWeightMax) {
      return 'İdeal aralığın ${(currentWeight - idealWeightMax).toStringAsFixed(1)} kg üstündesiniz.';
    }
    return 'İdeal kilo aralığındasınız.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Detaylı Analiz', style: AppTextStyles.h2),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundMint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMedium),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Column(
                children: [
                  _metricCard(
                    icon: Icons.monitor_heart_rounded,
                    title: 'BMI (Vücut Kitle İndeksi)',
                    value: bmi > 0 ? bmi.toStringAsFixed(1) : '-',
                    status: bmiStatus,
                    statusColor: _bmiStatusColor,
                    description: bmiDescription,
                  ),
                  const SizedBox(height: 14),
                  _metricCard(
                    icon: Icons.local_fire_department_rounded,
                    title: 'BMR (Bazal Metabolizma Hızı)',
                    value: bmr > 0 ? '${bmr.toStringAsFixed(0)} kcal' : '-',
                    status: 'Dinlenme halinde',
                    statusColor: AppColors.carbs,
                    description: 'Vücudunuzun temel yaşam fonksiyonlarını sürdürmek için ihtiyaç duyduğu günlük enerji miktarıdır. '
                        'Bu değer hiç hareket etmeden sadece nefes alıp vermek, kalp atışı gibi işlevler için harcanan kaloriyi gösterir.',
                  ),
                  const SizedBox(height: 14),
                  _metricCard(
                    icon: Icons.restaurant_rounded,
                    title: 'Günlük Kalori İhtiyacı',
                    value: dailyCalories > 0 ? '${dailyCalories.toStringAsFixed(0)} kcal' : '-',
                    status: _goalLabel,
                    statusColor: AppColors.primary,
                    description: 'BMR değerinizin aktivite seviyenize göre çarpılmasıyla hesaplanır. '
                        'Günlük toplam enerji ihtiyacınızı gösterir. '
                        'Hedefinize göre bu değerin altında veya üstünde beslenmeniz önerilir.',
                  ),
                  const SizedBox(height: 14),
                  _metricCard(
                    icon: Icons.scale_rounded,
                    title: 'İdeal Kilo Aralığı',
                    value: idealWeightMin > 0
                        ? '${idealWeightMin.toStringAsFixed(1)} - ${idealWeightMax.toStringAsFixed(1)} kg'
                        : '-',
                    status: _weightVsGoal,
                    statusColor: _idealWeightStatusColor,
                    description: 'BMI 18.5–24.9 aralığı baz alınarak hesaplanan sağlıklı kilo aralığınızdır. '
                        'Bu aralıkta kalmak; kalp hastalığı, diyabet ve diğer kronik rahatsızlıkların riskini azaltır. '
                        'Mevcut kilonuz: ${currentWeight > 0 ? currentWeight.toStringAsFixed(1) : "?"} kg.',
                  ),
                  const SizedBox(height: 20),
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundMint,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Bu değerler genel sağlık referansıdır; tıbbi teşhis veya tedavi yerine geçmez.',
                            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMedium),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color get _bmiStatusColor {
    switch (bmiStatus) {
      case 'Zayıf': return AppColors.info;
      case 'Normal': return AppColors.primary;
      case 'Fazla kilolu': return AppColors.warning;
      case 'Obez': return AppColors.error;
      default: return AppColors.textMedium;
    }
  }

  Color get _idealWeightStatusColor {
    if (currentWeight <= 0 || idealWeightMin <= 0) return AppColors.textMedium;
    if (currentWeight < idealWeightMin) return AppColors.info;
    if (currentWeight > idealWeightMax) return AppColors.warning;
    return AppColors.primary;
  }

  Widget _metricCard({
    required IconData icon,
    required String title,
    required String value,
    required String status,
    required Color statusColor,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.labelMedium.copyWith(color: AppColors.textDark)),
                    const SizedBox(height: 2),
                    Text(status, style: AppTextStyles.labelSmall.copyWith(color: statusColor, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Text(value, style: AppTextStyles.h1.copyWith(fontSize: 20, color: AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 12),
          Text(description, style: AppTextStyles.bodySmall.copyWith(height: 1.5)),
        ],
      ),
    );
  }
}
