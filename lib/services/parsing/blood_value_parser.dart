import '../ocr/ocr_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class ParsedBloodValue {
  final String name;
  final double? value;
  final String unit;
  final String status; // low | normal | high | unknown
  final String? referenceRangeLow;
  final String? referenceRangeHigh;

  const ParsedBloodValue({
    required this.name,
    this.value,
    required this.unit,
    this.status = 'unknown',
    this.referenceRangeLow,
    this.referenceRangeHigh,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'value': value,
        'unit': unit,
        'status': status,
        'reference_range_low': referenceRangeLow,
        'reference_range_high': referenceRangeHigh,
      };
}

class ParsedBloodValues {
  final bool isBloodTest;
  final double confidence;
  final String message;
  final List<String> matchedSignals;
  final Map<String, ParsedBloodValue> values; // key: normalized name (b12, ldl, etc.)

  const ParsedBloodValues({
    required this.isBloodTest,
    required this.confidence,
    required this.message,
    this.matchedSignals = const [],
    this.values = const {},
  });

  Map<String, dynamic> toJson() => {
        'is_valid': isBloodTest,
        'confidence': confidence,
        'message': message,
        'blood_values': values.map((k, v) => MapEntry(k, v.toJson())),
        'matched_signals': matchedSignals,
      };

  bool get hasValues => values.isNotEmpty;
}

class BloodValueParser {
  static final BloodValueParser _instance = BloodValueParser._();
  factory BloodValueParser() => _instance;
  BloodValueParser._();

  /// Maps from Turkish/English names to normalized keys.
  static const Map<String, String> _markerNames = {
    'b12': 'b12', 'b 12': 'b12', 'vitamin b12': 'b12', 'vit b12': 'b12',
    'vitamin d': 'vitamin_d', 'd vitamini': 'vitamin_d', '25-oh vitamin d': 'vitamin_d',
    '25 oh vitamin d': 'vitamin_d', '25-oh d': 'vitamin_d',
    'ferritin': 'ferritin',
    'demir': 'iron', 'iron': 'iron', 'serum demir': 'iron', 'serum demiri': 'iron', 'fe': 'iron',
    'ldl': 'ldl', 'ldl kolesterol': 'ldl', 'ldl cholesterol': 'ldl',
    'hdl': 'hdl', 'hdl kolesterol': 'hdl', 'hdl cholesterol': 'hdl',
    'total kolesterol': 'total_cholesterol', 'total cholesterol': 'total_cholesterol',
    'kolesterol': 'total_cholesterol', 'cholesterol': 'total_cholesterol',
    'trigliserid': 'triglyceride', 'trigliserit': 'triglyceride',
    'triglyceride': 'triglyceride', 'tg': 'triglyceride',
    'glukoz': 'glucose', 'glucose': 'glucose', 'aclik glukoz': 'glucose',
    'aclik kan sekeri': 'glucose', 'fasting glucose': 'glucose', 'aks': 'glucose', 'glu': 'glucose',
    'hba1c': 'hba1c', 'a1c': 'hba1c', 'hemoglobin a1c': 'hba1c',
    'tsh': 'tsh', 'tiroid': 'tsh',
    'alt': 'alt', 'sgpt': 'alt',
    'ast': 'ast', 'sgot': 'ast',
    'kreatinin': 'creatinine', 'kreatin': 'creatinine', 'creatinine': 'creatinine',
    'ure': 'urea', 'bun': 'urea', 'urea': 'urea',
    'crp': 'crp', 'c-reaktif protein': 'crp', 'c reactive protein': 'crp',
    'hemoglobin': 'hemoglobin', 'hgb': 'hemoglobin', 'hb': 'hemoglobin',
    'wbc': 'wbc', 'lokosit': 'wbc', 'leukocyte': 'wbc', 'beyaz kure': 'wbc',
    'rbc': 'rbc', 'eritrosit': 'rbc', 'erythrocyte': 'rbc', 'kirmizi kure': 'rbc',
    'plt': 'plt', 'trombosit': 'plt', 'platelet': 'plt',
  };

