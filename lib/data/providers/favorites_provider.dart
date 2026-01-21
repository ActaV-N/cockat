import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import 'cocktail_provider.dart';
import 'settings_provider.dart';

/// 비회원 즐겨찾기 최대 개수
const int kMaxFavoritesForGuest = 20;

/// 즐겨찾기 칵테일 ID 목록 (로컬 저장)
final favoriteCocktailsProvider =
    StateNotifierProvider<FavoriteCocktailsNotifier, Set<String>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return FavoriteCocktailsNotifier(prefs);
});

class FavoriteCocktailsNotifier extends StateNotifier<Set<String>> {
  final SharedPreferences _prefs;
  static const _key = 'favorite_cocktails';

  FavoriteCocktailsNotifier(this._prefs) : super(_loadFavorites(_prefs));

  static Set<String> _loadFavorites(SharedPreferences prefs) {
    final value = prefs.getStringList(_key);
    return value?.toSet() ?? {};
  }

  /// 즐겨찾기 토글 (추가/제거)
  /// 최대 개수 초과 시 false 반환
  Future<FavoriteResult> toggle(String cocktailId) async {
    if (state.contains(cocktailId)) {
      // 제거
      state = Set.from(state)..remove(cocktailId);
      await _save();
      return FavoriteResult.removed;
    } else {
      // 추가 - 최대 개수 확인
      if (state.length >= kMaxFavoritesForGuest) {
        return FavoriteResult.limitReached;
      }
      state = Set.from(state)..add(cocktailId);
      await _save();
      return FavoriteResult.added;
    }
  }

  /// 즐겨찾기에 추가
  Future<FavoriteResult> add(String cocktailId) async {
    if (state.contains(cocktailId)) {
      return FavoriteResult.alreadyExists;
    }
    if (state.length >= kMaxFavoritesForGuest) {
      return FavoriteResult.limitReached;
    }
    state = Set.from(state)..add(cocktailId);
    await _save();
    return FavoriteResult.added;
  }

  /// 즐겨찾기에서 제거
  Future<void> remove(String cocktailId) async {
    if (state.contains(cocktailId)) {
      state = Set.from(state)..remove(cocktailId);
      await _save();
    }
  }

  /// 전체 삭제
  Future<void> clear() async {
    state = {};
    await _save();
  }

  Future<void> _save() async {
    await _prefs.setStringList(_key, state.toList());
  }
}

/// 즐겨찾기 추가/제거 결과
enum FavoriteResult {
  added,
  removed,
  limitReached,
  alreadyExists,
}

/// 특정 칵테일이 즐겨찾기인지 확인
final isFavoriteProvider = Provider.family<bool, String>((ref, cocktailId) {
  return ref.watch(favoriteCocktailsProvider).contains(cocktailId);
});

/// 즐겨찾기 개수
final favoriteCountProvider = Provider<int>((ref) {
  return ref.watch(favoriteCocktailsProvider).length;
});

/// 즐겨찾기 남은 개수
final remainingFavoritesProvider = Provider<int>((ref) {
  return kMaxFavoritesForGuest - ref.watch(favoriteCountProvider);
});

/// 즐겨찾기 칵테일 목록 (CocktailMatch 형태)
final favoriteCocktailMatchesProvider =
    Provider<AsyncValue<List<CocktailMatch>>>((ref) {
  final favoriteIds = ref.watch(favoriteCocktailsProvider);
  final matchesAsync = ref.watch(cocktailMatchesProvider);

  return matchesAsync.whenData((matches) {
    return matches.where((m) => favoriteIds.contains(m.cocktail.id)).toList();
  });
});
