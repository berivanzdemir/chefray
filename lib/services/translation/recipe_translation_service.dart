import '../../models/recipe_model.dart';
import '../../models/ingredient_model.dart';
import '../../models/cooking_step_model.dart';

/// Translation/localization layer for converting API recipe data into Turkish.
/// Currently uses a static translation map. Ready for Gemini integration.
class RecipeTranslationService {
  RecipeTranslationService._();

  // ── Recipe Title Translations ─────────────────────────────
  static const Map<String, String> _titleMap = {
    // Common recipe titles from Spoonacular
    'asparagus and pea soup: real convenience food': 'Kuşkonmaz ve Bezelye Çorbası',
    'red lentil soup with chicken and turnips': 'Tavuklu ve Şalgamlı Kırmızı Mercimek Çorbası',
    'garlicky kale': 'Sarımsaklı Karalahana',
    'chicken and broccoli stir fry': 'Tavuk ve Brokoli Sote',
    'grilled salmon': 'Izgara Somon',
    'pasta primavera': 'Bahar Makarnası',
    'chicken soup': 'Tavuk Çorbası',
    'vegetable stir fry': 'Sebze Sote',
    'beef stew': 'Dana Güveç',
    'mushroom risotto': 'Mantarlı Risotto',
    'greek salad': 'Yunan Salatası',
    'tomato soup': 'Domates Çorbası',
    'caesar salad': 'Sezar Salatası',
    'chicken curry': 'Tavuk Köri',
    'fish tacos': 'Balık Taco',
    'quinoa salad': 'Kinoa Salatası',
    'avocado toast': 'Avokado Tost',
    'lentil soup': 'Mercimek Çorbası',
    'chicken parmesan': 'Tavuk Parmesan',
    'shrimp scampi': 'Karidesli Makarna',
    'miso soup': 'Miso Çorbası',
    'spaghetti bolognese': 'Bolonez Soslu Spagetti',
    'chicken tikka masala': 'Tavuk Tikka Masala',
    'pad thai': 'Pad Thai',
    'falafel': 'Falafel',
    'hummus': 'Humus',
    'guacamole': 'Guakamole',
    'fried rice': 'Kızarmış Pirinç',
    'banana bread': 'Muzlu Ekmek',
    'pancakes': 'Pankek',
    'omelette': 'Omlet',
    'smoothie bowl': 'Smoothie Kase',
    'chicken wrap': 'Tavuklu Dürüm',
    'tuna salad': 'Ton Balıklı Salata',
    'minestrone soup': 'Minestrone Çorbası',
    'gazpacho': 'Gazpaço',
    'bruschetta': 'Bruschetta',
    'ratatouille': 'Ratatuy',
    'cauliflower soup': 'Karnabahar Çorbası',
    'sweet potato soup': 'Tatlı Patates Çorbası',
  };

  // ── Tag Translations ──────────────────────────────────────
  static const Map<String, String> _tagMap = {
    'lunch': 'Öğle Yemeği',
    'dinner': 'Akşam Yemeği',
    'breakfast': 'Kahvaltı',
    'snack': 'Ara Öğün',
    'soup': 'Çorba',
    'main course': 'Ana Yemek',
    'side dish': 'Yan Yemek',
    'salad': 'Salata',
    'dessert': 'Tatlı',
    'appetizer': 'Meze',
    'beverage': 'İçecek',
    'bread': 'Ekmek',
    'sauce': 'Sos',
    'fingerfood': 'Parmak Yemeği',
    'marinade': 'Marinasyon',
    'antipasti': 'Antipasti',
    'starter': 'Başlangıç',
    'antipasto': 'Antipasti',
    'morning meal': 'Sabah Yemeği',
    'brunch': 'Brunch',
    'gluten free': 'Glutensiz',
    'dairy free': 'Süt Ürünsüz',
    'vegan': 'Vegan',
    'vegetarian': 'Vejetaryen',
    'ketogenic': 'Ketojenik',
    'paleo': 'Paleo',
    'whole30': 'Whole30',
    'lacto ovo vegetarian': 'Lakto-Ovo Vejetaryen',
    'primal': 'Primal',
    'pescatarian': 'Pesketaryen',
    'fodmap friendly': 'FODMAP Dostu',
    'high protein': 'Yüksek Protein',
    'low calorie': 'Düşük Kalori',
    'low fat': 'Düşük Yağ',
    'low carb': 'Düşük Karbonhidrat',
    'sugar free': 'Şekersiz',
    'nut free': 'Kuruyemişsiz',
    'egg free': 'Yumurtasız',
    'soy free': 'Soyasız',
  };

