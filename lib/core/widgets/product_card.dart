import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../data/providers/providers.dart';
import '../theme/app_colors.dart';
import 'animated_selection_indicator.dart';
import 'product_image.dart';
import 'storage_image.dart';

/// Redesigned Product Card with improved information hierarchy
///
/// Information hierarchy:
/// 1. Product Image (60-70% of card)
/// 2. Brand name (small, primary color)
/// 3. Product name (medium, bold)
/// 4. Specs: Volume | ABV (small, gray)
class ProductCard extends ConsumerWidget {
  final Product product;
  final bool showSelectionIndicator;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.showSelectionIndicator = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(effectiveIsProductSelectedProvider(product.id));
    final locale = ref.watch(currentLocaleCodeProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine card colors based on brightness
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.navyLight : colorScheme.surface;
    final selectedCardColor = isDark
        ? AppColors.navyLight.withValues(alpha: 0.8)
        : colorScheme.primaryContainer.withValues(alpha: 0.3);
    final borderColor = isDark
        ? AppColors.gray600
        : colorScheme.outlineVariant;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: isSelected ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected
            ? BorderSide(color: AppColors.coralPeach, width: 3)
            : BorderSide(color: borderColor, width: 0.5),
      ),
      color: isSelected ? selectedCardColor : cardColor,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          if (onTap != null) {
            onTap!();
          } else {
            ref.read(effectiveProductsServiceProvider).toggle(product.id);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product Image (top, 60-70% of card)
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                      child: ProductImage(
                        product: product,
                        mode: ImageDisplayMode.thumbnail,
                      ),
                    ),
                  ),
                  // Selection indicator (top-right)
                  if (showSelectionIndicator)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: AnimatedSelectionIndicator(
                        isSelected: isSelected,
                        size: 24,
                      ),
                    ),
                ],
              ),
            ),

            // Info section (bottom)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Brand (small, accent color) - first in hierarchy
                  if (product.brand != null)
                    Text(
                      product.brand!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark ? AppColors.coralLight : AppColors.coralDeep,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                  // Product name (medium, bold)
                  Text(
                    product.getLocalizedName(locale),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Specs: Volume | ABV (small, gray)
                  if (product.formattedVolume != null || product.abv != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _formatSpecs(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
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
    return specs.join(' · ');
  }
}
