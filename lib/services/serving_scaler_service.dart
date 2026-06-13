class ParsedIngredient {
  final String name;
  final String amount;
  final String originalRaw;

  const ParsedIngredient({
    required this.name,
    required this.amount,
    required this.originalRaw,
  });
}

class ServingScalerService {
  static String normalizeIngredientName(String name) {
    return name
        .toLowerCase()
        .trim()
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u');
  }

  static bool _isMeat(String normalized) {
    return normalized.contains('kuzu kusbasi') ||
        normalized.contains('dana eti') ||
        normalized.contains('kirmizi et') ||
        normalized.contains('tavuk') ||
        normalized.contains('balik') ||
        normalized.contains('kiyma') ||
        normalized.contains('kusbasi') ||
        normalized.contains('biftek') ||
        normalized.contains('sucuk') ||
        normalized.contains('sosis') ||
        normalized.contains('pastirma') ||
        normalized.contains('ciger');
  }

  static bool _isFreshHerb(String normalized) {
    return normalized.contains('taze sogan') ||
        normalized.contains('maydanoz') ||
        normalized.contains('dereotu') ||
        normalized.contains('nane') ||
        normalized.contains('roka') ||
        normalized.contains('feslegen') ||
        normalized.contains('kuzu kulagi') ||
        normalized.contains('semizotu') ||
        normalized.contains('ispanak');
  }

  static bool _isCountableVegetable(String normalized) {
    return normalized == 'sogan' ||
        normalized == 'kuru sogan' ||
        normalized.contains('patates') ||
        normalized.contains('domates') ||
        normalized.contains('biber') ||
        normalized.contains('sivri biber') ||
        normalized.contains('kapya biber') ||
        normalized.contains('patlican') ||
        normalized.contains('kabak') ||
        normalized.contains('havuc') ||
        normalized.contains('sarimsak') ||
        normalized.contains('limon') ||
        normalized.contains('yumurta') ||
        normalized.contains('elma') ||
        normalized.contains('muz') ||
        normalized.contains('portakal');
  }

  static bool _isGrainOrLegume(String normalized) {
    return normalized.contains('pirinc') ||
        normalized.contains('bulgur') ||
        normalized.contains('mercimek') ||
        normalized.contains('nohut') ||
        normalized.contains('kuru fasulye') ||
        normalized.contains('fasulye') ||
        normalized.contains('un') ||
        normalized.contains('irmik') ||
        normalized.contains('seker') ||
        normalized.contains('toz seker') ||
        normalized.contains('pudra sekeri');
  }

  static bool _isLiquid(String normalized) {
    return normalized == 'su' ||
        normalized == 'sut' ||
        normalized.contains('krema');
  }

  static bool _isOil(String normalized) {
    return normalized.contains('zeytinyagi') ||
        normalized.contains('sivi yag') ||
        normalized.contains('siviyag') ||
        normalized.contains('sirke') ||
        normalized.contains('nar eksisi');
  }

  static bool _isButter(String normalized) {
    return normalized.contains('tereyagi');
  }

  static bool _isSpice(String normalized) {
    return normalized.contains('tuz') ||
        normalized.contains('karabiber') ||
        normalized.contains('pul biber') ||
        normalized.contains('kimyon') ||
        normalized.contains('kekik') ||
        normalized.contains('isot');
  }

  static bool _isGarnish(String normalized) {
    return normalized.contains('garnitur') ||
        normalized.contains('bezelye') ||
        normalized.contains('konserve garnitur') ||
        normalized.contains('misir');
  }

  static String? inferDefaultUnit(String name, double? amount) {
    final normalized = normalizeIngredientName(name);

    if (amount == null) return null;

    if (_isMeat(normalized)) return 'g';

    if (_isFreshHerb(normalized)) {
      if (amount > 10) return 'g';
      if (normalized.contains('taze sogan')) return 'dal';
      return 'demet';
    }

    if (_isCountableVegetable(normalized)) {
      if (amount > 10) return 'g';
      if (normalized.contains('sarimsak')) return 'diş';
      return 'adet';
    }

    if (_isGrainOrLegume(normalized)) {
      if (amount > 20) return 'g';
      return 'su bardağı';
    }

    if (_isOil(normalized)) {
      if (amount > 20) return 'ml';
      return 'yemek kaşığı';
    }

    if (_isButter(normalized)) {
      if (amount > 10) return 'g';
      return 'yemek kaşığı';
    }

    if (_isSpice(normalized)) {
      if (amount > 10) return 'g';
      return 'çay kaşığı';
    }

    if (normalized.contains('yufka') || normalized.contains('lavas')) {
      if (amount > 10) return 'g';
      return 'adet';
    }

    if (_isGarnish(normalized)) {
      if (amount > 10) return 'g';
      return 'yemek kaşığı';
    }

    if (_isLiquid(normalized)) {
      if (amount > 20) return 'ml';
      return 'su bardağı';
    }

    // Default catch-all cases
    if (normalized.contains('makarna') || normalized.contains('eriste'))
      return 'g';
    if (normalized.contains('yulaf') ||
        normalized.contains('kakao') ||
        normalized.contains('bal') ||
        normalized.contains('pekmez') ||
        normalized.contains('tahin')) {
      if (amount > 10) return 'g';
      return 'yemek kaşığı';
    }
    if (normalized.contains('yogurt') || normalized.contains('salca')) {
      if (amount > 20) return 'g';
      return 'yemek kaşığı';
    }
    if (normalized.contains('vanilya') ||
        normalized.contains('kabartma tozu') ||
        normalized.contains('maya')) {
      return 'paket';
    }

    return null;
  }

