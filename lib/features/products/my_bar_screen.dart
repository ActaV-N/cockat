import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_colors_extension.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/models.dart';
import '../../data/providers/providers.dart';
import '../../l10n/app_localizations.dart';
import 'product_detail_screen.dart';

class MyBarScreen extends ConsumerWidget {
  const MyBarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final ingredientGroupsAsync = ref.watch(ingredientGroupsForMyBarProvider);
    final selectedCount = ref.watch(effectiveSelectedProductCountProvider);
    final locale = ref.watch(currentLocaleCodeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myBar),
        actions: [
          if (selectedCount > 0)
            TextButton.icon(
              onPressed: () {
                ref.read(effectiveProductsServiceProvider).clear();
              },
              icon: const Icon(Icons.clear_all),
              label: Text(l10n.clearAll),
            ),
        ],
      ),
      body: ingredientGroupsAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return _EmptyBarView(l10n: l10n);
          }
          return _MyBarContent(
            groups: groups,
            selectedCount: selectedCount,
            locale: locale,
          );
        },
        loading: () => CustomScrollView(
          slivers: [
            SliverShimmerGrid(
              itemCount: 6,
              itemBuilder: (context, index) => const ProductCardSkeleton(),
            ),
          ],
        ),
        error: (error, stack) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(ingredientGroupsForMyBarProvider),
        ),
      ),
    );
  }
}

class _EmptyBarView extends StatelessWidget {
  final AppLocalizations l10n;

  const _EmptyBarView({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              l10n.myBarEmpty,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              l10n.myBarEmptyPrompt,
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

class _MyBarContent extends StatelessWidget {
  final List<IngredientGroup> groups;
  final int selectedCount;
  final String locale;

  const _MyBarContent({
    required this.groups,
    required this.selectedCount,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.appColors;

    return CustomScrollView(
      slivers: [
        // Summary header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Container(
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
                children: [
                  Expanded(
                    child: _StatChip(
                      icon: Icons.inventory_2,
                      value: '$selectedCount',
                      label: l10n.ownedProducts(selectedCount),
                      color: AppColors.coralPeach,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: colors.divider,
                  ),
                  Expanded(
                    child: _StatChip(
                      icon: Icons.category_outlined,
                      value: '${groups.length}',
                      label: l10n.ingredientTypes(groups.length),
                      color: AppColors.purple,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Ingredient sections
        for (final group in groups) ...[
          SliverSectionHeader(
            title: group.getLocalizedDisplayName(locale),
            count: group.productCount,
            accentColor: colors.primary,
          ),
          _ProductGrid(products: group.products),
        ],

        // Bottom padding for floating nav
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.textTertiary,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}


class _ProductGrid extends StatelessWidget {
  final List<Product> products;

  const _ProductGrid({required this.products});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final product = products[index];
            return ProductCard(
              product: product,
              showSelectionIndicator: false,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProductDetailScreen(productId: product.id),
                  ),
                );
              },
            );
          },
          childCount: products.length,
        ),
      ),
    );
  }
}
