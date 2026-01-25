import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/misc_item.dart';
import '../../../data/providers/providers.dart';
import '../../../l10n/app_localizations.dart';

class OtherIngredientsSettingsPage extends ConsumerStatefulWidget {
  const OtherIngredientsSettingsPage({super.key});

  @override
  ConsumerState<OtherIngredientsSettingsPage> createState() =>
      _OtherIngredientsSettingsPageState();
}

class _OtherIngredientsSettingsPageState
    extends ConsumerState<OtherIngredientsSettingsPage> {
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.otherIngredients),
      ),
      body: Column(
        children: [
          // Category chips
          miscItemsAsync.when(
            data: (itemsByCategory) {
              final categories = itemsByCategory.keys.toList();
              return SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
            loading: () => const SizedBox(height: 48),
            error: (_, __) => const SizedBox(height: 48),
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

          // Bottom bar with count
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.itemsSelected(selectedCount),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
