import '../ocr/ocr_service.dart';

class _MealMatch {
  final int index;
  final String type;
  final String keyword;
  _MealMatch(this.index, this.type, this.keyword);
}

class ParsedDietPlan {
  final bool isDiet;
  final double confidence;
  final String message;
  final List<String> matchedSignals;
  final Map<String, List<String>> meals; // key: mealType, value: items
  final List<String> detectedFoodItems;

  const ParsedDietPlan({
    required this.isDiet,
    required this.confidence,
    required this.message,
    this.matchedSignals = const [],
    this.meals = const {},
    this.detectedFoodItems = const [],
  });

  Map<String, dynamic> toJson() => {
    'is_valid': isDiet,
    'confidence': confidence,
    'message': message,
    'diet_plan': meals,
    'matched_signals': matchedSignals,
  };

  bool get hasContent => meals.isNotEmpty;
}

class DietPlanParser {
  static final DietPlanParser _instance = DietPlanParser._();
  factory DietPlanParser() => _instance;
  DietPlanParser._();

  static const _mealKeywords = {
    'kahvaltı': 'breakfast',
    'kahvalti': 'breakfast',
    'sabah': 'breakfast',
    'öğle yemeği': 'lunch',
    'ogle yemegi': 'lunch',
    'öğle': 'lunch',
    'ogle': 'lunch',
    'akşam yemeği': 'dinner',
    'aksam yemegi': 'dinner',
    'akşam': 'dinner',
    'aksam': 'dinner',
    'ara öğün': 'snack',
    'ara ogun': 'snack',
    'kuşluk': 'snack',
    'ikindi': 'snack',
    'gece': 'snack',
  };

  /// Parses OCR text into structured diet plan.
  ParsedDietPlan parse(OcrResult ocrResult, List<String> matchedSignals) {
    if (!ocrResult.success || ocrResult.isEmpty) {
      return const ParsedDietPlan(
        isDiet: false,
        confidence: 0.0,
        message: 'OCR metni boş, parse edilemedi.',
      );
    }

    final text = ocrResult.rawText;
    final lowerText = text.toLowerCase();

    // Find all occurrences of meal markers
    final matches = <_MealMatch>[];
    for (final entry in _mealKeywords.entries) {
      final keyword = entry.key;
      var index = lowerText.indexOf(keyword);
      while (index != -1) {
        // Simple boundary check
        final startOk =
            index == 0 ||
            RegExp(r'[\s.,;:|>\-]').hasMatch(lowerText[index - 1]);
        final endIdx = index + keyword.length;
        final endOk =
            endIdx == lowerText.length ||
            RegExp(r'[\s.,;:|<\-]').hasMatch(lowerText[endIdx]);

        if (startOk && endOk) {
          matches.add(_MealMatch(index, entry.value, keyword));
        }
        index = lowerText.indexOf(keyword, index + keyword.length);
      }
    }

    matches.sort((a, b) => a.index.compareTo(b.index));

    // Remove overlapping or very close matches
    final filteredMatches = <_MealMatch>[];
    for (var i = 0; i < matches.length; i++) {
      if (filteredMatches.isNotEmpty &&
          matches[i].index <
              filteredMatches.last.index +
                  filteredMatches.last.keyword.length) {
        if (matches[i].keyword.length > filteredMatches.last.keyword.length) {
          filteredMatches.removeLast();
          filteredMatches.add(matches[i]);
        }
      } else {
        filteredMatches.add(matches[i]);
      }
    }

    final meals = <String, List<String>>{};
    final detectedFoodItems = <String>[];

    if (filteredMatches.isEmpty) {
      // Fallback: If no markers found, put everything in a general meal
      final foods = _extractFoodItems(text);
      if (foods.isNotEmpty) {
        meals['general'] = foods;
        detectedFoodItems.addAll(foods);
      }
    } else {
      // Split text by the matched markers
      for (var i = 0; i < filteredMatches.length; i++) {
        final match = filteredMatches[i];
        final startIdx = match.index + match.keyword.length;
        final endIdx = (i + 1 < filteredMatches.length)
            ? filteredMatches[i + 1].index
            : text.length;

        var sectionText = text.substring(startIdx, endIdx).trim();
        // Remove trailing or leading colons/dashes from section
        sectionText = sectionText.replaceFirst(RegExp(r'^[\s:.\-]+'), '');

        final foods = _extractFoodItems(sectionText);

        if (foods.isNotEmpty) {
          meals.putIfAbsent(match.type, () => []).addAll(foods);
          for (final f in foods) {
            if (!detectedFoodItems.contains(f)) detectedFoodItems.add(f);
          }
        }
      }
    }

    final hasValidContent = meals.isNotEmpty;

    return ParsedDietPlan(
      isDiet: hasValidContent,
      confidence: hasValidContent ? 0.84 : 0.2,
      message: hasValidContent
          ? 'Diyet listesi başarıyla okundu.'
          : 'Diyet listesinden öğün bilgisi çıkarılamadı.',
      matchedSignals: matchedSignals,
      meals: meals,
      detectedFoodItems: detectedFoodItems,
    );
  }

  List<String> _extractFoodItems(String sectionText) {
    // Split the section by newlines, bullets, or pipes.
    // We avoid splitting by standard commas inside names unless they are clearly list separators.
    final rawParts = sectionText.split(RegExp(r'[\n\r•*|]+'));

    final items = <String>[];
    for (var part in rawParts) {
      part = part.trim();
      if (part.isEmpty) continue;

      // If a single line has multiple commas followed by space and character/number, it's likely a list on one line
      // E.g. "1 Yumurta, 2 dilim peynir, 5 zeytin"
      final subParts = part.split(RegExp(r',\s+(?=[A-Za-z0-9])'));

      for (var sub in subParts) {
        sub = _cleanFoodItem(sub);
        if (sub.length > 2 && !RegExp(r'^[\d\s.,;:/\\\-–—]+$').hasMatch(sub)) {
          items.add(sub);
        }
      }
    }

    return items;
  }

  String _cleanFoodItem(String item) {
    var cleaned = item.trim();
    // Remove leading/trailing non-word chars except numbers
    cleaned = cleaned.replaceAll(RegExp(r'^[\s.,;:\-–—]+|[\s.,;:\-–—]+$'), '');

    // Remove metadata noise often found in PDFs
    cleaned = cleaned.replaceAll(
      RegExp(
        r'\b(açıklama|not|öneri|doktorunuz|diyetisyeniniz|hasta adı|hasta adi|tc|protokol|barkod|tarih|saat)\b',
        caseSensitive: false,
      ),
      '',
    );

    // We intentionally DO NOT strip quantities so "1 BARDAK SU" stays "1 BARDAK SU"
    return cleaned.trim();
  }
}
