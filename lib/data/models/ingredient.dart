import 'package:flutter/foundation.dart';

@immutable
class Ingredient {
  final String id;
  final String name;
  final String? nameKo;
  final String? category;
  final String? description;
  final double? strength; // ABV percentage
  final String? origin;
  final String? color;
  final List<String>? substitutes;

  const Ingredient({
    required this.id,
    required this.name,
    this.nameKo,
    this.category,
    this.description,
    this.strength,
    this.origin,
    this.color,
    this.substitutes,
  });

  /// Create from local JSON (Bar Assistant format)
  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['_id'] as String,
      name: json['name'] as String,
      nameKo: json['name_ko'] as String?,
      category: json['category'] as String?,
      description: json['description'] as String?,
      strength: (json['strength'] as num?)?.toDouble(),
      origin: json['origin'] as String?,
      color: json['color'] as String?,
      substitutes: (json['substitutes'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  /// Create from Supabase row
  factory Ingredient.fromSupabase(
    Map<String, dynamic> row, {
    List<String>? substitutes,
  }) {
    return Ingredient(
      id: row['id'] as String,
      name: row['name'] as String,
      nameKo: row['name_ko'] as String?,
      category: row['category'] as String?,
      description: row['description'] as String?,
      strength: (row['strength'] as num?)?.toDouble(),
      origin: row['origin'] as String?,
      substitutes: substitutes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'name_ko': nameKo,
      'category': category,
      'description': description,
      'strength': strength,
      'origin': origin,
      'color': color,
      'substitutes': substitutes,
    };
  }

  /// Convert to Supabase insert format
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'name': name,
      'name_ko': nameKo,
      'category': category,
      'description': description,
      'strength': strength,
      'origin': origin,
    };
  }

  Ingredient copyWith({
    String? id,
    String? name,
    String? nameKo,
    String? category,
    String? description,
    double? strength,
    String? origin,
    String? color,
    List<String>? substitutes,
  }) {
    return Ingredient(
      id: id ?? this.id,
      name: name ?? this.name,
      nameKo: nameKo ?? this.nameKo,
      category: category ?? this.category,
      description: description ?? this.description,
      strength: strength ?? this.strength,
      origin: origin ?? this.origin,
      color: color ?? this.color,
      substitutes: substitutes ?? this.substitutes,
    );
  }

  /// Get localized name based on locale
  String getLocalizedName(String locale) {
    if (locale == 'ko' && nameKo != null && nameKo!.isNotEmpty) {
      return nameKo!;
    }
    return name;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Ingredient && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Ingredient as used in a cocktail recipe
@immutable
class CocktailIngredient {
  final String id;
  final String name;
  final int sort;
  final double amount;
  final String units;
  final bool optional;
  final double? amountMax;
  final String? note;
  final List<String> substitutes;

  const CocktailIngredient({
    required this.id,
    required this.name,
    required this.sort,
    required this.amount,
    required this.units,
    this.optional = false,
    this.amountMax,
    this.note,
    this.substitutes = const [],
  });

  factory CocktailIngredient.fromJson(Map<String, dynamic> json) {
    return CocktailIngredient(
      id: json['_id'] as String,
      name: json['name'] as String,
      sort: json['sort'] as int? ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      units: json['units'] as String? ?? '',
      optional: json['optional'] as bool? ?? false,
      amountMax: (json['amount_max'] as num?)?.toDouble(),
      note: json['note'] as String?,
      substitutes: (json['substitutes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  /// Create from Supabase cocktail_ingredients row with joined ingredient
  factory CocktailIngredient.fromSupabase(Map<String, dynamic> row) {
    final ingredient = row['ingredient'] as Map<String, dynamic>?;
    return CocktailIngredient(
      id: row['ingredient_id'] as String,
      name: ingredient?['name'] as String? ?? row['ingredient_id'] as String,
      sort: row['sort_order'] as int? ?? 0,
      amount: (row['amount'] as num?)?.toDouble() ?? 0,
      units: row['units'] as String? ?? '',
      optional: row['is_optional'] as bool? ?? false,
      note: row['note'] as String?,
      substitutes: const [], // Loaded separately
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'sort': sort,
      'amount': amount,
      'units': units,
      'optional': optional,
      'amount_max': amountMax,
      'note': note,
      'substitutes': substitutes,
    };
  }

  String get formattedAmount {
    if (amountMax != null) {
      return '$amount-$amountMax $units';
    }
    // Format nicely
    final amountStr = amount == amount.roundToDouble()
        ? amount.round().toString()
        : amount.toString();
    return '$amountStr $units';
  }
}
