import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_colors_extension.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/providers/providers.dart';
import '../../l10n/app_localizations.dart';
import 'create_user_cocktail_screen.dart';
import 'user_cocktail_detail_screen.dart';

class UserCocktailsListScreen extends ConsumerWidget {
  const UserCocktailsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final cocktailsAsync = ref.watch(userCocktailsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myCocktails),
        backgroundColor: colors.background,
      ),
      body: cocktailsAsync.when(
        data: (cocktails) {
          if (cocktails.isEmpty) {
            return _EmptyState(l10n: l10n, colors: colors);
          }
          return _CocktailsList(cocktails: cocktails, l10n: l10n, colors: colors);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: colors.textSecondary),
              const SizedBox(height: AppTheme.spacingMd),
              Text(l10n.errorOccurred),
              const SizedBox(height: AppTheme.spacingSm),
              FilledButton(
                onPressed: () => ref.invalidate(userCocktailsProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const CreateUserCocktailScreen(),
          ),
        ),
        backgroundColor: AppColors.coralPeach,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(l10n.createCocktail),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppLocalizations l10n;
  final AppColorsExtension colors;

  const _EmptyState({required this.l10n, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.coralPeach.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_bar_outlined,
                size: 64,
                color: AppColors.coralPeach,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              l10n.noUserCocktails,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              l10n.noUserCocktailsPrompt,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CocktailsList extends StatelessWidget {
  final List<UserCocktail> cocktails;
  final AppLocalizations l10n;
  final AppColorsExtension colors;

  const _CocktailsList({
    required this.cocktails,
    required this.l10n,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      itemCount: cocktails.length,
      itemBuilder: (context, index) {
        final cocktail = cocktails[index];
        return _CocktailCard(cocktail: cocktail, l10n: l10n, colors: colors);
      },
    );
  }
}

class _CocktailCard extends ConsumerWidget {
  final UserCocktail cocktail;
  final AppLocalizations l10n;
  final AppColorsExtension colors;

  const _CocktailCard({
    required this.cocktail,
    required this.l10n,
    required this.colors,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(currentLocaleCodeProvider);
    final dateFormat = DateFormat.yMMMd(locale);

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => UserCocktailDetailScreen(cocktailId: cocktail.id),
          ),
        ),
        child: Row(
          children: [
            // 이미지
            SizedBox(
              width: 100,
              height: 100,
              child: cocktail.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: cocktail.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: colors.card,
                        child: Center(
                          child: Icon(
                            Icons.local_bar,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: colors.card,
                        child: Center(
                          child: Icon(
                            Icons.local_bar,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.coralPeach.withValues(alpha: 0.1),
                      child: Center(
                        child: Icon(
                          Icons.local_bar,
                          size: 40,
                          color: AppColors.coralPeach,
                        ),
                      ),
                    ),
            ),
            // 정보
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cocktail.getLocalizedName(locale),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (cocktail.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        cocktail.getLocalizedDescription(locale) ?? '',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      l10n.createdAt(dateFormat.format(cocktail.createdAt)),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            // 화살표
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacingSm),
              child: Icon(
                Icons.chevron_right,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
