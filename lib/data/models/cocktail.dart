import 'package:flutter/foundation.dart';
import 'ingredient.dart';

@immutable
class Cocktail {
  final String id;
  final String name;
  final String? nameKo;
  final String instructions;
  final String? instructionsKo;
  final String? description;
  final String? descriptionKo;
  final String? source;
  final String? garnish;
  final String? garnishKo;
  final double? abv;
  final List<String> tags;
  final String? glass;
  final String? method;
  final String? imageUrl;
  final List<CocktailIngredient> ingredients;

  const Cocktail({
    required this.id,
    required this.name,
    this.nameKo,
    required this.instructions,
    this.instructionsKo,
    this.description,
    this.descriptionKo,
    this.source,
    this.garnish,
    this.garnishKo,
    this.abv,
    this.tags = const [],
    this.glass,
    this.method,
    this.imageUrl,
    this.ingredients = const [],
  });

  factory Cocktail.fromJson(Map<String, dynamic> json) {
    return Cocktail(
      id: json['_id'] as String,
      name: json['name'] as String,
      nameKo: json['name_ko'] as String?,
      instructions: json['instructions'] as String? ?? '',
      instructionsKo: json['instructions_ko'] as String?,
      description: json['description'] as String?,
      descriptionKo: json['description_ko'] as String?,
      source: json['source'] as String?,
      garnish: json['garnish'] as String?,
      garnishKo: json['garnish_ko'] as String?,
      abv: (json['abv'] as num?)?.toDouble(),
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      glass: json['glass'] as String?,
      method: json['method'] as String?,
      imageUrl: json['image_url'] as String?,
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => CocktailIngredient.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Create from Supabase row with joined ingredients
  factory Cocktail.fromSupabase(
    Map<String, dynamic> row, {
    List<CocktailIngredient> ingredients = const [],
  }) {
    return Cocktail(
      id: row['id'] as String,
      name: row['name'] as String,
      nameKo: row['name_ko'] as String?,
      instructions: row['instructions'] as String? ?? '',
      instructionsKo: row['instructions_ko'] as String?,
      description: row['description'] as String?,
      descriptionKo: row['description_ko'] as String?,
      garnish: row['garnish'] as String?,
      garnishKo: row['garnish_ko'] as String?,
      abv: (row['abv'] as num?)?.toDouble(),
      tags: (row['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      glass: row['glass'] as String?,
      method: row['method'] as String?,
      imageUrl: row['image_url'] as String?,
      ingredients: ingredients,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'name_ko': nameKo,
      'instructions': instructions,
      'instructions_ko': instructionsKo,
      'description': description,
      'description_ko': descriptionKo,
      'source': source,
      'garnish': garnish,
      'garnish_ko': garnishKo,
      'abv': abv,
      'tags': tags,
      'glass': glass,
      'method': method,
      'image_url': imageUrl,
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
    };
  }

  /// Convert to Supabase insert format (without ingredients)
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'name': name,
      'name_ko': nameKo,
      'instructions': instructions,
      'instructions_ko': instructionsKo,
      'description': description,
      'description_ko': descriptionKo,
      'garnish': garnish,
      'garnish_ko': garnishKo,
      'abv': abv,
      'tags': tags,
      'glass': glass,
      'method': method,
      'image_url': imageUrl,
    };
  }

  /// Get required (non-optional) ingredients
  List<CocktailIngredient> get requiredIngredients =>
      ingredients.where((i) => !i.optional).toList();

  /// Get optional ingredients
  List<CocktailIngredient> get optionalIngredients =>
      ingredients.where((i) => i.optional).toList();

  /// Get all ingredient IDs (required only)
  Set<String> get requiredIngredientIds =>
      requiredIngredients.map((i) => i.id).toSet();

  /// Get all ingredient IDs including optional
  Set<String> get allIngredientIds =>
      ingredients.map((i) => i.id).toSet();

  /// Get localized name based on locale
  String getLocalizedName(String locale) {
    if (locale == 'ko' && nameKo != null && nameKo!.isNotEmpty) {
      return nameKo!;
    }
    return name;
  }

  /// Get localized description based on locale
  String? getLocalizedDescription(String locale) {
    if (locale == 'ko' && descriptionKo != null && descriptionKo!.isNotEmpty) {
      return descriptionKo;
    }
    return description;
  }

  /// Get localized instructions based on locale
  String getLocalizedInstructions(String locale) {
    if (locale == 'ko' && instructionsKo != null && instructionsKo!.isNotEmpty) {
      return instructionsKo!;
    }
    return instructions;
  }

  /// Get localized garnish based on locale
  String? getLocalizedGarnish(String locale) {
    if (locale == 'ko' && garnishKo != null && garnishKo!.isNotEmpty) {
      return garnishKo;
    }
    return garnish;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Cocktail && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Result of matching user's ingredients against a cocktail
@immutable
class CocktailMatch {
  final Cocktail cocktail;
  final Set<String> matchedIngredients;
  final Set<String> missingIngredients;
  final Set<String> availableSubstitutes;

  const CocktailMatch({
    required this.cocktail,
    required this.matchedIngredients,
    required this.missingIngredients,
    this.availableSubstitutes = const {},
  });

  /// Can make this cocktail with available ingredients
  bool get canMake => missingIngredients.isEmpty;

  /// Number of missing ingredients
  int get missingCount => missingIngredients.length;

  /// Match percentage (0-100)
  double get matchPercentage {
    final total = cocktail.requiredIngredientIds.length;
    if (total == 0) return 100;
    return (matchedIngredients.length / total) * 100;
  }

  /// Sort priority: can make first, then by missing count
  int compareTo(CocktailMatch other) {
    if (canMake && !other.canMake) return -1;
    if (!canMake && other.canMake) return 1;
    return missingCount.compareTo(other.missingCount);
  }
}