  // ── Ingredient Name Translations ──────────────────────────
  static const Map<String, String> _ingredientMap = {
    'garlic': 'Sarımsak',
    'garlic cloves': 'Sarımsak Dişi',
    'olive oil': 'Zeytinyağı',
    'extra virgin olive oil': 'Sızma Zeytinyağı',
    'onion': 'Soğan',
    'onions': 'Soğan',
    'kale': 'Karalahana',
    'balsamic vinegar': 'Balzamik Sirke',
    'salt': 'Tuz',
    'pepper': 'Karabiber',
    'black pepper': 'Karabiber',
    'sugar': 'Şeker',
    'butter': 'Tereyağı',
    'milk': 'Süt',
    'egg': 'Yumurta',
    'eggs': 'Yumurta',
    'flour': 'Un',
    'all-purpose flour': 'Un',
    'water': 'Su',
    'chicken': 'Tavuk',
    'chicken breast': 'Tavuk Göğüs',
    'chicken thighs': 'Tavuk But',
    'beef': 'Dana Eti',
    'ground beef': 'Kıyma',
    'salmon': 'Somon',
    'salmon fillets': 'Somon Fileto',
    'shrimp': 'Karides',
    'tuna': 'Ton Balığı',
    'rice': 'Pirinç',
    'brown rice': 'Esmer Pirinç',
    'pasta': 'Makarna',
    'spaghetti': 'Spagetti',
    'quinoa': 'Kinoa',
    'lentils': 'Mercimek',
    'red lentils': 'Kırmızı Mercimek',
    'green lentils': 'Yeşil Mercimek',
    'chickpeas': 'Nohut',
    'black beans': 'Siyah Fasulye',
    'kidney beans': 'Kuru Fasulye',
    'tomato': 'Domates',
    'tomatoes': 'Domates',
    'cherry tomatoes': 'Kiraz Domates',
    'tomato paste': 'Domates Salçası',
    'tomato sauce': 'Domates Sosu',
    'potato': 'Patates',
    'potatoes': 'Patates',
    'sweet potato': 'Tatlı Patates',
    'carrot': 'Havuç',
    'carrots': 'Havuç',
    'broccoli': 'Brokoli',
    'spinach': 'Ispanak',
    'cauliflower': 'Karnabahar',
    'bell pepper': 'Biber',
    'red bell pepper': 'Kırmızı Biber',
    'green bell pepper': 'Yeşil Biber',
    'cucumber': 'Salatalık',
    'zucchini': 'Kabak',
    'eggplant': 'Patlıcan',
    'mushrooms': 'Mantar',
    'mushroom': 'Mantar',
    'asparagus': 'Kuşkonmaz',
    'peas': 'Bezelye',
    'green beans': 'Yeşil Fasulye',
    'corn': 'Mısır',
    'celery': 'Kereviz',
    'lettuce': 'Marul',
    'cabbage': 'Lahana',
    'avocado': 'Avokado',
    'lemon': 'Limon',
    'lemon juice': 'Limon Suyu',
    'lime': 'Misket Limonu',
    'lime juice': 'Misket Limonu Suyu',
    'orange': 'Portakal',
    'apple': 'Elma',
    'banana': 'Muz',
    'strawberries': 'Çilek',
    'blueberries': 'Yaban Mersini',
    'ginger': 'Zencefil',
    'fresh ginger': 'Taze Zencefil',
    'turmeric': 'Zerdeçal',
    'cumin': 'Kimyon',
    'cinnamon': 'Tarçın',
    'paprika': 'Kırmızı Toz Biber',
    'chili flakes': 'Pul Biber',
    'red pepper flakes': 'Pul Biber',
    'oregano': 'Kekik',
    'basil': 'Fesleğen',
    'parsley': 'Maydanoz',
    'fresh parsley': 'Taze Maydanoz',
    'cilantro': 'Kişniş',
    'thyme': 'Kekik',
    'rosemary': 'Biberiye',
    'dill': 'Dereotu',
    'mint': 'Nane',
    'bay leaf': 'Defne Yaprağı',
    'bay leaves': 'Defne Yaprağı',
    'cheese': 'Peynir',
    'parmesan cheese': 'Parmesan Peyniri',
    'mozzarella cheese': 'Mozzarella Peyniri',
    'feta cheese': 'Beyaz Peynir',
    'cream cheese': 'Krem Peynir',
    'cheddar cheese': 'Kaşar Peyniri',
    'yogurt': 'Yoğurt',
    'greek yogurt': 'Süzme Yoğurt',
    'cream': 'Krema',
    'heavy cream': 'Kaymak',
    'sour cream': 'Ekşi Krema',
    'coconut milk': 'Hindistancevizi Sütü',
    'almond milk': 'Badem Sütü',
    'soy sauce': 'Soya Sosu',
    'vegetable broth': 'Sebze Suyu',
    'chicken broth': 'Tavuk Suyu',
    'chicken stock': 'Tavuk Suyu',
    'beef broth': 'Et Suyu',
    'vinegar': 'Sirke',
    'apple cider vinegar': 'Elma Sirkesi',
    'honey': 'Bal',
    'maple syrup': 'Akçaağaç Şurubu',
    'mustard': 'Hardal',
    'dijon mustard': 'Dijon Hardalı',
    'ketchup': 'Ketçap',
    'mayonnaise': 'Mayonez',
    'peanut butter': 'Fıstık Ezmesi',
    'almonds': 'Badem',
    'walnuts': 'Ceviz',
    'cashews': 'Kaju',
    'peanuts': 'Yer Fıstığı',
    'sesame seeds': 'Susam',
    'sunflower seeds': 'Ayçiçeği Çekirdeği',
    'flax seeds': 'Keten Tohumu',
    'chia seeds': 'Chia Tohumu',
    'breadcrumbs': 'Galeta Unu',
    'bread': 'Ekmek',
    'whole wheat bread': 'Tam Buğday Ekmeği',
    'pita bread': 'Pide',
    'tortilla': 'Tortilla',
    'noodles': 'Erişte',
    'oats': 'Yulaf',
    'cornstarch': 'Mısır Nişastası',
    'baking powder': 'Kabartma Tozu',
    'baking soda': 'Karbonat',
    'vanilla extract': 'Vanilya Özütü',
    'cocoa powder': 'Kakao Tozu',
    'chocolate': 'Çikolata',
    'dark chocolate': 'Bitter Çikolata',
    'coconut oil': 'Hindistancevizi Yağı',
    'sesame oil': 'Susam Yağı',
    'vegetable oil': 'Bitkisel Yağ',
    'canola oil': 'Kanola Yağı',
    'cooking spray': 'Pişirme Yağı Spreyi',
    'turnips': 'Şalgam',
    'turnip': 'Şalgam',
    'pea': 'Bezelye',
  };

