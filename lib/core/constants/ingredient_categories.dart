/// Ingredient category definitions for grouping
class IngredientCategories {
  static const Map<String, List<String>> categoryMapping = {
    'spirits': [
      'Spirit',
      'Vodka',
      'Gin',
      'Rum',
      'Tequila',
      'Mezcal',
      'Whiskey',
      'Bourbon',
      'Scotch',
      'Brandy',
      'Cognac',
      'Pisco',
      'Cachaca',
    ],
    'liqueurs': [
      'Liqueur',
      'Amaretto',
      'Orange Liqueur',
      'Coffee Liqueur',
      'Cream Liqueur',
      'Herbal Liqueur',
      'Fruit Liqueur',
    ],
    'wines': [
      'Wine',
      'Vermouth',
      'Sherry',
      'Port',
      'Champagne',
      'Sparkling Wine',
      'Fortified Wine',
    ],
    'bitters': [
      'Bitters',
      'Amaro',
    ],
    'juices': [
      'Juice',
      'Citrus',
      'Fresh Juice',
    ],
    'syrups': [
      'Syrup',
      'Sweetener',
      'Sugar',
    ],
    'other': [
      'Mixer',
      'Soda',
      'Egg',
      'Dairy',
      'Fruit',
      'Herb',
      'Spice',
      'Garnish',
    ],
  };

  /// Get category key for a given ingredient category string
  static String getCategoryKey(String? category) {
    if (category == null) return 'other';

    final lowerCategory = category.toLowerCase();

    for (final entry in categoryMapping.entries) {
      for (final keyword in entry.value) {
        if (lowerCategory.contains(keyword.toLowerCase())) {
          return entry.key;
        }
      }
    }

    return 'other';
  }

  /// Get all category keys
  static List<String> get allCategories => categoryMapping.keys.toList();
}
