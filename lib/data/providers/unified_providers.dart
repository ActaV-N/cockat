import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'auth_provider.dart';
import 'cocktail_provider.dart';
import 'favorites_provider.dart';
import 'ingredient_provider.dart';
import 'misc_item_provider.dart';
import 'product_provider.dart';

/// ============================================================
/// 통합 Provider - 비회원/회원 자동 분기
/// ============================================================
/// 비회원: SharedPreferences (로컬 저장)
/// 회원: Supabase DB (실시간 동기화)
/// ============================================================

// ==================== Optimistic UI State Holders ====================

/// Optimistic state for products (used during DB sync)
final _optimisticProductsProvider = StateProvider<Set<String>?>((ref) => null);

/// Optimistic state for favorites (used during DB sync)
final _optimisticFavoritesProvider =
    StateProvider<Set<String>?>((ref) => null);

/// Optimistic state for ingredients (used during DB sync)
final _optimisticIngredientsProvider =
    StateProvider<Set<String>?>((ref) => null);

// ==================== 즐겨찾기 ====================

/// 통합 즐겨찾기 ID 목록 (비회원: 로컬, 회원: DB)
final effectiveFavoritesProvider = Provider<Set<String>>((ref) {
  // Optimistic state takes priority during DB sync
  final optimistic = ref.watch(_optimisticFavoritesProvider);
  if (optimistic != null) return optimistic;

  final isAuthenticated = ref.watch(isAuthenticatedProvider);

  if (isAuthenticated) {
    // 회원: DB에서 가져옴
    final dbFavorites = ref.watch(userFavoritesDbProvider);
    return dbFavorites.valueOrNull?.toSet() ?? {};
  } else {
    // 비회원: 로컬에서 가져옴
    return ref.watch(favoriteCocktailsProvider);
  }
});

/// 통합 즐겨찾기 여부 확인
final effectiveIsFavoriteProvider =
    Provider.family<bool, String>((ref, cocktailId) {
  return ref.watch(effectiveFavoritesProvider).contains(cocktailId);
});

/// 통합 즐겨찾기 개수
final effectiveFavoriteCountProvider = Provider<int>((ref) {
  return ref.watch(effectiveFavoritesProvider).length;
});

/// 통합 즐겨찾기 칵테일 목록 (CocktailMatch 형태)
final effectiveFavoriteCocktailMatchesProvider =
    Provider<AsyncValue<List<CocktailMatch>>>((ref) {
  final favoriteIds = ref.watch(effectiveFavoritesProvider);
  final matchesAsync = ref.watch(cocktailMatchesProvider);

  return matchesAsync.whenData((matches) {
    return matches.where((m) => favoriteIds.contains(m.cocktail.id)).toList();
  });
});

// ==================== 상품 선택 ====================

/// 통합 선택 상품 ID 목록 (비회원: 로컬, 회원: DB)
final effectiveSelectedProductsProvider = Provider<Set<String>>((ref) {
  // Optimistic state takes priority during DB sync
  final optimistic = ref.watch(_optimisticProductsProvider);
  if (optimistic != null) return optimistic;

  final isAuthenticated = ref.watch(isAuthenticatedProvider);

  if (isAuthenticated) {
    // 회원: DB에서 가져옴
    final dbProducts = ref.watch(userProductsDbProvider);
    return dbProducts.valueOrNull?.toSet() ?? {};
  } else {
    // 비회원: 로컬에서 가져옴
    return ref.watch(selectedProductsProvider);
  }
});

/// 통합 선택 상품 여부 확인
final effectiveIsProductSelectedProvider =
    Provider.family<bool, String>((ref, productId) {
  return ref.watch(effectiveSelectedProductsProvider).contains(productId);
});

/// 통합 선택 상품 개수
final effectiveSelectedProductCountProvider = Provider<int>((ref) {
  return ref.watch(effectiveSelectedProductsProvider).length;
});

/// 통합 선택 상품 목록 (Product 객체)
final effectiveSelectedProductsListProvider =
    Provider<AsyncValue<List<Product>>>((ref) {
  final productsAsync = ref.watch(productsProvider);
  final selectedIds = ref.watch(effectiveSelectedProductsProvider);

  return productsAsync.whenData((products) {
    return products.where((p) => selectedIds.contains(p.id)).toList();
  });
});

// ==================== 재료 선택 ====================

