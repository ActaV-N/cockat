import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_colors_extension.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/models.dart';
import '../../data/providers/providers.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/ingredient_availability_card.dart';

class CocktailDetailScreen extends ConsumerStatefulWidget {
  final String cocktailId;

  const CocktailDetailScreen({super.key, required this.cocktailId});

  @override
  ConsumerState<CocktailDetailScreen> createState() =>
      _CocktailDetailScreenState();
}

class _CocktailDetailScreenState extends ConsumerState<CocktailDetailScreen> {
  bool _hasLoggedView = false;

  void _logCocktailView(Cocktail cocktail, String locale) {
    if (_hasLoggedView) return;
    _hasLoggedView = true;

    final analytics = ref.read(analyticsServiceProvider);
    analytics.logScreenView(screenName: 'CocktailDetail');
    analytics.logViewCocktail(
      cocktailId: cocktail.id,
      cocktailName: cocktail.getLocalizedName(locale),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 상세 재료 정보가 포함된 칵테일 로드 (lazy loading)
    final cocktailAsync =
        ref.watch(cocktailWithIngredientsProvider(widget.cocktailId));
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(currentLocaleCodeProvider);

    return cocktailAsync.when(
      data: (cocktail) {
        if (cocktail == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Cocktail not found')),
          );
        }

        _logCocktailView(cocktail, locale);

        final colors = context.appColors;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Premium Hero App Bar
              SliverAppBar(
                expandedHeight: 420,
                pinned: true,
                stretch: true,
                backgroundColor: colors.surface,
                surfaceTintColor: Colors.transparent,
                systemOverlayStyle: SystemUiOverlayStyle.light,
                leading: _FloatingBackButton(),
                actions: [
                  _FloatingFavoriteButton(cocktailId: cocktail.id),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Hero Image
                      CocktailImage(
                        cocktail: cocktail,
                        mode: ImageDisplayMode.full,
                        fit: BoxFit.cover,
                      ),
                      // Premium gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.3),
                              Colors.transparent,
                              Colors.transparent,
                              colors.background.withValues(alpha: 0.8),
                              colors.background,
                            ],
                            stops: const [0.0, 0.2, 0.5, 0.85, 1.0],
                          ),
                        ),
                      ),
                      // Title at bottom
                      Positioned(
                        left: AppTheme.spacingMd,
                        right: AppTheme.spacingMd,
                        bottom: AppTheme.spacingLg,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              cocktail.getLocalizedName(locale),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: colors.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                            ),
                            if (cocktail.tags.isNotEmpty) ...[
                              const SizedBox(height: AppTheme.spacingSm),
                              Wrap(
                                spacing: AppTheme.spacingXs,
                                runSpacing: AppTheme.spacingXs,
                                children: cocktail.tags.take(3).map((tag) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.spacingSm,
                                      vertical: AppTheme.spacingXs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(
                                          AppTheme.radiusRound),
                                    ),
                                    child: Text(
                                      tag,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: colors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content with rounded top
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.background,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats Row
                        _StatsRow(cocktail: cocktail, l10n: l10n),
                        const SizedBox(height: AppTheme.spacingLg),

                        // Ingredients
                        _SectionTitle(title: l10n.ingredients),
                        const SizedBox(height: AppTheme.spacingSm),
                        _IngredientsList(
                          cocktailId: cocktail.id,
                          ingredients: cocktail.ingredients,
                          l10n: l10n,
                          locale: locale,
                        ),
                        const SizedBox(height: AppTheme.spacingLg),

                        // Instructions
                        _SectionTitle(title: l10n.instructions),
                        const SizedBox(height: AppTheme.spacingSm),
                        _InstructionsCard(
                            instructions:
                                cocktail.getLocalizedInstructions(locale)),

                        // Garnish
                        if (cocktail.getLocalizedGarnish(locale) != null &&
                            cocktail
                                .getLocalizedGarnish(locale)!
                                .isNotEmpty) ...[
                          const SizedBox(height: AppTheme.spacingLg),
                          _SectionTitle(title: l10n.garnish),
                          const SizedBox(height: AppTheme.spacingSm),
                          _GarnishCard(
                              garnish: cocktail.getLocalizedGarnish(locale)!),
                        ],

                        // Description
                        if (cocktail.getLocalizedDescription(locale) != null &&
                            cocktail
                                .getLocalizedDescription(locale)!
                                .isNotEmpty) ...[
                          const SizedBox(height: AppTheme.spacingLg),
                          _SectionTitle(title: l10n.description),
                          const SizedBox(height: AppTheme.spacingSm),
                          Text(
                            cocktail.getLocalizedDescription(locale)!,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: colors.textSecondary,
                                      height: 1.6,
                                    ),
                          ),
                        ],

                        const SizedBox(height: 100), // Bottom padding for nav
                      ],
                    ),
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

class _FloatingBackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingFavoriteButton extends ConsumerWidget {
  final String cocktailId;

  const _FloatingFavoriteButton({required this.cocktailId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(effectiveIsFavoriteProvider(cocktailId));
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isFavorite
                  ? AppColors.error.withValues(alpha: 0.9)
                  : Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                final favoritesService =
                    ref.read(effectiveFavoritesServiceProvider);
                final result = favoritesService.toggle(cocktailId);

                final message = switch (result) {
                  FavoriteResult.added => l10n.addedToFavorites,
                  FavoriteResult.removed => l10n.removedFromFavorites,
                  _ => null,
                };

                if (message != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final Cocktail cocktail;
  final AppLocalizations l10n;

  const _StatsRow({required this.cocktail, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (cocktail.abv != null)
            _StatItem(
              icon: Icons.local_bar,
              value: '${cocktail.abv!.toStringAsFixed(0)}%',
              label: 'ABV',
              color: AppColors.coralPeach,
            ),
          if (cocktail.glass != null)
            _StatItem(
              icon: Icons.wine_bar,
              value: cocktail.glass!,
              label: l10n.glass,
              color: AppColors.purple,
            ),
          if (cocktail.method != null)
            _StatItem(
              icon: Icons.blender,
              value: cocktail.method!,
              label: l10n.method,
              color: AppColors.success,
            ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.textTertiary,
                ),
          ),
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
    final colors = context.appColors;

    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
        ),
      ],
    );
  }
}

class _IngredientsList extends ConsumerWidget {
  final String cocktailId;
  final List<CocktailIngredient> ingredients;
  final AppLocalizations l10n;
  final String locale;

  const _IngredientsList({
    required this.cocktailId,
    required this.ingredients,
    required this.l10n,
    required this.locale,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final availabilityAsync =
        ref.watch(cocktailIngredientAvailabilityProvider(cocktailId));
    final userUnit = ref.watch(effectiveUnitSystemProvider);

    return availabilityAsync.when(
      data: (availabilities) {
        return Container(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
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
                  locale: locale,
                );
              }).toList(),
            ),
          ),
        );
      },
      loading: () => Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Text('Error: $error'),
      ),
    );
  }
}

class _InstructionsCard extends StatelessWidget {
  final String instructions;

  const _InstructionsCard({required this.instructions});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final steps =
        instructions.split('\n').where((s) => s.trim().isNotEmpty).toList();

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value.trim();
            final cleanStep = step.replaceFirst(RegExp(r'^\d+[\.\)]\s*'), '');

            return Padding(
              padding: EdgeInsets.only(
                  bottom: index < steps.length - 1 ? AppTheme.spacingMd : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.coralPeach,
                          AppColors.coralDeep,
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        cleanStep,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                            ),
                      ),
                    ),
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

class _GarnishCard extends StatelessWidget {
  final String garnish;

  const _GarnishCard({required this.garnish});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.eco,
                color: AppColors.success,
                size: 22,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Text(
                garnish,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

