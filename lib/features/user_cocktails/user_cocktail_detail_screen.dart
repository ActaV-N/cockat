import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/services/image_upload_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_colors_extension.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/storage_image.dart';
import '../../data/models/models.dart';
import '../../data/providers/providers.dart';
import '../../l10n/app_localizations.dart';
import '../products/product_detail_screen.dart';
import 'create_user_cocktail_screen.dart';

class UserCocktailDetailScreen extends ConsumerStatefulWidget {
  final String cocktailId;

  const UserCocktailDetailScreen({super.key, required this.cocktailId});

  @override
  ConsumerState<UserCocktailDetailScreen> createState() =>
      _UserCocktailDetailScreenState();
}

class _UserCocktailDetailScreenState
    extends ConsumerState<UserCocktailDetailScreen> {
  bool _hasChanges = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cocktailAsync =
        ref.watch(userCocktailWithIngredientsProvider(widget.cocktailId));
    final locale = ref.watch(currentLocaleCodeProvider);

    return cocktailAsync.when(
      data: (cocktail) {
        if (cocktail == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(l10n.errorOccurred)),
          );
        }

        final colors = context.appColors;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              Navigator.of(context).pop(_hasChanges);
            }
          },
          child: Scaffold(
            body: CustomScrollView(
            slivers: [
              // Premium Hero App Bar (표준 칵테일과 동일)
              SliverAppBar(
                expandedHeight: 420,
                pinned: true,
                stretch: true,
                backgroundColor: colors.surface,
                surfaceTintColor: Colors.transparent,
                systemOverlayStyle: SystemUiOverlayStyle.light,
                leading: _FloatingBackButton(
                  onBack: () => Navigator.of(context).pop(_hasChanges),
                ),
                actions: [
                  _FloatingEditButton(
                    onTap: () async {
                      final result = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => CreateUserCocktailScreen(cocktailToEdit: cocktail),
                        ),
                      );
                      if (result == true) {
                        setState(() {
                          _hasChanges = true;
                        });
                        // 모든 관련 provider 무효화하여 데이터 새로고침
                        ref.invalidate(userCocktailsProvider);
                        ref.invalidate(userCocktailIngredientsProvider(widget.cocktailId));
                        ref.invalidate(userCocktailWithIngredientsProvider(widget.cocktailId));
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  _FloatingDeleteButton(
                    onTap: () => _confirmDelete(context, ref, cocktail, l10n),
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Hero Image
                      _buildHeroImage(cocktail, colors),
                      // Premium gradient overlay (5-stop like standard)
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.3),
                              Colors.transparent,
                              Colors.transparent,
                              colors.background.withValues(alpha: 0.8),
                              colors.background,
                            ],
                            stops: const [0.0, 0.2, 0.5, 0.85, 1.0],
                          ),
                        ),
                      ),
                      // Title at bottom
                      Positioned(
                        left: AppTheme.spacingMd,
                        right: AppTheme.spacingMd,
                        bottom: AppTheme.spacingLg,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // "My Recipe" 배지
                            Container(
                              margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingSm,
                                vertical: AppTheme.spacingXs,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.coralPeach.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.edit_note,
                                    size: 14,
                                    color: AppColors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'My Recipe',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: AppColors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            // Title
                            Text(
                              cocktail.getLocalizedName(locale),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: colors.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.background,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats Row
                        _StatsRow(cocktail: cocktail, l10n: l10n),
                        const SizedBox(height: AppTheme.spacingLg),

                        // Ingredients
                        if (cocktail.ingredients.isNotEmpty) ...[
                          _SectionTitle(title: l10n.ingredients),
                          const SizedBox(height: AppTheme.spacingSm),
                          _IngredientsList(
                            ingredients: cocktail.ingredients,
                            l10n: l10n,
                            colors: colors,
                            locale: locale,
                          ),
                          const SizedBox(height: AppTheme.spacingLg),
                        ],

                        // Instructions
                        _SectionTitle(title: l10n.instructions),
                        const SizedBox(height: AppTheme.spacingSm),
                        _InstructionsCard(
                          instructions: cocktail.getLocalizedInstructions(locale),
                        ),

                        // Garnish
                        if (cocktail.getLocalizedGarnish(locale) != null &&
                            cocktail.getLocalizedGarnish(locale)!.isNotEmpty) ...[
                          const SizedBox(height: AppTheme.spacingLg),
                          _SectionTitle(title: l10n.garnish),
                          const SizedBox(height: AppTheme.spacingSm),
                          _GarnishCard(
                            garnish: cocktail.getLocalizedGarnish(locale)!,
                          ),
                        ],

                        // Created date
                        const SizedBox(height: AppTheme.spacingLg),
                        _CreatedDateCard(
                          createdAt: cocktail.createdAt,
                          locale: locale,
                          l10n: l10n,
                          colors: colors,
                        ),

                        // Description (맨 아래)
                        if (cocktail.description != null &&
                            cocktail.description!.isNotEmpty) ...[
                          const SizedBox(height: AppTheme.spacingLg),
                          _SectionTitle(title: l10n.description),
                          const SizedBox(height: AppTheme.spacingSm),
                          Container(
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
                            child: Text(
                              cocktail.getLocalizedDescription(locale) ?? '',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: colors.textSecondary,
                                    height: 1.6,
                                  ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 100), // Bottom padding for nav
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.errorOccurred)),
      ),
    );
  }

  Widget _buildHeroImage(UserCocktail cocktail, AppColorsExtension colors) {
    if (cocktail.imageUrl != null && cocktail.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: cocktail.imageUrl!,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (context, url) => ShimmerPlaceholder(
          borderRadius: BorderRadius.zero,
        ),
        errorWidget: (context, url, error) {
          if (kDebugMode) {
            debugPrint('❌ Hero image load failed: $url');
            debugPrint('   Error: $error');
          }
          return _buildPlaceholderImage(colors);
        },
      );
    }
    return _buildPlaceholderImage(colors);
  }

  Widget _buildPlaceholderImage(AppColorsExtension colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.coralPeach.withValues(alpha: 0.3),
            AppColors.purple.withValues(alpha: 0.2),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.local_bar,
          size: 80,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    UserCocktail cocktail,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteCocktailConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final service = ref.read(userCocktailServiceProvider);
      final imageService = ref.read(imageUploadServiceProvider);

      // 이미지 삭제
      if (cocktail.imageUrl != null) {
        await imageService.deleteCocktailImage(cocktail.imageUrl!);
      }

      // 칵테일 삭제
      final success = await service.deleteCocktail(cocktail.id);

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.cocktailDeleted)),
          );
          Navigator.of(context).pop(true); // 삭제 성공 시 true 반환
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.errorOccurred)),
          );
        }
      }
    }
  }
}

