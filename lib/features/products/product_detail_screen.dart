import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/models.dart';
import '../../data/providers/providers.dart';
import '../../l10n/app_localizations.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final productAsync = ref.watch(productByIdProvider(productId));
    final isOwned = ref.watch(effectiveIsProductSelectedProvider(productId));

    return productAsync.when(
      data: (product) {
        if (product == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(l10n.productNotFound)),
          );
        }
        return _ProductDetailContent(
          product: product,
          isOwned: isOwned,
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

class _ProductDetailContent extends ConsumerWidget {
  final Product product;
  final bool isOwned;

  const _ProductDetailContent({
    required this.product,
    required this.isOwned,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(currentLocaleCodeProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with image
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.45,
            pinned: true,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _ProductHeroImage(imageUrl: product.imageUrl),
            ),
          ),

          // Product Information
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand
                  if (product.brand != null) ...[
                    Text(
                      product.brand!,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                  ],

                  // Product Name
                  Text(
                    product.getLocalizedName(locale),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),

                  // Specs Grid
                  _SpecsGrid(product: product, l10n: l10n),
                  const SizedBox(height: 24),

                  // Description
                  if (product.getLocalizedDescription(locale) != null &&
                      product.getLocalizedDescription(locale)!.isNotEmpty) ...[
                    Text(
                      l10n.description,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.getLocalizedDescription(locale)!,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Ingredient Info
                  _IngredientInfo(product: product, l10n: l10n),

                  // Bottom spacing for fixed button
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      // Fixed bottom button
      bottomNavigationBar: _BottomActionButton(
        product: product,
        isOwned: isOwned,
        locale: locale,
      ),
    );
  }
}

class _ProductHeroImage extends StatelessWidget {
  final String? imageUrl;

  const _ProductHeroImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(context),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    }
    return _placeholder(context);
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.liquor,
          size: 80,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}

class _SpecsGrid extends StatelessWidget {
  final Product product;
  final AppLocalizations l10n;

  const _SpecsGrid({required this.product, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final specs = <Widget>[];

    if (product.volumeMl != null) {
      specs.add(_SpecItem(
        icon: Icons.water_drop_outlined,
        label: l10n.volume,
        value: product.formattedVolume!,
      ));
    }
    if (product.abv != null) {
      specs.add(_SpecItem(
        icon: Icons.local_bar_outlined,
        label: l10n.alcoholContent,
        value: '${product.abv}%',
      ));
    }
    if (product.country != null) {
      specs.add(_SpecItem(
        icon: Icons.public,
        label: l10n.country,
        value: product.country!,
      ));
    }

    if (specs.isEmpty) return const SizedBox.shrink();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: specs,
    );
  }
}

class _SpecItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SpecItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientInfo extends ConsumerWidget {
  final Product product;
  final AppLocalizations l10n;

  const _IngredientInfo({required this.product, required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (product.ingredientId == null) return const SizedBox.shrink();

    final ingredientAsync = ref.watch(ingredientByIdProvider(product.ingredientId!));
    final locale = ref.watch(currentLocaleCodeProvider);

    return ingredientAsync.when(
      data: (ingredient) {
        if (ingredient == null) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.category_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.ingredientType,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                ingredient.getLocalizedName(locale),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (ingredient.category != null) ...[
                const SizedBox(height: 4),
                Text(
                  ingredient.category!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _BottomActionButton extends ConsumerWidget {
  final Product product;
  final bool isOwned;
  final String locale;

  const _BottomActionButton({
    required this.product,
    required this.isOwned,
    required this.locale,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.gray900.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 4),
        child: FilledButton.icon(
          onPressed: () {
            if (isOwned) {
              // 확인 다이얼로그
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: Text(l10n.removeFromMyBar),
                  content: Text(l10n.removeProductConfirm(product.getLocalizedDisplayName(locale))),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(l10n.cancel),
                    ),
                    FilledButton(
                      onPressed: () {
                        ref
                            .read(effectiveProductsServiceProvider)
                            .toggle(product.id);
                        Navigator.pop(dialogContext); // 다이얼로그 닫기
                        Navigator.pop(context); // 상세 화면 닫기
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                      ),
                      child: Text(l10n.remove),
                    ),
                  ],
                ),
              );
            } else {
              ref.read(effectiveProductsServiceProvider).toggle(product.id);
            }
          },
          icon: Icon(
              isOwned ? Icons.remove_circle_outline : Icons.add_circle_outline),
          label: Text(isOwned ? l10n.removeFromMyBar : l10n.addToMyBar),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor:
                isOwned ? AppColors.error : Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
