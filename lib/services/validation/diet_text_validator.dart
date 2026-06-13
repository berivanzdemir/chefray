import '../ocr/ocr_service.dart';

class DietValidationResult {
  final bool isDiet;
  final double confidence;
  final String message;
  final List<String> matchedSignals;
  final int mealSignalCount;
  final int foodSignalCount;
  final int negativeSignalCount;

  const DietValidationResult({
    required this.isDiet,
    required this.confidence,
    required this.message,
    this.matchedSignals = const [],
    this.mealSignalCount = 0,
    this.foodSignalCount = 0,
    this.negativeSignalCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'is_diet': isDiet,
    'confidence': confidence,
    'message': message,
    'matched_signals': matchedSignals,
    'meal_signal_count': mealSignalCount,
    'food_signal_count': foodSignalCount,
    'negative_signal_count': negativeSignalCount,
  };
}

class DietTextValidator {
  static final DietTextValidator _instance = DietTextValidator._();
  factory DietTextValidator() => _instance;
  DietTextValidator._();

  static const _positiveMealSignals = [
    'kahvaltı',
    'ara öğün',
    'ara ogun',
    'öğle',
    'ogle',
    'akşam',
    'aksam',
    'gece öğünü',
    'gece ogunu',
    'öğün',
    'ogun',
    'diyet',
    'liste',
    'beslenme',
    'gram',
    'porsiyon',
    'kalori',
    'kcal',
  ];

  static const _positiveFoodSignals = [
    'yumurta',
    'peynir',
    'zeytin',
    'yoğurt',
    'yogurt',
    'tavuk',
    'balık',
    'balik',
    'salata',
    'sebze',
    'meyve',
    'yulaf',
    'çorba',
    'corba',
    'bulgur',
    'pirinç',
    'ekmek',
    'domates',
    'salatalık',
    'biber',
    'ıspanak',
    'ispanak',
    'brokoli',
    'havuç',
    'patates',
    'soğan',
    'sogan',
    'mercimek',
    'nohut',
    'fasulye',
    'makarna',
    'pilav',
    'kinoa',
    'chia',
    'keten',
    'ceviz',
    'badem',
    'zeytinyağı',
    'zeytinyagi',
    'tereyağı',
    'tereyagi',
    'bal',
    'reçel',
    'receller',
    'şeker',
    'seker',
    'kepek',
    'tam buğday',
    'tam bugday',
    'çavdar',
    'cavdar',
    'ton balığı',
    'ton baligi',
    'somon',
    'levrek',
    'çupra',
    'cupra',
    'köfte',
    'kofte',
    'et',
    'kıyma',
    'kiyma',
    'süt',
    'sut',
    'ayran',
    'kefir',
    'peynir altı suyu',
    'humus',
    'tahin',
    'avokado',
    'muz',
    'elma',
    'portakal',
    'mandalina',
    'üzüm',
    'uzum',
    'çilek',
    'cilek',
    'karpuz',
    'kavun',
    'ananas',
    'yaban mersini',
    'tarif',
    'yemek',
    'öneri',
    'oneri',
    'plan',
    'günlük',
    'gunluk',
    'haftalık',
    'haftalik',
    'pazartesi',
    'salı',
    'sali',
    'çarşamba',
    'carsamba',
    'perşembe',
    'persembe',
    'cuma',
    'cumartesi',
    'pazar',
    '1. gün',
    '2. gün',
    '3. gün',
    '1.gün',
    '2.gün',
    '3.gün',
    'kuşluk',
    'kusluk',
    'ikindi',
  ];

  static const _negativeLabSignals = [
    'hemogram',
    'glukoz',
    'glucose',
    'ldl',
    'hdl',
    'trigliserid',
    'triglyceride',
    'ferritin',
    'tsh',
    'hgb',
    'hemoglobin',
    'eritrosit',
    'erythrocyte',
    'lökosit',
    'leukocyte',
    'laboratuvar',
    'laboratory',
    'referans aralığı',
    'referans araligi',
    'reference range',
    'biyokimya',
    'biochemistry',
    'tam kan sayımı',
    'tam kan sayimi',
    'complete blood count',
    'sonuç',
    'sonuc',
    'birim',
    'unit',
    'hba1c',
    'a1c',
    'alt',
    'ast',
    'kreatinin',
    'creatinine',
    'üre',
    'ure',
    'crp',
    'wbc',
    'rbc',
    'plt',
    'trombosit',
    'platelet',
    'demir',
    'iron',
    'kalsiyum',
    'calcium',
    'magnezyum',
    'magnesium',
    'sodyum',
    'sodium',
    'potasyum',
    'potassium',
    'albümin',
    'albumin',
    'total protein',
    'total kolesterol',
    'total cholesterol',
    'ürük asit',
    'uric acid',
    'sedimentasyon',
    'sedimentation',
    'hematokrit',
    'hematocrit',
    'mcv',
    'mch',
    'mchc',
  ];