/// 통합 직접 선택 재료 ID 목록 (비회원: 로컬, 회원: DB)
final effectiveSelectedIngredientsProvider = Provider<Set<String>>((ref) {
  // Optimistic state takes priority during DB sync
  final optimistic = ref.watch(_optimisticIngredientsProvider);
  if (optimistic != null) return optimistic;

  final isAuthenticated = ref.watch(isAuthenticatedProvider);

  if (isAuthenticated) {
    // 회원: DB에서 가져옴
    final dbIngredients = ref.watch(userIngredientsDbProvider);
    return dbIngredients.valueOrNull?.toSet() ?? {};
  } else {
    // 비회원: 로컬에서 가져옴
    return ref.watch(selectedIngredientsProvider);
  }
});

/// 통합 선택 재료 여부 확인
final effectiveIsIngredientSelectedProvider =
    Provider.family<bool, String>((ref, ingredientId) {
  return ref.watch(effectiveSelectedIngredientsProvider).contains(ingredientId);
});

/// 통합 선택 재료 개수
final effectiveSelectedIngredientCountProvider = Provider<int>((ref) {
  return ref.watch(effectiveSelectedIngredientsProvider).length;
});

// ==================== 칵테일 매칭용 통합 재료 ====================

/// 상품에서 추출한 재료 ID (통합)
final effectiveIngredientIdsFromProductsProvider = Provider<Set<String>>((ref) {
  final productsAsync = ref.watch(productsProvider);
  final selectedProductIds = ref.watch(effectiveSelectedProductsProvider);

  final products = productsAsync.valueOrNull ?? [];
  final ingredientIds = <String>{};

  for (final product in products) {
    if (selectedProductIds.contains(product.id) &&
        product.ingredientId != null) {
      ingredientIds.add(product.ingredientId!);
    }
  }

  return ingredientIds;
});

/// 칵테일 매칭용 통합 재료 ID (상품 + 직접선택 + 기타재료)
/// Stream providers를 watch하여 실시간 업데이트 보장
/// misc_items는 ingredient_misc_mapping을 통해 ingredient_id로 변환
final effectiveAllIngredientIdsProvider = Provider<Set<String>>((ref) {
  // Watch stream providers to ensure real-time updates for authenticated users
  ref.watch(userIngredientsDbProvider);
  ref.watch(userProductsDbProvider);
  ref.watch(userMiscItemsDbProvider);

  final fromProducts = ref.watch(effectiveIngredientIdsFromProductsProvider);
  final directSelection = ref.watch(effectiveSelectedIngredientsProvider);
  final selectedMiscItemIds = ref.watch(effectiveSelectedMiscItemsProvider);

  // misc_items 매핑 테이블을 통해 ingredient_id로 변환
  final mappingAsync = ref.watch(ingredientMiscMappingProvider);
  final mapping = mappingAsync.valueOrNull ?? {};

  // 선택된 misc_item_id를 ingredient_id로 변환
  final ingredientIdsFromMisc = <String>{};
  for (final entry in mapping.entries) {
    // entry.key = ingredient_id, entry.value = misc_item_id
    if (selectedMiscItemIds.contains(entry.value)) {
      ingredientIdsFromMisc.add(entry.key);
    }
  }

  return {...fromProducts, ...directSelection, ...ingredientIdsFromMisc};
});

/// 통합 선택 개수 (상품 + 직접선택 재료)
final effectiveTotalSelectedCountProvider = Provider<int>((ref) {
  return ref.watch(effectiveSelectedProductCountProvider) +
      ref.watch(effectiveSelectedIngredientCountProvider);
});

// ==================== 즐겨찾기 액션 ====================

/// 통합 즐겨찾기 서비스
final effectiveFavoritesServiceProvider =
    Provider<EffectiveFavoritesService>((ref) {
  return EffectiveFavoritesService(ref);
});

class EffectiveFavoritesService {
  final Ref _ref;

  EffectiveFavoritesService(this._ref);

  bool get isAuthenticated => _ref.read(isAuthenticatedProvider);

  // Optimistic UI: immediately return result, sync to DB in background
  FavoriteResult toggle(String cocktailId) {
    if (isAuthenticated) {
      return _toggleDbOptimistic(cocktailId);
    } else {
      return _ref.read(favoriteCocktailsProvider.notifier).toggle(cocktailId);
    }
  }

