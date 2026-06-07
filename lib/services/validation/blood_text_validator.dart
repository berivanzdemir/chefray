import '../ocr/ocr_service.dart';

class BloodValidationResult {
  final bool isBloodTest;
  final double confidence;
  final String message;
  final List<String> matchedSignals;
  final int labSignalCount;
  final int numericValueCount;
  final int negativeSignalCount;

  const BloodValidationResult({
    required this.isBloodTest,
    required this.confidence,
    required this.message,
    this.matchedSignals = const [],
    this.labSignalCount = 0,
    this.numericValueCount = 0,
    this.negativeSignalCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'is_blood_test': isBloodTest,
        'confidence': confidence,
        'message': message,
        'matched_signals': matchedSignals,
        'lab_signal_count': labSignalCount,
        'numeric_value_count': numericValueCount,
        'negative_signal_count': negativeSignalCount,
      };
}

class BloodTextValidator {
  static final BloodTextValidator _instance = BloodTextValidator._();
  factory BloodTextValidator() => _instance;
  BloodTextValidator._();

  static const _positiveLabSignals = [
    'hemogram', 'biyokimya', 'laboratuvar', 'laboratory',
    'referans aralığı', 'referans araligi', 'reference range',
    'sonuç', 'sonuc', 'birim', 'unit',
    'glukoz', 'glucose', 'açlık glukoz', 'aclik glukoz', 'fasting glucose',
    'hba1c', 'a1c', 'hemoglobin a1c',
    'ldl', 'hdl', 'total kolesterol', 'total cholesterol',
    'trigliserid', 'triglyceride',
    'b12', 'b 12', 'vitamin b12',
    'vitamin d', 'd vitamini', '25-oh', '25 oh',
    'ferritin', 'demir', 'iron', 'serum demir',
    'tsh', 'tiroid', 'thyroid',
    'alt', 'ast', 'sgpt', 'sgot',
    'kreatinin', 'creatinine',
    'üre', 'ure', 'bun',
    'crp', 'c-reaktif', 'c reactive',
    'hemoglobin', 'hgb', 'hb',
    'wbc', 'lökosit', 'leukocyte', 'beyaz küre',
    'rbc', 'eritrosit', 'erythrocyte', 'kırmızı küre',
    'plt', 'trombosit', 'platelet',
    'mcv', 'mch', 'mchc', 'rdw',
    'hematokrit', 'hematocrit', 'hct',
    'sedimentasyon', 'sedimentation', 'esh',
    'total protein', 'albümin', 'albumin',
    'kalsiyum', 'calcium', 'magnezyum', 'magnesium',
    'sodyum', 'sodium', 'potasyum', 'potassium',
    'klor', 'chloride', 'fosfor', 'phosphorus',
    'ürük asit', 'uric acid',
    'ggt', 'alp', 'total bilirubin', 'direkt bilirubin',
    'hdl kolesterol', 'ldl kolesterol', 'hdl cholesterol', 'ldl cholesterol',
  ];

  static const _negativeDietSignals = [
    'kahvalti', 'ogle', 'aksam',
    'ara ogun', 'diyet listesi', 'diyetisyen',
    'porsiyon', 'tarif', 'yemek listesi',
    'ogun', 'yemek kasigi', 'su bardagi',
    'hasta', 'tablo', 'beslenme',
  ];

