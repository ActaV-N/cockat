import 'package:flutter/foundation.dart';

import 'ingredient.dart';
import 'product.dart';

/// Ingredient별로 그룹화된 Product 목록
@immutable
class IngredientGroup {
  final String ingredientId;
  final String ingredientName;
  final String? ingredientNameKo;
  final Ingredient? ingredient;
  final List<Product> products;

  const IngredientGroup({
    required this.ingredientId,
    required this.ingredientName,
    this.ingredientNameKo,
    this.ingredient,
    required this.products,
  });

  /// 로케일 기반 표시용 이름
  String getLocalizedDisplayName(String locale) {
    if (locale == 'ko' &&
        ingredientNameKo != null &&
        ingredientNameKo!.isNotEmpty) {
      return ingredientNameKo!;
    }
    return ingredientName;
  }

  /// @deprecated Use getLocalizedDisplayName instead
  String get displayName => ingredientName;

  /// 상품 개수
  int get productCount => products.length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IngredientGroup && other.ingredientId == ingredientId;
  }

  @override
  int get hashCode => ingredientId.hashCode;
}
