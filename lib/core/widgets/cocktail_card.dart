import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../data/providers/providers.dart';
import '../../features/cocktails/cocktail_detail_screen.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_colors_extension.dart';
import '../theme/app_theme.dart';
import 'cocktail_image.dart';
import 'favorite_button.dart';
import 'storage_image.dart';

/// Premium cocktail card with modern styling
class CocktailCard extends ConsumerWidget {
  final CocktailMatch match;
  final bool showStatus;
  final bool showFavoriteButton;

  const CocktailCard({
    super.key,
    required this.match,
    this.showStatus = true,
    this.showFavoriteButton = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cocktail = match.cocktail;
    final l10n = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final locale = ref.watch(currentLocaleCodeProvider);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Material(
          color: colors.card,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      CocktailDetailScreen(cocktailId: cocktail.id),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image section with overlays
                Expanded(
                  flex: 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Cocktail image
                      CocktailImage(
                        cocktail: cocktail,
                        mode: ImageDisplayMode.thumbnail,
                        fit: BoxFit.cover,
                      ),
                      // Gradient overlay for better text readability
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.3),
                              ],
                              stops: const [0.6, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // Favorite button (top right)
                      if (showFavoriteButton)
                        Positioned(
                          top: AppTheme.spacingSm,
                          right: AppTheme.spacingSm,
                          child: FavoriteButton(
                            cocktailId: cocktail.id,
                            size: 36,
                          ),
                        ),
                      // Status badge (bottom left, above gradient)
                      if (showStatus)
                        Positioned(
                          bottom: AppTheme.spacingSm,
                          left: AppTheme.spacingSm,
                          child: _StatusBadge(match: match, l10n: l10n),
                        ),
                    ],
                  ),
                ),
                // Info section
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingSm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Cocktail name
                      Text(
                        cocktail.getLocalizedName(locale),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // ABV and glass info
                      Row(
                        children: [
                          if (cocktail.abv != null) ...[
                            Icon(
                              Icons.local_bar,
                              size: 12,
                              color: colors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${cocktail.abv!.toStringAsFixed(0)}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: colors.textTertiary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final CocktailMatch match;
  final AppLocalizations l10n;

  const _StatusBadge({
    required this.match,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    final IconData icon;

    if (match.canMake) {
      color = AppColors.success;
      label = l10n.canMake;
      icon = Icons.check_circle;
    } else if (match.missingCount == 1) {
      color = AppColors.warning;
      label = l10n.oneMoreIngredient;
      icon = Icons.add_circle;
    } else {
      color = AppColors.gray500;
      label = l10n.nMoreIngredients(match.missingCount);
      icon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: AppColors.white,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

/// Grid view for cocktail cards
class CocktailCardGrid extends StatelessWidget {
  final List<CocktailMatch> matches;
  final bool showStatus;
  final bool showFavoriteButton;

  const CocktailCardGrid({
    super.key,
    required this.matches,
    this.showStatus = true,
    this.showFavoriteButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: AppTheme.spacingSm,
          mainAxisSpacing: AppTheme.spacingSm,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => CocktailCard(
            match: matches[index],
            showStatus: showStatus,
            showFavoriteButton: showFavoriteButton,
          ),
          childCount: matches.length,
        ),
      ),
    );
  }
}