  String _normalizeTurkishChars(String text) {
    return text.toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('i̇', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  BloodValidationResult validate(OcrResult ocrResult) {
    if (!ocrResult.success || ocrResult.isEmpty) {
      return const BloodValidationResult(
        isBloodTest: false,
        confidence: 0.0,
        message: 'Kan değeri belgesinden okunabilir metin çıkarılamadı. '
            'Lütfen daha net bir belge yükleyin.',
        matchedSignals: [],
        labSignalCount: 0,
        numericValueCount: 0,
        negativeSignalCount: 0,
      );
    }

    final text = _normalizeTurkishChars(ocrResult.rawText);
    final matchedSignals = <String>[];

    // Count lab/medical signals
    int labSignalCount = 0;
    for (final signal in _positiveLabSignals) {
      if (text.contains(signal)) {
        labSignalCount++;
        matchedSignals.add(signal);
      }
    }

    // Count numeric values with units or reference ranges
    // Pattern: number followed by common units (mg/dL, pg/mL, ng/mL, etc.)
    final numericPattern = RegExp(
      r'(\d+[.,]\d+|\d+)\s*(mg/dl|mg/l|pg/ml|ng/ml|µg/dl|µg/l|ng/dl|g/dl|u/l|iu/l|mmol/l|µmol/l|%|fl|pg|mm/h)',
      caseSensitive: false,
    );
    final numericMatches = numericPattern.allMatches(text);
    int numericValueCount = numericMatches.length;

    // Alternative: look for "sonuç" or "result" followed by numbers
    final resultPattern = RegExp(
      r'(sonu[çc]|result|de[ğg]er|value)[:\s]*(\d+[.,]\d+|\d+)',
      caseSensitive: false,
    );
    final resultMatches = resultPattern.allMatches(text);
    numericValueCount += resultMatches.length;

    // Look for reference range patterns like (X - Y) or [X - Y]
    final refPattern = RegExp(r'[\(\[][\d.,]+\s*[-–]\s*[\d.,]+[\)\]]');
    final refMatches = refPattern.allMatches(text);
    numericValueCount += refMatches.length;

    // Count negative diet signals
    int negativeSignalCount = 0;
    for (final signal in _negativeDietSignals) {
      if (text.contains(signal)) {
        negativeSignalCount++;
      }
    }

    // Validation rules
    // 1. At least 2 lab/medical signals required
    // 2. At least 1 numeric values with units or reference ranges
    // 3. Diet signals shouldn't dominate
    final meetsLabRequirement = labSignalCount >= 2;
    final meetsNumericRequirement = numericValueCount >= 1;
    final dietDominant = negativeSignalCount > labSignalCount;

    // Calculate confidence
    double confidence = 0.0;
    if (meetsLabRequirement && meetsNumericRequirement) {
      confidence += 0.5;
      confidence += (labSignalCount * 0.04).clamp(0.0, 0.25);
      confidence += (numericValueCount * 0.04).clamp(0.0, 0.2);
      confidence -= (negativeSignalCount * 0.05).clamp(0.0, 0.2);
      confidence = confidence.clamp(0.0, 1.0);
    } else if (labSignalCount >= 1 && numericValueCount >= 1) {
      confidence = 0.35 + (labSignalCount * 0.04) + (numericValueCount * 0.03);
      confidence = confidence.clamp(0.0, 0.5);
    }

    if (dietDominant) {
      return BloodValidationResult(
        isBloodTest: false,
        confidence: confidence * 0.3,
        message: 'Bu dosya kan değeri belgesi gibi görünmüyor. '
            'Diyet listesi sinyalleri tespit edildi. '
            'Lütfen laboratuvar sonucu içeren bir belge yükleyin.',
        matchedSignals: matchedSignals,
        labSignalCount: labSignalCount,
        numericValueCount: numericValueCount,
        negativeSignalCount: negativeSignalCount,
      );
    }

    if (!meetsLabRequirement || !meetsNumericRequirement) {
      return BloodValidationResult(
        isBloodTest: false,
        confidence: confidence,
        message: 'Bu dosya kan değeri belgesi gibi görünmüyor. '
            'Lütfen laboratuvar sonucu içeren bir belge yükleyin.',
        matchedSignals: matchedSignals,
        labSignalCount: labSignalCount,
        numericValueCount: numericValueCount,
        negativeSignalCount: negativeSignalCount,
      );
    }

    if (confidence < 0.4) {
      return BloodValidationResult(
        isBloodTest: true,
        confidence: confidence,
        message: 'Belge algılandı ancak bazı değerler okunamadı. '
            'Yine de devam edebilirsiniz.',
        matchedSignals: matchedSignals,
        labSignalCount: labSignalCount,
        numericValueCount: numericValueCount,
        negativeSignalCount: negativeSignalCount,
      );
    }

    return BloodValidationResult(
      isBloodTest: true,
      confidence: confidence,
      message: 'Kan değeri belgesi başarıyla doğrulandı.',
      matchedSignals: matchedSignals,
      labSignalCount: labSignalCount,
      numericValueCount: numericValueCount,
      negativeSignalCount: negativeSignalCount,
    );
  }
}
