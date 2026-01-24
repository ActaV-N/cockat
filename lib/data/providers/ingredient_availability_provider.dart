import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'auth_provider.dart';
import 'cocktail_provider.dart';
import 'ingredient_provider.dart';
import 'product_provider.dart';
import 'unified_providers.dart';

/// 칵테일의 각 재료별 소유 정보 제공
/// [cocktailId]를 받아 해당 칵테일의 모든 재료에 대한 가용성 정보를 반환
final cocktailIngredientAvailabilityProvider =
    Provider.family<AsyncValue<List<IngredientAvailability>>, String>(
  (ref, cocktailId) {
    // 해당 칵테일의 상세 재료 정보 로드 (lazy loading)
    final cocktailIngredientsAsync =
        ref.watch(cocktailIngredientsProvider(cocktailId));
    final ingredientsAsync = ref.watch(ingredientsProvider);
    final productsAsync = ref.watch(productsProvider);

    // 비회원/회원 분기
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final selectedProductIds = isAuthenticated
        ? ref.watch(effectiveSelectedProductsProvider)
        : ref.watch(selectedProductsProvider);
    final selectedIngredientIds = isAuthenticated
        ? ref.watch(effectiveSelectedIngredientsProvider)
        : ref.watch(selectedIngredientsProvider);

    return cocktailIngredientsAsync.whenData((cocktailIngredients) {
      if (cocktailIngredients.isEmpty) return <IngredientAvailability>[];

      final ingredients = ingredientsAsync.valueOrNull ?? [];
      final products = productsAsync.valueOrNull ?? [];

      // 재료 ID → Ingredient 맵
      final ingredientMap = {for (var i in ingredients) i.id: i};

      // 선택된 제품들
      final ownedProducts = products
          .where((p) => selectedProductIds.contains(p.id))
          .toList();

      // 제품 그룹핑: ingredient_id → List<Product>
      final productsByIngredient = <String, List<Product>>{};
      for (final product in ownedProducts) {
        if (product.ingredientId != null) {
          productsByIngredient
              .putIfAbsent(product.ingredientId!, () => [])
              .add(product);
        }
      }

      // 소유한 재료 ID 집합 (제품 기반 + 직접 선택)
      final allOwnedIngredientIds = <String>{
        ...selectedIngredientIds,
        ...productsByIngredient.keys,
      };

      return cocktailIngredients.map((cocktailIngredient) {
        final ingredientId = cocktailIngredient.id;
        final ingredient = ingredientMap[ingredientId];

        // 1. 직접 소유 여부 확인
        final directlyOwned = selectedIngredientIds.contains(ingredientId);
        final ownedProductsForIngredient =
            productsByIngredient[ingredientId] ?? [];
        final isOwned = directlyOwned || ownedProductsForIngredient.isNotEmpty;

        // 2. 대체재 확인 (소유하지 않은 경우에만)
        final availableSubstitutes = <SubstituteInfo>[];

        if (!isOwned) {
          // 칵테일 레벨 대체재
          for (final subId in cocktailIngredient.substitutes) {
            if (allOwnedIngredientIds.contains(subId)) {
              final subIngredient = ingredientMap[subId];
              availableSubstitutes.add(SubstituteInfo(
                substituteId: subId,
                substituteName: subIngredient?.name ?? subId,
                ownedProducts: productsByIngredient[subId] ?? [],
              ));
            }
          }

          // 재료 레벨 대체재
          if (ingredient?.substitutes != null) {
            for (final subId in ingredient!.substitutes!) {
              // 이미 추가된 대체재는 스킵
              if (!availableSubstitutes.any((s) => s.substituteId == subId)) {
                if (allOwnedIngredientIds.contains(subId)) {
                  final subIngredient = ingredientMap[subId];
                  availableSubstitutes.add(SubstituteInfo(
                    substituteId: subId,
                    substituteName: subIngredient?.name ?? subId,
                    ownedProducts: productsByIngredient[subId] ?? [],
                  ));
                }
              }
            }
          }
        }

        return IngredientAvailability(
          ingredientId: ingredientId,
          ingredientName: cocktailIngredient.name,
          isOwned: isOwned,
          ownedProducts: ownedProductsForIngredient,
          availableSubstitutes: availableSubstitutes,
        );
      }).toList();
    });
  },
);
