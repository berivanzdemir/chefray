/// Model for diet analysis result data.
class AnalysisModel {
  final int currentCalories;
  final int targetCalories;
  final double caloriePercentage;
  final int remainingCalories;
  final List<GoalStatus> goals;
  final List<AllergenStatus> allergens;
  final MealDistribution distribution;
  final String aiComment;
  final String analysisDate;

  const AnalysisModel({
    required this.currentCalories,
    required this.targetCalories,
    required this.caloriePercentage,
    required this.remainingCalories,
    required this.goals,
    required this.allergens,
    required this.distribution,
    required this.aiComment,
    required this.analysisDate,
  });
}

class GoalStatus {
  final String name;
  final String status; // 'uygun', 'uygun_degil', 'kismen'
  final String label;

  const GoalStatus({
    required this.name,
    required this.status,
    required this.label,
  });
}

class AllergenStatus {
  final String name;
  final bool detected;

  const AllergenStatus({required this.name, required this.detected});
}

class MealDistribution {
  final int breakfast;
  final int lunch;
  final int dinner;
  final int snack;

  const MealDistribution({
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.snack,
  });
}

class AnalysisMockData {
  AnalysisMockData._();

  static const AnalysisModel result = AnalysisModel(
    currentCalories: 1450,
    targetCalories: 2200,
    caloriePercentage: 0.66,
    remainingCalories: 750,
    goals: [
      GoalStatus(name: 'Yüksek Protein', status: 'uygun', label: 'Hedefe uygun'),
      GoalStatus(name: 'Glutensiz', status: 'uygun_degil', label: 'Hedefe uygun değil'),
      GoalStatus(name: 'Düşük Şeker', status: 'uygun', label: 'Hedefe uygun'),
      GoalStatus(name: 'Düşük Yağ', status: 'kismen', label: 'Kısmen uygun'),
    ],
    allergens: [
      AllergenStatus(name: 'Gluten', detected: true),
      AllergenStatus(name: 'Laktoz', detected: true),
      AllergenStatus(name: 'Kuruyemiş', detected: false),
      AllergenStatus(name: 'Soya', detected: false),
    ],
    distribution: MealDistribution(
      breakfast: 25,
      lunch: 30,
      dinner: 30,
      snack: 15,
    ),
    aiComment:
        'Protein alımın iyi görünüyor! 💪 Karbonhidrat oranını biraz azaltarak hedeflerine daha kolay ulaşabilirsin.',
    analysisDate: '20 Mayıs 2024 · 10:42',
  );
}
