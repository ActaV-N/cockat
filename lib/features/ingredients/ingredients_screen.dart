import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../data/providers/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../core/constants/constants.dart';

class IngredientsScreen extends ConsumerWidget {
  const IngredientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final ingredientsAsync = ref.watch(filteredIngredientsProvider);
    final selectedCount = ref.watch(effectiveSelectedIngredientCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myIngredients),
        actions: [
          if (selectedCount > 0)
            TextButton.icon(
              onPressed: () {
                ref.read(effectiveIngredientsServiceProvider).clear();
              },
              icon: const Icon(Icons.clear_all),
              label: Text(l10n.clearAll),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.searchIngredients,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: ref.watch(ingredientSearchQueryProvider).isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          ref.read(ingredientSearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                ref.read(ingredientSearchQueryProvider.notifier).state = value;
              },
            ),
          ),

          // Selected count
          if (selectedCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Chip(
                    avatar: const Icon(Icons.check_circle, size: 18),
                    label: Text(l10n.selectedCount(selectedCount)),
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  ),
                ],
              ),
            ),

          // Ingredient List
          Expanded(
            child: ingredientsAsync.when(
              data: (ingredients) => _IngredientList(ingredients: ingredients),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientList extends ConsumerWidget {
  final List<Ingredient> ingredients;

  const _IngredientList({required this.ingredients});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    // Group ingredients by category
    final grouped = <String, List<Ingredient>>{};
    for (final ingredient in ingredients) {
      final category = IngredientCategories.getCategoryKey(ingredient.category);
      grouped.putIfAbsent(category, () => []).add(ingredient);
    }

    final categoryNames = {
      'spirits': l10n.spirits,
      'liqueurs': l10n.liqueurs,
      'wines': l10n.wines,
      'bitters': l10n.bitters,
      'juices': l10n.juices,
      'syrups': l10n.syrups,
      'other': l10n.other,
    };

    final sortedCategories = IngredientCategories.allCategories
        .where((cat) => grouped.containsKey(cat))
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final category = sortedCategories[index];
        final categoryIngredients = grouped[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                categoryNames[category] ?? category,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            ...categoryIngredients.map((ingredient) => _IngredientTile(
                  ingredient: ingredient,
                )),
          ],
        );
      },
    );
  }
}

class _IngredientTile extends ConsumerWidget {
  final Ingredient ingredient;

  const _IngredientTile({required this.ingredient});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(effectiveIsIngredientSelectedProvider(ingredient.id));

    return ListTile(
      title: Text(ingredient.name),
      subtitle: ingredient.category != null
          ? Text(
              ingredient.category!,
              style: Theme.of(context).textTheme.bodySmall,
            )
          : null,
      trailing: Checkbox(
        value: isSelected,
        onChanged: (_) {
          ref.read(effectiveIngredientsServiceProvider).toggle(ingredient.id);
        },
      ),
      onTap: () {
        ref.read(effectiveIngredientsServiceProvider).toggle(ingredient.id);
      },
    );
  }
}
