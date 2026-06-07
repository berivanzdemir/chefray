import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../models/ai/analysis_results.dart';
import '../ocr/ocr_service.dart';
import '../validation/blood_text_validator.dart';
import '../parsing/blood_value_parser.dart';

/// Blood analysis service using OCR + rule-based parser.
/// No AI/Gemini used — blood values are parsed from OCR text.
class BloodAnalysisService {
  final OcrService _ocrService = OcrService();
  final BloodTextValidator _validator = BloodTextValidator();
  final BloodValueParser _parser = BloodValueParser();

  Future<BloodAnalysisResult> analyzeBloodDocument({
    required File file,
    required DocumentValidationResult validationResult,
  }) async {
    debugPrint('Blood analysis (rule-based) started');

    try {
      // 1. Run OCR
      final ocrResult = await _ocrService.extractText(file);

      if (!ocrResult.success || ocrResult.isEmpty) {
        return BloodAnalysisResult(
          markers: const [],
          generalNote: 'Kan değeri belgesinden metin çıkarılamadı.',
          safetyWarning: 'Bu değerlendirme yalnızca beslenme kişiselleştirmesi içindir. '
              'Kesin değerlendirme için sağlık uzmanına danışın.',
          rawExtractedText: '',
        );
      }

      // 2. Validate
      final validation = _validator.validate(ocrResult);

      // 3. Parse blood values from OCR text
      final parsed = _parser.parse(ocrResult, validation.matchedSignals);

      // 4. Convert parsed values to BloodMarkers
      final List<BloodMarker> markers = [];

      for (final entry in parsed.values.entries) {
        final pv = entry.value;
        markers.add(BloodMarker(
          name: pv.name,
          value: pv.value?.toString(),
          unit: pv.unit,
          referenceRange: pv.referenceRangeLow != null && pv.referenceRangeHigh != null
              ? '${pv.referenceRangeLow} - ${pv.referenceRangeHigh}'
              : null,
          status: pv.status,
          nutritionNote: _getNutritionNote(entry.key, pv.status),
        ));
      }

      final attentionMarkers = markers
          .where((m) => m.status == 'low' || m.status == 'high')
          .map((m) => m.name)
          .toList();

      final generalNote = markers.isNotEmpty
          ? '${markers.length} kan değeri tespit edildi.'
              '${attentionMarkers.isNotEmpty ? ' Dikkat edilmesi gereken değerler: ${attentionMarkers.join(", ")}.' : ''}'
          : 'Kan değerleri belgeden okunamadı.';

      return BloodAnalysisResult(
        markers: markers,
        generalNote: generalNote,
        safetyWarning: 'Bu değerlendirme yalnızca beslenme kişiselleştirmesi içindir. '
            'Kesin değerlendirme için sağlık uzmanına danışın.',
        rawExtractedText: ocrResult.rawText,
      );
    } catch (e, st) {
      debugPrint('Blood analysis error: $e');
      debugPrint('Stack trace: $st');
      return BloodAnalysisResult(
        markers: const [],
        generalNote: 'Kan değerleri analiz edilemedi.',
        safetyWarning: 'Bu değerlendirme yalnızca beslenme kişiselleştirmesi içindir. '
            'Kesin değerlendirme için sağlık uzmanına danışın.',
        rawExtractedText: '',
      );
    }
  }

  String _getNutritionNote(String normalizedName, String status) {
    if (status == 'normal') return 'Normal seviyede.';

    final notes = <String, String>{
      'b12': 'B12 açısından zengin besinler: yumurta, balık, et, süt ürünleri.',
      'vitamin_d': 'D vitamini kaynakları: yağlı balık, yumurta sarısı, güneş ışığı.',
      'ferritin': 'Demir kaynakları: kırmızı et, baklagiller, ıspanak.',
      'iron': 'Demir kaynakları: kırmızı et, baklagiller, koyu yeşil sebzeler.',
      'ldl': 'LDL düşürmeye yardımcı: lifli gıdalar, zeytinyağı, balık.',
      'hdl': 'HDL artırmaya yardımcı: zeytinyağı, omega-3, egzersiz.',
      'triglyceride': 'Trigliserid düşürmeye yardımcı: omega-3, düşük şeker, egzersiz.',
      'glucose': 'Kan şekeri dengesi için: düşük glisemik indeksli besinler, lif.',
      'hba1c': 'Uzun vadeli şeker dengesi için: tam tahıllar, sebzeler, düzenli öğün.',
    };

    return notes[normalizedName] ?? 'Değer referans aralığı dışında.';
  }
}
