import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import 'settings_provider.dart';

// Supabase client provider
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// All ingredients from Supabase
final ingredientsProvider = FutureProvider<List<Ingredient>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);

  // Fetch ingredients
  final ingredientsResponse = await supabase
      .from('ingredients')
      .select()
      .order('name');

  // Fetch substitutes
  final substitutesResponse = await supabase
      .from('ingredient_substitutes')
      .select('ingredient_id, substitute_id');

  // Build substitutes map
  final substitutesMap = <String, List<String>>{};
  for (final row in substitutesResponse) {
    final ingredientId = row['ingredient_id'] as String;
    final substituteId = row['substitute_id'] as String;
    substitutesMap.putIfAbsent(ingredientId, () => []).add(substituteId);
  }

  return (ingredientsResponse as List)
      .map((row) => Ingredient.fromSupabase(
            row as Map<String, dynamic>,
            substitutes: substitutesMap[row['id']],
          ))
      .toList();
});

// Search query for ingredients
final ingredientSearchQueryProvider = StateProvider<String>((ref) => '');

// Filtered ingredients based on search
final filteredIngredientsProvider = Provider<AsyncValue<List<Ingredient>>>((ref) {
  final ingredientsAsync = ref.watch(ingredientsProvider);
  final query = ref.watch(ingredientSearchQueryProvider).toLowerCase();

  return ingredientsAsync.whenData((ingredients) {
    if (query.isEmpty) return ingredients;
    return ingredients
        .where((i) =>
            i.name.toLowerCase().contains(query) ||
            (i.nameKo?.toLowerCase().contains(query) ?? false))
        .toList();
  });
});

// User's selected ingredients (persisted locally)
final selectedIngredientsProvider =
    StateNotifierProvider<SelectedIngredientsNotifier, Set<String>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SelectedIngredientsNotifier(prefs);
});

class SelectedIngredientsNotifier extends StateNotifier<Set<String>> {
  final SharedPreferences _prefs;
  static const _key = 'selected_ingredients';

  SelectedIngredientsNotifier(this._prefs) : super(_loadSelected(_prefs));

  static Set<String> _loadSelected(SharedPreferences prefs) {
    final value = prefs.getStringList(_key);
    return value?.toSet() ?? {};
  }

  Future<void> toggle(String ingredientId) async {
    if (state.contains(ingredientId)) {
      state = Set.from(state)..remove(ingredientId);
    } else {
      state = Set.from(state)..add(ingredientId);
    }
    await _save();
  }

  Future<void> add(String ingredientId) async {
    if (!state.contains(ingredientId)) {
      state = Set.from(state)..add(ingredientId);
      await _save();
    }
  }

  Future<void> remove(String ingredientId) async {
    if (state.contains(ingredientId)) {
      state = Set.from(state)..remove(ingredientId);
      await _save();
    }
  }

  Future<void> clear() async {
    state = {};
    await _save();
  }

  Future<void> _save() async {
    await _prefs.setStringList(_key, state.toList());
  }
}

// Check if an ingredient is selected
final isIngredientSelectedProvider = Provider.family<bool, String>((ref, id) {
  return ref.watch(selectedIngredientsProvider).contains(id);
});

// Count of selected ingredients
final selectedIngredientCountProvider = Provider<int>((ref) {
  return ref.watch(selectedIngredientsProvider).length;
});

// Ingredient by ID
final ingredientByIdProvider = Provider.family<AsyncValue<Ingredient?>, String>((ref, id) {
  return ref.watch(ingredientsProvider).whenData(
        (ingredients) => ingredients.where((i) => i.id == id).firstOrNull,
      );
});
