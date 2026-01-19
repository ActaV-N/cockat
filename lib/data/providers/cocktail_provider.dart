import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'ingredient_provider.dart';

// All cocktails from data source
final cocktailsProvider = FutureProvider<List<Cocktail>>((ref) async {
  final jsonString = await rootBundle.loadString('assets/data/cocktails.json');
  final jsonList = json.decode(jsonString) as List<dynamic>;
  return jsonList
      .map((e) => Cocktail.fromJson(e as Map<String, dynamic>))
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));
});

// Search query for cocktails
final cocktailSearchQueryProvider = StateProvider<String>((ref) => '');

// Cocktail by ID
final cocktailByIdProvider = Provider.family<AsyncValue<Cocktail?>, String>((ref, id) {
  return ref.watch(cocktailsProvider).whenData(
        (cocktails) => cocktails.firstWhereOrNull((c) => c.id == id),
      );
});

// Matched cocktails based on user's ingredients
final cocktailMatchesProvider = Provider<AsyncValue<List<CocktailMatch>>>((ref) {
  final cocktailsAsync = ref.watch(cocktailsProvider);
  final selectedIngredients = ref.watch(selectedIngredientsProvider);
  final ingredientsAsync = ref.watch(ingredientsProvider);

  if (selectedIngredients.isEmpty) {
    return cocktailsAsync.whenData((cocktails) {
      // Return all cocktails with full missing count when nothing selected
      return cocktails.map((c) {
        return CocktailMatch(
          cocktail: c,
          matchedIngredients: {},
          missingIngredients: c.requiredIngredientIds,
        );
      }).toList();
    });
  }

  return cocktailsAsync.whenData((cocktails) {
    final ingredientsList = ingredientsAsync.valueOrNull ?? [];

    // Build a map of ingredient substitutes for quick lookup
    final substituteMap = <String, Set<String>>{};
    for (final ingredient in ingredientsList) {
      if (ingredient.substitutes != null && ingredient.substitutes!.isNotEmpty) {
        substituteMap[ingredient.id] = ingredient.substitutes!.toSet();
      }
    }

    final matches = <CocktailMatch>[];

    for (final cocktail in cocktails) {
      final requiredIds = cocktail.requiredIngredientIds;
      final matched = <String>{};
      final missing = <String>{};
      final usedSubstitutes = <String>{};

      for (final ingredientId in requiredIds) {
        if (selectedIngredients.contains(ingredientId)) {
          matched.add(ingredientId);
        } else {
          // Check if user has a substitute
          bool foundSubstitute = false;

          // Check cocktail-level substitutes
          final cocktailIngredient = cocktail.ingredients
              .firstWhereOrNull((i) => i.id == ingredientId);
          if (cocktailIngredient != null) {
            for (final sub in cocktailIngredient.substitutes) {
              if (selectedIngredients.contains(sub)) {
                matched.add(ingredientId);
                usedSubstitutes.add(sub);
                foundSubstitute = true;
                break;
              }
            }
          }

          // Check ingredient-level substitutes
          if (!foundSubstitute && substituteMap.containsKey(ingredientId)) {
            for (final sub in substituteMap[ingredientId]!) {
              if (selectedIngredients.contains(sub)) {
                matched.add(ingredientId);
                usedSubstitutes.add(sub);
                foundSubstitute = true;
                break;
              }
            }
          }

          if (!foundSubstitute) {
            missing.add(ingredientId);
          }
        }
      }

      matches.add(CocktailMatch(
        cocktail: cocktail,
        matchedIngredients: matched,
        missingIngredients: missing,
        availableSubstitutes: usedSubstitutes,
      ));
    }

    // Sort: can make first, then by missing count
    matches.sort((a, b) => a.compareTo(b));

    return matches;
  });
});

// Cocktails that can be made
final canMakeCocktailsProvider = Provider<AsyncValue<List<CocktailMatch>>>((ref) {
  return ref.watch(cocktailMatchesProvider).whenData(
        (matches) => matches.where((m) => m.canMake).toList(),
      );
});

// Cocktails that need 1 more ingredient
final almostCanMakeCocktailsProvider = Provider<AsyncValue<List<CocktailMatch>>>((ref) {
  return ref.watch(cocktailMatchesProvider).whenData(
        (matches) => matches.where((m) => m.missingCount == 1).toList(),
      );
});

// Filtered cocktails based on search and matches
final filteredCocktailMatchesProvider = Provider<AsyncValue<List<CocktailMatch>>>((ref) {
  final matchesAsync = ref.watch(cocktailMatchesProvider);
  final query = ref.watch(cocktailSearchQueryProvider).toLowerCase();

  return matchesAsync.whenData((matches) {
    if (query.isEmpty) return matches;
    return matches
        .where((m) => m.cocktail.name.toLowerCase().contains(query))
        .toList();
  });
});
