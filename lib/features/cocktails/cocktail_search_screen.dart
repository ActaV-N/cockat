import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/widgets.dart';
import '../../data/models/models.dart';
import '../../data/providers/providers.dart';
import '../../l10n/app_localizations.dart';
import 'cocktail_detail_screen.dart';

class CocktailSearchScreen extends ConsumerStatefulWidget {
  const CocktailSearchScreen({super.key});

  @override
  ConsumerState<CocktailSearchScreen> createState() =>
      _CocktailSearchScreenState();
}

class _CocktailSearchScreenState extends ConsumerState<CocktailSearchScreen> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    // Auto-focus the search field when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    // Clear search query when leaving the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cocktailSearchQueryProvider.notifier).state = '';
    });
    super.dispose();
  }

  void _onSearchChanged(String value) {
    ref.read(cocktailSearchQueryProvider.notifier).state = value;
  }

  void _clearSearch() {
    _controller.clear();
    ref.read(cocktailSearchQueryProvider.notifier).state = '';
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final searchQuery = ref.watch(cocktailSearchQueryProvider);
    final matchesAsync = ref.watch(filteredCocktailMatchesProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.searchCocktails,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSearch,
                  )
                : null,
          ),
        ),
      ),
      body: matchesAsync.when(
        data: (matches) {
          // Show empty state when searching with no results
          if (matches.isEmpty && searchQuery.isNotEmpty) {
            return _EmptySearchResult(searchQuery: searchQuery);
          }

          // Show hint when no search query
          if (searchQuery.isEmpty) {
            return _SearchHint();
          }

          // Show search results
          return _SearchResults(matches: matches);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _SearchHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.searchCocktails,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}

class _EmptySearchResult extends StatelessWidget {
  final String searchQuery;

  const _EmptySearchResult({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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

class _SearchResults extends StatelessWidget {
  final List<CocktailMatch> matches;

  const _SearchResults({required this.matches});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        final cocktail = match.cocktail;

        return ListTile(
          leading: CocktailImage(
            cocktail: cocktail,
            mode: ImageDisplayMode.thumbnail,
            width: 48,
            height: 48,
            borderRadius: BorderRadius.circular(8),
          ),
          title: Text(
            cocktail.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: cocktail.abv != null
              ? Text(
                  '${cocktail.abv}% ABV',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                )
              : null,
          trailing: _buildStatusChip(context, match, l10n),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CocktailDetailScreen(cocktailId: cocktail.id),
              ),
            );
          },
        );
      },
    );
  }

  Widget? _buildStatusChip(
      BuildContext context, CocktailMatch match, AppLocalizations l10n) {
    if (match.canMake) {
      return _StatusChip(label: l10n.canMake, color: Colors.green);
    } else if (match.missingCount == 1) {
      return _StatusChip(label: l10n.oneMoreIngredient, color: Colors.orange);
    } else if (match.missingCount > 1) {
      return _StatusChip(
          label: l10n.nMoreIngredients(match.missingCount), color: Colors.grey);
    }
    return null;
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
            ),
      ),
    );
  }
}
