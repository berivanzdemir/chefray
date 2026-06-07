import 'package:flutter/material.dart';
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
    return text.toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
  }

  List<String> _getIngredientsForStep() {
    List<String> usedIngredients = [];
    String normDesc = _normalizeTurkish(stepDescription);
    
    for (var ingredient in recipeIngredients) {
      if (ingredient.name.isEmpty || ingredient.name.toLowerCase().contains('düzenleniyor')) continue;
      
      String normIng = _normalizeTurkish(ingredient.name);
      
      if (normDesc.contains(normIng)) {
        usedIngredients.add(ingredient.name);
        continue;
      }
      
      List<String> words = normIng.split(' ');
      bool isMatch = false;
      for (var word in words) {
        if (word.length > 3 && normDesc.contains(word)) {
          isMatch = true;
          break;
        }
      }
      
      if (isMatch) {
        usedIngredients.add(ingredient.name);
      }
    }
    
    if (usedIngredients.isEmpty) {
      if (recipeIngredients.isNotEmpty) {
        for (int i = 0; i < recipeIngredients.length && i < 3; i++) {
          if (recipeIngredients[i].name.isNotEmpty && !recipeIngredients[i].name.toLowerCase().contains('düzenleniyor')) {
            usedIngredients.add(recipeIngredients[i].name);
          }
        }
      }
    }
    
    return usedIngredients.toSet().toList(); 
  }

  @override
  Widget build(BuildContext context) {
    final stepIngredients = _getIngredientsForStep();

    if (stepIngredients.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bu adımda kullanılan',
          style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: stepIngredients.map((ing) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    ing,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87.withValues(alpha: 0.8)),
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
