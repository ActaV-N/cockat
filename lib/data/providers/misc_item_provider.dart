import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import 'auth_provider.dart';
import 'ingredient_provider.dart';
import 'settings_provider.dart';

// ==================== Misc Items Data ====================

/// All misc items from Supabase
final miscItemsProvider = FutureProvider<List<MiscItem>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);

  final response = await supabase
      .from('misc_items')
      .select()
      .order('sort_order');

  return (response as List)
      .map((row) => MiscItem.fromSupabase(row as Map<String, dynamic>))
      .toList();
});

/// Misc items grouped by category
final miscItemsByCategoryProvider =
    Provider<AsyncValue<Map<String, List<MiscItem>>>>((ref) {
  final itemsAsync = ref.watch(miscItemsProvider);

  return itemsAsync.whenData((items) {
    final grouped = <String, List<MiscItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }
    return grouped;
  });
});

/// Get available categories
final miscItemCategoriesProvider = Provider<AsyncValue<List<String>>>((ref) {
  final itemsAsync = ref.watch(miscItemsProvider);

  return itemsAsync.whenData((items) {
    final categories = items.map((i) => i.category).toSet();
    return MiscItemCategories.allCategories
        .where((c) => categories.contains(c))
        .toList();
  });
});

// ==================== Local Selection (Non-authenticated) ====================

/// Selected misc items stored locally (for non-authenticated users)
final selectedMiscItemsLocalProvider =
    StateNotifierProvider<SelectedMiscItemsNotifier, Set<String>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SelectedMiscItemsNotifier(prefs);
});

class SelectedMiscItemsNotifier extends StateNotifier<Set<String>> {
  final SharedPreferences _prefs;
  static const _key = 'selected_misc_items';

  SelectedMiscItemsNotifier(this._prefs) : super(_loadSelected(_prefs));

  static Set<String> _loadSelected(SharedPreferences prefs) {
    final value = prefs.getStringList(_key);
    return value?.toSet() ?? {};
  }

  Future<void> toggle(String itemId) async {
    if (state.contains(itemId)) {
      state = Set.from(state)..remove(itemId);
    } else {
      state = Set.from(state)..add(itemId);
    }
    await _save();
  }

  Future<void> addAll(Set<String> itemIds) async {
    state = Set.from(state)..addAll(itemIds);
    await _save();
  }

  Future<void> clear() async {
    state = {};
    await _save();
  }

  Future<void> _save() async {
    await _prefs.setStringList(_key, state.toList());
  }
}

// ==================== DB Selection (Authenticated) ====================

/// Selected misc items from DB (for authenticated users)
final userMiscItemsDbProvider = StreamProvider<List<String>>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) return Stream.value([]);

  return supabase
      .from('user_misc_items')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .map((data) => data.map((row) => row['misc_item_id'] as String).toList());
});

// ==================== Unified (Auto-switch based on auth) ====================

/// Unified selected misc items (non-auth: local, auth: DB)
final effectiveSelectedMiscItemsProvider = Provider<Set<String>>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);

  if (isAuthenticated) {
    final dbItems = ref.watch(userMiscItemsDbProvider);
    return dbItems.valueOrNull?.toSet() ?? {};
  } else {
    return ref.watch(selectedMiscItemsLocalProvider);
  }
});

/// Check if a specific misc item is selected
final effectiveIsMiscItemSelectedProvider =
    Provider.family<bool, String>((ref, itemId) {
  return ref.watch(effectiveSelectedMiscItemsProvider).contains(itemId);
});

/// Count of selected misc items
final effectiveSelectedMiscItemCountProvider = Provider<int>((ref) {
  return ref.watch(effectiveSelectedMiscItemsProvider).length;
});

// ==================== Misc Items Service ====================

/// Unified misc items service (handles auth/non-auth automatically)
final effectiveMiscItemsServiceProvider =
    Provider<EffectiveMiscItemsService>((ref) {
  return EffectiveMiscItemsService(ref);
});

class EffectiveMiscItemsService {
  final Ref _ref;

  EffectiveMiscItemsService(this._ref);

  bool get isAuthenticated => _ref.read(isAuthenticatedProvider);

  Future<void> toggle(String itemId) async {
    if (isAuthenticated) {
      await _toggleDb(itemId);
    } else {
      await _ref.read(selectedMiscItemsLocalProvider.notifier).toggle(itemId);
    }
  }

  Future<void> _toggleDb(String itemId) async {
    final supabase = _ref.read(supabaseClientProvider);
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;

    final currentItems = _ref.read(effectiveSelectedMiscItemsProvider);

    if (currentItems.contains(itemId)) {
      await supabase
          .from('user_misc_items')
          .delete()
          .eq('user_id', userId)
          .eq('misc_item_id', itemId);
    } else {
      await supabase.from('user_misc_items').insert({
        'user_id': userId,
        'misc_item_id': itemId,
      });
    }
    _ref.invalidate(userMiscItemsDbProvider);
  }

  Future<void> clear() async {
    if (isAuthenticated) {
      final supabase = _ref.read(supabaseClientProvider);
      final userId = _ref.read(currentUserIdProvider);
      if (userId == null) return;

      await supabase.from('user_misc_items').delete().eq('user_id', userId);
      _ref.invalidate(userMiscItemsDbProvider);
    } else {
      await _ref.read(selectedMiscItemsLocalProvider.notifier).clear();
    }
  }
}
