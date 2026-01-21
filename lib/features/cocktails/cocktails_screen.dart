import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/widgets.dart';
import '../../data/models/models.dart';
import '../../data/providers/providers.dart';
import '../../l10n/app_localizations.dart';
import 'cocktail_detail_screen.dart';

class CocktailsScreen extends ConsumerWidget {
  const CocktailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final matchesAsync = ref.watch(filteredCocktailMatchesProvider);
    final selectedCount = ref.watch(totalSelectedCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cocktails),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.searchCocktails,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: ref.watch(cocktailSearchQueryProvider).isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          ref.read(cocktailSearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                ref.read(cocktailSearchQueryProvider.notifier).state = value;
              },
            ),
          ),

          // Results
          Expanded(
            child: matchesAsync.when(
              data: (matches) {
                final favoritesAsync = ref.watch(effectiveFavoriteCocktailMatchesProvider);
                final favorites = favoritesAsync.valueOrNull ?? [];
                final searchQuery = ref.watch(cocktailSearchQueryProvider);
                final showFavorites = searchQuery.isEmpty && favorites.isNotEmpty;

                // Empty search state
                if (matches.isEmpty && searchQuery.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noResultsFound,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.tryDifferentSearch,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                    ),
                  );
                }

                // When no products selected, show all cocktails
                if (selectedCount == 0) {
                  return CustomScrollView(
                    slivers: [
                      // Favorites Section (when not searching)
                      if (showFavorites) ...[
                        _SectionHeader(
                          title: l10n.favorites,
                          count: favorites.length,
                          color: Colors.red,
                        ),
                        _CocktailGrid(matches: favorites, showStatus: false),
                      ],

                      _SectionHeader(
                        title: l10n.allCocktails,
                        count: matches.length,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      _CocktailGrid(matches: matches, showStatus: false),
                      const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
                    ],
                  );
                }

                final canMake = matches.where((m) => m.canMake).toList();
                final almostCanMake = matches.where((m) => m.missingCount == 1).toList();
                final needMore = matches.where((m) => m.missingCount > 1).toList();

                return CustomScrollView(
                  slivers: [
                    // Favorites Section (when not searching)
                    if (showFavorites) ...[
                      _SectionHeader(
                        title: l10n.favorites,
                        count: favorites.length,
                        color: Colors.red,
                      ),
                      _CocktailGrid(matches: favorites),
                    ],

                    // Can Make Section
                    if (canMake.isNotEmpty) ...[
                      _SectionHeader(
                        title: l10n.canMake,
                        count: canMake.length,
                        color: Colors.green,
                      ),
                      _CocktailGrid(matches: canMake),
                    ],

                    // Almost Can Make Section
                    if (almostCanMake.isNotEmpty) ...[
                      _SectionHeader(
                        title: l10n.almostCanMake,
                        count: almostCanMake.length,
                        color: Colors.orange,
                      ),
                      _CocktailGrid(matches: almostCanMake),
                    ],

                    // Need More Section (limited to first 20)
                    if (needMore.isNotEmpty) ...[
                      _SectionHeader(
                        title: l10n.nMoreIngredients(2),
                        count: needMore.length,
                        color: Colors.grey,
                      ),
                      _CocktailGrid(matches: needMore.take(20).toList()),
                    ],

                    const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Spacer(),
            Text(
              '$count',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CocktailGrid extends StatelessWidget {
  final List<CocktailMatch> matches;
  final bool showStatus;

  const _CocktailGrid({required this.matches, this.showStatus = true});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _CocktailCard(
            match: matches[index],
            showStatus: showStatus,
          ),
          childCount: matches.length,
        ),
      ),
    );
  }
}

class _CocktailCard extends StatelessWidget {
  final CocktailMatch match;
  final bool showStatus;

  const _CocktailCard({required this.match, this.showStatus = true});

  @override
  Widget build(BuildContext context) {
    final cocktail = match.cocktail;
    final l10n = AppLocalizations.of(context)!;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CocktailDetailScreen(cocktailId: cocktail.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cocktail image
              CocktailImage(
                cocktail: cocktail,
                mode: ImageDisplayMode.thumbnail,
                width: 48,
                height: 48,
                borderRadius: BorderRadius.circular(12),
              ),
              const Spacer(),
              Text(
                cocktail.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (showStatus) ...[
                const SizedBox(height: 4),
                if (match.canMake)
                  _StatusChip(
                    label: l10n.canMake,
                    color: Colors.green,
                  )
                else if (match.missingCount == 1)
                  _StatusChip(
                    label: l10n.oneMoreIngredient,
                    color: Colors.orange,
                  )
                else
                  _StatusChip(
                    label: l10n.nMoreIngredients(match.missingCount),
                    color: Colors.grey,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
            ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
