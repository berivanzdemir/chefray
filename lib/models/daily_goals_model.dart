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
    // Handle both SharedPreferences cache (old names) and Supabase (new names)
    final dateStr = json['target_date'] ?? json['goal_date'];

    // water_goal_l is in liters, app uses ml.
    double wTarget = 2000;
    if (json['water_target'] != null) {
      wTarget = _toDouble(json['water_target']) ?? 2000;
    } else if (json['water_goal_l'] != null) {
      wTarget = (_toDouble(json['water_goal_l']) ?? 2.0) * 1000;
    }

    // water_consumed_l is in liters, app uses ml.
    double wConsumed = 0;
    if (json['water_consumed'] != null) {
      wConsumed = _toDouble(json['water_consumed']) ?? 0;
    } else if (json['water_consumed_l'] != null) {
      wConsumed = (_toDouble(json['water_consumed_l']) ?? 0) * 1000;
    }

    return DailyGoals(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      targetDate: dateStr != null
          ? DateTime.parse(dateStr as String)
          : DateTime.now(),
      caloriesTarget:
          _toDouble(json['calories_target'] ?? json['calorie_goal']) ?? 2000,
      caloriesConsumed:
          _toDouble(json['calories_consumed']) ??
          0, // App state is always accurate via local cache
      proteinTarget:
          _toDouble(json['protein_target'] ?? json['protein_goal_g']) ?? 100,
      proteinConsumed: _toDouble(json['protein_consumed']) ?? 0,
      waterTarget: wTarget,
      waterConsumed: wConsumed,
      activityTarget:
          _toDouble(json['activity_target'] ?? json['activity_goal_min']) ?? 60,
      activityCompleted:
          _toDouble(
            json['activity_completed'] ?? json['activity_completed_min'],
          ) ??
          0,
    );
  }

  // Used for saving to SharedPreferences (local cache)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'target_date':
          "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}",
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

  // Used for saving to Supabase (only existing columns)
  Map<String, dynamic> toSupabaseJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'goal_date':
          "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}",
      'calorie_goal': caloriesTarget.round(),
      'protein_goal_g': proteinTarget.round(),
      'water_goal_l': waterTarget / 1000.0, // ml to L
      'activity_goal_min': activityTarget.round(),
      'water_consumed_l': waterConsumed / 1000.0, // ml to L
      'activity_completed_min': activityCompleted.round(),
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