/// Floating Back Button with blur effect (표준 칵테일과 동일)
class _FloatingBackButton extends StatelessWidget {
  final VoidCallback onBack;

  const _FloatingBackButton({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              onPressed: onBack,
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating Edit Button with blur effect
class _FloatingEditButton extends StatelessWidget {
  final VoidCallback onTap;

  const _FloatingEditButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.edit, color: Colors.white, size: 20),
              onPressed: onTap,
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating Delete Button with blur effect
class _FloatingDeleteButton extends StatelessWidget {
  final VoidCallback onTap;

  const _FloatingDeleteButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.white, size: 20),
              onPressed: onTap,
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
    );
  }
}

/// Stats Row (표준 칵테일과 동일 스타일)
class _StatsRow extends StatelessWidget {
  final UserCocktail cocktail;
  final AppLocalizations l10n;

  const _StatsRow({required this.cocktail, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final hasStats = cocktail.abv != null || cocktail.glass != null || cocktail.method != null;

    if (!hasStats) return const SizedBox.shrink();

    return Container(
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (cocktail.abv != null)
            _StatItem(
              icon: Icons.local_bar,
              value: '${cocktail.abv!.toStringAsFixed(0)}%',
              label: 'ABV',
              color: AppColors.coralPeach,
            ),
          if (cocktail.glass != null)
            _StatItem(
              icon: Icons.wine_bar,
              value: cocktail.glass!,
              label: l10n.glass,
              color: AppColors.purple,
            ),
          if (cocktail.method != null)
            _StatItem(
              icon: Icons.blender,
              value: cocktail.method!,
              label: l10n.method,
              color: AppColors.success,
            ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.textTertiary,
                ),
          ),
        ],
      ),
    );
  }
}

