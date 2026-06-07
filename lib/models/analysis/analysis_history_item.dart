import '../ai/analysis_results.dart';

class AnalysisHistoryItem {
  final String id;
  final String userId;
  final DateTime createdAt;

  final DietAnalysisResult? dietAnalysis;
  final BloodAnalysisResult? bloodAnalysis;
  final CombinedHealthAnalysis? combinedAnalysis;

  final String summary;
  final List<String> nutritionPriorities;
  final List<String> safetyNotes;

  const AnalysisHistoryItem({
    required this.id,
    required this.userId,
    required this.createdAt,
    this.dietAnalysis,
    this.bloodAnalysis,
    this.combinedAnalysis,
    required this.summary,
    required this.nutritionPriorities,
    required this.safetyNotes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'summary': summary,
      'nutrition_priorities': nutritionPriorities,
      'safety_notes': safetyNotes,
      'diet_analysis': dietAnalysis != null ? _dietAnalysisToJson(dietAnalysis!) : null,
      'blood_analysis': bloodAnalysis != null ? _bloodAnalysisToJson(bloodAnalysis!) : null,
      'combined_analysis': combinedAnalysis != null ? _combinedAnalysisToJson(combinedAnalysis!) : null,
    };
  }

  factory AnalysisHistoryItem.fromJson(Map<String, dynamic> json) {
    return AnalysisHistoryItem(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? json['userId'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : (json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now()),
      summary: json['summary'] ?? '',
      nutritionPriorities: List<String>.from(json['nutrition_priorities'] ?? json['nutritionPriorities'] ?? []),
      safetyNotes: List<String>.from(json['safety_notes'] ?? json['safetyNotes'] ?? []),
      dietAnalysis: json['diet_analysis'] != null 
          ? _dietAnalysisFromJson(json['diet_analysis']) 
          : (json['dietAnalysis'] != null ? _dietAnalysisFromJson(json['dietAnalysis']) : null),
      bloodAnalysis: json['blood_analysis'] != null 
          ? _bloodAnalysisFromJson(json['blood_analysis']) 
          : (json['bloodAnalysis'] != null ? _bloodAnalysisFromJson(json['bloodAnalysis']) : null),
      combinedAnalysis: json['combined_analysis'] != null 
          ? _combinedAnalysisFromJson(json['combined_analysis']) 
          : (json['combinedAnalysis'] != null ? _combinedAnalysisFromJson(json['combinedAnalysis']) : null),
    );
  }

  // Helper serializers for DietAnalysisResult
  static Map<String, dynamic> _dietAnalysisToJson(DietAnalysisResult res) {
    return {
      'dailyCalorieTarget': res.dailyCalorieTarget,
      'proteinGrams': res.proteinGrams,
      'carbsGrams': res.carbsGrams,
      'fatGrams': res.fatGrams,
      'dietSummary': res.dietSummary,
      'avoidedFoods': res.avoidedFoods,
      'nutritionNotes': res.nutritionNotes,
      'rawExtractedText': res.rawExtractedText,
      'breakfast': res.breakfast != null ? _dietMealToJson(res.breakfast!) : null,
      'lunch': res.lunch != null ? _dietMealToJson(res.lunch!) : null,
      'dinner': res.dinner != null ? _dietMealToJson(res.dinner!) : null,
      'snacks': res.snacks.map((s) => _dietMealToJson(s)).toList(),
    };
  }

  static DietAnalysisResult _dietAnalysisFromJson(Map<String, dynamic> map) {
    return DietAnalysisResult(
      dailyCalorieTarget: map['dailyCalorieTarget'] as int?,
      proteinGrams: map['proteinGrams'] as int?,
      carbsGrams: map['carbsGrams'] as int?,
      fatGrams: map['fatGrams'] as int?,
      dietSummary: map['dietSummary'] as String? ?? '',
      avoidedFoods: List<String>.from(map['avoidedFoods'] ?? []),
      nutritionNotes: List<String>.from(map['nutritionNotes'] ?? []),
      rawExtractedText: map['rawExtractedText'] as String? ?? '',
      breakfast: map['breakfast'] != null ? _dietMealFromJson(map['breakfast']) : null,
      lunch: map['lunch'] != null ? _dietMealFromJson(map['lunch']) : null,
      dinner: map['dinner'] != null ? _dietMealFromJson(map['dinner']) : null,
      snacks: (map['snacks'] as List?)?.map((s) => _dietMealFromJson(s)).toList() ?? const [],
    );
  }

  static Map<String, dynamic> _dietMealToJson(DietMeal meal) {
    return {
      'name': meal.name,
      'items': meal.items,
      'calories': meal.calories,
    };
  }

  static DietMeal _dietMealFromJson(Map<String, dynamic> map) {
    return DietMeal(
      name: map['name'] as String? ?? '',
      items: List<String>.from(map['items'] ?? []),
      calories: map['calories'] as String?,
    );
  }

  // Helper serializers for BloodAnalysisResult
  static Map<String, dynamic> _bloodAnalysisToJson(BloodAnalysisResult res) {
    return {
      'generalNote': res.generalNote,
      'safetyWarning': res.safetyWarning,
      'rawExtractedText': res.rawExtractedText,
      'markers': res.markers.map((m) => _bloodMarkerToJson(m)).toList(),
    };
  }

  static BloodAnalysisResult _bloodAnalysisFromJson(Map<String, dynamic> map) {
    return BloodAnalysisResult(
      generalNote: map['generalNote'] as String? ?? '',
      safetyWarning: map['safetyWarning'] as String? ?? '',
      rawExtractedText: map['rawExtractedText'] as String? ?? '',
      markers: (map['markers'] as List?)?.map((m) => _bloodMarkerFromJson(m)).toList() ?? const [],
    );
  }

  static Map<String, dynamic> _bloodMarkerToJson(BloodMarker marker) {
    return {
      'name': marker.name,
      'value': marker.value,
      'unit': marker.unit,
      'referenceRange': marker.referenceRange,
      'status': marker.status,
      'nutritionNote': marker.nutritionNote,
    };
  }

  static BloodMarker _bloodMarkerFromJson(Map<String, dynamic> map) {
    return BloodMarker(
      name: map['name'] as String? ?? '',
      value: map['value'] as String?,
      unit: map['unit'] as String?,
      referenceRange: map['referenceRange'] as String?,
      status: map['status'] as String? ?? 'unknown',
      nutritionNote: map['nutritionNote'] as String?,
    );
  }

  // Helper serializers for CombinedHealthAnalysis
  static Map<String, dynamic> _combinedAnalysisToJson(CombinedHealthAnalysis res) {
    return {
      'combinedSummary': res.combinedSummary,
      'nutritionPriorities': res.nutritionPriorities,
      'avoidOrLimit': res.avoidOrLimit,
      'recommendedMealFocus': res.recommendedMealFocus,
      'safetyNotes': res.safetyNotes,
    };
  }

  static CombinedHealthAnalysis _combinedAnalysisFromJson(Map<String, dynamic> map) {
    return CombinedHealthAnalysis(
      combinedSummary: map['combinedSummary'] as String? ?? '',
      nutritionPriorities: List<String>.from(map['nutritionPriorities'] ?? []),
      avoidOrLimit: List<String>.from(map['avoidOrLimit'] ?? []),
      recommendedMealFocus: List<String>.from(map['recommendedMealFocus'] ?? []),
      safetyNotes: List<String>.from(map['safetyNotes'] ?? []),
    );
  }
}
