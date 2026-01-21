import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers/providers.dart';
import '../../../l10n/app_localizations.dart';

class OnboardingProductsPage extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const OnboardingProductsPage({super.key, required this.onNext});

  @override
  ConsumerState<OnboardingProductsPage> createState() =>
      _OnboardingProductsPageState();
}

class _OnboardingProductsPageState
    extends ConsumerState<OnboardingProductsPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final productsAsync = ref.watch(productsProvider);
    final selectedProducts = ref.watch(effectiveSelectedProductsProvider);
    final selectedCount = selectedProducts.length;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.liquor_rounded,
                size: 64,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.onboardingProductsTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.onboardingProductsSubtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: l10n.searchProducts,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Products list
        Expanded(
          child: productsAsync.when(
            data: (products) {
              var filtered = products.where((p) {
                if (_searchQuery.isEmpty) return true;
                final query = _searchQuery.toLowerCase();
                return p.name.toLowerCase().contains(query) ||
                    (p.brand?.toLowerCase().contains(query) ?? false);
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: colorScheme.outlineVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noResultsFound,
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final product = filtered[index];
                  final isSelected = selectedProducts.contains(product.id);

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: product.imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                product.imageUrl!,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 48,
                                  height: 48,
                                  color: colorScheme.surfaceContainerHighest,
                                  child: Icon(
                                    Icons.liquor,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.liquor,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                      title: Text(product.displayName),
                      subtitle: product.formattedVolume != null
                          ? Text(
                              product.formattedVolume!,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            )
                          : null,
                      trailing: Checkbox(
                        value: isSelected,
                        onChanged: (_) => ref
                            .read(effectiveProductsServiceProvider)
                            .toggle(product.id),
                      ),
                      onTap: () => ref
                          .read(effectiveProductsServiceProvider)
                          .toggle(product.id),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),

        // Bottom bar with count and next button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.itemsSelected(selectedCount),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                FilledButton.icon(
                  onPressed: widget.onNext,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(l10n.next),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
