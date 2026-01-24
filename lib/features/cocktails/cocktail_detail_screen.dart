import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/models.dart';
import '../../data/providers/providers.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/ingredient_availability_card.dart';

class CocktailDetailScreen extends ConsumerWidget {
  final String cocktailId;

  const CocktailDetailScreen({super.key, required this.cocktailId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 상세 재료 정보가 포함된 칵테일 로드 (lazy loading)
    final cocktailAsync = ref.watch(cocktailWithIngredientsProvider(cocktailId));
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
              // App Bar with expanded image
              SliverAppBar(
                expandedHeight: 350,
                pinned: true,
                stretch: true,
                actions: [
                  _FavoriteButton(cocktailId: cocktail.id),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    cocktail.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 1),
                          blurRadius: 4,
                          color: AppColors.gray900.withValues(alpha: 0.54),
                        ),
                      ],
                    ),
                  ),
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 16, right: 48),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      CocktailImage(
                        cocktail: cocktail,
                        mode: ImageDisplayMode.full,
                        fit: BoxFit.cover,
                      ),
                      // Gradient overlay for better text readability
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.transparent,
                              AppColors.gray900.withValues(alpha: 0.7),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ],
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
                        cocktailId: cocktail.id,
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
  final String cocktailId;
  final List<CocktailIngredient> ingredients;
  final AppLocalizations l10n;

  const _IngredientsList({
    required this.cocktailId,
    required this.ingredients,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availabilityAsync =
        ref.watch(cocktailIngredientAvailabilityProvider(cocktailId));
    final userUnit = ref.watch(effectiveUnitSystemProvider);

    return availabilityAsync.when(
      data: (availabilities) {
        return Card(
          child: Column(
            children: ingredients.map((ingredient) {
              final availability = availabilities.firstWhere(
                (a) => a.ingredientId == ingredient.id,
                orElse: () => IngredientAvailability(
                  ingredientId: ingredient.id,
                  ingredientName: ingredient.name,
                  isOwned: false,
                ),
              );

              return IngredientAvailabilityCard(
                ingredient: ingredient,
                availability: availability,
                userUnit: userUnit,
                l10n: l10n,
              );
            }).toList(),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: $error'),
        ),
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

class _FavoriteButton extends ConsumerWidget {
  final String cocktailId;

  const _FavoriteButton({required this.cocktailId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 통합 Provider 사용 (비회원: 로컬, 회원: DB)
    final isFavorite = ref.watch(effectiveIsFavoriteProvider(cocktailId));
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final l10n = AppLocalizations.of(context)!;

    return IconButton(
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        color: isFavorite ? AppColors.error : null,
      ),
      onPressed: () {
        final favoritesService = ref.read(effectiveFavoritesServiceProvider);
        final result = favoritesService.toggle(cocktailId);

        switch (result) {
          case FavoriteResult.added:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.addedToFavorites),
                duration: const Duration(seconds: 2),
              ),
            );
            break;
          case FavoriteResult.removed:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.removedFromFavorites),
                duration: const Duration(seconds: 2),
              ),
            );
            break;
          case FavoriteResult.limitReached:
            // 비회원만 제한이 있음
            if (!isAuthenticated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.favoritesLimitReached(kMaxFavoritesForGuest)),
                  duration: const Duration(seconds: 3),
                  action: SnackBarAction(
                    label: l10n.signUpForMore,
                    onPressed: () {
                      // TODO: Navigate to sign up screen
                    },
                  ),
                ),
              );
            }
            break;
          case FavoriteResult.alreadyExists:
            break;
        }
      },
    );
  }
}
