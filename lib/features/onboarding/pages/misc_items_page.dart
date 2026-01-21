import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/misc_item.dart';
import '../../../data/providers/providers.dart';
import '../../../l10n/app_localizations.dart';

class OnboardingMiscItemsPage extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const OnboardingMiscItemsPage({super.key, required this.onNext});

  @override
  ConsumerState<OnboardingMiscItemsPage> createState() =>
      _OnboardingMiscItemsPageState();
}

class _OnboardingMiscItemsPageState
    extends ConsumerState<OnboardingMiscItemsPage> {
  String? _selectedCategory;

  String _getCategoryName(BuildContext context, String category) {
    final l10n = AppLocalizations.of(context)!;
    switch (category) {
      case 'ice':
        return l10n.ice;
      case 'fresh':
        return l10n.fresh;
      case 'dairy':
        return l10n.dairy;
      case 'garnish':
        return l10n.garnish;
      case 'mixer':
        return l10n.mixer;
      case 'syrup':
        return l10n.syrup;
      case 'bitters':
        return l10n.bitters;
      default:
        return category;
    }
  }

  String _getCategoryIcon(String category) {
    return MiscItemCategories.categoryIcons[category] ?? '📦';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final miscItemsAsync = ref.watch(miscItemsByCategoryProvider);
    final selectedItems = ref.watch(effectiveSelectedMiscItemsProvider);
    final selectedCount = selectedItems.length;
    final locale = ref.watch(localeProvider)?.languageCode ?? 'en';

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.kitchen_rounded,
                size: 64,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.onboardingMiscTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.onboardingMiscSubtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        // Category chips
        miscItemsAsync.when(
          data: (itemsByCategory) {
            final categories = itemsByCategory.keys.toList();
            return SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: categories.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text(l10n.allIngredients),
                        selected: _selectedCategory == null,
                        onSelected: (_) =>
                            setState(() => _selectedCategory = null),
                      ),
                    );
                  }
                  final category = categories[index - 1];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      avatar: Text(_getCategoryIcon(category)),
                      label: Text(_getCategoryName(context, category)),
                      selected: _selectedCategory == category,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = category),
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const SizedBox(height: 40),
          error: (_, __) => const SizedBox(height: 40),
        ),
        const SizedBox(height: 8),

        // Items list
        Expanded(
          child: miscItemsAsync.when(
            data: (itemsByCategory) {
              List<MapEntry<String, List<MiscItem>>> categoriesToShow;
              if (_selectedCategory != null) {
                final items = itemsByCategory[_selectedCategory];
                if (items != null) {
                  categoriesToShow = [MapEntry(_selectedCategory!, items)];
                } else {
                  categoriesToShow = [];
                }
              } else {
                categoriesToShow = itemsByCategory.entries.toList();
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categoriesToShow.length,
                itemBuilder: (context, categoryIndex) {
                  final entry = categoriesToShow[categoryIndex];
                  final category = entry.key;
                  final items = entry.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 4,
                        ),
                        child: Row(
                          children: [
                            Text(
                              _getCategoryIcon(category),
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getCategoryName(context, category),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: items.map((item) {
                          final isSelected = selectedItems.contains(item.id);
                          return FilterChip(
                            label: Text(item.getLocalizedName(locale)),
                            selected: isSelected,
                            onSelected: (_) => ref
                                .read(effectiveMiscItemsServiceProvider)
                                .toggle(item.id),
                            avatar: isSelected
                                ? const Icon(Icons.check, size: 18)
                                : null,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
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