  FavoriteResult _toggleDbOptimistic(String cocktailId) {
    final supabase = _ref.read(supabaseClientProvider);
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return FavoriteResult.removed;

    final currentFavorites = _ref.read(effectiveFavoritesProvider);
    final isRemoving = currentFavorites.contains(cocktailId);
    final result = isRemoving ? FavoriteResult.removed : FavoriteResult.added;

    // 1. Immediately update optimistic state (UI reflects instantly)
    _ref.read(_optimisticFavoritesProvider.notifier).state = isRemoving
        ? (currentFavorites.toSet()..remove(cocktailId))
        : (currentFavorites.toSet()..add(cocktailId));

    // 2. Sync to DB in background
    final dbOperation = isRemoving
        ? supabase
            .from('user_favorites')
            .delete()
            .eq('user_id', userId)
            .eq('cocktail_id', cocktailId)
        : supabase.from('user_favorites').insert({
            'user_id': userId,
            'cocktail_id': cocktailId,
          });

    dbOperation.then((_) {
      // 3. Success: just invalidate DB provider
      // Keep optimistic state - it already shows correct value
      // Next operation will update it based on current state
      _ref.invalidate(userFavoritesDbProvider);
    }).catchError((error) {
      // 4. Failure: rollback by clearing optimistic state
      _ref.read(_optimisticFavoritesProvider.notifier).state = null;
      _ref.invalidate(userFavoritesDbProvider);
      debugPrint('Failed to sync favorites: $error');
    });

    return result; // Return immediately
  }
}

// ==================== 상품 선택 액션 ====================

/// 통합 상품 선택 서비스
final effectiveProductsServiceProvider =
    Provider<EffectiveProductsService>((ref) {
  return EffectiveProductsService(ref);
});

class EffectiveProductsService {
  final Ref _ref;

  EffectiveProductsService(this._ref);

  bool get isAuthenticated => _ref.read(isAuthenticatedProvider);

  // Optimistic UI: immediately update state, sync to DB in background
  void toggle(String productId) {
    if (isAuthenticated) {
      _toggleDbOptimistic(productId);
    } else {
      _ref.read(selectedProductsProvider.notifier).toggle(productId);
    }
  }

  void _toggleDbOptimistic(String productId) {
    final supabase = _ref.read(supabaseClientProvider);
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;

    final currentProducts = _ref.read(effectiveSelectedProductsProvider);
    final isRemoving = currentProducts.contains(productId);

    // 1. Immediately update optimistic state (UI reflects instantly)
    _ref.read(_optimisticProductsProvider.notifier).state = isRemoving
        ? (currentProducts.toSet()..remove(productId))
        : (currentProducts.toSet()..add(productId));

    // 2. Sync to DB in background
    final dbOperation = isRemoving
        ? supabase
            .from('user_products')
            .delete()
            .eq('user_id', userId)
            .eq('product_id', productId)
        : supabase.from('user_products').insert({
            'user_id': userId,
            'product_id': productId,
          });

    dbOperation.then((_) {
      // 3. Success: just invalidate DB provider
      // Keep optimistic state - it already shows correct value
      // Next operation will update it based on current state
      _ref.invalidate(userProductsDbProvider);
    }).catchError((error) {
      // 4. Failure: rollback by clearing optimistic state
      _ref.read(_optimisticProductsProvider.notifier).state = null;
      _ref.invalidate(userProductsDbProvider);
      debugPrint('Failed to sync products: $error');
    });
  }

  Future<void> clear() async {
    if (isAuthenticated) {
      final supabase = _ref.read(supabaseClientProvider);
      final userId = _ref.read(currentUserIdProvider);
      if (userId == null) return;

      await supabase.from('user_products').delete().eq('user_id', userId);
      // Invalidate to trigger UI refresh
      _ref.invalidate(userProductsDbProvider);
    } else {
      _ref.read(selectedProductsProvider.notifier).clear();
    }
  }
}

// ==================== 재료 선택 액션 ====================

/// 통합 재료 선택 서비스
final effectiveIngredientsServiceProvider =
    Provider<EffectiveIngredientsService>((ref) {
  return EffectiveIngredientsService(ref);
});

class EffectiveIngredientsService {
  final Ref _ref;

  EffectiveIngredientsService(this._ref);

  bool get isAuthenticated => _ref.read(isAuthenticatedProvider);

