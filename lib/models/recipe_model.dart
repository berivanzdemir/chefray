import 'package:flutter/material.dart';
import 'ingredient_model.dart';
import 'cooking_step_model.dart';

int extractMinutes(String? value) {
  if (value == null || value.trim().isEmpty) return 0;
  final match = RegExp(r'\d+').firstMatch(value);
  if (match == null) return 0;
  return int.tryParse(match.group(0)!) ?? 0;
}

/// Model for a complete recipe.
class RecipeModel {
  final String id;
  final String title;
  final String? displayTitle;
  final String description;
  final String? imageUrl;
  final String? category;
  final String? prepTime;
  final String? cookTime;
  final int? totalTimeMin;
  final int? caloriesKcal;
  final int? proteinG;
  final String mealType;
  final String? mealTypeV2;
  final String? dishType;
  final String? dishTypeV2;
  final bool isRecommendable;
  final bool isDietFriendly;
  final bool isGlutenFree;
  final bool isHighProtein;
  final bool isLowCalorie;
  final String? glutenStatus;
  final String? calorieStatus;
  final String? proteinStatus;
  final bool recommendationReady;
  final String? blockedReason;
  final String? excludeReasonV2;
  final Map<String, dynamic>? rawJson;

  // Legacy support fields (for component/cooking UI compatibility)
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final int timeMinutes;
  final List<String> tags;
  final List<IngredientModel> ingredients;
  final List<CookingStepModel> steps;
  final int? readyInMinutes;
  final int? servings;
  final List<String> categories;
  final List<String> allergens;
  final List<String> dietTypes;
  final String? sourceUrl;
  final DateTime? createdAt;
  final bool hasNutritionData;

