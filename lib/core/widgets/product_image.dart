import 'package:flutter/material.dart';

import '../../data/models/product.dart';
import '../theme/app_colors.dart';
import 'storage_image.dart';

/// Product-specific image widget with appropriate placeholder
///
/// Features:
/// - Shimmer loading animation
/// - Product-specific placeholder icon (liquor bottle)
/// - Error state with visual feedback
/// - Optimized caching strategy
class ProductImage extends StatelessWidget {
  final Product product;
  final ImageDisplayMode mode;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ProductImage({
    super.key,
    required this.product,
    this.mode = ImageDisplayMode.thumbnail,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return StorageImage(
      imageUrl: product.imageUrl,
      thumbnailUrl: product.thumbnailUrl,
      mode: mode,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
      placeholder: ProductShimmerPlaceholder(
        width: width,
        height: height,
        borderRadius: borderRadius,
      ),
      errorWidget: ProductErrorPlaceholder(
        width: width,
        height: height,
        borderRadius: borderRadius,
        productName: product.name,
      ),
    );
  }
}

/// Shimmer placeholder specifically designed for product images
class ProductShimmerPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const ProductShimmerPlaceholder({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerPlaceholder(
      width: width,
      height: height,
      borderRadius: borderRadius,
      icon: Icons.liquor,
    );
  }
}

/// Error placeholder specifically designed for product images
class ProductErrorPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final String? productName;

  const ProductErrorPlaceholder({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.productName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.navyLight,
                  AppColors.navyLight.withValues(alpha: 0.7),
                ]
              : [
                  theme.colorScheme.surfaceContainerHighest,
                  theme.colorScheme.surfaceContainerHigh,
                ],
        ),
        borderRadius: borderRadius,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bottle icon with subtle styling
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.liquor,
              size: 36,
              color: isDark
                  ? AppColors.gray300
                  : theme.colorScheme.outline,
            ),
          ),
          // Product name fallback (if space allows)
          if (productName != null && (height == null || height! > 120)) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                productName!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? AppColors.gray300.withValues(alpha: 0.7)
                      : theme.colorScheme.outline.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
