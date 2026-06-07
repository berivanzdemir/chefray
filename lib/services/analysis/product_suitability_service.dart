import '../../models/product/product_model.dart';
import '../../models/user_health_profile.dart';

class ProductSuitabilityService {
  /// Ürün özelliklerine (şeker, tuz, protein vb.) ve kullanıcının sağlık
  /// profiline bakarak basit kural bazlı bir ChefRay Yorumu üretir.
  String analyzeSuitability(ProductModel product, {UserHealthProfile? profile}) {
    List<String> insights = [];

    // 1. Şeker Kontrolü
    if (product.sugars != null && product.sugars! > 15.0) {
      insights.add("İlave şeker oranı yüksek görünüyor, porsiyon kontrolüne dikkat etmelisin.");
    } else if (product.sugars != null && product.sugars! <= 5.0) {
      insights.add("Şeker oranı düşük, bu harika!");
    }

    // 2. Doymuş Yağ Kontrolü
    if (product.saturatedFat != null && product.saturatedFat! > 5.0) {
      insights.add("Doymuş yağ içeriği fazla; sürekli tüketiminden kaçınmalısın.");
    }

    // 3. Protein Kontrolü
    if (product.protein != null && product.protein! > 10.0) {
      insights.add("Protein açısından destekleyici bir ürün.");
    }

    // 4. Lif Kontrolü
    if (product.fiber != null && product.fiber! > 6.0) {
      insights.add("Lif açısından zengin, tokluk hissini artıracaktır.");
    }
    
    // 5. Tuz Kontrolü
    if (product.salt != null && product.salt! > 1.5) {
      insights.add("Tuz oranı yüksek, gün içindeki diğer öğünlerini dengelemelisin.");
    }

    // Kullanıcı Profiline Göre Alerjen/Tercih Kontrolleri
    if (profile != null) {
      final userAllergies = profile.allergies.map((e) => e.toLowerCase()).toList();
      final productAllergies = product.allergens.map((e) => e.toLowerCase()).toList();
      
      for (var allergy in userAllergies) {
        if (productAllergies.contains(allergy) || 
           (allergy.contains('gluten') && productAllergies.any((a) => a.contains('gluten') || a.contains('wheat')))) {
          insights.insert(0, "⚠️ DİKKAT: Profilindeki alerjen ($allergy) bu üründe bulunuyor!");
        }
      }

      final preferences = profile.dietPreferences.map((e) => e.toLowerCase()).toList();
      if (preferences.any((p) => p.contains('düşük karbonhidrat') || p.contains('low carb'))) {
        if (product.carbs != null && product.carbs! > 20.0) {
          insights.add("Düşük karbonhidrat hedefin için bu ürünün karbonhidrat değeri biraz yüksek.");
        }
      }
    }

    if (insights.isEmpty) {
      return "Bu ürün hakkında yeterli detaylı besin değeri bulunmuyor, ancak porsiyon kontrolüne her zaman dikkat et.";
    }

    return insights.join(" ");
  }
}