  const RecipeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.timeMinutes,
    required this.tags,
    required this.ingredients,
    required this.steps,
    required this.mealType,
    this.imageUrl,
    this.displayTitle,
    this.category,
    this.prepTime,
    this.cookTime,
    this.totalTimeMin,
    this.caloriesKcal,
    this.proteinG,
    this.mealTypeV2,
    this.dishType,
    this.dishTypeV2,
    this.isRecommendable = true,
    this.isDietFriendly = true,
    this.isGlutenFree = false,
    this.isHighProtein = false,
    this.isLowCalorie = false,
    this.glutenStatus,
    this.calorieStatus,
    this.proteinStatus,
    this.recommendationReady = false,
    this.blockedReason,
    this.excludeReasonV2,
    this.readyInMinutes,
    this.servings,
    this.categories = const [],
    this.allergens = const [],
    this.dietTypes = const [],
    this.sourceUrl,
    this.createdAt,
    this.hasNutritionData = true,
    this.rawJson,
  });

  RecipeModel copyWith({
    String? id,
    String? title,
    String? displayTitle,
    String? description,
    String? imageUrl,
    String? category,
    String? prepTime,
    String? cookTime,
    int? totalTimeMin,
    int? caloriesKcal,
    int? proteinG,
    String? mealType,
    String? mealTypeV2,
    String? dishType,
    String? dishTypeV2,
    bool? isRecommendable,
    bool? isDietFriendly,
    bool? isGlutenFree,
    bool? isHighProtein,
    bool? isLowCalorie,
    String? glutenStatus,
    String? calorieStatus,
    String? proteinStatus,
    bool? recommendationReady,
    String? blockedReason,
    String? excludeReasonV2,
    int? calories,
    int? protein,
    int? carbs,
    int? fat,
    int? timeMinutes,
    List<String>? tags,
    List<IngredientModel>? ingredients,
    List<CookingStepModel>? steps,
    int? readyInMinutes,
    int? servings,
    List<String>? categories,
    List<String>? allergens,
    List<String>? dietTypes,
    String? sourceUrl,
    DateTime? createdAt,
    bool? hasNutritionData,
    Map<String, dynamic>? rawJson,
  }) {
    return RecipeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      displayTitle: displayTitle ?? this.displayTitle,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      prepTime: prepTime ?? this.prepTime,
      cookTime: cookTime ?? this.cookTime,
      totalTimeMin: totalTimeMin ?? this.totalTimeMin,
      caloriesKcal: caloriesKcal ?? this.caloriesKcal,
      proteinG: proteinG ?? this.proteinG,
      mealType: mealType ?? this.mealType,
      mealTypeV2: mealTypeV2 ?? this.mealTypeV2,
      dishType: dishType ?? this.dishType,
      dishTypeV2: dishTypeV2 ?? this.dishTypeV2,
      isRecommendable: isRecommendable ?? this.isRecommendable,
      isDietFriendly: isDietFriendly ?? this.isDietFriendly,
      isGlutenFree: isGlutenFree ?? this.isGlutenFree,
      isHighProtein: isHighProtein ?? this.isHighProtein,
      isLowCalorie: isLowCalorie ?? this.isLowCalorie,
      glutenStatus: glutenStatus ?? this.glutenStatus,
      calorieStatus: calorieStatus ?? this.calorieStatus,
      proteinStatus: proteinStatus ?? this.proteinStatus,
      recommendationReady: recommendationReady ?? this.recommendationReady,
      blockedReason: blockedReason ?? this.blockedReason,
      excludeReasonV2: excludeReasonV2 ?? this.excludeReasonV2,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      timeMinutes: timeMinutes ?? this.timeMinutes,
      tags: tags ?? this.tags,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      readyInMinutes: readyInMinutes ?? this.readyInMinutes,
      servings: servings ?? this.servings,
      categories: categories ?? this.categories,
      allergens: allergens ?? this.allergens,
      dietTypes: dietTypes ?? this.dietTypes,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      createdAt: createdAt ?? this.createdAt,
      hasNutritionData: hasNutritionData ?? this.hasNutritionData,
      rawJson: rawJson ?? this.rawJson,
    );
  }

  int? get calculatedTotalMinutes {
    if (totalTimeMin != null && totalTimeMin! > 0) {
      return totalTimeMin;
    }

    final prep = extractMinutes(prepTime);
    final cook = extractMinutes(cookTime);
    final total = prep + cook;

    if (total <= 0) return null;
    return total;
  }

  String? get displayTime {
    final minutes = calculatedTotalMinutes;
    if (minutes != null) {
      return '$minutes dk';
    }
    return null;
  }

  String get shownTitle {
    return displayTitle?.isNotEmpty == true ? displayTitle! : title;
  }

  static String cleanRecipeTitle(String title) {
    String cleaned = title;
    
    final patterns = [
      '1 Dakikada Hazır:', '1 Dakikada Hazır',
      '5 Dakikada Hazır:', '5 Dakikada Hazır',
      '10 Dakikada Hazır:', '10 Dakikada Hazır',
      '15 Dakikada Hazır:', '15 Dakikada Hazır',
      '20 Dakikada Hazır:', '20 Dakikada Hazır',
      '30 Dakikada Hazır:', '30 Dakikada Hazır',
      'Bunu Böyle Deneyen Var Mı?', 'Bunu Böyle Deneyen Var Mı',
      'Bunu Deneyen Var Mı?', 'Bunu Deneyen Var Mı',
      'Mutlaka Deneyin',
      'Şipşak', 'Sipşak', 'Sipsak',
      'Pratik',
      'Kolay',
      'Nefis',
      'Videolu',
      'Tam Ölçülü',
      'Kıyır Kıyır', 'Kiyir Kiyir',
      'Lezzetli',
      'En Güzel', 'En Guzel',
      'Ev Yapımı', 'Ev Yapimi'
    ];
    
    for (final pattern in patterns) {
      final regExp = RegExp(RegExp.escape(pattern), caseSensitive: false);
      cleaned = cleaned.replaceAll(regExp, '');
    }
    
    cleaned = cleaned.trim();
    if (cleaned.startsWith(':')) {
      cleaned = cleaned.substring(1).trim();
    }
    if (cleaned.startsWith('-')) {
      cleaned = cleaned.substring(1).trim();
    }
    cleaned = cleaned.trim();
    
    if (cleaned.isEmpty) {
      return title;
    }
    
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  factory RecipeModel.fromSupabaseJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? UniqueKey().toString();
    final title = json['title']?.toString() ?? 'Lezzetli Tarif';
    final displayTitle = json['display_title']?.toString();
    final description = json['description']?.toString() ?? 'Sağlıklı ve lezzetli bir ev tarifi.';
    final imageUrl = json['image_url']?.toString();
    final category = json['category']?.toString() ?? 'Genel';
    final prepTime = json['prep_time']?.toString();
    final cookTime = json['cook_time']?.toString();
    final totalTimeMin = int.tryParse(json['total_time_min']?.toString() ?? '');
    final caloriesKcal = int.tryParse(json['calories_kcal']?.toString() ?? '');
    final proteinG = int.tryParse(json['protein_g']?.toString() ?? '');
    
    final mealType = json['meal_type']?.toString() ?? 'breakfast';
    final mealTypeV2 = json['meal_type_v2']?.toString();
    final dishType = json['dish_type']?.toString();
    final dishTypeV2 = json['dish_type_v2']?.toString();
    
    final isRecommendable = json['is_recommendable'] != false;
    final isDietFriendly = json['is_diet_friendly'] != false;
    final isGlutenFree = json['is_gluten_free'] == true;
    final isHighProtein = json['is_high_protein'] == true;
    final isLowCalorie = json['is_low_calorie'] == true;
    
    final glutenStatus = json['gluten_status']?.toString();
    final calorieStatus = json['calorie_status']?.toString();
    final proteinStatus = json['protein_status']?.toString();
    final recommendationReady = json['recommendation_ready'] == true;
    final blockedReason = json['blocked_reason']?.toString();
    final excludeReasonV2 = json['exclude_reason_v2']?.toString();

    // Legacy support fields
    final legacyCalories = caloriesKcal ?? 350;
    final legacyProtein = proteinG ?? 12;
    final legacyCarbs = int.tryParse(json['carbs']?.toString() ?? '') ?? 45;
    final legacyFat = int.tryParse(json['fat']?.toString() ?? '') ?? 10;
    final legacyTimeMinutes = totalTimeMin ?? (extractMinutes(prepTime) + extractMinutes(cookTime));

    // 2. Ingredients parsing - multiple format support
    final List<IngredientModel> ingredientModels = [];
    final rawIngData = json['ingredients'] ?? json['ingredient_list'];
    
    if (rawIngData != null) {
      if (rawIngData is List) {
        for (var item in rawIngData) {
          if (item == null) continue;
          if (item is Map) {
            String name = item['name']?.toString() ?? item['ingredient']?.toString() ?? '';
            String amount = item['display']?.toString() ?? '';
            
            if (amount.trim().isEmpty) {
              final quantity = item['quantity']?.toString() ?? item['amount']?.toString() ?? '';
              final unit = item['unit']?.toString() ?? item['measure']?.toString() ?? '';
              final note = item['note']?.toString() ?? '';
              
              final List<String> parts = [];
              if (quantity.isNotEmpty) parts.add(quantity);
              if (unit.isNotEmpty) parts.add(unit);
              if (name.isNotEmpty && !parts.contains(name)) parts.add(name);
              if (note.isNotEmpty) parts.add('($note)');
              
              amount = parts.join(' ').trim();
              if (amount.isEmpty) amount = 'Göz kararı / İsteğe bağlı';
            }
            
            if (name.isNotEmpty && !name.contains('[object Object]') && !name.contains('object Object')) {
              ingredientModels.add(IngredientModel(
                name: name,
                amount: amount,
                calories: 0,
              ));
            }
          } else {
            final name = item.toString().trim();
            if (name.isNotEmpty && !name.contains('[object Object]') && !name.contains('object Object')) {
              ingredientModels.add(IngredientModel(
                name: name,
                amount: '1 porsiyon',
                calories: 0,
              ));
            }
          }
        }
      } else if (rawIngData is String) {
        final rawStr = rawIngData.trim();
        if (rawStr.isNotEmpty && !rawStr.contains('[object Object]') && !rawStr.contains('object Object')) {
          List<String> parts = [];
          if (rawStr.contains('\n')) {
            parts = rawStr.split('\n');
          } else if (rawStr.contains(';')) {
            parts = rawStr.split(';');
          } else if (rawStr.contains(',')) {
            parts = rawStr.split(',');
          } else {
            parts = [rawStr];
          }
          
          for (var part in parts) {
            final name = part.trim();
            if (name.isNotEmpty && !name.contains('[object Object]') && !name.contains('object Object')) {
              ingredientModels.add(IngredientModel(
                name: name,
                amount: '1 porsiyon',
                calories: 0,
              ));
            }
          }
        }
      }
    }
    
    // Fallback to ingredients_text if models are empty due to [object Object] corruption
    if (ingredientModels.isEmpty) {
      final textData = json['ingredients_text']?.toString() ?? '';
      if (textData.isNotEmpty) {
        final parts = textData.split(RegExp(r'[,;\n]'));
        for (var part in parts) {
          final name = part.trim();
          if (name.isNotEmpty && !name.contains('[object Object]') && !name.contains('object Object')) {
            ingredientModels.add(IngredientModel(
              name: name,
              amount: 'Göz kararı / İsteğe bağlı',
              calories: 0,
            ));
          }
        }
      }
    }

    if (ingredientModels.isEmpty) {
      ingredientModels.add(const IngredientModel(
        name: 'Malzeme bilgisi düzenleniyor.',
        amount: '',
        calories: 0,
      ));
    }

    // 3. Instructions/Steps parsing - multiple format support
    final List<CookingStepModel> stepModels = [];
    final rawInstData = json['instructions'] ?? json['steps'] ?? json['recipe_steps'];
    
    if (rawInstData != null) {
      if (rawInstData is List) {
        for (var i = 0; i < rawInstData.length; i++) {
          final item = rawInstData[i];
          if (item == null) continue;
          if (item is Map) {
            final text = item['text']?.toString() ?? item['step_description']?.toString() ?? item['description']?.toString() ?? '';
            final stepNum = int.tryParse(item['step']?.toString() ?? '') ?? (i + 1);
            if (text.isNotEmpty) {
              stepModels.add(CookingStepModel(
                step: stepNum,
                title: 'Adım $stepNum',
                description: text,
                duration: '5 dk',
                timerSeconds: 300,
              ));
            }
          } else {
            final text = item.toString().trim();
            if (text.isNotEmpty) {
              stepModels.add(CookingStepModel(
                step: i + 1,
                title: 'Adım ${i + 1}',
                description: text,
                duration: '5 dk',
                timerSeconds: 300,
              ));
            }
          }
        }
      } else if (rawInstData is String) {
        final rawStr = rawInstData.trim();
        if (rawStr.isNotEmpty) {
          List<String> parts = [];
          if (rawStr.contains('\n')) {
            parts = rawStr.split('\n');
          } else if (rawStr.contains('.')) {
            parts = rawStr.split('.');
          } else {
            parts = [rawStr];
          }
          
          final validParts = parts.map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
          final maxSteps = validParts.length > 8 ? 8 : validParts.length;
          
          for (int i = 0; i < maxSteps; i++) {
            final desc = validParts[i];
            final stepCounter = i + 1;
            
            String dynamicTitle = 'Adım $stepCounter';
            String dynamicDuration = '5 dk';
            
            if (stepCounter == 1) {
              dynamicTitle = 'Hazırlık';
              dynamicDuration = '10 dk';
            } else if (stepCounter == maxSteps && maxSteps > 1) {
              dynamicTitle = 'Servis Edin';
              dynamicDuration = '0 dk';
            } else {
              dynamicTitle = stepCounter % 2 == 0 ? 'Malzemeleri Ekleyin' : 'Pişirin';
              dynamicDuration = '10 dk';
            }

            stepModels.add(CookingStepModel(
              step: stepCounter,
              title: dynamicTitle,
              description: desc,
              duration: dynamicDuration,
              timerSeconds: 300,
            ));
          }
        }
      }
    }
    
    if (stepModels.isEmpty) {
      stepModels.add(const CookingStepModel(
        step: 1,
        title: 'Yapılış',
        description: 'Yapılış adımları bulunamadı.',
        duration: '',
        timerSeconds: 0,
      ));
    }

    final List<String> detectedAllergens = [];
    final List<String> detectedDietTypes = ['Dengeli', 'Sağlıklı'];

    final ingNamesLower = ingredientModels.map((e) => e.name.toLowerCase()).toList();
    bool hasMeat = false;
    bool hasDairy = false;
    bool hasGluten = false;
    bool hasEgg = false;

    for (var name in ingNamesLower) {
      if (name.contains('yoğurt') || name.contains('süt') || name.contains('peynir') || name.contains('tereyağı') || name.contains('labne') || name.contains('kefir')) {
        hasDairy = true;
        detectedAllergens.add('laktoz');
        detectedAllergens.add('süt ürünleri');
      }
      if (name.contains('pirinç') || name.contains('un') || name.contains('kruton') || name.contains('ekmek') || name.contains('makarna')) {
        hasGluten = true;
        detectedAllergens.add('gluten');
      }
      if (name.contains('yumurta')) {
        hasEgg = true;
        detectedAllergens.add('yumurta');
      }
      if (name.contains('somon') || name.contains('balık') || name.contains('ton balığı')) {
        hasMeat = true;
        detectedAllergens.add('balık');
      }
      if (name.contains('dana') || name.contains('bonfile') || name.contains('et') || name.contains('tavuk') || name.contains('köfte')) {
        hasMeat = true;
      }
      if (name.contains('ceviz') || name.contains('fındık') || name.contains('fıstık') || name.contains('badem')) {
        detectedAllergens.add('fındık');
        detectedAllergens.add('fıstık');
      }
    }

    if (!hasMeat && !hasDairy && !hasEgg) {
      detectedDietTypes.add('Vegan');
      detectedDietTypes.add('Vejetaryen');
    } else if (!hasMeat) {
      detectedDietTypes.add('Vejetaryen');
    }
    if (!hasGluten) {
      detectedDietTypes.add('Glutensiz');
    }
    if (!hasDairy) {
      detectedDietTypes.add('Laktozsuz');
    }

    // Map DB mealType to standard Turkish name for tags
    String turkishMealType = 'Kahvaltı';
    final dbMealLower = mealType.toLowerCase();
    if (dbMealLower == 'breakfast') {
      turkishMealType = 'Kahvaltı';
    } else if (dbMealLower == 'lunch') {
      turkishMealType = 'Öğle Yemeği';
    } else if (dbMealLower == 'dinner') {
      turkishMealType = 'Akşam Yemeği';
    } else if (dbMealLower == 'snack') {
      turkishMealType = 'Ara Öğün';
    }

    final tagsList = <String>[category, turkishMealType];
    tagsList.addAll(detectedDietTypes);

    final validImageUrl = imageUrl != null && imageUrl.isNotEmpty
        ? imageUrl
        : 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500';

    return RecipeModel(
      id: id,
      title: title,
      displayTitle: displayTitle,
      description: description,
      imageUrl: validImageUrl,
      category: category,
      prepTime: prepTime,
      cookTime: cookTime,
      totalTimeMin: totalTimeMin,
      caloriesKcal: caloriesKcal,
      proteinG: proteinG,
      mealType: mealType,
      mealTypeV2: mealTypeV2,
      dishType: dishType,
      dishTypeV2: dishTypeV2,
      isRecommendable: isRecommendable,
      isDietFriendly: isDietFriendly,
      isGlutenFree: isGlutenFree,
      isHighProtein: isHighProtein,
      isLowCalorie: isLowCalorie,
      glutenStatus: glutenStatus,
      calorieStatus: calorieStatus,
      proteinStatus: proteinStatus,
      recommendationReady: recommendationReady,
      blockedReason: blockedReason,
      excludeReasonV2: excludeReasonV2,
      calories: legacyCalories,
      protein: legacyProtein,
      carbs: legacyCarbs,
      fat: legacyFat,
      timeMinutes: legacyTimeMinutes,
      tags: tagsList.toSet().toList(),
      ingredients: ingredientModels,
      steps: stepModels,
      readyInMinutes: legacyTimeMinutes,
      servings: int.tryParse(json['servings']?.toString() ?? '') ?? 2,
      categories: [category],
      allergens: detectedAllergens.toSet().toList(),
      dietTypes: detectedDietTypes,
      sourceUrl: json['source_url']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      hasNutritionData: caloriesKcal != null || proteinG != null,
      rawJson: json,
    );
  }
}

