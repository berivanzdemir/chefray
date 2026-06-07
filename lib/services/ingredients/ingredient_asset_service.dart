import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/ingredient_normalizer.dart';

class IngredientAssetService {
  final SupabaseClient _client = Supabase.instance.client;
  
  // Cache for already fetched images to avoid multiple network calls
  static final Map<String, String?> _imageCache = {};

  Future<String?> getIngredientImageUrl(String ingredientName) async {
    final String ingredientKey = IngredientNormalizer.normalize(ingredientName);
    
    if (_imageCache.containsKey(ingredientKey)) {
      return _imageCache[ingredientKey];
    }
    
    try {
      final response = await _client
          .from('ingredient_assets')
          .select('image_url')
          .eq('ingredient_key', ingredientKey)
          .maybeSingle();

      if (response != null && response['image_url'] != null) {
        final url = response['image_url'] as String;
        _imageCache[ingredientKey] = url;
        return url;
      }
      
      _imageCache[ingredientKey] = null;
      return null;
    } catch (e) {
      _imageCache[ingredientKey] = null;
      return null;
    }
  }
}
