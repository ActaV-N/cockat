import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'auth_provider.dart';
import 'ingredient_provider.dart';
import 'misc_item_provider.dart';
import 'product_provider.dart';
import 'unified_providers.dart';

// ============ 헬퍼 함수 ============

/// 페이지네이션으로 모든 cocktail_ingredients 가져오기 (limit 1000 우회)
Future<List<Map<String, dynamic>>> _fetchAllCocktailIngredientIds(
  dynamic supabase,
) async {
  final List<Map<String, dynamic>> allData = [];
  int offset = 0;
  const int limit = 1000;

  while (true) {
    final response = await supabase
        .from('cocktail_ingredients')
        .select('cocktail_id, ingredient_id, is_optional')
        .order('id')
        .range(offset, offset + limit - 1);

    final list = response as List;
    for (final item in list) {
      allData.add(item as Map<String, dynamic>);
    }

    if (list.length < limit) break;
    offset += limit;
  }

  return allData;
}

// ============ 기본 Providers ============

// All cocktails from Supabase (기본 정보만, 재료는 lazy load)
final cocktailsProvider = FutureProvider<List<Cocktail>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);

  // Fetch cocktails (기본 정보만)
  final cocktailsResponse = await supabase
      .from('cocktails')
      .select()
      .order('name');

  // 페이지네이션으로 모든 ingredient_id 가져오기 (매칭용)
  final ingredientIds = await _fetchAllCocktailIngredientIds(supabase);

  // Group ingredient IDs by cocktail (매칭 계산용, 상세 정보 없이 ID만)
  final ingredientIdsByCocktail = <String, List<CocktailIngredient>>{};
  for (final row in ingredientIds) {
    final cocktailId = row['cocktail_id'] as String;
    ingredientIdsByCocktail.putIfAbsent(cocktailId, () => []).add(
          CocktailIngredient(
            id: row['ingredient_id'] as String,
            name: row['ingredient_id'] as String, // 임시 이름 (상세 페이지에서 로드)
            sort: 0,
            amount: 0,
            units: '',
            optional: row['is_optional'] as bool? ?? false,
          ),
        );
  }

  return (cocktailsResponse as List)
      .map((row) => Cocktail.fromSupabase(
            row as Map<String, dynamic>,
            ingredients: ingredientIdsByCocktail[row['id']] ?? [],
          ))
      .toList();
});

// ============ Lazy Loading Providers ============

/// 특정 칵테일의 상세 재료 정보 (상세 페이지용)
final cocktailIngredientsProvider =
    FutureProvider.family<List<CocktailIngredient>, String>((ref, cocktailId) async {
  final supabase = ref.watch(supabaseClientProvider);

  final response = await supabase
      .from('cocktail_ingredients')
      .select('*, ingredients(name, name_ko)')
      .eq('cocktail_id', cocktailId)
      .order('sort_order');

  return (response as List).map((row) {
    final ingredient = row['ingredients'] as Map<String, dynamic>?;
    return CocktailIngredient(
      id: row['ingredient_id'] as String,
      name: ingredient?['name'] as String? ?? row['ingredient_id'] as String,
      sort: row['sort_order'] as int? ?? 0,
      amount: (row['amount'] as num?)?.toDouble() ?? 0,
      units: row['units'] as String? ?? '',
      optional: row['is_optional'] as bool? ?? false,
      note: row['note'] as String?,
    );
  }).toList();
});

/// 재료 정보가 포함된 완전한 칵테일 (상세 페이지용)
final cocktailWithIngredientsProvider =
    FutureProvider.family<Cocktail?, String>((ref, cocktailId) async {
  final cocktailsAsync = ref.watch(cocktailsProvider);
  final cocktails = cocktailsAsync.valueOrNull;
  if (cocktails == null) return null;

  final cocktail = cocktails.firstWhereOrNull((c) => c.id == cocktailId);
  if (cocktail == null) return null;

  // 상세 재료 정보 로드
  final ingredients = await ref.watch(cocktailIngredientsProvider(cocktailId).future);

  return Cocktail(
    id: cocktail.id,
    name: cocktail.name,
    nameKo: cocktail.nameKo,
    instructions: cocktail.instructions,
    description: cocktail.description,
    garnish: cocktail.garnish,
    abv: cocktail.abv,
    tags: cocktail.tags,
    glass: cocktail.glass,
    method: cocktail.method,
    imageUrl: cocktail.imageUrl,
    ingredients: ingredients,
  );
});

// Search query for cocktails
final cocktailSearchQueryProvider = StateProvider<String>((ref) => '');

// Cocktail by ID
final cocktailByIdProvider = Provider.family<AsyncValue<Cocktail?>, String>((ref, id) {
  return ref.watch(cocktailsProvider).whenData(
        (cocktails) => cocktails.firstWhereOrNull((c) => c.id == id),
      );
});

// Featured cocktail IDs (MD's Pick) - hardcoded selection
const featuredCocktailIds = [
  'negroni',
  'mojito',
  'margarita',
  'old-fashioned',
  'espresso-martini',
  'cosmopolitan',
  'aperol-spritz',
  'moscow-mule',
];

// Featured cocktails provider
final featuredCocktailsProvider = Provider<AsyncValue<List<Cocktail>>>((ref) {
  return ref.watch(cocktailsProvider).whenData(
        (cocktails) => featuredCocktailIds
            .map((id) => cocktails.firstWhereOrNull((c) => c.id == id))
            .whereType<Cocktail>()
            .toList(),
      );
});

/// Combined ingredient IDs from both products and direct ingredient selection
/// This allows both methods to work together
/// 자동으로 비회원/회원 데이터 소스를 분기
/// misc_items는 ingredient_misc_mapping을 통해 ingredient_id로 변환
final allSelectedIngredientIdsProvider = Provider<Set<String>>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);

  if (isAuthenticated) {
    // 회원: 통합 Provider 사용
    return ref.watch(effectiveAllIngredientIdsProvider);
  } else {
    // 비회원: 로컬 Provider 사용 (상품 + 직접선택 + 기타재료)
    final fromProducts = ref.watch(ingredientIdsFromProductsProvider);
    final directSelection = ref.watch(selectedIngredientsProvider);
    final selectedMiscItemIds = ref.watch(selectedMiscItemsLocalProvider);

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
  }
});

/// Total count of selected items (products + direct ingredients)
/// 자동으로 비회원/회원 데이터 소스를 분기
final totalSelectedCountProvider = Provider<int>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);

  if (isAuthenticated) {
    // 회원: 통합 Provider 사용
    return ref.watch(effectiveTotalSelectedCountProvider);
  } else {
    // 비회원: 로컬 Provider 사용
    final productCount = ref.watch(selectedProductCountProvider);
    final ingredientCount = ref.watch(selectedIngredientCountProvider);
    return productCount + ingredientCount;
  }
});

// Matched cocktails based on user's selection (products + ingredients)
final cocktailMatchesProvider = Provider<AsyncValue<List<CocktailMatch>>>((ref) {
  final cocktailsAsync = ref.watch(cocktailsProvider);
  // Use combined ingredients from products AND direct selection
  final selectedIngredients = ref.watch(allSelectedIngredientIdsProvider);
  final ingredientsAsync = ref.watch(ingredientsProvider);

  if (selectedIngredients.isEmpty) {
    return cocktailsAsync.whenData((cocktails) {
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
        .where((m) =>
            m.cocktail.name.toLowerCase().contains(query) ||
            (m.cocktail.nameKo?.toLowerCase().contains(query) ?? false))
        .toList();
  });
});