class RecipeMockData {
  RecipeMockData._();

  static const primary = RecipeModel(
    id: 'salmon-quinoa',
    title: 'Limonlu Somon, Kinoa ve Buharda Sebzeler',
    description: 'Yüksek proteinli, omega-3 açısından zengin, dengeli ve hafif bir öğün.',
    calories: 450,
    protein: 38,
    carbs: 40,
    fat: 16,
    timeMinutes: 25,
    tags: ['Yüksek Protein', 'Düşük Kalori', 'Glutensiz'],
    mealType: 'Öğle Yemeği',
    ingredients: [
      IngredientModel(name: 'Somon Fileto', amount: '150g', calories: 310, nutrientTag: 'Yüksek Protein, Omega-3', category: IngredientCategory.seafood),
      IngredientModel(name: 'Kinoa', amount: '80g', calories: 120, nutrientTag: 'Lif, Kompleks Karbonhidrat', category: IngredientCategory.grain),
      IngredientModel(name: 'Buharda Sebzeler', amount: '150g', calories: 80, nutrientTag: 'Lif, C Vitamini', category: IngredientCategory.vegetable),
      IngredientModel(name: 'Limon', amount: '1/2 adet', calories: 5, category: IngredientCategory.fruit),
      IngredientModel(name: 'Zeytinyağı', amount: '1 tatlı kaşığı', calories: 40, category: IngredientCategory.liquid),
      IngredientModel(name: 'Tuz & Karabiber', amount: 'az miktar', calories: 0, category: IngredientCategory.spice),
    ],
    steps: [
      CookingStepModel(step: 1, title: 'Kinoayı Pişirin', description: 'Kinoayı bol suyla yıkayın. 1 su bardağı su ile tencereye alın. Kısık ateşte 12-15 dakika pişirin ve demlenmeye bırakın.', duration: '12-15 dk', timerSeconds: 780),
      CookingStepModel(step: 2, title: 'Somonu Marine Edin', description: 'Somonun üzerine limon suyu, zeytinyağı, tuz ve karabiber ekleyin. 10 dakika marine edin.', duration: '10 dk', timerSeconds: 600, tip: 'Somonu fazla bekletmeyin, dokusu bozulabilir.'),
      CookingStepModel(step: 3, title: 'Somonu Pişirin', description: 'Tavayı ısıtın ve somonu her iki tarafı altın rengi olana kadar pişirin.', duration: '8-10 dk', timerSeconds: 540),
      CookingStepModel(step: 4, title: 'Sebzeleri Buharda Pişirin', description: 'Brokoli ve havucu buharda 8-10 dakika kadar pişirin.', duration: '8-10 dk', timerSeconds: 540),
      CookingStepModel(step: 5, title: 'Servis Edin', description: 'Kinoayı tabağa alın, üzerine somon ve sebzeleri ekleyin. Limon dilimleriyle servis edin.', duration: '2 dk', timerSeconds: 120),
    ],
  );

