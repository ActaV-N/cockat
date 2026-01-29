import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/services/image_upload_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_colors_extension.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/providers/providers.dart';
import '../../l10n/app_localizations.dart';
import 'create_user_cocktail_screen.dart';

class UserCocktailDetailScreen extends ConsumerWidget {
  final String cocktailId;

  const UserCocktailDetailScreen({super.key, required this.cocktailId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final cocktailAsync = ref.watch(userCocktailWithIngredientsProvider(cocktailId));
    final locale = ref.watch(currentLocaleCodeProvider);

    return cocktailAsync.when(
      data: (cocktail) {
        if (cocktail == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(l10n.errorOccurred)),
          );
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Hero App Bar
              _buildAppBar(context, ref, cocktail, l10n, colors, locale),
              // Content
              SliverPadding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // 설명
                    if (cocktail.description != null) ...[
                      _buildSection(
                        context,
                        l10n.description,
                        cocktail.getLocalizedDescription(locale) ?? '',
                        colors,
                      ),
                      const SizedBox(height: AppTheme.spacingLg),
                    ],

                    // 재료
                    if (cocktail.ingredients.isNotEmpty) ...[
                      _buildIngredientsSection(context, cocktail, l10n, colors),
                      const SizedBox(height: AppTheme.spacingLg),
                    ],

                    // 만드는 방법
                    _buildSection(
                      context,
                      l10n.instructions,
                      cocktail.getLocalizedInstructions(locale),
                      colors,
                    ),
                    const SizedBox(height: AppTheme.spacingLg),

                    // 추가 정보
                    _buildInfoSection(context, cocktail, l10n, colors, locale),
                    const SizedBox(height: AppTheme.spacingXl),
                  ]),
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
      error: (_, __) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.errorOccurred)),
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    UserCocktail cocktail,
    AppLocalizations l10n,
    AppColorsExtension colors,
    String locale,
  ) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: colors.surface,
      leading: _FloatingBackButton(),
      actions: [
        _FloatingEditButton(
          onTap: () async {
            final result = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => CreateUserCocktailScreen(cocktailToEdit: cocktail),
              ),
            );
            if (result == true) {
              ref.invalidate(userCocktailWithIngredientsProvider(cocktailId));
            }
          },
        ),
        const SizedBox(width: 4),
        _FloatingDeleteButton(
          onTap: () => _confirmDelete(context, ref, cocktail, l10n),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // 이미지
            if (cocktail.imageUrl != null)
              CachedNetworkImage(
                imageUrl: cocktail.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: colors.card,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (_, __, ___) => _buildPlaceholderImage(colors),
              )
            else
              _buildPlaceholderImage(colors),
            // 그라데이션 오버레이
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            // 칵테일 이름
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Text(
                cocktail.getLocalizedName(locale),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(AppColorsExtension colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.coralPeach.withValues(alpha: 0.3),
            AppColors.purple.withValues(alpha: 0.2),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.local_bar,
          size: 80,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String content,
    AppColorsExtension colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.6,
              ),
        ),
      ],
    );
  }

  Widget _buildIngredientsSection(
    BuildContext context,
    UserCocktail cocktail,
    AppLocalizations l10n,
    AppColorsExtension colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.ingredients,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        ...cocktail.ingredients.map((ing) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: ing.isOptional
                          ? colors.textSecondary
                          : AppColors.coralPeach,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ing.displayName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontStyle: ing.isOptional
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                    ),
                  ),
                  if (ing.amountWithUnits.isNotEmpty)
                    Text(
                      ing.amountWithUnits,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                          ),
                    ),
                  if (ing.isOptional) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.textSecondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        l10n.optional,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                              fontSize: 10,
                            ),
                      ),
                    ),
                  ],
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    UserCocktail cocktail,
    AppLocalizations l10n,
    AppColorsExtension colors,
    String locale,
  ) {
    final dateFormat = DateFormat.yMMMd(locale);
    final infoItems = <Widget>[];

    if (cocktail.glass != null) {
      infoItems.add(_buildInfoChip(
        context,
        Icons.wine_bar,
        cocktail.glass!,
        colors,
      ));
    }

    if (cocktail.method != null) {
      infoItems.add(_buildInfoChip(
        context,
        Icons.blender,
        cocktail.method!,
        colors,
      ));
    }

    if (cocktail.garnish != null) {
      infoItems.add(_buildInfoChip(
        context,
        Icons.eco,
        cocktail.getLocalizedGarnish(locale)!,
        colors,
      ));
    }

    if (cocktail.abv != null) {
      infoItems.add(_buildInfoChip(
        context,
        Icons.percent,
        '${cocktail.abv!.toStringAsFixed(1)}%',
        colors,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (infoItems.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: infoItems,
          ),
          const SizedBox(height: AppTheme.spacingMd),
        ],
        Text(
          l10n.createdAt(dateFormat.format(cocktail.createdAt)),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(
    BuildContext context,
    IconData icon,
    String label,
    AppColorsExtension colors,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.textSecondary),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    UserCocktail cocktail,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteCocktailConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final service = ref.read(userCocktailServiceProvider);
      final imageService = ref.read(imageUploadServiceProvider);

      // 이미지 삭제
      if (cocktail.imageUrl != null) {
        await imageService.deleteCocktailImage(cocktail.imageUrl!);
      }

      // 칵테일 삭제
      final success = await service.deleteCocktail(cocktail.id);

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.cocktailDeleted)),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.errorOccurred)),
          );
        }
      }
    }
  }
}

class _FloatingBackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.of(context).pop(),
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _FloatingEditButton extends StatelessWidget {
  final VoidCallback onTap;

  const _FloatingEditButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.edit, color: Colors.white),
        ),
      ),
    );
  }
}

class _FloatingDeleteButton extends StatelessWidget {
  final VoidCallback onTap;

  const _FloatingDeleteButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
    );
  }
}
