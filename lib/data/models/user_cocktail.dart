import 'package:flutter/foundation.dart';

/// 사용자가 만든 커스텀 칵테일
@immutable
class UserCocktail {
  final String id;
  final String userId;
  final String name;
  final String? nameKo;
  final String? description;
  final String? descriptionKo;
  final String instructions;
  final String? instructionsKo;
  final String? garnish;
  final String? garnishKo;
  final String? glass;
  final String? method;
  final double? abv;
  final List<String> tags;
  final String? imageUrl;
  final bool isPublic;
  final String? basedOnCocktailId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<UserCocktailIngredient> ingredients;

  const UserCocktail({
    required this.id,
    required this.userId,
    required this.name,
    this.nameKo,
    this.description,
    this.descriptionKo,
    required this.instructions,
    this.instructionsKo,
    this.garnish,
    this.garnishKo,
    this.glass,
    this.method,
    this.abv,
    this.tags = const [],
    this.imageUrl,
    this.isPublic = false,
    this.basedOnCocktailId,
    required this.createdAt,
    required this.updatedAt,
    this.ingredients = const [],
  });

  factory UserCocktail.fromSupabase(
    Map<String, dynamic> row, {
    List<UserCocktailIngredient> ingredients = const [],
  }) {
    return UserCocktail(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      name: row['name'] as String,
      nameKo: row['name_ko'] as String?,
      description: row['description'] as String?,
      descriptionKo: row['description_ko'] as String?,
      instructions: row['instructions'] as String? ?? '',
      instructionsKo: row['instructions_ko'] as String?,
      garnish: row['garnish'] as String?,
      garnishKo: row['garnish_ko'] as String?,
      glass: row['glass'] as String?,
      method: row['method'] as String?,
      abv: (row['abv'] as num?)?.toDouble(),
      tags: (row['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      imageUrl: row['image_url'] as String?,
      isPublic: row['is_public'] as bool? ?? false,
      basedOnCocktailId: row['based_on_cocktail_id'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      ingredients: ingredients,
    );
  }

  /// 생성/수정용 데이터 (id, user_id, timestamps 제외)
  Map<String, dynamic> toInsertData() {
    return {
      'name': name,
      'name_ko': nameKo,
      'description': description,
      'description_ko': descriptionKo,
      'instructions': instructions,
      'instructions_ko': instructionsKo,
      'garnish': garnish,
      'garnish_ko': garnishKo,
      'glass': glass,
      'method': method,
      'abv': abv,
      'tags': tags,
      'image_url': imageUrl,
      'is_public': isPublic,
      'based_on_cocktail_id': basedOnCocktailId,
    };
  }

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
    if (locale == 'ko' &&
        instructionsKo != null &&
        instructionsKo!.isNotEmpty) {
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

  UserCocktail copyWith({
    String? id,
    String? userId,
    String? name,
    String? nameKo,
    String? description,
    String? descriptionKo,
    String? instructions,
    String? instructionsKo,
    String? garnish,
    String? garnishKo,
    String? glass,
    String? method,
    double? abv,
    List<String>? tags,
    String? imageUrl,
    bool? isPublic,
    String? basedOnCocktailId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<UserCocktailIngredient>? ingredients,
  }) {
    return UserCocktail(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      nameKo: nameKo ?? this.nameKo,
      description: description ?? this.description,
      descriptionKo: descriptionKo ?? this.descriptionKo,
      instructions: instructions ?? this.instructions,
      instructionsKo: instructionsKo ?? this.instructionsKo,
      garnish: garnish ?? this.garnish,
      garnishKo: garnishKo ?? this.garnishKo,
      glass: glass ?? this.glass,
      method: method ?? this.method,
      abv: abv ?? this.abv,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      isPublic: isPublic ?? this.isPublic,
      basedOnCocktailId: basedOnCocktailId ?? this.basedOnCocktailId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ingredients: ingredients ?? this.ingredients,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserCocktail && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 사용자 칵테일의 재료
@immutable
class UserCocktailIngredient {
  final int? id;
  final String userCocktailId;
  final String? ingredientId;
  final String? customIngredientName;
  final double? amount;
  final String? units;
  final int sortOrder;
  final bool isOptional;
  final String? note;

  const UserCocktailIngredient({
    this.id,
    required this.userCocktailId,
    this.ingredientId,
    this.customIngredientName,
    this.amount,
    this.units,
    this.sortOrder = 0,
    this.isOptional = false,
    this.note,
  });

  /// 재료 이름 (기존 재료 또는 커스텀)
  String get displayName => customIngredientName ?? ingredientId ?? '';

  /// 양과 단위를 합친 문자열
  String get amountWithUnits {
    if (amount == null) return '';
    final unitStr = units ?? '';
    return '${amount!.toStringAsFixed(amount! == amount!.truncate() ? 0 : 1)} $unitStr'
        .trim();
  }

  factory UserCocktailIngredient.fromSupabase(Map<String, dynamic> row) {
    return UserCocktailIngredient(
      id: row['id'] as int?,
      userCocktailId: row['user_cocktail_id'] as String,
      ingredientId: row['ingredient_id'] as String?,
      customIngredientName: row['custom_ingredient_name'] as String?,
      amount: (row['amount'] as num?)?.toDouble(),
      units: row['units'] as String?,
      sortOrder: row['sort_order'] as int? ?? 0,
      isOptional: row['is_optional'] as bool? ?? false,
      note: row['note'] as String?,
    );
  }

  Map<String, dynamic> toInsertData() {
    return {
      'user_cocktail_id': userCocktailId,
      'ingredient_id': ingredientId,
      'custom_ingredient_name': customIngredientName,
      'amount': amount,
      'units': units,
      'sort_order': sortOrder,
      'is_optional': isOptional,
      'note': note,
    };
  }

  UserCocktailIngredient copyWith({
    int? id,
    String? userCocktailId,
    String? ingredientId,
    String? customIngredientName,
    double? amount,
    String? units,
    int? sortOrder,
    bool? isOptional,
    String? note,
  }) {
    return UserCocktailIngredient(
      id: id ?? this.id,
      userCocktailId: userCocktailId ?? this.userCocktailId,
      ingredientId: ingredientId ?? this.ingredientId,
      customIngredientName: customIngredientName ?? this.customIngredientName,
      amount: amount ?? this.amount,
      units: units ?? this.units,
      sortOrder: sortOrder ?? this.sortOrder,
      isOptional: isOptional ?? this.isOptional,
      note: note ?? this.note,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserCocktailIngredient && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
