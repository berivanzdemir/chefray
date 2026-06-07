class HealthScoreService {
  /// Computes a health score out of 100 based on goals and simple rules
  static int calculateHealthScore({
    required double waterPercent,
    required double caloriePercent,
    required double proteinPercent,
    required double activityPercent,
    List<String> bloodTestFlags = const [],
  }) {
    int score = 100;

    if (waterPercent < 0.5) score -= 10;
    
    // Being very far from calorie goal (e.g. eating < 50% or > 150%)
    if (caloriePercent < 0.5 || caloriePercent > 1.5) score -= 10;
    
    if (proteinPercent < 0.6) score -= 10;
    if (activityPercent < 0.5) score -= 10;

    // Blood test flags logic (simplified)
    for (final flag in bloodTestFlags) {
      final lower = flag.toLowerCase();
      if (lower.contains('düşük') || lower.contains('yüksek') || lower.contains('riskli')) {
        score -= 5;
      }
    }

    // Clamp between 0 and 100
    if (score < 0) return 0;
    if (score > 100) return 100;
    
    return score;
  }

  static String getHealthScoreStatus(int score) {
    if (score >= 80) return 'Dengeli';
    if (score >= 60) return 'Dikkat Edilmeli';
    if (score >= 40) return 'Geliştirilmeli';
    return 'Riskli / Düşük';
  }
}