  /// Reference ranges for determining status (approximate, not diagnostic).
  static const Map<String, _RefRange> _referenceRanges = {
    'b12': _RefRange(200, 900, 'pg/mL'),
    'vitamin_d': _RefRange(30, 100, 'ng/mL'),
    'ferritin': _RefRange(30, 400, 'ng/mL'),
    'iron': _RefRange(60, 170, 'µg/dL'),
    'ldl': _RefRange(0, 130, 'mg/dL'),
    'hdl': _RefRange(40, 60, 'mg/dL'),
    'total_cholesterol': _RefRange(0, 200, 'mg/dL'),
    'triglyceride': _RefRange(0, 150, 'mg/dL'),
    'glucose': _RefRange(70, 100, 'mg/dL'),
    'hba1c': _RefRange(0, 5.7, '%'),
    'tsh': _RefRange(0.5, 4.5, 'mIU/L'),
    'alt': _RefRange(10, 40, 'U/L'),
    'ast': _RefRange(10, 40, 'U/L'),
    'creatinine': _RefRange(0.6, 1.3, 'mg/dL'),
    'urea': _RefRange(15, 45, 'mg/dL'),
    'crp': _RefRange(0, 5, 'mg/L'),
    'hemoglobin': _RefRange(13.5, 17.5, 'g/dL'),
    'wbc': _RefRange(4.0, 11.0, 'K/µL'),
    'rbc': _RefRange(4.5, 5.9, 'M/µL'),
    'plt': _RefRange(150, 450, 'K/µL'),
  };
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
  ParsedBloodValues parse(OcrResult ocrResult, List<String> matchedSignals) {
    if (!ocrResult.success || ocrResult.isEmpty) {
      return ParsedBloodValues(
        isBloodTest: false,
        confidence: 0.0,
        message: 'OCR metni boş, parse edilemedi.',
      );
    }

    final text = _normalizeTurkishChars(ocrResult.rawText);
    
    if (kDebugMode) {
      debugPrint('--- KAN TAHLİLİ DEBUG LOGLARI (PARSER) ---');
      debugPrint('Normalize OCR Text (ilk 1000 karakter):');
      debugPrint(text.length > 1000 ? text.substring(0, 1000) : text);
    }
    
    final values = <String, ParsedBloodValue>{};

    // Strategy: look for marker name near a numeric value
    // Pattern: marker_name ... number ... unit
    for (final entry in _markerNames.entries) {
      final markerPattern = entry.key;
      final normalizedName = entry.value;

      // Find the marker in text
      final markerIndex = text.indexOf(markerPattern);
      if (markerIndex == -1) continue;

      // Look around the marker for a numeric value (within ~100 chars)
      final searchStart = (markerIndex - 20).clamp(0, text.length);
      final searchEnd = (markerIndex + 150).clamp(0, text.length);
      final context = text.substring(searchStart, searchEnd);

      // Find numeric values in context. Optional colon, spaces, then number, then optional unit.
      final valueMatch = RegExp(
        r'[:\s]*(\d+[.,]\d+|\d+)\s*(mg/dl|mg/l|pg/ml|ng/ml|µg/dl|µg/l|ng/dl|g/dl|u/l|iu/l|uiu/ml|mmol/l|µmol/l|%|fl|pg|mm/h|gr/dl|10\^3/ul|10\^6/ul)?',
        caseSensitive: false,
      ).firstMatch(context);

      if (valueMatch != null) {
        final valueStr = valueMatch.group(1)?.replaceAll(',', '.');
        final value = double.tryParse(valueStr ?? '');
        if (value == null) continue;

        // Determine unit
        String unit = valueMatch.group(2)?.trim() ?? '';
        if (unit.isEmpty) {
          unit = _referenceRanges[normalizedName]?.unit ?? '';
        }

        // Determine status using reference ranges
        final refRange = _referenceRanges[normalizedName];
        String status = 'unknown';
        String? refLow;
        String? refHigh;

        if (refRange != null) {
          refLow = refRange.low.toString();
          refHigh = refRange.high.toString();

          if (value < refRange.low) {
            status = 'low';
          } else if (value > refRange.high) {
            status = 'high';
          } else {
            status = 'normal';
          }
        }

        values[normalizedName] = ParsedBloodValue(
          name: entry.key,
          value: value,
          unit: unit,
          status: status,
          referenceRangeLow: refLow,
          referenceRangeHigh: refHigh,
        );
      }
    }

    final hasValidValues = values.isNotEmpty && values.length >= 2;

    if (kDebugMode) {
      debugPrint('Parsed Blood Values JSON:');
      debugPrint(jsonEncode(values.map((k, v) => MapEntry(k, v.toJson()))));
    }

    return ParsedBloodValues(
      isBloodTest: hasValidValues,
      confidence: hasValidValues ? 0.88 : 0.2,
      message: hasValidValues
          ? 'Kan değeri belgesi başarıyla okundu.'
          : 'Kan değeri belgesinden değerler çıkarılamadı.',
      matchedSignals: matchedSignals,
      values: values,
    );
  }
}

class _RefRange {
  final double low;
  final double high;
  final String unit;
  const _RefRange(this.low, this.high, this.unit);
}
