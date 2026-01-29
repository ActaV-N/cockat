import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/widgets.dart';
import '../../data/models/models.dart';
import '../../data/providers/providers.dart';
import '../../l10n/app_localizations.dart';
import '../ingredients/ingredients_screen.dart';

/// 상품(술병) 선택 화면
class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final productsAsync = ref.watch(filteredProductsProvider);
    final selectedCount = ref.watch(effectiveSelectedProductCountProvider);

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
      body: productsAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return _EmptyProductsView(l10n: l10n);
          }
          return _ProductsBody(
            products: products,
            selectedCount: selectedCount,
            l10n: l10n,
          );
        },
        loading: () => ShimmerGrid(
          itemCount: 6,
          childAspectRatio: 0.7,
          itemBuilder: (context, index) => const ProductCardSkeleton(),
        ),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(filteredProductsProvider),
        ),
      ),
    );
  }
}

/// 상품이 없을 때 표시되는 뷰
class _EmptyProductsView extends StatelessWidget {
  final AppLocalizations l10n;

  const _EmptyProductsView({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.liquor_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noProductsAvailable,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.emptyBarPrompt,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: () => _navigateToIngredients(context),
              child: Text(l10n.fallbackToIngredients),
            ),
          ],
        ),
      ),
    );
  }
}

/// 상품 목록 본문
class _ProductsBody extends ConsumerWidget {
  final List<Product> products;
  final int selectedCount;
  final AppLocalizations l10n;

  const _ProductsBody({
    required this.products,
    required this.selectedCount,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // 검색바
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: SearchBarField(
            hintText: l10n.searchProducts,
            searchQueryProvider: productSearchQueryProvider,
          ),
        ),

        // 선택 개수 + 재료로 선택하기 버튼
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              if (selectedCount > 0)
                Chip(
                  avatar: Icon(
                    Icons.check_circle,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  label: Text(l10n.productsSelected(selectedCount)),
                  backgroundColor: theme.colorScheme.primaryContainer,
                ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _navigateToIngredients(context),
                icon: const Icon(Icons.category_outlined, size: 18),
                label: Text(l10n.fallbackToIngredients),
              ),
            ],
          ),
        ),

        // 상품 그리드
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return ProductCard(product: products[index]);
            },
          ),
        ),
      ],
    );
  }
}

/// 재료 선택 화면으로 이동
void _navigateToIngredients(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => const IngredientsScreen(),
    ),
  );
}
