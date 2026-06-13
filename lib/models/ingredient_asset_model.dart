class IngredientAssetModel {
  final String id;
  final String ingredientKey;
  final String displayName;
  final String imageUrl;
  final DateTime? createdAt;

  IngredientAssetModel({
    required this.id,
    required this.ingredientKey,
    required this.displayName,
    required this.imageUrl,
    this.createdAt,
  });

  factory IngredientAssetModel.fromJson(Map<String, dynamic> json) {
    return IngredientAssetModel(
      id: json['id'] as String,
      ingredientKey: json['ingredient_key'] as String,
      displayName: json['display_name'] as String,
      imageUrl: json['image_url'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }
}
