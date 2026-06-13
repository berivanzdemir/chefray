/// Pure calculation service for BMI, BMR, ideal weight range, daily calorie needs.
/// All methods are static — no state, no side effects.
class HealthCalculationService {
  HealthCalculationService._();

  // ── BMI ────────────────────────────────────────────────────

  static double calculateBMI(double weightKg, double heightCm) {
    final h = heightCm / 100;
    if (h <= 0) return 0;
    return weightKg / (h * h);
  }

  static String getBMIStatus(double bmi) {
    if (bmi <= 0) return 'Bilinmiyor';
    if (bmi < 18.5) return 'Zayıf';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Fazla kilolu';
    return 'Obez';
  }

  static ({String status, String description}) getBMIDetail(double bmi) {
    if (bmi <= 0) {
      return (
        status: 'Bilinmiyor',
        description:
            'BMI hesaplanamadı. Boy ve kilo bilgilerinizi güncelleyin.',
      );
    }
    if (bmi < 18.5) {
      return (
        status: 'Zayıf',
        description:
            'Vücut ağırlığınız boyunuza göre düşük. Dengeli bir beslenme programıyla ideal kilonuza ulaşabilirsiniz.',
      );
    }
    if (bmi < 25) {
      return (
        status: 'Normal',
        description:
            'Vücut ağırlığınız boyunuza göre ideal aralıkta. Bu durumu korumak sağlığınız için faydalıdır.',
      );
    }
    if (bmi < 30) {
      return (
        status: 'Fazla kilolu',
        description:
            'Vücut ağırlığınız boyunuza göre ideal aralığın üzerinde. Dengeli beslenme ve düzenli aktivite ile ideal kilonuza yaklaşabilirsiniz.',
      );
    }
    return (
      status: 'Obez',
      description:
          'Vücut ağırlığınız boyunuza göre yüksek. Bir sağlık uzmanına danışarak size özel bir plan oluşturmanız önerilir.',
    );
  }

  // ── Ideal Weight Range ─────────────────────────────────────

  static ({double min, double max}) calculateIdealWeightRange(double heightCm) {
    final h = heightCm / 100;
    return (min: 18.5 * h * h, max: 24.9 * h * h);
  }

  // ── BMR (Mifflin-St Jeor) ──────────────────────────────────

  static double calculateBMR(
    double weightKg,
    double heightCm,
    int age,
    String gender,
  ) {
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    final g = gender.toLowerCase();
    if (g == 'erkek' || g == 'male') return base + 5;
    // Kadın / Female / Diğer
    return base - 161;
  }

  // ── Activity Coefficient ───────────────────────────────────

  static double _activityCoefficient(String? activityLevel) {
    switch (activityLevel?.toLowerCase()) {
      case 'düşük':
      case 'low':
      case 'sedentary':
        return 1.2;
      case 'orta':
      case 'medium':
      case 'moderate':
        return 1.55;
      case 'yüksek':
      case 'high':
      case 'active':
      case 'çok aktif':
      case 'very active':
        return 1.725;
      default:
        return 1.55; // Default: Orta
    }
  }

  // ── Daily Calories ─────────────────────────────────────────

  static double calculateDailyCalories(double bmr, String? activityLevel) {
    return bmr * _activityCoefficient(activityLevel);
  }

  // ── Daily Goals ────────────────────────────────────────────

  static ({double calories, double proteinG, double waterMl})
  calculateDailyGoals(double dailyCalories, double weightKg, String? goalType) {
    double calorieGoal = dailyCalories;
    double proteinG = weightKg * 1.6; // g/kg
    double waterMl = weightKg * 33; // ml/kg

    switch (goalType?.toLowerCase()) {
      case 'kilo vermek':
      case 'lose weight':
        calorieGoal = dailyCalories - 300;
        proteinG = weightKg * 2.0;
        waterMl = weightKg * 35;
        break;
      case 'kas kazanmak':
      case 'gain muscle':
        calorieGoal = dailyCalories + 300;
        proteinG = weightKg * 2.2;
        waterMl = weightKg * 35;
        break;
      case 'kilo korumak':
      case 'maintain weight':
      case 'daha dengeli beslenmek':
      case 'sağlıklı tarifler keşfetmek':
      default:
        break;
    }

    return (calories: calorieGoal, proteinG: proteinG, waterMl: waterMl);
  }

  // ── Suggestions ────────────────────────────────────────────

  static List<String> getSuggestions(
    String? goalType,
    double bmi,
    String bmiStatus,
  ) {
    final suggestions = <String>[];

    // Goal-based suggestions
    switch (goalType?.toLowerCase()) {
      case 'kilo vermek':
      case 'lose weight':
        suggestions.add('Gün içinde su tüketimini biraz daha artır.');
        suggestions.add(
          'Protein hedefini tamamlamak için dengeli ara öğün ekleyebilirsin.',
        );
        suggestions.add(
          'Haftada birkaç gün hafif egzersiz eklemek hedefini destekleyebilir.',
        );
        break;
      case 'kas kazanmak':
      case 'gain muscle':
        suggestions.add(
          'Protein alımını artırmak için öğünlerine yumurta, tavuk veya baklagil ekle.',
        );
        suggestions.add(
          'Düzenli ağırlık çalışması kas kazanımını hızlandırabilir.',
        );
        suggestions.add(
          'Antrenman sonrası karbonhidrat ve protein dengesine dikkat et.',
        );
        break;
      case 'kilo korumak':
      case 'maintain weight':
        suggestions.add(
          'Mevcut beslenme düzenini koruyarak porsiyon kontrolüne devam et.',
        );
        suggestions.add('Haftalık düzenli tartı takibi ile kilonu sabit tut.');
        suggestions.add('Farklı besin gruplarından dengeli öğünler oluştur.');
        break;
      default:
        suggestions.add('Dengeli ve çeşitli beslenmeye özen göster.');
        suggestions.add('Günde en az 2 litre su içmeyi hedefle.');
        suggestions.add('Haftada 150 dakika orta tempolu aktivite hedefle.');
    }

    // BMI-based additions
    if (bmiStatus == 'Zayıf') {
      if (!suggestions.any((s) => s.contains('dengeli'))) {
        suggestions.add(
          'Dengeli bir beslenme programıyla ideal kilona ulaşabilirsin.',
        );
      }
    } else if (bmiStatus == 'Fazla kilolu' || bmiStatus == 'Obez') {
      if (!suggestions.any((s) => s.contains('su'))) {
        suggestions.add(
          'Gün içinde su tüketimini artırarak metabolizmanı destekle.',
        );
      }
    }

    return suggestions.take(3).toList();
  }
}
