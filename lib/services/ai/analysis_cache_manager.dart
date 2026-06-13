import 'dart:io';
import 'package:crypto/crypto.dart';
import '../../models/ai/analysis_results.dart';

class AnalysisCacheManager {
  static final AnalysisCacheManager _instance =
      AnalysisCacheManager._internal();
  factory AnalysisCacheManager() => _instance;
  AnalysisCacheManager._internal();

  final Map<String, DocumentValidationResult> _validationCache = {};
  final Map<String, DietAnalysisResult> _dietAnalysisCache = {};
  final Map<String, BloodAnalysisResult> _bloodAnalysisCache = {};

  Future<String> getFileHash(File file) async {
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }

  void cacheValidation(
    String hash,
    UploadType type,
    DocumentValidationResult result,
  ) {
    _validationCache['$hash-${type.name}'] = result;
  }

  DocumentValidationResult? getValidation(String hash, UploadType type) {
    return _validationCache['$hash-${type.name}'];
  }

  void cacheDietAnalysis(String hash, DietAnalysisResult result) {
    _dietAnalysisCache[hash] = result;
  }

  DietAnalysisResult? getDietAnalysis(String hash) {
    return _dietAnalysisCache[hash];
  }

  void cacheBloodAnalysis(String hash, BloodAnalysisResult result) {
    _bloodAnalysisCache[hash] = result;
  }

  BloodAnalysisResult? getBloodAnalysis(String hash) {
    return _bloodAnalysisCache[hash];
  }

  void clearCache() {
    _validationCache.clear();
    _dietAnalysisCache.clear();
    _bloodAnalysisCache.clear();
  }
}
