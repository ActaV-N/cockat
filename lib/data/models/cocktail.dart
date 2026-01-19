import 'package:flutter/foundation.dart';
import 'ingredient.dart';

@immutable
class Cocktail {
  final String id;
  final String name;
  final String instructions;
  final String? description;
  final String? source;
  final String? garnish;
  final double? abv;
  final List<String> tags;
  final String? glass;
  final String? method;
  final List<CocktailIngredient> ingredients;
  final List<CocktailImage> images;

  const Cocktail({
    required this.id,
    required this.name,
    required this.instructions,
    this.description,
    this.source,
    this.garnish,
    this.abv,
    this.tags = const [],
    this.glass,
    this.method,
    this.ingredients = const [],
    this.images = const [],
  });

  factory Cocktail.fromJson(Map<String, dynamic> json) {
    return Cocktail(
      id: json['_id'] as String,
      name: json['name'] as String,
      instructions: json['instructions'] as String? ?? '',
      description: json['description'] as String?,
      source: json['source'] as String?,
      garnish: json['garnish'] as String?,
      abv: (json['abv'] as num?)?.toDouble(),
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      glass: json['glass'] as String?,
      method: json['method'] as String?,
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => CocktailIngredient.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => CocktailImage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'instructions': instructions,
      'description': description,
      'source': source,
      'garnish': garnish,
      'abv': abv,
      'tags': tags,
      'glass': glass,
      'method': method,
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
      'images': images.map((e) => e.toJson()).toList(),
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Cocktail && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

@immutable
class CocktailImage {
  final String uri;
  final int sort;
  final String? copyright;
  final String? placeholderHash;

  const CocktailImage({
    required this.uri,
    this.sort = 0,
    this.copyright,
    this.placeholderHash,
  });

  factory CocktailImage.fromJson(Map<String, dynamic> json) {
    return CocktailImage(
      uri: json['uri'] as String,
      sort: json['sort'] as int? ?? 0,
      copyright: json['copyright'] as String?,
      placeholderHash: json['placeholder_hash'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uri': uri,
      'sort': sort,
      'copyright': copyright,
      'placeholder_hash': placeholderHash,
    };
  }
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
