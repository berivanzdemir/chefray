import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../models/ingredient_model.dart';

class StepItemsChips extends StatelessWidget {
  final String stepDescription;
  final List<IngredientModel> recipeIngredients;

  const StepItemsChips({
    super.key,
    required this.stepDescription,
    required this.recipeIngredients,
  });

  String _normalizeTurkish(String text) {
    return text
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
  }

  String _cleanIngredientName(String name) {
    String cleaned = name.toLowerCase();

    final removePhrases = [
      'su bardağı',
      'yemek kaşığı',
      'tatlı kaşığı',
      'çay kaşığı',
      'kahve fincanı',
    ];
    for (var phrase in removePhrases) {
      cleaned = cleaned.replaceAll(phrase, ' ');
    }

    // remove numbers and punctuation
    cleaned = cleaned.replaceAll(RegExp(r'\d+'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'[^\w\sçğıöşü]'), ' ');

    final removeWords = {
      'haşlanmış',
      'doğranmış',
      'taze',
      'rendelenmiş',
      'kuru',
      'sıcak',
      'soğuk',
      'kavrulmuş',
      'ezilmiş',
      'ince',
      'kalın',
      'iri',
      'adet',
      'demet',
      'tutam',
      'gram',
      'gr',
      'kg',
      'ml',
      'litre',
      'ölçü',
      'tepeleme',
      'silme',
      'yarım',
      'çeyrek',
      'dilim',
      'parça',
      'avuç',
      'bardak',
      'kaşık',
      'fincan',
      'kase',
      'paket',
      'diş',
      'baş',
    };

    List<String> words = cleaned.split(RegExp(r'\s+'));
    words.removeWhere((w) => removeWords.contains(w) || w.isEmpty);

    return words.join(' ');
  }

