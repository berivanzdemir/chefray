class DailyGoals {
  final String? id;
  final String userId;
  final DateTime targetDate;
  
  final double caloriesTarget;
  final double caloriesConsumed;
  
  final double proteinTarget;
  final double proteinConsumed;
  
  final double waterTarget;
  final double waterConsumed;
  
  final double activityTarget;
  final double activityCompleted;

  DailyGoals({
    this.id,
    required this.userId,
    required this.targetDate,
    required this.caloriesTarget,
    this.caloriesConsumed = 0,
    required this.proteinTarget,
    this.proteinConsumed = 0,
    required this.waterTarget,
    this.waterConsumed = 0,
    required this.activityTarget,
    this.activityCompleted = 0,
  });

  factory DailyGoals.fromJson(Map<String, dynamic> json) {
    return DailyGoals(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      targetDate: DateTime.parse(json['target_date'] as String),
      caloriesTarget: _toDouble(json['calories_target']) ?? 2000,
      caloriesConsumed: _toDouble(json['calories_consumed']) ?? 0,
      proteinTarget: _toDouble(json['protein_target']) ?? 100,
      proteinConsumed: _toDouble(json['protein_consumed']) ?? 0,
      waterTarget: _toDouble(json['water_target']) ?? 8,
      waterConsumed: _toDouble(json['water_consumed']) ?? 0,
      activityTarget: _toDouble(json['activity_target']) ?? 60,
      activityCompleted: _toDouble(json['activity_completed']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'target_date': "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}",
      'calories_target': caloriesTarget,
      'calories_consumed': caloriesConsumed,
      'protein_target': proteinTarget,
      'protein_consumed': proteinConsumed,
      'water_target': waterTarget,
      'water_consumed': waterConsumed,
      'activity_target': activityTarget,
      'activity_completed': activityCompleted,
    };
  }

  DailyGoals copyWith({
    String? id,
    String? userId,
    DateTime? targetDate,
    double? caloriesTarget,
    double? caloriesConsumed,
    double? proteinTarget,
    double? proteinConsumed,
    double? waterTarget,
    double? waterConsumed,
    double? activityTarget,
    double? activityCompleted,
  }) {
    return DailyGoals(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      targetDate: targetDate ?? this.targetDate,
      caloriesTarget: caloriesTarget ?? this.caloriesTarget,
      caloriesConsumed: caloriesConsumed ?? this.caloriesConsumed,
      proteinTarget: proteinTarget ?? this.proteinTarget,
      proteinConsumed: proteinConsumed ?? this.proteinConsumed,
      waterTarget: waterTarget ?? this.waterTarget,
      waterConsumed: waterConsumed ?? this.waterConsumed,
      activityTarget: activityTarget ?? this.activityTarget,
      activityCompleted: activityCompleted ?? this.activityCompleted,
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