  static const List<RecipeModel> all = [
    primary,
    RecipeModel(
      id: 'chicken-pesto',
      title: 'Pesto Soslu Tavuk ve Brokoli',
      description: 'Yüksek proteinli, lifli ve doyurucu dengeli bir öğün.',
      calories: 520, protein: 42, carbs: 62, fat: 14, timeMinutes: 20,
      tags: ['Yüksek Protein', 'Glutensiz'],
      mealType: 'Öğle Yemeği',
      ingredients: [], steps: [],
    ),
    RecipeModel(
      id: 'lentil-soup',
      title: 'Mercimek Çorbası',
      description: 'Bitkisel protein kaynağı, lifli ve tok tutan lezzetli bir çorba.',
      calories: 380, protein: 16, carbs: 48, fat: 15, timeMinutes: 15,
      tags: ['Vegan', 'Glutensiz', 'Lifli'],
      mealType: 'Akşam Yemeği',
      ingredients: [], steps: [],
    ),
    RecipeModel(
      id: 'tuna-salad',
      title: 'Ton Balıklı Avokado Salatası',
      description: 'Omega-3 açısından zengin, hafif ve sağlıklı bir seçenek.',
      calories: 420, protein: 24, carbs: 58, fat: 10, timeMinutes: 25,
      tags: ['Vegan', 'Lifli'],
      mealType: 'Kahvaltı',
      ingredients: [], steps: [],
    ),
    RecipeModel(
      id: 'beef-rice',
      title: 'Dana Sote, Esmer Pirinç ve Sebzeler',
      description: 'Demir açısından zengin, enerji veren klasik ve doyurucu bir öğün.',
      calories: 560, protein: 46, carbs: 55, fat: 18, timeMinutes: 30,
      tags: ['Yüksek Protein', 'Düşük Kalori'],
      mealType: 'Akşam Yemeği',
      ingredients: [], steps: [],
    ),
  ];
}
