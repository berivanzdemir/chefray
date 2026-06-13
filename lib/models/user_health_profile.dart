/// User health & nutrition profile gathered during the "Seni Tanıyalım"
/// onboarding flow. Persisted to Supabase `user_health_profiles` table.
class UserHealthProfile {
  final String? id;
  final String userId;
  final String? name;
  final int? age;
  final String? gender;
  final double? heightCm;
  final double? weightKg;
  final String? goalType;
  final List<String> healthConditions;
  final List<String> allergies;
  final List<String> dietPreferences;
  final String? activityLevel;
  final int streakDays;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserHealthProfile({
    this.id,
    this.userId = '',
    this.name,
    this.age,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.goalType,
    this.healthConditions = const [],
    this.allergies = const [],
    this.dietPreferences = const [],
    this.activityLevel,
    this.streakDays = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory UserHealthProfile.empty() {
    return const UserHealthProfile(
      userId: '',
      name: null,
      age: null,
      gender: null,
      heightCm: null,
      weightKg: null,
      goalType: null,
      healthConditions: [],
      allergies: [],
      dietPreferences: [],
      activityLevel: null,
      streakDays: 0,
    );
  }

  double get bmi {
    if (heightCm == null || weightKg == null || heightCm! <= 0) return 0;
    final h = heightCm! / 100;
    return weightKg! / (h * h);
  }

  UserHealthProfile copyWith({
    String? id,
    String? userId,
    String? name,
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
    String? goalType,
    List<String>? healthConditions,
    List<String>? allergies,
    List<String>? dietPreferences,
    String? activityLevel,
    int? streakDays,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserHealthProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      goalType: goalType ?? this.goalType,
      healthConditions: healthConditions ?? this.healthConditions,
      allergies: allergies ?? this.allergies,
      dietPreferences: dietPreferences ?? this.dietPreferences,
      activityLevel: activityLevel ?? this.activityLevel,
      streakDays: streakDays ?? this.streakDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'age': age,
    'gender': gender,
    'height_cm': heightCm,
    'weight_kg': weightKg,
    'goal_type': goalType,
    'health_conditions': healthConditions,
    'allergies': allergies,
    'diet_preferences': dietPreferences,
    'activity_level': activityLevel,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
  };

  factory UserHealthProfile.fromJson(Map<String, dynamic> json) {
    return UserHealthProfile(
      id: json['id'] as String?,
      userId: (json['user_id'] as String?) ?? '',
      name: json['name'] as String?,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      heightCm: _toDouble(json['height_cm']),
      weightKg: _toDouble(json['weight_kg']),
      goalType:
          (json['goal_type'] as String?) ?? json['nutrition_goal'] as String?,
      healthConditions: List<String>.from(
        (json['health_conditions'] as List?) ?? [],
      ),
      allergies: List<String>.from((json['allergies'] as List?) ?? []),
      dietPreferences: List<String>.from(
        (json['diet_preferences'] as List?) ??
            (json['diet_preference'] != null
                ? [json['diet_preference'] as String]
                : []),
      ),
      activityLevel: json['activity_level'] as String?,
      streakDays: (json['streak_days'] as int?) ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
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
