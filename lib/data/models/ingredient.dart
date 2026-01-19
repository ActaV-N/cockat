import 'package:flutter/foundation.dart';

@immutable
class Ingredient {
  final String id;
  final String name;
  final String? category;
  final String? description;
  final double? strength; // ABV percentage
  final String? origin;
  final String? color;
  final List<String>? substitutes;

  const Ingredient({
    required this.id,
    required this.name,
    this.category,
    this.description,
    this.strength,
    this.origin,
    this.color,
    this.substitutes,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['_id'] as String,
      name: json['name'] as String,
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

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'category': category,
      'description': description,
      'strength': strength,
      'origin': origin,
      'color': color,
      'substitutes': substitutes,
    };
  }

  Ingredient copyWith({
    String? id,
    String? name,
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
      category: category ?? this.category,
      description: description ?? this.description,
      strength: strength ?? this.strength,
      origin: origin ?? this.origin,
      color: color ?? this.color,
      substitutes: substitutes ?? this.substitutes,
    );
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
    return '$amount $units';
  }
}
