import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/models.dart';
import '../../data/providers/providers.dart';
import '../../l10n/app_localizations.dart';
import 'cocktail_detail_screen.dart';
import 'cocktail_search_screen.dart';
import 'cocktail_section_list_screen.dart';
import 'widgets/featured_carousel.dart';

class CocktailsScreen extends ConsumerWidget {
  const CocktailsScreen({super.key});

  void _navigateToSection(
    BuildContext context,
    String title,
    List<CocktailMatch> matches,
    Color color, {
    bool showStatus = true,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CocktailSectionListScreen(
          title: title,
          matches: matches,
          sectionColor: color,
          showStatus: showStatus,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final matchesAsync = ref.watch(filteredCocktailMatchesProvider);
    final selectedCount = ref.watch(totalSelectedCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cocktails),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: l10n.searchCocktails,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CocktailSearchScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: matchesAsync.when(
        data: (matches) {
          final favoritesAsync = ref.watch(effectiveFavoriteCocktailMatchesProvider);
          final favorites = favoritesAsync.valueOrNull ?? [];
          final showFavorites = favorites.isNotEmpty;

          // When no products selected, show all cocktails
          if (selectedCount == 0) {
            return CustomScrollView(
              slivers: [
                // Featured Carousel
                const SliverToBoxAdapter(
                  child: FeaturedCocktailCarousel(),
                ),

                // Favorites Section
                if (showFavorites) ...[
                  _SectionHeader(
                    title: l10n.favorites,
                    count: favorites.length,
                    color: AppColors.error,
                    onViewAll: () => _navigateToSection(
                      context,
                      l10n.favorites,
                      favorites,
                      AppColors.error,
                      showStatus: false,
                    ),
                  ),
                  _CocktailGrid(
                    matches: favorites.take(10).toList(),
                    showStatus: false,
                  ),
                ],

                _SectionHeader(
                  title: l10n.allCocktails,
                  count: matches.length,
                  color: Theme.of(context).colorScheme.primary,
                  onViewAll: () => _navigateToSection(
                    context,
                    l10n.allCocktails,
                    matches,
                    Theme.of(context).colorScheme.primary,
                    showStatus: false,
                  ),
                ),
                _CocktailGrid(
                  matches: matches.take(10).toList(),
                  showStatus: false,
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
              ],
            );
          }

          final canMake = matches.where((m) => m.canMake).toList();
          final almostCanMake = matches.where((m) => m.missingCount == 1).toList();
          final needMore = matches.where((m) => m.missingCount > 1).toList();

          return CustomScrollView(
            slivers: [
              // Featured Carousel
              const SliverToBoxAdapter(
                child: FeaturedCocktailCarousel(),
              ),

              // Favorites Section
              if (showFavorites) ...[
                _SectionHeader(
                  title: l10n.favorites,
                  count: favorites.length,
                  color: AppColors.error,
                  onViewAll: () => _navigateToSection(
                    context,
                    l10n.favorites,
                    favorites,
                    AppColors.error,
                  ),
                ),
                _CocktailGrid(matches: favorites.take(10).toList()),
              ],

              // Can Make Section
              if (canMake.isNotEmpty) ...[
                _SectionHeader(
                  title: l10n.canMake,
                  count: canMake.length,
                  color: AppColors.success,
                  onViewAll: () => _navigateToSection(
                    context,
                    l10n.canMake,
                    canMake,
                    AppColors.success,
                  ),
                ),
                _CocktailGrid(matches: canMake.take(10).toList()),
              ],

              // Almost Can Make Section
              if (almostCanMake.isNotEmpty) ...[
                _SectionHeader(
                  title: l10n.almostCanMake,
                  count: almostCanMake.length,
                  color: AppColors.warning,
                  onViewAll: () => _navigateToSection(
                    context,
                    l10n.almostCanMake,
                    almostCanMake,
                    AppColors.warning,
                  ),
                ),
                _CocktailGrid(matches: almostCanMake.take(10).toList()),
              ],

              // Need More Section
              if (needMore.isNotEmpty) ...[
                _SectionHeader(
                  title: l10n.nMoreIngredients(2),
                  count: needMore.length,
                  color: AppColors.gray600,
                  onViewAll: () => _navigateToSection(
                    context,
                    l10n.nMoreIngredients(2),
                    needMore,
                    AppColors.gray600,
                  ),
                ),
                _CocktailGrid(matches: needMore.take(10).toList()),
              ],

              const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final VoidCallback? onViewAll;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
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
            const SizedBox(width: 8),
            Text(
              '$count',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const Spacer(),
            if (count > 10 && onViewAll != null)
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.viewAll),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios, size: 12),
                  ],
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
          childAspectRatio: 0.75,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cocktail image with status overlay
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CocktailImage(
                    cocktail: cocktail,
                    mode: ImageDisplayMode.thumbnail,
                    fit: BoxFit.cover,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  // Status badge overlay
                  if (showStatus)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _buildStatusBadge(context, l10n),
                    ),
                ],
              ),
            ),
            // Info section
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cocktail name
                  Text(
                    cocktail.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // ABV info
                  if (cocktail.abv != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.local_bar,
                          size: 12,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${cocktail.abv!.toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, AppLocalizations l10n) {
    final Color color;
    final String label;

    if (match.canMake) {
      color = AppColors.success;
      label = l10n.canMake;
    } else if (match.missingCount == 1) {
      color = AppColors.warning;
      label = l10n.oneMoreIngredient;
    } else {
      color = AppColors.gray600;
      label = l10n.nMoreIngredients(match.missingCount);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}
