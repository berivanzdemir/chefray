import '../../models/recipe_model.dart';

class AllergenFilterService {
  // Alerjen keyword map
  static const Map<String, List<String>> allergenKeywords = {
    'Gluten': [
      'gluten',
      'buğday',
      'un',
      'ekmek',
      'makarna',
      'bulgur',
      'irmik',
      'yufka',
      'galeta',
    ],
    'Laktoz': [
      'süt',
      'yoğurt',
      'peynir',
      'krema',
      'tereyağı',
      'kefir',
      'ayran',
      'kaşar',
    ],
    'Kuruyemiş': [
      'ceviz',
      'fındık',
      'badem',
      'fıstık',
      'kaju',
      'antep fıstığı',
    ],
    'Deniz ürünü': [
      'balık',
      'somon',
      'ton balığı',
      'levrek',
      'çipura',
      'karides',
      'midye',
    ],
    'Yumurta': ['yumurta', 'omlet', 'mayonez'],
    'Soya': ['soya', 'soya sosu', 'tofu'],
  };

  bool containsUserAllergen({
    required RecipeModel recipe,
    required List<String> userAllergies,
  }) {
    final warnings = detectAllergenWarnings(
      recipe: recipe,
      userAllergies: userAllergies,
    );
    return warnings.isNotEmpty;
  }

  List<String> detectAllergenWarnings({
    required RecipeModel recipe,
    required List<String> userAllergies,
  }) {
    List<String> warnings = [];

    // Tarifin metin alanlarını birleştir (küçük harfe çevirerek)
    final String recipeText = [
      recipe.title.toLowerCase(),
      recipe.description.toLowerCase(),
      ...recipe.tags.map((e) => e.toLowerCase()),
      ...recipe.ingredients.map((e) => e.name.toLowerCase()),
    ].join(' ');

    for (final allergy in userAllergies) {
      if (allergy == 'Yok') continue;

      final keywords = allergenKeywords[allergy] ?? [];
      for (final keyword in keywords) {
        if (recipeText.contains(keyword)) {
          warnings.add(
            'Bu tarif $allergy içerebilir ("$keyword" tespit edildi).',
          );
          break; // Bir keyword bulunduysa o alerjen için aramayı durdur
        }
      }
    }

    return warnings;
  }

  List<RecipeModel> removeUnsafeRecipes({
    required List<RecipeModel> recipes,
    required List<String> userAllergies,
  }) {
    return recipes.where((recipe) {
      return !containsUserAllergen(
        recipe: recipe,
        userAllergies: userAllergies,
      );
    }).toList();
  }
}
