import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/models.dart';
import '../../l10n/app_localizations.dart';
import 'cocktail_detail_screen.dart';

class CocktailSectionListScreen extends StatelessWidget {
  final String title;
  final List<CocktailMatch> matches;
  final Color sectionColor;
  final bool showStatus;

  const CocktailSectionListScreen({
    super.key,
    required this.title,
    required this.matches,
    required this.sectionColor,
    this.showStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: matches.isEmpty
          ? _EmptyState()
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: matches.length,
              itemBuilder: (context, index) {
                return _CocktailCard(
                  match: matches[index],
                  showStatus: showStatus,
                );
              },
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_bar_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noResultsFound,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
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
        color: color.withValues(alpha: 0.85),
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
