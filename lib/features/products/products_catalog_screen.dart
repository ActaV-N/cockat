import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/widgets.dart';
import '../../data/models/models.dart';
import '../../data/providers/providers.dart';
import '../../l10n/app_localizations.dart';

class ProductsCatalogScreen extends ConsumerWidget {
  const ProductsCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final productsAsync = ref.watch(catalogFilteredProductsProvider);
    final categoriesAsync = ref.watch(productCategoriesProvider);
    final selectedCategory = ref.watch(productCategoryFilterProvider);
    final selectedCount = ref.watch(effectiveSelectedProductCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.products),
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
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBarField(
              hintText: l10n.searchProducts,
              searchQueryProvider: productSearchQueryProvider,
            ),
          ),

          // Category Filter Chips
          categoriesAsync.when(
            data: (categories) => _CategoryFilterChips(
              categories: categories,
              selectedCategory: selectedCategory,
              l10n: l10n,
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Selected count chip
          if (selectedCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Chip(
                    avatar: Icon(
                      Icons.check_circle,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    label: Text(l10n.productsSelected(selectedCount)),
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                  ),
                ],
              ),
            ),

          // Product Grid
          Expanded(
            child: productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return _EmptyState(l10n: l10n);
                }
                return _ProductGrid(products: products);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilterChips extends ConsumerWidget {
  final List<String> categories;
  final String? selectedCategory;
  final AppLocalizations l10n;

  const _CategoryFilterChips({
    required this.categories,
    required this.selectedCategory,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryNames = {
      'spirits': l10n.spirits,
      'liqueurs': l10n.liqueurs,
      'wines': l10n.wines,
      'bitters': l10n.bitters,
      'juices': l10n.juices,
      'syrups': l10n.syrups,
      'other': l10n.other,
    };

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // "All" chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(l10n.allIngredients),
              selected: selectedCategory == null,
              onSelected: (_) {
                ref.read(productCategoryFilterProvider.notifier).state = null;
              },
            ),
          ),
          // Category chips
          ...categories.map((category) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(categoryNames[category] ?? category),
                  selected: selectedCategory == category,
                  onSelected: (_) {
                    ref.read(productCategoryFilterProvider.notifier).state =
                        selectedCategory == category ? null : category;
                  },
                ),
              )),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppLocalizations l10n;

  const _EmptyState({required this.l10n});

  @override
  Widget build(BuildContext context) {
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
}

class _ProductGrid extends ConsumerWidget {
  final List<Product> products;

  const _ProductGrid({required this.products});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return _ProductCard(product: products[index]);
      },
    );
  }
}

class _ProductCard extends ConsumerWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected =
        ref.watch(effectiveIsProductSelectedProvider(product.id));
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          ref.read(effectiveProductsServiceProvider).toggle(product.id);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 상단: 상품명 + 선택 인디케이터
            _buildHeader(theme, isSelected),

            // 중앙: 이미지
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ProductImage(
                  product: product,
                  mode: ImageDisplayMode.thumbnail,
                ),
              ),
            ),

            // 하단: 브랜드 + 스펙
            _buildFooter(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              product.name,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          AnimatedSelectionIndicator(
            isSelected: isSelected,
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    final hasInfo = product.brand != null ||
        product.formattedVolume != null ||
        product.abv != null;

    if (!hasInfo) {
      return const SizedBox(height: 8);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (product.brand != null)
            Text(
              product.brand!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (product.formattedVolume != null || product.abv != null)
            Text(
              _formatSpecs(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
        ],
      ),
    );
  }

  String _formatSpecs() {
    final specs = <String>[];
    if (product.formattedVolume != null) {
      specs.add(product.formattedVolume!);
    }
    if (product.abv != null) {
      specs.add('${product.abv}%');
    }
    return specs.join(' | ');
  }
}
