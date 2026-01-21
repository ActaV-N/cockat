import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/constants.dart';
import '../models/models.dart';
import 'ingredient_provider.dart';
import 'settings_provider.dart';

// All products from Supabase
final productsProvider = FutureProvider<List<Product>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);

  final response = await supabase
      .from('products')
      .select()
      .order('brand')
      .order('name');

  return (response as List)
      .map((row) => Product.fromSupabase(row as Map<String, dynamic>))
      .toList();
});

// Search query for products
final productSearchQueryProvider = StateProvider<String>((ref) => '');

// Filtered products based on search
final filteredProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final productsAsync = ref.watch(productsProvider);
  final query = ref.watch(productSearchQueryProvider).toLowerCase();

  return productsAsync.whenData((products) {
    if (query.isEmpty) return products;
    return products
        .where((p) =>
            p.name.toLowerCase().contains(query) ||
            (p.brand?.toLowerCase().contains(query) ?? false) ||
            p.displayName.toLowerCase().contains(query))
        .toList();
  });
});

// Products grouped by ingredient type
final productsByIngredientProvider =
    Provider<AsyncValue<Map<String, List<Product>>>>((ref) {
  final productsAsync = ref.watch(productsProvider);

  return productsAsync.whenData((products) {
    final grouped = <String, List<Product>>{};
    for (final product in products) {
      if (product.ingredientId != null) {
        grouped.putIfAbsent(product.ingredientId!, () => []).add(product);
      }
    }
    return grouped;
  });
});

// User's selected products (persisted locally)
final selectedProductsProvider =
    StateNotifierProvider<SelectedProductsNotifier, Set<String>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SelectedProductsNotifier(prefs);
});

class SelectedProductsNotifier extends StateNotifier<Set<String>> {
  final SharedPreferences _prefs;
  static const _key = 'selected_products';

  SelectedProductsNotifier(this._prefs) : super(_loadSelected(_prefs));

  static Set<String> _loadSelected(SharedPreferences prefs) {
    final value = prefs.getStringList(_key);
    return value?.toSet() ?? {};
  }

  // Optimistic UI: Update state immediately, save in background
  void toggle(String productId) {
    final previousState = state; // Backup for rollback

    // 1. Immediately update state (UI reflects instantly)
    if (state.contains(productId)) {
      state = Set.from(state)..remove(productId);
    } else {
      state = Set.from(state)..add(productId);
    }

    // 2. Save in background (fire-and-forget)
    _save().catchError((error) {
      // 3. Rollback on failure
      state = previousState;
      // TODO: Notify user of error
      debugPrint('Failed to save product selection: $error');
    });
  }

  void add(String productId) {
    if (!state.contains(productId)) {
      final previousState = state;
      state = Set.from(state)..add(productId);
      _save().catchError((error) {
        state = previousState;
        debugPrint('Failed to save product: $error');
      });
    }
  }

  void remove(String productId) {
    if (state.contains(productId)) {
      final previousState = state;
      state = Set.from(state)..remove(productId);
      _save().catchError((error) {
        state = previousState;
        debugPrint('Failed to remove product: $error');
      });
    }
  }

  void clear() {
    final previousState = state;
    state = {};
    _save().catchError((error) {
      state = previousState;
      debugPrint('Failed to clear products: $error');
    });
  }

  Future<void> _save() async {
    await _prefs.setStringList(_key, state.toList());
  }
}

// Check if a product is selected
final isProductSelectedProvider = Provider.family<bool, String>((ref, id) {
  return ref.watch(selectedProductsProvider).contains(id);
});

// Count of selected products
final selectedProductCountProvider = Provider<int>((ref) {
  return ref.watch(selectedProductsProvider).length;
});

// Product by ID
final productByIdProvider =
    Provider.family<AsyncValue<Product?>, String>((ref, id) {
  return ref.watch(productsProvider).whenData(
        (products) => products.where((p) => p.id == id).firstOrNull,
      );
});

// Selected products as list
final selectedProductsListProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final productsAsync = ref.watch(productsProvider);
  final selectedIds = ref.watch(selectedProductsProvider);

  return productsAsync.whenData((products) {
    return products.where((p) => selectedIds.contains(p.id)).toList();
  });
});

// Category filter for products catalog
final productCategoryFilterProvider = StateProvider<String?>((ref) => null);

// Filtered products based on search and category
final catalogFilteredProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final productsAsync = ref.watch(productsProvider);
  final query = ref.watch(productSearchQueryProvider).toLowerCase();
  final categoryFilter = ref.watch(productCategoryFilterProvider);
  final ingredientsAsync = ref.watch(ingredientsProvider);

  return productsAsync.whenData((products) {
    var filtered = products;

    // Filter by search query
    if (query.isNotEmpty) {
      filtered = filtered
          .where((p) =>
              p.name.toLowerCase().contains(query) ||
              (p.brand?.toLowerCase().contains(query) ?? false) ||
              p.displayName.toLowerCase().contains(query))
          .toList();
    }

    // Filter by category
    if (categoryFilter != null) {
      final ingredients = ingredientsAsync.valueOrNull ?? [];
      final ingredientMap = {for (var i in ingredients) i.id: i};

      filtered = filtered.where((p) {
        if (p.ingredientId == null) return false;
        final ingredient = ingredientMap[p.ingredientId];
        if (ingredient == null) return false;
        return IngredientCategories.getCategoryKey(ingredient.category) == categoryFilter;
      }).toList();
    }

    return filtered;
  });
});

// Get unique categories from products
final productCategoriesProvider = Provider<AsyncValue<List<String>>>((ref) {
  final productsAsync = ref.watch(productsProvider);
  final ingredientsAsync = ref.watch(ingredientsProvider);

  return productsAsync.whenData((products) {
    final ingredients = ingredientsAsync.valueOrNull ?? [];
    final ingredientMap = {for (var i in ingredients) i.id: i};
    final categories = <String>{};

    for (final product in products) {
      if (product.ingredientId != null) {
        final ingredient = ingredientMap[product.ingredientId];
        if (ingredient != null) {
          categories.add(IngredientCategories.getCategoryKey(ingredient.category));
        }
      }
    }

    return IngredientCategories.allCategories
        .where((c) => categories.contains(c))
        .toList();
  });
});

/// Ingredient IDs derived from selected products
/// This is the bridge between product selection and cocktail matching
final ingredientIdsFromProductsProvider = Provider<Set<String>>((ref) {
  final productsAsync = ref.watch(productsProvider);
  final selectedProductIds = ref.watch(selectedProductsProvider);

  final products = productsAsync.valueOrNull ?? [];
  final ingredientIds = <String>{};

  for (final product in products) {
    if (selectedProductIds.contains(product.id) && product.ingredientId != null) {
      ingredientIds.add(product.ingredientId!);
    }
  }

  return ingredientIds;
});
