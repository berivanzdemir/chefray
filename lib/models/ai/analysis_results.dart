// Models for AI analysis results used throughout ChefRay.

// ── Upload Type ──────────────────────────────────────────────────────────────

enum UploadType { dietPdf, bloodPdf }

// ── Document Validation ──────────────────────────────────────────────────────

class DocumentValidationResult {
  final bool isValid;
  final String
  detectedType; // diet_list | blood_test | unknown | unreadable | unsupported
  final double confidence;
  final String extractedTextSummary;
  final String reason;
  final String userMessage;

  const DocumentValidationResult({
    required this.isValid,
    required this.detectedType,
    required this.confidence,
    required this.extractedTextSummary,
    required this.reason,
    required this.userMessage,
  });

  String get extractedText => extractedTextSummary;
  String get summary => extractedTextSummary;

  factory DocumentValidationResult.invalid(
    String message, {
    String reason = '',
  }) => DocumentValidationResult(
    isValid: false,
    detectedType: 'unknown',
    confidence: 0.0,
    extractedTextSummary: '',
    reason: reason,
    userMessage: message,
  );

  Map<String, dynamic> toJson() => {
    'isValid': isValid,
    'detectedType': detectedType,
    'confidence': confidence,
    'extractedTextSummary': extractedTextSummary,
    'reason': reason,
    'userMessage': userMessage,
  };
}

// ── Diet Analysis ────────────────────────────────────────────────────────────

class DietMeal {
  final String name;
  final List<String> items;
  final String? calories;
  const DietMeal({required this.name, this.items = const [], this.calories});
}

class DietAnalysisResult {
  final int? dailyCalorieTarget;
  final DietMeal? breakfast;
  final DietMeal? lunch;
  final DietMeal? dinner;
  final List<DietMeal> snacks;
  final int? proteinGrams;
  final int? carbsGrams;
  final int? fatGrams;
  final List<String> avoidedFoods;
  final String dietSummary;
  final List<String> nutritionNotes;
  final String rawExtractedText;

  const DietAnalysisResult({
    this.dailyCalorieTarget,
    this.breakfast,
    this.lunch,
    this.dinner,
    this.snacks = const [],
    this.proteinGrams,
    this.carbsGrams,
    this.fatGrams,
    this.avoidedFoods = const [],
    this.dietSummary = '',
    this.nutritionNotes = const [],
    this.rawExtractedText = '',
  });

  factory DietAnalysisResult.empty() =>
      const DietAnalysisResult(dietSummary: 'Diyet belgesi analiz edilemedi.');

  Map<String, dynamic> toJson() => {
    'dailyCalorieTarget': dailyCalorieTarget,
    'breakfast': breakfast != null
        ? {
            'name': breakfast!.name,
            'items': breakfast!.items,
            'calories': breakfast!.calories,
          }
        : null,
    'lunch': lunch != null
        ? {
            'name': lunch!.name,
            'items': lunch!.items,
            'calories': lunch!.calories,
          }
        : null,
    'dinner': dinner != null
        ? {
            'name': dinner!.name,
            'items': dinner!.items,
            'calories': dinner!.calories,
          }
        : null,
    'snacks': snacks
        .map((s) => {'name': s.name, 'items': s.items, 'calories': s.calories})
        .toList(),
    'proteinGrams': proteinGrams,
    'carbsGrams': carbsGrams,
    'fatGrams': fatGrams,
    'avoidedFoods': avoidedFoods,
    'dietSummary': dietSummary,
    'nutritionNotes': nutritionNotes,
    'rawExtractedText': rawExtractedText,
  };
}

// ── Blood Analysis ───────────────────────────────────────────────────────────

class BloodMarker {
  final String name;
  final String? value;
  final String? unit;
  final String? referenceRange;
  final String status; // low | high | normal | unknown
  final String? nutritionNote;
  const BloodMarker({
    required this.name,
    this.value,
    this.unit,
    this.referenceRange,
    this.status = 'unknown',
    this.nutritionNote,
  });
}

