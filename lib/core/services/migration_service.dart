import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/providers/settings_provider.dart';
import '../../data/providers/ingredient_provider.dart';

/// 마이그레이션 결과
class MigrationResult {
  int productsMigrated = 0;
  int ingredientsMigrated = 0;
  int favoritesMigrated = 0;

  bool get hasData =>
      productsMigrated + ingredientsMigrated + favoritesMigrated > 0;

  int get totalMigrated =>
      productsMigrated + ingredientsMigrated + favoritesMigrated;
}

/// 마이그레이션 서비스 Provider
final migrationServiceProvider = Provider<DataMigrationService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return DataMigrationService(supabase, prefs);
});

/// 마이그레이션 필요 여부 Provider
final needsMigrationProvider = Provider<bool>((ref) {
  final service = ref.watch(migrationServiceProvider);
  return service.needsMigration();
});

/// 로컬 데이터 요약 Provider
final localDataSummaryProvider = Provider<LocalDataSummary>((ref) {
  final service = ref.watch(migrationServiceProvider);
  return service.getLocalDataSummary();
});

/// 로컬 데이터 요약
class LocalDataSummary {
  final int productsCount;
  final int ingredientsCount;
  final int favoritesCount;

  LocalDataSummary({
    required this.productsCount,
    required this.ingredientsCount,
    required this.favoritesCount,
  });

  bool get hasData => productsCount + ingredientsCount + favoritesCount > 0;
  int get totalCount => productsCount + ingredientsCount + favoritesCount;
}

/// 비회원 → 회원 전환 시 로컬 데이터를 DB로 마이그레이션
class DataMigrationService {
  final SupabaseClient _supabase;
  final SharedPreferences _prefs;

  // SharedPreferences keys
  static const _productsKey = 'selected_products';
  static const _ingredientsKey = 'selected_ingredients';
  static const _favoritesKey = 'favorite_cocktails';

  DataMigrationService(this._supabase, this._prefs);

  /// 로컬 데이터 요약 반환
  LocalDataSummary getLocalDataSummary() {
    final products = _prefs.getStringList(_productsKey) ?? [];
    final ingredients = _prefs.getStringList(_ingredientsKey) ?? [];
    final favorites = _prefs.getStringList(_favoritesKey) ?? [];

    return LocalDataSummary(
      productsCount: products.length,
      ingredientsCount: ingredients.length,
      favoritesCount: favorites.length,
    );
  }

  /// 마이그레이션 필요 여부 확인
  bool needsMigration() {
    return getLocalDataSummary().hasData;
  }

  /// 로컬 데이터를 클라우드로 마이그레이션
  Future<MigrationResult> migrateToCloud(String userId) async {
    final result = MigrationResult();

    // 1. 선택된 상품 마이그레이션
    final localProducts = _prefs.getStringList(_productsKey) ?? [];
    if (localProducts.isNotEmpty) {
      try {
        await _supabase.from('user_products').upsert(
          localProducts
              .map((id) => {'user_id': userId, 'product_id': id})
              .toList(),
          onConflict: 'user_id,product_id',
        );
        result.productsMigrated = localProducts.length;
      } catch (e) {
        // 에러가 발생해도 다음 항목 계속 진행
        debugPrint('Failed to migrate products: $e');
      }
    }

    // 2. 직접 선택된 재료 마이그레이션
    final localIngredients = _prefs.getStringList(_ingredientsKey) ?? [];
    if (localIngredients.isNotEmpty) {
      try {
        await _supabase.from('user_ingredients').upsert(
          localIngredients
              .map((id) => {'user_id': userId, 'ingredient_id': id})
              .toList(),
          onConflict: 'user_id,ingredient_id',
        );
        result.ingredientsMigrated = localIngredients.length;
      } catch (e) {
        debugPrint('Failed to migrate ingredients: $e');
      }
    }

    // 3. 즐겨찾기 마이그레이션
    final localFavorites = _prefs.getStringList(_favoritesKey) ?? [];
    if (localFavorites.isNotEmpty) {
      try {
        await _supabase.from('user_favorites').upsert(
          localFavorites
              .map((id) => {'user_id': userId, 'cocktail_id': id})
              .toList(),
          onConflict: 'user_id,cocktail_id',
        );
        result.favoritesMigrated = localFavorites.length;
      } catch (e) {
        debugPrint('Failed to migrate favorites: $e');
      }
    }

    return result;
  }

  /// 마이그레이션 후 로컬 데이터 정리
  Future<void> clearLocalData() async {
    await _prefs.remove(_productsKey);
    await _prefs.remove(_ingredientsKey);
    await _prefs.remove(_favoritesKey);
  }

  /// 마이그레이션 완료 후 로컬 데이터 정리 및 결과 반환
  /// alwaysClear: true면 마이그레이션 성공 여부와 관계없이 로컬 데이터 삭제
  Future<MigrationResult> migrateAndClear(String userId, {bool alwaysClear = true}) async {
    final result = await migrateToCloud(userId);
    // 마이그레이션 시도 후 항상 로컬 데이터 삭제 (다음 로그인 시 팝업 방지)
    if (alwaysClear || result.hasData) {
      await clearLocalData();
    }
    return result;
  }
}