  // ── Unit Translations ─────────────────────────────────────
  static const Map<String, String> _unitMap = {
    'cup': 'su bardağı',
    'cups': 'su bardağı',
    'tablespoon': 'yemek kaşığı',
    'tablespoons': 'yemek kaşığı',
    'tbsp': 'yemek kaşığı',
    'tbsps': 'yemek kaşığı',
    'teaspoon': 'tatlı kaşığı',
    'teaspoons': 'tatlı kaşığı',
    'tsp': 'tatlı kaşığı',
    'tsps': 'tatlı kaşığı',
    'ounce': 'ons',
    'ounces': 'ons',
    'oz': 'ons',
    'pound': 'libre',
    'pounds': 'libre',
    'lb': 'libre',
    'lbs': 'libre',
    'piece': 'adet',
    'pieces': 'adet',
    'slice': 'dilim',
    'slices': 'dilim',
    'clove': 'diş',
    'cloves': 'diş',
    'pinch': 'tutam',
    'bunch': 'demet',
    'sprig': 'dal',
    'sprigs': 'dal',
    'handful': 'avuç',
    'small': 'küçük',
    'medium': 'orta',
    'large': 'büyük',
    'serving': 'porsiyon',
    'servings': 'porsiyon',
    'can': 'kutu',
    'jar': 'kavanoz',
    'package': 'paket',
    'head': 'baş',
    'stalk': 'sap',
    'stalks': 'sap',
    'leaf': 'yaprak',
    'leaves': 'yaprak',
    'dash': 'tutam',
    'to taste': 'isteğe göre',
  };

