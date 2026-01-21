import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'auth_provider.dart';
import 'cocktail_provider.dart';
import 'favorites_provider.dart';
import 'ingredient_provider.dart';
import 'product_provider.dart';

/// ============================================================
/// 통합 Provider - 비회원/회원 자동 분기
/// ============================================================
/// 비회원: SharedPreferences (로컬 저장)
/// 회원: Supabase DB (실시간 동기화)
/// ============================================================

// ==================== 즐겨찾기 ====================

/// 통합 즐겨찾기 ID 목록 (비회원: 로컬, 회원: DB)
final effectiveFavoritesProvider = Provider<Set<String>>((ref) {
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

/// 칵테일 매칭용 통합 재료 ID (상품 + 직접선택)
/// Stream providers를 watch하여 실시간 업데이트 보장
final effectiveAllIngredientIdsProvider = Provider<Set<String>>((ref) {
  // Watch stream providers to ensure real-time updates for authenticated users
  ref.watch(userIngredientsDbProvider);
  ref.watch(userProductsDbProvider);

  final fromProducts = ref.watch(effectiveIngredientIdsFromProductsProvider);
  final directSelection = ref.watch(effectiveSelectedIngredientsProvider);
  return {...fromProducts, ...directSelection};
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

  Future<FavoriteResult> toggle(String cocktailId) async {
    if (isAuthenticated) {
      return _toggleDb(cocktailId);
    } else {
      return _ref.read(favoriteCocktailsProvider.notifier).toggle(cocktailId);
    }
  }

  Future<FavoriteResult> _toggleDb(String cocktailId) async {
    final supabase = _ref.read(supabaseClientProvider);
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return FavoriteResult.removed;

    final currentFavorites = _ref.read(effectiveFavoritesProvider);

    if (currentFavorites.contains(cocktailId)) {
      // 제거
      await supabase
          .from('user_favorites')
          .delete()
          .eq('user_id', userId)
          .eq('cocktail_id', cocktailId);
      // Invalidate to trigger UI refresh
      _ref.invalidate(userFavoritesDbProvider);
      return FavoriteResult.removed;
    } else {
      // 추가
      await supabase.from('user_favorites').insert({
        'user_id': userId,
        'cocktail_id': cocktailId,
      });
      // Invalidate to trigger UI refresh
      _ref.invalidate(userFavoritesDbProvider);
      return FavoriteResult.added;
    }
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

  Future<void> toggle(String productId) async {
    if (isAuthenticated) {
      await _toggleDb(productId);
    } else {
      await _ref.read(selectedProductsProvider.notifier).toggle(productId);
    }
  }

  Future<void> _toggleDb(String productId) async {
    final supabase = _ref.read(supabaseClientProvider);
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;

    final currentProducts = _ref.read(effectiveSelectedProductsProvider);

    if (currentProducts.contains(productId)) {
      // 제거
      await supabase
          .from('user_products')
          .delete()
          .eq('user_id', userId)
          .eq('product_id', productId);
    } else {
      // 추가
      await supabase.from('user_products').insert({
        'user_id': userId,
        'product_id': productId,
      });
    }
    // Invalidate to trigger UI refresh
    _ref.invalidate(userProductsDbProvider);
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
      await _ref.read(selectedProductsProvider.notifier).clear();
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

  Future<void> toggle(String ingredientId) async {
    if (isAuthenticated) {
      await _toggleDb(ingredientId);
    } else {
      await _ref.read(selectedIngredientsProvider.notifier).toggle(ingredientId);
    }
  }

  Future<void> _toggleDb(String ingredientId) async {
    final supabase = _ref.read(supabaseClientProvider);
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;

    final currentIngredients = _ref.read(effectiveSelectedIngredientsProvider);

    if (currentIngredients.contains(ingredientId)) {
      // 제거
      await supabase
          .from('user_ingredients')
          .delete()
          .eq('user_id', userId)
          .eq('ingredient_id', ingredientId);
    } else {
      // 추가
      await supabase.from('user_ingredients').insert({
        'user_id': userId,
        'ingredient_id': ingredientId,
      });
    }
    // Invalidate to trigger UI refresh
    _ref.invalidate(userIngredientsDbProvider);
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
