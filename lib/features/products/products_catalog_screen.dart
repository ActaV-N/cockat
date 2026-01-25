import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/widgets.dart';
import '../../data/models/models.dart';
import '../../data/providers/providers.dart';
import '../../l10n/app_localizations.dart';

class ProductsCatalogScreen extends ConsumerStatefulWidget {
  const ProductsCatalogScreen({super.key});

  @override
  ConsumerState<ProductsCatalogScreen> createState() =>
      _ProductsCatalogScreenState();
}

class _ProductsCatalogScreenState extends ConsumerState<ProductsCatalogScreen> {
  final FocusNode _searchFocusNode = FocusNode();
  bool _showRecentSearches = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onFocusChanged);
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _showRecentSearches = _searchFocusNode.hasFocus;
    });
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isNotEmpty) {
      ref.read(recentProductSearchesProvider.notifier).addSearch(query);
    }
    _searchFocusNode.unfocus();
  }

  void _selectRecentSearch(String query) {
    ref.read(productSearchQueryProvider.notifier).state = query;
    _searchFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final productsAsync = ref.watch(sortedCatalogProductsProvider);
    final categoriesAsync = ref.watch(productCategoriesProvider);
    final selectedCategory = ref.watch(productCategoryFilterProvider);
    final selectedCount = ref.watch(effectiveSelectedProductCountProvider);
    final recentSearches = ref.watch(recentProductSearchesProvider);
    final searchQuery = ref.watch(productSearchQueryProvider);

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
          // Search Bar with recent searches
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SearchBarWithSubmit(
                  hintText: l10n.searchProducts,
                  focusNode: _searchFocusNode,
                  onSubmitted: _onSearchSubmitted,
                ),
                // Recent searches dropdown
                if (_showRecentSearches &&
                    recentSearches.isNotEmpty &&
                    searchQuery.isEmpty)
                  _RecentSearchesDropdown(
                    searches: recentSearches,
                    onSelect: _selectRecentSearch,
                    onDelete: (query) {
                      ref
                          .read(recentProductSearchesProvider.notifier)
                          .removeSearch(query);
                    },
                    onClearAll: () {
                      ref
                          .read(recentProductSearchesProvider.notifier)
                          .clearAll();
                    },
                  ),
              ],
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

          // Sort and selected count row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (selectedCount > 0)
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
                const Spacer(),
                // Sort dropdown
                _SortDropdown(l10n: l10n),
              ],
            ),
          ),

          // Product Grid
          Expanded(
            child: productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return _EmptyState(l10n: l10n, searchQuery: searchQuery);
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

class _SearchBarWithSubmit extends ConsumerStatefulWidget {
  final String hintText;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;

  const _SearchBarWithSubmit({
    required this.hintText,
    required this.focusNode,
    required this.onSubmitted,
  });

  @override
  ConsumerState<_SearchBarWithSubmit> createState() =>
      _SearchBarWithSubmitState();
}

class _SearchBarWithSubmitState extends ConsumerState<_SearchBarWithSubmit> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    ref.read(productSearchQueryProvider.notifier).state = _controller.text;
  }

  void _clearSearch() {
    _controller.clear();
    ref.read(productSearchQueryProvider.notifier).state = '';
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(productSearchQueryProvider);

    // Sync controller if changed externally
    if (_controller.text != query) {
      _controller.text = query;
      _controller.selection =
          TextSelection.fromPosition(TextPosition(offset: query.length));
    }

    return TextField(
      controller: _controller,
      focusNode: widget.focusNode,
      textInputAction: TextInputAction.search,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: query.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _clearSearch,
              )
            : null,
      ),
    );
  }
}

class _RecentSearchesDropdown extends StatelessWidget {
  final List<String> searches;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onDelete;
  final VoidCallback onClearAll;

