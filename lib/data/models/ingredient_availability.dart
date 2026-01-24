import 'package:flutter/foundation.dart';

import 'product.dart';

/// 재료 소유 상태 및 사용 가능한 제품/대체재 정보
@immutable
class IngredientAvailability {
  /// 재료 ID
  final String ingredientId;

  /// 재료명
  final String ingredientName;

  /// 소유 여부 (직접 소유 또는 제품 보유)
  final bool isOwned;

  /// 이 재료를 제공하는 소유 제품들
  final List<Product> ownedProducts;

  /// 사용 가능한 대체재 정보
  final List<SubstituteInfo> availableSubstitutes;

  const IngredientAvailability({
    required this.ingredientId,
    required this.ingredientName,
    required this.isOwned,
    this.ownedProducts = const [],
    this.availableSubstitutes = const [],
  });

  /// 직접 소유 또는 대체재로 사용 가능
  bool get canUse => isOwned || availableSubstitutes.isNotEmpty;

  /// 표시할 주요 제품/대체재 (최대 3개)
  List<String> get displayItems {
    final items = <String>[];

    // 직접 소유 제품
    items.addAll(ownedProducts.take(2).map((p) => p.displayName));

    // 대체재
    if (items.length < 3 && availableSubstitutes.isNotEmpty) {
      items.add(availableSubstitutes.first.displayName);
    }

    return items;
  }

  /// 추가 항목 개수 (더보기 표시용)
  int get moreCount {
    final total = ownedProducts.length + availableSubstitutes.length;
    return total > 3 ? total - 3 : 0;
  }
}

/// 대체재 정보
@immutable
class SubstituteInfo {
  /// 대체재 재료 ID
  final String substituteId;

  /// 대체재 재료명
  final String substituteName;

  /// 이 대체재를 제공하는 소유 제품들
  final List<Product> ownedProducts;

  const SubstituteInfo({
    required this.substituteId,
    required this.substituteName,
    this.ownedProducts = const [],
  });

  String get displayName {
    if (ownedProducts.isEmpty) return substituteName;
    return ownedProducts.first.displayName;
  }
}