/// Section Title (표준 칵테일과 동일 스타일)
class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
        ),
      ],
    );
  }
}

/// Ingredients List with expandable product info (표준 칵테일과 동일)
class _IngredientsList extends ConsumerWidget {
  final List<UserCocktailIngredient> ingredients;
  final AppLocalizations l10n;
  final AppColorsExtension colors;
  final String locale;

  const _IngredientsList({
    required this.ingredients,
    required this.l10n,
    required this.colors,
    required this.locale,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final ingredientsAsync = ref.watch(ingredientsProvider);

    // 사용자 보유 제품/재료 정보
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final selectedProductIds = isAuthenticated
        ? ref.watch(effectiveSelectedProductsProvider)
        : ref.watch(selectedProductsProvider);
    final selectedIngredientIds = isAuthenticated
        ? ref.watch(effectiveSelectedIngredientsProvider)
        : ref.watch(selectedIngredientsProvider);

    // misc_items 관련 데이터 (lime juice 등)
    final selectedMiscItemIds = ref.watch(effectiveSelectedMiscItemsProvider);
    final ingredientMiscMappingAsync = ref.watch(ingredientMiscMappingProvider);
    final miscMapping = ingredientMiscMappingAsync.valueOrNull ?? {};

    final products = productsAsync.valueOrNull ?? [];
    final allIngredients = ingredientsAsync.valueOrNull ?? [];

    // 재료 ID → Ingredient 맵
    final ingredientMap = {for (var i in allIngredients) i.id: i};

    // 선택된 제품들
    final ownedProducts =
        products.where((p) => selectedProductIds.contains(p.id)).toList();

    // 제품 그룹핑: ingredient_id → List<Product>
    final productsByIngredient = <String, List<Product>>{};
    for (final product in ownedProducts) {
      if (product.ingredientId != null) {
        productsByIngredient
            .putIfAbsent(product.ingredientId!, () => [])
            .add(product);
      }
    }

    // misc_items 매핑을 통해 소유한 재료 ID 집합
    final miscOwnedIngredientIds = <String>{};
    for (final entry in miscMapping.entries) {
      if (selectedMiscItemIds.contains(entry.value)) {
        miscOwnedIngredientIds.add(entry.key);
      }
    }

    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Column(
          children: ingredients.map((ing) {
            // DB 재료인 경우 (ingredientId 존재)
            if (ing.ingredientId != null && ing.ingredientId!.isNotEmpty) {
              final ingredientId = ing.ingredientId!;
              final ingredient = ingredientMap[ingredientId];
              final ingredientName =
                  ingredient?.getLocalizedName(locale) ?? ing.displayName;
              final ownedProductsForIng =
                  productsByIngredient[ingredientId] ?? [];
              final directlyOwned = selectedIngredientIds.contains(ingredientId);
              final miscOwned = miscOwnedIngredientIds.contains(ingredientId);
              final isOwned =
                  directlyOwned || ownedProductsForIng.isNotEmpty || miscOwned;

              // 제품이 있는 경우 확장 가능 타일
              if (ownedProductsForIng.isNotEmpty) {
                return _ExpandableIngredientTile(
                  ingredientName: ingredientName,
                  amount: ing.amountWithUnits,
                  isOptional: ing.isOptional,
                  isOwned: isOwned,
                  ownedProducts: ownedProductsForIng,
                  l10n: l10n,
                  colors: colors,
                  locale: locale,
                );
              }

              // 제품 없으면 단순 타일 (소유 상태 표시)
              return _SimpleIngredientTile(
                ingredientName: ingredientName,
                amount: ing.amountWithUnits,
                isOptional: ing.isOptional,
                isOwned: isOwned,
                l10n: l10n,
                colors: colors,
              );
            }

            // 커스텀 재료인 경우
            return _SimpleIngredientTile(
              ingredientName: ing.displayName,
              amount: ing.amountWithUnits,
              isOptional: ing.isOptional,
              isOwned: null, // 커스텀 재료는 소유 상태 표시 안함
              l10n: l10n,
              colors: colors,
              isCustom: true,
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// 단순 재료 타일
class _SimpleIngredientTile extends StatelessWidget {
  final String ingredientName;
  final String amount;
  final bool isOptional;
  final bool? isOwned;
  final AppLocalizations l10n;
  final AppColorsExtension colors;
  final bool isCustom;

  const _SimpleIngredientTile({
    required this.ingredientName,
    required this.amount,
    required this.isOptional,
    required this.isOwned,
    required this.l10n,
    required this.colors,
    this.isCustom = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(
        isOwned == true
            ? Icons.check_circle
            : (isOwned == false ? Icons.circle_outlined : Icons.edit_note),
        color: isOwned == true
            ? AppColors.success
            : (isOwned == false
                ? colors.textTertiary
                : AppColors.coralPeach),
        size: 20,
      ),
      title: Text(
        ingredientName,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontStyle: isOptional ? FontStyle.italic : FontStyle.normal,
            ),
      ),
      subtitle: amount.isNotEmpty
          ? Text(
              amount,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
            )
          : null,
      trailing: isOptional
          ? Chip(
              label: Text(l10n.optional),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              labelPadding: const EdgeInsets.symmetric(horizontal: 6),
              labelStyle: const TextStyle(fontSize: 10),
            )
          : null,
    );
  }
}

/// 확장 가능 재료 타일 (보유 제품 표시)
class _ExpandableIngredientTile extends StatelessWidget {
  final String ingredientName;
  final String amount;
  final bool isOptional;
  final bool isOwned;
  final List<Product> ownedProducts;
  final AppLocalizations l10n;
  final AppColorsExtension colors;
  final String locale;

  const _ExpandableIngredientTile({
    required this.ingredientName,
    required this.amount,
    required this.isOptional,
    required this.isOwned,
    required this.ownedProducts,
    required this.l10n,
    required this.colors,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Icon(
          Icons.check_circle,
          color: AppColors.success,
          size: 20,
        ),
        title: Text(
          ingredientName,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontStyle: isOptional ? FontStyle.italic : FontStyle.normal,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (amount.isNotEmpty)
              Text(
                amount,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
            const SizedBox(height: 2),
            Text(
              '${ownedProducts.length} ${l10n.myBarProducts}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
        trailing: isOptional
            ? Chip(
                label: Text(l10n.optional),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                labelStyle: const TextStyle(fontSize: 10),
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: ownedProducts.map((product) {
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductDetailScreen(productId: product.id),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.liquor,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            product.getLocalizedDisplayName(locale),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: colors.textTertiary,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Instructions Card (표준 칵테일과 동일 스타일 - 번호 있는 단계)
class _InstructionsCard extends StatelessWidget {
  final String instructions;

  const _InstructionsCard({required this.instructions});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final steps = instructions.split('\n').where((s) => s.trim().isNotEmpty).toList();

    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value.trim();
            final cleanStep = step.replaceFirst(RegExp(r'^\d+[\.\)]\s*'), '');

            return Padding(
              padding: EdgeInsets.only(
                bottom: index < steps.length - 1 ? AppTheme.spacingMd : 0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 번호 badge
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.coralPeach,
                          AppColors.coralDeep,
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        cleanStep,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Garnish Card (표준 칵테일과 동일 스타일)
class _GarnishCard extends StatelessWidget {
  final String garnish;

  const _GarnishCard({required this.garnish});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.eco,
                color: AppColors.success,
                size: 22,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Text(
                garnish,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Created Date Card
class _CreatedDateCard extends StatelessWidget {
  final DateTime createdAt;
  final String locale;
  final AppLocalizations l10n;
  final AppColorsExtension colors;

  const _CreatedDateCard({
    required this.createdAt,
    required this.locale,
    required this.l10n,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd(locale);

    return Container(
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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.textTertiary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_today,
              color: colors.textTertiary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.createdAt(dateFormat.format(createdAt)),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