  const _RecentSearchesDropdown({
    required this.searches,
    required this.onSelect,
    required this.onDelete,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  '최근 검색어',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onClearAll,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    '전체 삭제',
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ],
            ),
          ),
          ...searches.take(5).map((query) => InkWell(
                onTap: () => onSelect(query),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          query,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () => onDelete(query),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _SortDropdown extends ConsumerWidget {
  final AppLocalizations l10n;

  const _SortDropdown({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sortOption = ref.watch(productSortOptionProvider);

    final sortLabels = {
      ProductSortOption.nameAsc: '이름순 (가나다)',
      ProductSortOption.nameDesc: '이름순 (역순)',
      ProductSortOption.brandAsc: '브랜드순 (가나다)',
      ProductSortOption.brandDesc: '브랜드순 (역순)',
      ProductSortOption.abvAsc: '도수 낮은순',
      ProductSortOption.abvDesc: '도수 높은순',
    };

    return PopupMenuButton<ProductSortOption>(
      initialValue: sortOption,
      onSelected: (value) {
        ref.read(productSortOptionProvider.notifier).state = value;
      },
      itemBuilder: (context) => ProductSortOption.values
          .map((option) => PopupMenuItem(
                value: option,
                child: Row(
                  children: [
                    if (sortOption == option)
                      Icon(Icons.check, size: 18, color: theme.colorScheme.primary)
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    Text(sortLabels[option] ?? ''),
                  ],
                ),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort, size: 16, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              '정렬',
              style: theme.textTheme.labelMedium,
            ),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilterChips extends ConsumerStatefulWidget {
  final List<String> categories;
  final String? selectedCategory;
  final AppLocalizations l10n;

  const _CategoryFilterChips({
    required this.categories,
    required this.selectedCategory,
    required this.l10n,
  });

  @override
  ConsumerState<_CategoryFilterChips> createState() =>
      _CategoryFilterChipsState();
}

class _CategoryFilterChipsState extends ConsumerState<_CategoryFilterChips> {
  bool _isExpanded = false;

  // Category icons mapping
  static const _categoryIcons = {
    'spirits': Icons.liquor,
    'liqueurs': Icons.local_bar,
    'wines': Icons.wine_bar,
    'bitters': Icons.science,
    'juices': Icons.local_drink,
    'syrups': Icons.water_drop,
    'other': Icons.more_horiz,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = widget.l10n;
    final selectedCategory = widget.selectedCategory;

    final categoryNames = {
      'spirits': l10n.spirits,
      'liqueurs': l10n.liqueurs,
      'wines': l10n.wines,
      'bitters': l10n.bitters,
      'juices': l10n.juices,
      'syrups': l10n.syrups,
      'other': l10n.other,
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with expand/collapse button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Selected category chip or "All" button
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            selectedCategory != null
                                ? _categoryIcons[selectedCategory] ??
                                    Icons.category
                                : Icons.apps,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            selectedCategory != null
                                ? categoryNames[selectedCategory] ??
                                    selectedCategory
                                : l10n.allIngredients,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          AnimatedRotation(
                            turns: _isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.expand_more,
                              size: 20,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Clear filter button (if filter applied)
                if (selectedCategory != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      ref.read(productCategoryFilterProvider.notifier).state =
                          null;
                    },
                    tooltip: l10n.clearAll,
                  ),
              ],
            ),
          ),

          // Expanded category grid
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // "All" chip
                  _CategoryChip(
                    icon: Icons.apps,
                    label: l10n.allIngredients,
                    isSelected: selectedCategory == null,
                    onTap: () {
                      ref.read(productCategoryFilterProvider.notifier).state =
                          null;
                      setState(() => _isExpanded = false);
                    },
                  ),
                  // Category chips
                  ...widget.categories.map((category) => _CategoryChip(
                        icon: _categoryIcons[category] ?? Icons.category,
                        label: categoryNames[category] ?? category,
                        isSelected: selectedCategory == category,
                        onTap: () {
                          ref
                              .read(productCategoryFilterProvider.notifier)
                              .state = category;
                          setState(() => _isExpanded = false);
                        },
                      )),
                ],
              ),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),

          const Divider(height: 1),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: isSelected ? colorScheme.primaryContainer : colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color:
                    isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color:
                      isSelected ? colorScheme.primary : colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  final AppLocalizations l10n;
  final String searchQuery;

  const _EmptyState({required this.l10n, required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasSearchQuery = searchQuery.isNotEmpty;
    final categoryFilter = ref.watch(productCategoryFilterProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CockatLogo.watermark(),
            const SizedBox(height: 24),
            Text(
              hasSearchQuery
                  ? '"$searchQuery"에 대한 결과가 없어요'
                  : l10n.noResultsFound,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasSearchQuery
                  ? '다른 검색어를 입력하거나\n필터를 변경해보세요'
                  : l10n.tryDifferentSearch,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Action buttons
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (hasSearchQuery)
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.read(productSearchQueryProvider.notifier).state = '';
                    },
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('검색어 지우기'),
                  ),
                if (categoryFilter != null)
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.read(productCategoryFilterProvider.notifier).state =
                          null;
                    },
                    icon: const Icon(Icons.filter_alt_off, size: 18),
                    label: const Text('필터 초기화'),
                  ),
              ],
            ),
          ],
        ),
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
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ProductCard(product: products[index]);
      },
    );
  }
}

