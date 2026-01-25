/// Miscellaneous bar item (ice, garnishes, fresh ingredients, etc.)
class MiscItem {
  final String id;
  final String name;
  final String? nameKo;
  final String category; // 'ice', 'fresh', 'dairy', 'garnish', 'mixer', 'syrup', 'bitters'
  final String? description;
  final String? imageUrl;
  final int sortOrder;

  const MiscItem({
    required this.id,
    required this.name,
    this.nameKo,
    required this.category,
    this.description,
    this.imageUrl,
    this.sortOrder = 0,
  });

  factory MiscItem.fromSupabase(Map<String, dynamic> json) {
    return MiscItem(
      id: json['id'] as String,
      name: json['name'] as String,
      nameKo: json['name_ko'] as String?,
      category: json['category'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_ko': nameKo,
      'category': category,
      'description': description,
      'image_url': imageUrl,
      'sort_order': sortOrder,
    };
  }

  /// Get localized name based on locale
  String getLocalizedName(String locale) {
    if (locale == 'ko' && nameKo != null && nameKo!.isNotEmpty) {
      return nameKo!;
    }
    return name;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MiscItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Category definitions for misc items
class MiscItemCategories {
  static const List<String> allCategories = [
    'ice',
    'fresh',
    'dairy',
    'garnish',
    'mixer',
    'syrup',
    'bitters',
  ];

  static const Map<String, String> categoryIcons = {
    'ice': '🧊',
    'fresh': '🍋',
    'dairy': '🥚',
    'garnish': '🍒',
    'mixer': '🥤',
    'syrup': '🍯',
    'bitters': '🫗',
  };
}
