import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import 'settings_provider.dart';

// All ingredients from data source
final ingredientsProvider = FutureProvider<List<Ingredient>>((ref) async {
  // Load from bundled JSON asset
  final jsonString = await rootBundle.loadString('assets/data/ingredients.json');
  final jsonList = json.decode(jsonString) as List<dynamic>;
  return jsonList
      .map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));
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
        .where((i) => i.name.toLowerCase().contains(query))
        .toList();
  });
});

// User's selected ingredients (persisted)
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