  // ── Cooking Instruction Keywords ──────────────────────────
  static const Map<String, String> _instructionKeywords = {
    'preheat': 'önceden ısıtın',
    'heat': 'ısıtın',
    'boil': 'kaynatın',
    'simmer': 'kısık ateşte pişirin',
    'bake': 'fırınlayın',
    'roast': 'kızartın',
    'grill': 'ızgara yapın',
    'fry': 'kızartın',
    'sauté': 'soteleyin',
    'saute': 'soteleyin',
    'stir': 'karıştırın',
    'mix': 'karıştırın',
    'combine': 'birleştirin',
    'add': 'ekleyin',
    'pour': 'dökün',
    'drain': 'süzün',
    'chop': 'doğrayın',
    'dice': 'küp küp doğrayın',
    'slice': 'dilimleyin',
    'mince': 'kıyın',
    'crush': 'ezin',
    'whisk': 'çırpın',
    'blend': 'karıştırın',
    'season': 'baharatlayın',
    'sprinkle': 'serpin',
    'serve': 'servis edin',
    'garnish': 'süsleyin',
    'cover': 'kapatın',
    'let': 'bırakın',
    'rest': 'dinlendirin',
    'cool': 'soğutun',
    'remove': 'çıkarın',
    'place': 'yerleştirin',
    'spread': 'yayın',
    'brush': 'sürün',
    'marinate': 'marine edin',
    'toss': 'karıştırın',
    'cook': 'pişirin',
    'reduce': 'azaltın',
    'minutes': 'dakika',
    'minute': 'dakika',
    'hours': 'saat',
    'hour': 'saat',
    'degrees': 'derece',
    'oven': 'fırın',
    'pan': 'tava',
    'pot': 'tencere',
    'bowl': 'kase',
    'plate': 'tabak',
    'skillet': 'tava',
  };

  /// Translate a full RecipeModel from English to Turkish
  static RecipeModel translateRecipe(RecipeModel recipe) {
    return recipe.copyWith(
      title: translateTitle(recipe.title),
      description: _translateDescription(recipe.description, recipe.title),
      tags: recipe.tags.map((t) => translateTag(t)).toList(),
      ingredients: recipe.ingredients.map((i) => _translateIngredient(i)).toList(),
      steps: recipe.steps.map((s) => _translateStep(s)).toList(),
      mealType: translateTag(recipe.mealType),
    );
  }

  /// Translate a list of recipes
  static List<RecipeModel> translateRecipes(List<RecipeModel> recipes) {
    return recipes.map((r) => translateRecipe(r)).toList();
  }

  /// Translate recipe title
  static String translateTitle(String title) {
    final lower = title.toLowerCase().trim();
    if (_titleMap.containsKey(lower)) return _titleMap[lower]!;

    // Try word-by-word translation for compound titles
    String result = title;
    _ingredientMap.forEach((en, tr) {
      final regex = RegExp(r'\b' + RegExp.escape(en) + r'\b', caseSensitive: false);
      result = result.replaceAll(regex, tr);
    });

    // Translate common cooking words in title
    final titleWords = {
      'soup': 'Çorbası',
      'salad': 'Salatası',
      'stir fry': 'Sote',
      'stir-fry': 'Sote',
      'grilled': 'Izgara',
      'baked': 'Fırında',
      'roasted': 'Kavrulmuş',
      'steamed': 'Buharda',
      'fried': 'Kızarmış',
      'creamy': 'Kremalı',
      'spicy': 'Baharatlı',
      'crispy': 'Çıtır',
      'stuffed': 'Dolma',
      'braised': 'Haşlanmış',
      'smoked': 'Füme',
      'marinated': 'Marine',
      'glazed': 'Glazürlü',
      'with': 've',
      'and': 've',
      'in': '',
      'the': '',
      'a': '',
      'an': '',
    };

    titleWords.forEach((en, tr) {
      final regex = RegExp(r'\b' + RegExp.escape(en) + r'\b', caseSensitive: false);
      result = result.replaceAll(regex, tr);
    });

    // Clean up extra spaces
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();
    return result;
  }

  /// Translate tag
  static String translateTag(String tag) {
    final lower = tag.toLowerCase().trim();
    return _tagMap[lower] ?? _capitalizeFirst(tag);
  }

