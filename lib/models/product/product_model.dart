class ProductModel {
  final String barcode;
  final String? name;
  final String? brand;
  final String? imageUrl;
  final String? ingredientsText;
  final List<String> allergens;
  final List<String> traces;
  final String? nutriScore;
  final String? novaGroup;
  final double? calories;
  final double? fat;
  final double? saturatedFat;
  final double? carbs;
  final double? sugars;
  final double? fiber;
  final double? protein;
  final double? salt;

  ProductModel({
    required this.barcode,
    this.name,
    this.brand,
    this.imageUrl,
    this.ingredientsText,
    this.allergens = const [],
    this.traces = const [],
    this.nutriScore,
    this.novaGroup,
    this.calories,
    this.fat,
    this.saturatedFat,
    this.carbs,
    this.sugars,
    this.fiber,
    this.protein,
    this.salt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json, String barcode) {
    final product = json['product'] ?? {};
    final nutriments = product['nutriments'] ?? {};

    List<String> parseTags(dynamic tags) {
      if (tags is List) {
        return tags.map((e) => e.toString().replaceFirst('en:', '')).toList();
      }
      return [];
    }

    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return ProductModel(
      barcode: barcode,
      name: product['product_name']?.toString(),
      brand: product['brands']?.toString(),
      imageUrl: product['image_url']?.toString(),
      ingredientsText: product['ingredients_text']?.toString(),
      allergens: parseTags(product['allergens_tags']),
      traces: parseTags(product['traces_tags']),
      nutriScore: product['nutriscore_grade']?.toString().toUpperCase(),
      novaGroup: product['nova_group']?.toString(),
      calories: parseDouble(nutriments['energy-kcal_100g']),
      fat: parseDouble(nutriments['fat_100g']),
      saturatedFat: parseDouble(nutriments['saturated-fat_100g']),
      carbs: parseDouble(nutriments['carbohydrates_100g']),
      sugars: parseDouble(nutriments['sugars_100g']),
      fiber: parseDouble(nutriments['fiber_100g']),
      protein: parseDouble(nutriments['proteins_100g']),
      salt: parseDouble(nutriments['salt_100g']),
    );
  }
}
