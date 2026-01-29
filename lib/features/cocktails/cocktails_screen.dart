import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/models.dart';
import '../../data/providers/providers.dart';
import '../../l10n/app_localizations.dart';
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
    final matchesAsync = ref.watch(cocktailMatchesProvider);
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
          final favoritesAsync =
              ref.watch(effectiveFavoriteCocktailMatchesProvider);
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
                  SliverSectionHeader(
                    title: l10n.favorites,
                    count: favorites.length,
                    accentColor: AppColors.error,
                    onViewAll: () => _navigateToSection(
                      context,
                      l10n.favorites,
                      favorites,
                      AppColors.error,
                      showStatus: false,
                    ),
                  ),
                  CocktailCardGrid(
                    matches: favorites.take(10).toList(),
                    showStatus: false,
                  ),
                ],

                SliverSectionHeader(
                  title: l10n.allCocktails,
                  count: matches.length,
                  accentColor: Theme.of(context).colorScheme.primary,
                  onViewAll: () => _navigateToSection(
                    context,
                    l10n.allCocktails,
                    matches,
                    Theme.of(context).colorScheme.primary,
                    showStatus: false,
                  ),
                ),
                CocktailCardGrid(
                  matches: matches.take(10).toList(),
                  showStatus: false,
                ),
                // Bottom padding for floating nav bar
                const SliverPadding(
                    padding: EdgeInsets.only(bottom: 100)),
              ],
            );
          }

          final canMake = matches.where((m) => m.canMake).toList();
          final almostCanMake =
              matches.where((m) => m.missingCount == 1).toList();
          final needMore = matches.where((m) => m.missingCount > 1).toList();

          return CustomScrollView(
            slivers: [
              // Featured Carousel
              const SliverToBoxAdapter(
                child: FeaturedCocktailCarousel(),
              ),

              // Favorites Section
              if (showFavorites) ...[
                SliverSectionHeader(
                  title: l10n.favorites,
                  count: favorites.length,
                  accentColor: AppColors.error,
                  onViewAll: () => _navigateToSection(
                    context,
                    l10n.favorites,
                    favorites,
                    AppColors.error,
                  ),
                ),
                CocktailCardGrid(matches: favorites.take(10).toList()),
              ],

              // Can Make Section
              if (canMake.isNotEmpty) ...[
                SliverSectionHeader(
                  title: l10n.canMake,
                  count: canMake.length,
                  accentColor: AppColors.success,
                  onViewAll: () => _navigateToSection(
                    context,
                    l10n.canMake,
                    canMake,
                    AppColors.success,
                  ),
                ),
                CocktailCardGrid(matches: canMake.take(10).toList()),
              ],

              // Almost Can Make Section
              if (almostCanMake.isNotEmpty) ...[
                SliverSectionHeader(
                  title: l10n.almostCanMake,
                  count: almostCanMake.length,
                  accentColor: AppColors.warning,
                  onViewAll: () => _navigateToSection(
                    context,
                    l10n.almostCanMake,
                    almostCanMake,
                    AppColors.warning,
                  ),
                ),
                CocktailCardGrid(matches: almostCanMake.take(10).toList()),
              ],

              // Need More Section
              if (needMore.isNotEmpty) ...[
                SliverSectionHeader(
                  title: l10n.nMoreIngredients(2),
                  count: needMore.length,
                  accentColor: AppColors.gray600,
                  onViewAll: () => _navigateToSection(
                    context,
                    l10n.nMoreIngredients(2),
                    needMore,
                    AppColors.gray600,
                  ),
                ),
                CocktailCardGrid(matches: needMore.take(10).toList()),
              ],

              // Bottom padding for floating nav bar
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          );
        },
        loading: () => CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: FeaturedCocktailCarousel(),
            ),
            SliverShimmerGrid(
              itemCount: 6,
              itemBuilder: (context, index) => const CocktailCardSkeleton(),
            ),
          ],
        ),
        error: (error, stack) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(cocktailMatchesProvider),
        ),
      ),
    );
  }
}