  /// Translate an ingredient
  static IngredientModel _translateIngredient(IngredientModel ing) {
    return ing.copyWith(
      name: translateIngredientName(ing.name),
      amount: _translateAmount(ing.amount),
      nutrientTag: ing.nutrientTag != null ? _translateNutrientTag(ing.nutrientTag!) : null,
    );
  }

  /// Translate ingredient name
  static String translateIngredientName(String name) {
    final lower = name.toLowerCase().trim();
    if (_ingredientMap.containsKey(lower)) return _ingredientMap[lower]!;

    // Try partial match
    String result = name;
    _ingredientMap.forEach((en, tr) {
      final regex = RegExp(r'\b' + RegExp.escape(en) + r'\b', caseSensitive: false);
      result = result.replaceAll(regex, tr);
    });
    return result;
  }

  /// Translate amount string (e.g., "2.0 cups" → "2 su bardağı")
  static String _translateAmount(String amount) {
    String result = amount;
    _unitMap.forEach((en, tr) {
      final regex = RegExp(r'\b' + RegExp.escape(en) + r'\b', caseSensitive: false);
      result = result.replaceAll(regex, tr);
    });
    // Clean ".0" amounts
    result = result.replaceAll(RegExp(r'(\d+)\.0\b'), r'$1');
    return result;
  }

  /// Translate nutrient tag
  static String _translateNutrientTag(String tag) {
    final translations = {
      'Protein': 'Protein',
      'High Protein': 'Yüksek Protein',
      'Omega-3': 'Omega-3',
      'Fiber': 'Lif',
      'High Fiber': 'Yüksek Lif',
      'Vitamin C': 'C Vitamini',
      'Vitamin A': 'A Vitamini',
      'Iron': 'Demir',
      'Calcium': 'Kalsiyum',
      'Complex Carbs': 'Kompleks Karbonhidrat',
      'Low Fat': 'Düşük Yağ',
      'Low Calorie': 'Düşük Kalori',
    };
    return translations[tag] ?? tag;
  }

  /// Create short Turkish description
  static String _translateDescription(String description, String title) {
    // If description is too long (from Spoonacular HTML-stripped summary),
    // generate a short Turkish one
    if (description.length > 120) {
      final translatedTitle = translateTitle(title);
      return 'Dengeli ve lezzetli bir tarif: $translatedTitle. Sağlıklı beslenme hedeflerinize uygun bir seçenek.';
    }
    // Short descriptions — try word-by-word
    String result = description;
    _ingredientMap.forEach((en, tr) {
      final regex = RegExp(r'\b' + RegExp.escape(en) + r'\b', caseSensitive: false);
      result = result.replaceAll(regex, tr);
    });
    return result;
  }

  /// Translate a cooking step
  static CookingStepModel _translateStep(CookingStepModel step) {
    return step.copyWith(
      title: 'Adım ${step.step}',
      description: _translateInstruction(step.description),
      duration: _translateDuration(step.duration),
    );
  }

  /// Translate cooking instruction text
  static String _translateInstruction(String text) {
    String result = text;

    // Translate ingredient names first
    _ingredientMap.forEach((en, tr) {
      final regex = RegExp(r'\b' + RegExp.escape(en) + r'\b', caseSensitive: false);
      result = result.replaceAll(regex, tr);
    });

    // Translate cooking verbs and keywords
    _instructionKeywords.forEach((en, tr) {
      final regex = RegExp(r'\b' + RegExp.escape(en) + r'\b', caseSensitive: false);
      result = result.replaceAll(regex, tr);
    });

    // Translate units
    _unitMap.forEach((en, tr) {
      final regex = RegExp(r'\b' + RegExp.escape(en) + r'\b', caseSensitive: false);
      result = result.replaceAll(regex, tr);
    });

    return result;
  }

  /// Translate duration string
  static String _translateDuration(String duration) {
    return duration
        .replaceAll(RegExp(r'\bminutes\b', caseSensitive: false), 'dk')
        .replaceAll(RegExp(r'\bminute\b', caseSensitive: false), 'dk')
        .replaceAll(RegExp(r'\bhours\b', caseSensitive: false), 'saat')
        .replaceAll(RegExp(r'\bhour\b', caseSensitive: false), 'saat')
        .replaceAll(RegExp(r'\bmin\b', caseSensitive: false), 'dk');
  }

  static String _capitalizeFirst(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