  List<String> _getIngredientsForStep() {
    String rawText = stepDescription;
    String normDesc = _normalizeTurkish(rawText);

    // Remove punctuation
    normDesc = normDesc.replaceAll(RegExp(r'[^\w\s]'), ' ');
    normDesc = normDesc.replaceAll(RegExp(r'\s+'), ' ').trim();

    List<String> descWords = normDesc.split(' ');
    if (descWords.isEmpty || descWords.first.isEmpty) {
      return [];
    }

    // Build the dictionary
    Set<String> dictionarySet = {};

    // Add recipe ingredients first (prioritize exact recipe items)
    for (var ing in recipeIngredients) {
      if (ing.name.isNotEmpty &&
          !ing.name.toLowerCase().contains('düzenleniyor')) {
        dictionarySet.add(ing.name.trim());
      }
    }

    // Add common ingredients
    // Note: Do not include items with prep-words like 'taze soğan' or 'kuru nane' here
    // because they will be cleaned to 'soğan' and 'nane', and due to length sorting,
    // they would incorrectly override a recipe's base 'soğan'.
    // Recipe's own 'taze soğan' will still be added via recipeIngredients.
    final List<String> commonIngredients = [
      'domates salçası',
      'biber salçası',
      'tavuk suyu',
      'et suyu',
      'soya sosu',
      'nar ekşisi',
      'zeytinyağı',
      'sıvı yağ',
      'tereyağı',
      'kuru fasulye',
      'maş fasulyesi',
      'yeşil mercimek',
      'kırmızı mercimek',
      'sarı mercimek',
      'yeşil biber',
      'kırmızı biber',
      'pul biber',
      'karabiber',
      'dolmalık biber',
      'süzme yoğurt',
      'cheddar peyniri',
      'kaşar peyniri',
      'beyaz peynir',
      'su',
      'mercimek',
      'bulgur',
      'pirinç',
      'soğan',
      'sarımsak',
      'domates',
      'biber',
      'patates',
      'havuç',
      'brokoli',
      'karnabahar',
      'kabak',
      'patlıcan',
      'mantar',
      'tavuk',
      'et',
      'kıyma',
      'balık',
      'somon',
      'maydanoz',
      'nane',
      'dereotu',
      'reyhan',
      'yağ',
      'yoğurt',
      'süt',
      'peynir',
      'salça',
      'un',
      'yumurta',
      'limon',
      'sirke',
      'şeker',
      'tuz',
      'kimyon',
      'kekik',
      'mısır',
      'fasulye',
      'nohut',
      'bezelye',
      'ceviz',
      'fındık',
      'fıstık',
      'badem',
      'krema',
      'vanilya',
    ];
    dictionarySet.addAll(commonIngredients);

    // Map keywords to their normalized words
    Map<String, List<String>> keywordTokens = {};
    for (var item in dictionarySet) {
      String cleanItem = _cleanIngredientName(item);
      String normItem = _normalizeTurkish(cleanItem);
      if (normItem.isEmpty) continue;

      List<String> tokens = normItem.split(' ');
      tokens.removeWhere((t) => t.isEmpty);
      if (tokens.isNotEmpty) {
        keywordTokens[item] = tokens;
      }
    }

    // Sort dictionary items: First by word count (desc), then by string length (desc)
    List<String> sortedItems = keywordTokens.keys.toList();
    sortedItems.sort((a, b) {
      int wordsA = keywordTokens[a]!.length;
      int wordsB = keywordTokens[b]!.length;
      if (wordsA != wordsB) {
        return wordsB.compareTo(wordsA);
      }
      return b.length.compareTo(a.length);
    });

    List<String> matchedOriginalNames = [];
    Set<int> matchedWordIndices = {};

    bool matchMultiWordStartsWith(
      List<String> keyWords,
      List<String> textWords,
      int startIdx,
    ) {
      for (int j = 0; j < keyWords.length; j++) {
        if (startIdx + j >= textWords.length) return false;

        String kw = keyWords[j];
        String tw = textWords[startIdx + j];

        if (matchedWordIndices.contains(startIdx + j))
          return false; // Already matched part of another ingredient

        if (kw == 'su') {
          if (tw != 'su' && tw != 'suyu' && tw != 'suyunu' && tw != 'suya') {
            return false;
          }
        } else if (kw == 'et') {
          if (!tw.startsWith('et')) return false; // et, eti, etleri
        } else if (kw == 'un') {
          if (tw != 'un' && tw != 'unu' && tw != 'una' && tw != 'unun')
            return false;
        } else if (tw.startsWith(kw)) {
          // matched
        } else {
          // Try mutation k->g, p->b, t->d
          String kwMutated = kw;
          if (kw.endsWith('k')) {
            kwMutated = '${kw.substring(0, kw.length - 1)}g';
          } else if (kw.endsWith('p')) {
            kwMutated = '${kw.substring(0, kw.length - 1)}b';
          } else if (kw.endsWith('t')) {
            kwMutated = '${kw.substring(0, kw.length - 1)}d';
          }

          if (!tw.startsWith(kwMutated)) {
            return false;
          }
        }
      }
      return true;
    }

    for (var item in sortedItems) {
      List<String> keyWords = keywordTokens[item]!;

      // Search the sequence in descWords
      for (int i = 0; i <= descWords.length - keyWords.length; i++) {
        if (matchMultiWordStartsWith(keyWords, descWords, i)) {
          matchedOriginalNames.add(item);
          // Mark indices as matched so we don't match substrings (e.g. "domates salçası" matched, skip "domates")
          for (int k = 0; k < keyWords.length; k++) {
            matchedWordIndices.add(i + k);
          }
        }
      }
    }

    final uniqueIngredients = matchedOriginalNames
        .toSet()
        .take(6)
        .toList(); // max 6 chips

    if (kDebugMode) {
      debugPrint('--- Step text ingredient analysis ---');
      debugPrint('stepIndex: -');
      debugPrint('rawInstruction: $stepDescription');
      debugPrint('normalizedInstruction: $normDesc');
      debugPrint('extractedIngredients: $uniqueIngredients');
      debugPrint('extractedCount: ${uniqueIngredients.length}');
      debugPrint('hiddenBecauseEmpty: ${uniqueIngredients.isEmpty}');
    }

    return uniqueIngredients;
  }

  IconData _getIconForIngredient(String ingName) {
    final lower = ingName.toLowerCase();
    if (lower.contains('su') ||
        lower.contains('süt') ||
        lower.contains('yağ') ||
        lower.contains('sos')) {
      return Icons.water_drop_outlined;
    }
    if (lower.contains('et') ||
        lower.contains('tavuk') ||
        lower.contains('balık')) {
      return Icons.set_meal_outlined;
    }
    return Icons.eco_outlined; // Leaf/bean icon
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stepIngredients = _getIngredientsForStep();

    if (stepIngredients.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bu adımda kullanılan',
          style: TextStyle(
            color: isDark
                ? const Color(0xFFDFFFEF)
                : const Color(0xFF0D9B5E), // Green title matching reference
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: stepIngredients.map((ing) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E3A31) : Colors.white,
                borderRadius: BorderRadius.circular(20), // Pill shape
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2B4A40)
                      : const Color(0xFFE2EFE7),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getIconForIngredient(ing),
                    size: 14,
                    color: isDark
                        ? const Color(0xFFF3FFF9)
                        : const Color(0xFF0D9B5E),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    ing,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFFF3FFF9)
                          : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
