import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../models/ai/analysis_results.dart';
import '../ocr/ocr_service.dart';
import '../validation/diet_text_validator.dart';
import '../validation/blood_text_validator.dart';

/// Rule-based document validation service.
/// No AI/Gemini used — validates via OCR + keyword/signal analysis.
class DocumentValidationService {
  final OcrService _ocrService = OcrService();

  Future<DocumentValidationResult> validateDocument({
    required File file,
    required UploadType uploadType,
  }) async {
    debugPrint('===== DOCUMENT VALIDATION (RULE-BASED) START =====');
    debugPrint('Upload type: $uploadType');
    debugPrint('File path: ${file.path}');

    // 1. Run OCR
    final ocrResult = await _ocrService.extractText(file);

    if (!ocrResult.success) {
      final msg = uploadType == UploadType.dietPdf
          ? 'Diyet listesinden okunabilir metin çıkarılamadı. Lütfen daha net bir fotoğraf veya PDF yükleyin.'
          : 'Kan değeri belgesinden okunabilir metin çıkarılamadı. Lütfen daha net bir belge yükleyin.';
      return DocumentValidationResult.invalid(msg, reason: ocrResult.error ?? 'OCR failed');
    }

    debugPrint('OCR text length: ${ocrResult.rawText.length}');

    // 2. Validate with appropriate validator
    if (uploadType == UploadType.dietPdf) {
      final validator = DietTextValidator();
      final result = validator.validate(ocrResult);

      debugPrint('Diet validation: isDiet=${result.isDiet} confidence=${result.confidence}');
      debugPrint('Diet meal signals: ${result.mealSignalCount}');
      debugPrint('Diet food signals: ${result.foodSignalCount}');
      debugPrint('Diet negative signals: ${result.negativeSignalCount}');
      debugPrint('Diet matched: ${result.matchedSignals.join(", ")}');

      return DocumentValidationResult(
        isValid: result.isDiet,
        detectedType: result.isDiet ? 'diet_list' : 'unknown',
        confidence: result.confidence,
        extractedTextSummary: ocrResult.rawText.length > 200
            ? '${ocrResult.rawText.substring(0, 200)}...'
            : ocrResult.rawText,
        reason: result.message,
        userMessage: result.message,
      );
    } else {
      final validator = BloodTextValidator();
      final result = validator.validate(ocrResult);

      if (kDebugMode) {
        debugPrint('--- KAN TAHLİLİ DEBUG LOGLARI (VALIDATION) ---');
        final fileName = file.path.split(Platform.pathSeparator).last;
        final ext = fileName.split('.').last.toLowerCase();
        debugPrint('Dosya Adı: $fileName');
        debugPrint('Dosya Uzantısı: $ext');
        debugPrint('MIME Type Tahmini: image/$ext (Eğer pdf ise application/pdf)');
        debugPrint('Format: ${ext == "pdf" ? "PDF (1 sayfa işlendi)" : "Görsel (Image OCR)"}');
        
        final rawTxt = ocrResult.rawText;
        debugPrint('OCR raw text (ilk 1000 karakter):');
        debugPrint(rawTxt.length > 1000 ? rawTxt.substring(0, 1000) : rawTxt);
        
        debugPrint('Validation Sonucu: isBlood=${result.isBloodTest}, Confidence=${result.confidence}');
        debugPrint('Matched Signals: ${result.matchedSignals.join(", ")}');
        debugPrint('Numeric Value Count: ${result.numericValueCount}');
        debugPrint('Final Status: ${result.message}');
      }

      return DocumentValidationResult(
        isValid: result.isBloodTest,
        detectedType: result.isBloodTest ? 'blood_test' : 'unknown',
        confidence: result.confidence,
        extractedTextSummary: ocrResult.rawText.length > 200
            ? '${ocrResult.rawText.substring(0, 200)}...'
            : ocrResult.rawText,
        reason: result.message,
        userMessage: result.message,
      );
    }
  }
}
