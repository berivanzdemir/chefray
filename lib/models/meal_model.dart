/// Model for a single meal item detected in diet analysis.
class MealModel {
  final String name;
  final String time;
  final String mealType;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  const MealModel({
    required this.name,
    required this.time,
    required this.mealType,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}

// ── Mock Data ──────────────────────────────────────────────
class MealMockData {
  MealMockData._();

  static const List<MealModel> detectedMeals = [
    MealModel(
      name: 'Izgara Tavuk, Bulgur Pilavı, Salata',
      time: '12:45',
      mealType: 'Öğle Yemeği',
      calories: 520,
      protein: 42,
      carbs: 62,
      fat: 14,
    ),
    MealModel(
      name: 'Omlet, Tam Buğday Ekmek, Domates',
      time: '08:30',
      mealType: 'Kahvaltı',
      calories: 350,
      protein: 28,
      carbs: 30,
      fat: 12,
    ),
    MealModel(
      name: 'Yoğurt, Muz, Ceviz',
      time: '16:20',
      mealType: 'Ara Öğün',
      calories: 220,
      protein: 12,
      carbs: 28,
      fat: 6,
    ),
  ];
}
