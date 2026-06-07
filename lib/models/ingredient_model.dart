enum IngredientCategory {
  vegetable,
  meat,
  spice,
  liquid,
  grain,
  dairy,
  seafood,
  fruit,
  other,
}

/// Model for a recipe ingredient.
class IngredientModel {
  final String name;
  final String amount;
  final int calories;
  final String? nutrientTag;
  final String? imageUrl;
  final String? assetPath;
  final IngredientCategory category;

  const IngredientModel({
    required this.name,
    required this.amount,
    required this.calories,
    this.nutrientTag,
    this.imageUrl,
    this.assetPath,
    this.category = IngredientCategory.other,
  });

  IngredientModel copyWith({
    String? name,
    String? amount,
    int? calories,
    String? nutrientTag,
    String? imageUrl,
    String? assetPath,
    IngredientCategory? category,
  }) {
    return IngredientModel(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      calories: calories ?? this.calories,
      nutrientTag: nutrientTag ?? this.nutrientTag,
      imageUrl: imageUrl ?? this.imageUrl,
      assetPath: assetPath ?? this.assetPath,
      category: category ?? this.category,
    );
  }
}