  static int getOriginalServings(Map<String, dynamic> rawJson) {
    final servingsRaw =
        rawJson['servings'] ??
        rawJson['portion_count'] ??
        rawJson['serving_count'] ??
        rawJson['yield'];
    return int.tryParse(servingsRaw?.toString() ?? '') ?? 1;
  }

  static double calculateMultiplier(
    int originalServings,
    int selectedServings,
  ) {
    if (originalServings <= 0) return 1.0;
    return selectedServings / originalServings;
  }

  static String scaleNutritionValue(dynamic value, double multiplier) {
    if (value == null) return "0";
    final numVal = double.tryParse(value.toString()) ?? 0.0;
    final scaled = numVal * multiplier;
    return formatNumber(scaled);
  }

  static ParsedIngredient parseIngredientAmount(String raw) {
    final regex = RegExp(
      r'^([\d½¼¾⅓⅔]+(?:[.,/][\d]+)?|yarım|çeyrek)\s*(?:adet|diş|gram|gr|g|kg|ml|litre|lt|su bardağı|çay bardağı|yemek kaşığı|tatlı kaşığı|çay kaşığı|bardak|fincan|demet|tutam|dilim|paket|avuç|kase|damla|porsiyon|büyük|orta|küçük|boy)?',
      caseSensitive: false,
    );

    final match = regex.firstMatch(raw.trim());
    if (match != null && match.group(0)!.trim().isNotEmpty) {
      final amount = match.group(0)!.trim();
      final name = raw.trim().substring(amount.length).trim();
      if (name.isNotEmpty) {
        final capitalName = name[0].toUpperCase() + name.substring(1);
        return ParsedIngredient(
          name: capitalName,
          amount: amount,
          originalRaw: raw.trim(),
        );
      }
    }

    final trimmed = raw.trim();
    final capitalName = trimmed.isNotEmpty
        ? trimmed[0].toUpperCase() + trimmed.substring(1)
        : trimmed;
    return ParsedIngredient(
      name: capitalName,
      amount: '',
      originalRaw: raw.trim(),
    );
  }

  static String scaleIngredientAmount(String amount, double multiplier) {
    if (multiplier == 1.0 || amount.isEmpty) return amount;

    final numMatch = RegExp(
      r'^([\d½¼¾⅓⅔]+(?:[.,/][\d]+)?|yarım|çeyrek)',
    ).firstMatch(amount);
    if (numMatch == null) return amount;

    final numStr = numMatch.group(1)!;
    final val = parseFraction(numStr.toLowerCase());
    if (val == 0.0) return amount;

    final scaled = val * multiplier;
    final rest = amount.substring(numMatch.end);

    return '${formatNumber(scaled)}$rest';
  }

  static double parseFraction(String text) {
    if (text == 'yarım') return 0.5;
    if (text == 'çeyrek') return 0.25;
    if (text == '½') return 0.5;
    if (text == '¼') return 0.25;
    if (text == '¾') return 0.75;
    if (text == '⅓') return 1 / 3;
    if (text == '⅔') return 2 / 3;

    if (text.contains('/')) {
      final parts = text.split('/');
      if (parts.length == 2) {
        final num = double.tryParse(parts[0].trim());
        final den = double.tryParse(parts[1].trim());
        if (num != null && den != null && den != 0) {
          return num / den;
        }
      }
    }

    // Remove comma and check if it's a valid float
    final normalized = text.replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0.0;
  }

  static String formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1).replaceAll('.0', '');
  }

  static String scaleQuantitiesInText(String text, double multiplier) {
    if (multiplier == 1.0) return text;

    final regex = RegExp(
      r'(\d+(?:[.,]\d+)?|yarım|çeyrek|1/2|½|¼|¾)\s*(adet|diş|gram|gr|g|kg|ml|litre|lt|su bardağı|çay bardağı|yemek kaşığı|tatlı kaşığı|çay kaşığı|tutam|dal|yaprak|paket|kase|bardak)(?![a-zA-ZçğıöşüÇĞİÖŞÜ])',
      caseSensitive: false,
    );

    return text.replaceAllMapped(regex, (match) {
      final numStr = match.group(1)!;
      final unitStr = match.group(2)!;

      final val = parseFraction(numStr.toLowerCase());
      if (val == 0.0) return match.group(0)!;

      final scaled = val * multiplier;
      return '${formatNumber(scaled)} $unitStr';
    });
  }
}