  DietValidationResult validate(OcrResult ocrResult) {
    if (!ocrResult.success || ocrResult.isEmpty) {
      return const DietValidationResult(
        isDiet: false,
        confidence: 0.0,
        message:
            'Diyet listesinden okunabilir metin çıkarılamadı. '
            'Lütfen daha net bir fotoğraf veya PDF yükleyin.',
        matchedSignals: [],
        mealSignalCount: 0,
        foodSignalCount: 0,
        negativeSignalCount: 0,
      );
    }

    final text = ocrResult.lowerText;
    final matchedSignals = <String>[];

    // Count positive meal signals
    int mealSignalCount = 0;
    for (final signal in _positiveMealSignals) {
      if (text.contains(signal)) {
        mealSignalCount++;
        matchedSignals.add(signal);
      }
    }

    // Count positive food signals
    int foodSignalCount = 0;
    for (final signal in _positiveFoodSignals) {
      if (text.contains(signal)) {
        foodSignalCount++;
        matchedSignals.add(signal);
      }
    }

    // Count negative lab signals
    int negativeSignalCount = 0;
    for (final signal in _negativeLabSignals) {
      if (text.contains(signal)) {
        negativeSignalCount++;
      }
    }

    // Validation rules
    // 1. Empty text → reject
    // 2. At least 2 meal signals required
    // 3. At least 3 food signals required
    // 4. If lab signals outnumber meal signals, reject

    final meetsMealRequirement = mealSignalCount >= 2;
    final meetsFoodRequirement = foodSignalCount >= 3;
    final labDominant = negativeSignalCount > mealSignalCount + foodSignalCount;

    // Calculate confidence
    double confidence = 0.0;
    if (meetsMealRequirement && meetsFoodRequirement) {
      confidence += 0.5;
      confidence += (mealSignalCount * 0.05).clamp(0.0, 0.2);
      confidence += (foodSignalCount * 0.03).clamp(0.0, 0.2);
      confidence -= (negativeSignalCount * 0.05).clamp(0.0, 0.2);
      confidence = confidence.clamp(0.0, 1.0);
    } else if (mealSignalCount >= 1 && foodSignalCount >= 1) {
      // Borderline case
      confidence = 0.4 + (mealSignalCount * 0.03) + (foodSignalCount * 0.02);
      confidence = confidence.clamp(0.0, 0.55);
    }

    if (labDominant) {
      return DietValidationResult(
        isDiet: false,
        confidence: confidence * 0.3,
        message:
            'Bu dosya diyet listesi gibi görünmüyor. '
            'Laboratuvar sinyalleri tespit edildi. '
            'Lütfen öğün bilgileri içeren bir diyet listesi yükleyin.',
        matchedSignals: matchedSignals,
        mealSignalCount: mealSignalCount,
        foodSignalCount: foodSignalCount,
        negativeSignalCount: negativeSignalCount,
      );
    }

    if (!meetsMealRequirement || !meetsFoodRequirement) {
      return DietValidationResult(
        isDiet: false,
        confidence: confidence,
        message:
            'Bu dosya diyet listesi gibi görünmüyor. '
            'Lütfen öğün bilgileri içeren bir diyet listesi yükleyin.',
        matchedSignals: matchedSignals,
        mealSignalCount: mealSignalCount,
        foodSignalCount: foodSignalCount,
        negativeSignalCount: negativeSignalCount,
      );
    }

    // Low confidence warning
    if (confidence < 0.6) {
      return DietValidationResult(
        isDiet: true,
        confidence: confidence,
        message:
            'Bu dosya diyet listesi gibi görünüyor ancak emin değiliz. '
            'Belge kalitesi düşük olabilir.',
        matchedSignals: matchedSignals,
        mealSignalCount: mealSignalCount,
        foodSignalCount: foodSignalCount,
        negativeSignalCount: negativeSignalCount,
      );
    }

    return DietValidationResult(
      isDiet: true,
      confidence: confidence,
      message: 'Diyet listesi başarıyla doğrulandı.',
      matchedSignals: matchedSignals,
      mealSignalCount: mealSignalCount,
      foodSignalCount: foodSignalCount,
      negativeSignalCount: negativeSignalCount,
    );
  }
}
