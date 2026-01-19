import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../data/providers/providers.dart';
import '../../l10n/app_localizations.dart';

class CocktailDetailScreen extends ConsumerWidget {
  final String cocktailId;

  const CocktailDetailScreen({super.key, required this.cocktailId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cocktailAsync = ref.watch(cocktailByIdProvider(cocktailId));
    final l10n = AppLocalizations.of(context)!;

    return cocktailAsync.when(
      data: (cocktail) {
        if (cocktail == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Cocktail not found')),
          );
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    cocktail.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).colorScheme.primaryContainer,
                          Theme.of(context).colorScheme.surface,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.local_bar,
                        size: 80,
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tags
                      if (cocktail.tags.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: cocktail.tags
                              .map((tag) => Chip(
                                    label: Text(tag),
                                    visualDensity: VisualDensity.compact,
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Description
                      if (cocktail.description != null &&
                          cocktail.description!.isNotEmpty) ...[
                        Text(
                          cocktail.description!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Info Row
                      _InfoRow(cocktail: cocktail, l10n: l10n),
                      const SizedBox(height: 24),

                      // Ingredients
                      _SectionTitle(title: l10n.ingredients),
                      const SizedBox(height: 8),
                      _IngredientsList(
                        ingredients: cocktail.ingredients,
                        l10n: l10n,
                      ),
                      const SizedBox(height: 24),

                      // Instructions
                      _SectionTitle(title: l10n.instructions),
                      const SizedBox(height: 8),
                      _InstructionsCard(instructions: cocktail.instructions),

                      // Garnish
                      if (cocktail.garnish != null &&
                          cocktail.garnish!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _SectionTitle(title: l10n.garnish),
                        const SizedBox(height: 8),
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.eco),
                            title: Text(cocktail.garnish!),
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final Cocktail cocktail;
  final AppLocalizations l10n;

  const _InfoRow({required this.cocktail, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (cocktail.glass != null)
          _InfoChip(
            icon: Icons.wine_bar,
            label: cocktail.glass!,
          ),
        if (cocktail.method != null) ...[
          const SizedBox(width: 8),
          _InfoChip(
            icon: Icons.blender,
            label: cocktail.method!,
          ),
        ],
        if (cocktail.abv != null) ...[
          const SizedBox(width: 8),
          _InfoChip(
            icon: Icons.percent,
            label: '${cocktail.abv!.toStringAsFixed(0)}%',
          ),
        ],
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

class _IngredientsList extends ConsumerWidget {
  final List<CocktailIngredient> ingredients;
  final AppLocalizations l10n;

  const _IngredientsList({required this.ingredients, required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIngredients = ref.watch(selectedIngredientsProvider);

    return Card(
      child: Column(
        children: ingredients.map((ingredient) {
          final hasIngredient = selectedIngredients.contains(ingredient.id);

          return ListTile(
            leading: Icon(
              hasIngredient ? Icons.check_circle : Icons.circle_outlined,
              color: hasIngredient
                  ? Colors.green
                  : Theme.of(context).colorScheme.outline,
            ),
            title: Text(ingredient.name),
            subtitle: Text(ingredient.formattedAmount),
            trailing: ingredient.optional
                ? Chip(
                    label: Text(l10n.optional),
                    visualDensity: VisualDensity.compact,
                  )
                : null,
          );
        }).toList(),
      ),
    );
  }
}

class _InstructionsCard extends StatelessWidget {
  final String instructions;

  const _InstructionsCard({required this.instructions});

  @override
  Widget build(BuildContext context) {
    final steps = instructions.split('\n').where((s) => s.trim().isNotEmpty).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value.trim();
            // Remove leading numbers like "1. " or "1) "
            final cleanStep = step.replaceFirst(RegExp(r'^\d+[\.\)]\s*'), '');

            return Padding(
              padding: EdgeInsets.only(bottom: index < steps.length - 1 ? 12 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(cleanStep),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
