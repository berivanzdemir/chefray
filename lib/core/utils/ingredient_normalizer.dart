class IngredientNormalizer {
  static String normalize(String input) {
    String text = input.toLowerCase().trim();
    
    // Replace Turkish chars
    text = text.replaceAll('ç', 'c');
    text = text.replaceAll('ğ', 'g');
    text = text.replaceAll('ı', 'i');
    text = text.replaceAll('ö', 'o');
    text = text.replaceAll('ş', 's');
    text = text.replaceAll('ü', 'u');
    
    // Replace spaces with hyphens
    text = text.replaceAll(RegExp(r'\s+'), '-');
    
    // Remove special characters except hyphens and alphanumeric
    text = text.replaceAll(RegExp(r'[^a-z0-9\-]'), '');
    
    return text;
  }
}
