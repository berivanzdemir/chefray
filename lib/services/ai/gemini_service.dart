import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';

class GeminiModelInfo {
  final String name;
  final List<String> supportedGenerationMethods;

  GeminiModelInfo({
    required this.name,
    required this.supportedGenerationMethods,
  });
}

class GeminiService {
  // ── Cache & Fallbacks for Model Resolution ──────────────────────────────
  static String? _cachedBestModel;

  static final List<String> _priorityModels = [
    'models/gemini-flash-latest',
    'models/gemini-2.0-flash',
    'models/gemini-2.5-flash',
    'models/gemini-flash-lite-latest',
  ];
  static int _currentModelIndex = 0;

  // ── Direct HTTP API Helpers ──────────────────────────────────────────────

  Future<List<GeminiModelInfo>> listAvailableModels() async {
    final apiKey = AppConfig.geminiApiKey;
    if (apiKey.trim().isEmpty) return [];

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List list = data['models'] ?? [];
        final List<GeminiModelInfo> models = [];
        for (var item in list) {
          final modelName = item['name'] as String? ?? '';
          final methods = List<String>.from(
            item['supportedGenerationMethods'] ?? [],
          );
          models.add(
            GeminiModelInfo(
              name: modelName,
              supportedGenerationMethods: methods,
            ),
          );
        }
        return models;
      }
      return [];
    } catch (e) {
      debugPrint('Gemini listModels exception: $e');
      return [];
    }
  }

  Future<String> resolveBestModel() async {
    if (_cachedBestModel != null) return _cachedBestModel!;

    try {
      final models = await listAvailableModels();
      final candidates = models
          .where(
            (m) => m.supportedGenerationMethods.contains('generateContent'),
          )
          .map((m) => m.name)
          .toList();

      if (candidates.isNotEmpty) {
        for (int i = 0; i < _priorityModels.length; i++) {
          final priorityModelStripped = _priorityModels[i].replaceFirst(
            'models/',
            '',
          );
          for (var cand in candidates) {
            final strippedCand = cand.replaceFirst('models/', '');
            if (strippedCand == priorityModelStripped) {
              _cachedBestModel = cand;
              _currentModelIndex = i;
              return cand;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error listAvailableModels: $e');
    }

    _cachedBestModel = _priorityModels[_currentModelIndex];
    return _cachedBestModel!;
  }

  Future<String> _postGenerateContent(
    String modelName,
    Map<String, dynamic> requestBody,
  ) async {
    final apiKey = AppConfig.geminiApiKey;
    if (apiKey.trim().isEmpty) {
      throw Exception('Gemini API Key is missing in environment.');
    }

    String cleanModel = modelName;
    if (cleanModel.startsWith('models/')) {
      cleanModel = cleanModel.substring('models/'.length);
    }
    cleanModel = 'models/$cleanModel';

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/$cleanModel:generateContent?key=$apiKey',
    );

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List? ?? [];
        if (candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content?['parts'] as List? ?? [];
          if (parts.isNotEmpty) {
            return parts[0]['text'] as String? ?? '';
          }
        }
        return '';
      } else {
        debugPrint('Gemini HTTP error: ${response.statusCode}');

        if (_currentModelIndex < _priorityModels.length - 1) {
          _currentModelIndex++;
          final nextModel = _priorityModels[_currentModelIndex];
          _cachedBestModel = nextModel;
          return await _postGenerateContent(nextModel, requestBody);
        }

        throw Exception('Gemini API error: ${response.statusCode}');
      }
    } catch (e) {
      if (_currentModelIndex < _priorityModels.length - 1) {
        _currentModelIndex++;
        final nextModel = _priorityModels[_currentModelIndex];
        _cachedBestModel = nextModel;
        return await _postGenerateContent(nextModel, requestBody);
      }
      rethrow;
    }
  }

  // ── Public AI Text Generation Interface ──────────────────────────────────
  //
  //  IMPORTANT: Only used for recipe recommendation and mascot suggestions.
  //  NEVER send raw health documents, PDFs, or personal data to this method.
  //  Only send anonymized JSON summaries.

  Future<String> generateText({required String prompt}) async {
    final modelName = await resolveBestModel();
    final body = {
      "contents": [
        {
          "parts": [
            {"text": prompt},
          ],
        },
      ],
    };
    return await _postGenerateContent(modelName, body);
  }

  /// Parses a JSON list from AI response text.
  List<dynamic> extractAndParseJsonList(String responseText) {
    try {
      String clean = responseText.trim();

      if (clean.contains('```json')) {
        final start = clean.indexOf('```json') + 7;
        final end = clean.indexOf('```', start);
        if (end != -1) {
          clean = clean.substring(start, end).trim();
        }
      } else if (clean.contains('```')) {
        final start = clean.indexOf('```') + 3;
        final end = clean.indexOf('```', start);
        if (end != -1) {
          clean = clean.substring(start, end).trim();
        }
      }

      final firstBracket = clean.indexOf('[');
      final lastBracket = clean.lastIndexOf(']');
      if (firstBracket != -1 &&
          lastBracket != -1 &&
          lastBracket > firstBracket) {
        clean = clean.substring(firstBracket, lastBracket + 1);
      }

      return jsonDecode(clean) as List<dynamic>;
    } catch (e) {
      debugPrint('JSON list parsing error: $e');
      return [];
    }
  }
}