class BloodAnalysisResult {
  final List<BloodMarker> markers;
  final String generalNote;
  final String safetyWarning;
  final String rawExtractedText;

  const BloodAnalysisResult({
    this.markers = const [],
    this.generalNote = '',
    this.safetyWarning =
        'Bu değerlendirme yalnızca beslenme kişiselleştirmesi içindir. Kesin değerlendirme için sağlık uzmanına danışın.',
    this.rawExtractedText = '',
  });

  factory BloodAnalysisResult.empty() => const BloodAnalysisResult(
    generalNote: 'Kan değerleri belgesi analiz edilemedi.',
  );

  Map<String, dynamic> toJson() => {
    'markers': markers
        .map(
          (m) => {
            'name': m.name,
            'value': m.value,
            'unit': m.unit,
            'referenceRange': m.referenceRange,
            'status': m.status,
            'nutritionNote': m.nutritionNote,
          },
        )
        .toList(),
    'generalNote': generalNote,
    'safetyWarning': safetyWarning,
    'rawExtractedText': rawExtractedText,
  };
}

// ── Combined Analysis ────────────────────────────────────────────────────────

class CombinedHealthAnalysis {
  final String combinedSummary;
  final List<String> nutritionPriorities;
  final List<String> avoidOrLimit;
  final List<String> recommendedMealFocus;
  final List<String> safetyNotes;

  const CombinedHealthAnalysis({
    this.combinedSummary = '',
    this.nutritionPriorities = const [],
    this.avoidOrLimit = const [],
    this.recommendedMealFocus = const [],
    this.safetyNotes = const [],
  });

  factory CombinedHealthAnalysis.empty() =>
      const CombinedHealthAnalysis(combinedSummary: 'Analiz tamamlanamadı.');

  factory CombinedHealthAnalysis.fromJson(Map<String, dynamic> j) =>
      CombinedHealthAnalysis(
        combinedSummary:
            (j['generalSummary'] as String?) ??
            (j['combinedSummary'] as String?) ??
            '',
        nutritionPriorities: List<String>.from(j['nutritionPriorities'] ?? []),
        avoidOrLimit: List<String>.from(j['avoidOrLimit'] ?? []),
        recommendedMealFocus: List<String>.from(
          j['recommendedMealFocus'] ?? [],
        ),
        safetyNotes: List<String>.from(
          j['safetyNotes'] ?? j['additionalHealthTips'] ?? [],
        ),
      );
}

// ── Recipe Recommendation ────────────────────────────────────────────────────

class RecipeRecommendationResult {
  final String recipeId;
  final String recipeTitle;
  final int matchScore; // 0–100
  final String suggestedMealType;
  final String matchReason;
  final List<String> healthNotes;
  final List<String> warnings;
  final List<String> allergenWarnings;
  final List<String> priorityTags;
  final bool isSafeForUser;

  const RecipeRecommendationResult({
    required this.recipeId,
    required this.recipeTitle,
    this.matchScore = 0,
    this.suggestedMealType = '',
    this.matchReason = '',
    this.healthNotes = const [],
    this.warnings = const [],
    this.allergenWarnings = const [],
    this.priorityTags = const [],
    this.isSafeForUser = true,
  });

  factory RecipeRecommendationResult.fromJson(Map<String, dynamic> j) =>
      RecipeRecommendationResult(
        recipeId: (j['recipeId'] as String?) ?? '',
        recipeTitle: (j['recipeTitle'] as String?) ?? '',
        matchScore: (j['matchScore'] as num?)?.toInt() ?? 0,
        suggestedMealType: (j['suggestedMealType'] as String?) ?? '',
        matchReason: (j['matchReason'] as String?) ?? '',
        healthNotes: List<String>.from(j['healthNotes'] ?? []),
        warnings: List<String>.from(j['warnings'] ?? []),
        allergenWarnings: List<String>.from(j['allergenWarnings'] ?? []),
        priorityTags: List<String>.from(j['priorityTags'] ?? []),
        isSafeForUser: (j['isSafeForUser'] as bool?) ?? true,
      );
}