  // Optimistic UI: immediately update state, sync to DB in background
  void toggle(String ingredientId) {
    if (isAuthenticated) {
      _toggleDbOptimistic(ingredientId);
    } else {
      _ref.read(selectedIngredientsProvider.notifier).toggle(ingredientId);
    }
  }

  void _toggleDbOptimistic(String ingredientId) {
    final supabase = _ref.read(supabaseClientProvider);
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;

    final currentIngredients = _ref.read(effectiveSelectedIngredientsProvider);
    final isRemoving = currentIngredients.contains(ingredientId);

    // 1. Immediately update optimistic state (UI reflects instantly)
    _ref.read(_optimisticIngredientsProvider.notifier).state = isRemoving
        ? (currentIngredients.toSet()..remove(ingredientId))
        : (currentIngredients.toSet()..add(ingredientId));

    // 2. Sync to DB in background
    final dbOperation = isRemoving
        ? supabase
            .from('user_ingredients')
            .delete()
            .eq('user_id', userId)
            .eq('ingredient_id', ingredientId)
        : supabase.from('user_ingredients').insert({
            'user_id': userId,
            'ingredient_id': ingredientId,
          });

    dbOperation.then((_) {
      // 3. Success: just invalidate DB provider
      // Keep optimistic state - it already shows correct value
      // Next operation will update it based on current state
      _ref.invalidate(userIngredientsDbProvider);
    }).catchError((error) {
      // 4. Failure: rollback by clearing optimistic state
      _ref.read(_optimisticIngredientsProvider.notifier).state = null;
      _ref.invalidate(userIngredientsDbProvider);
      debugPrint('Failed to sync ingredients: $error');
    });
  }

  Future<void> clear() async {
    if (isAuthenticated) {
      final supabase = _ref.read(supabaseClientProvider);
      final userId = _ref.read(currentUserIdProvider);
      if (userId == null) return;

      await supabase.from('user_ingredients').delete().eq('user_id', userId);
      // Invalidate to trigger UI refresh
      _ref.invalidate(userIngredientsDbProvider);
    } else {
      await _ref.read(selectedIngredientsProvider.notifier).clear();
    }
  }
}

// ==================== 내 술장 그룹핑 ====================

/// Ingredient별로 그룹화된 소유 상품 (내 술장용)
final ingredientGroupsForMyBarProvider =
    Provider<AsyncValue<List<IngredientGroup>>>((ref) {
  final productsAsync = ref.watch(effectiveSelectedProductsListProvider);
  final ingredientsAsync = ref.watch(ingredientsProvider);

  return productsAsync.whenData((products) {
    final ingredientsList = ingredientsAsync.valueOrNull ?? [];
    final ingredientsMap = {for (var i in ingredientsList) i.id: i};

    // Ingredient별로 그룹화
    final grouped = <String, List<Product>>{};
    for (final product in products) {
      final key = product.ingredientId ?? '_other';
      grouped.putIfAbsent(key, () => []).add(product);
    }

    // 각 그룹을 상품명으로 정렬
    for (final entry in grouped.entries) {
      entry.value.sort((a, b) => a.name.compareTo(b.name));
    }

    // IngredientGroup 목록 생성
    final groups = <IngredientGroup>[];
    for (final entry in grouped.entries) {
      final ingredientId = entry.key;
      final groupProducts = entry.value;

      if (ingredientId == '_other') {
        groups.add(IngredientGroup(
          ingredientId: ingredientId,
          ingredientName: 'Other',
          ingredientNameKo: '기타',
          products: groupProducts,
        ));
      } else {
        final ingredient = ingredientsMap[ingredientId];
        if (ingredient != null) {
          groups.add(IngredientGroup(
            ingredientId: ingredientId,
            ingredientName: ingredient.name,
            ingredientNameKo: ingredient.nameKo,
            ingredient: ingredient,
            products: groupProducts,
          ));
        } else {
          // Ingredient를 찾을 수 없는 경우
          groups.add(IngredientGroup(
            ingredientId: ingredientId,
            ingredientName: ingredientId,
            products: groupProducts,
          ));
        }
      }
    }

    // Ingredient 이름으로 정렬 (기타는 맨 뒤)
    groups.sort((a, b) {
      if (a.ingredientId == '_other') return 1;
      if (b.ingredientId == '_other') return -1;
      return a.ingredientName.compareTo(b.ingredientName);
    });

    return groups;
  });
});
