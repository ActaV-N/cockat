import 'package:flutter/material.dart';

import '../../data/models/cocktail.dart';
import '../theme/app_colors.dart';
import 'storage_image.dart';

/// Cocktail-specific image widget with appropriate placeholder
///
/// Features:
/// - Shimmer loading animation
/// - Cocktail-specific placeholder icon (cocktail glass)
/// - Error state with gradient background
/// - Optimized caching strategy
class CocktailImage extends StatelessWidget {
  final Cocktail cocktail;
  final ImageDisplayMode mode;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const CocktailImage({
    super.key,
    required this.cocktail,
    this.mode = ImageDisplayMode.thumbnail,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return StorageImage(
      imageUrl: cocktail.imageUrl,
      thumbnailUrl: null, // Cocktail doesn't have thumbnailUrl yet
      mode: mode,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
      placeholder: CocktailShimmerPlaceholder(
        width: width,
        height: height,
        borderRadius: borderRadius,
      ),
      errorWidget: CocktailErrorPlaceholder(
        width: width,
        height: height,
        borderRadius: borderRadius,
        cocktailName: cocktail.name,
      ),
    );
  }
}

/// Shimmer placeholder specifically designed for cocktail images
class CocktailShimmerPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const CocktailShimmerPlaceholder({
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
      icon: Icons.local_bar,
    );
  }
}

/// Error placeholder specifically designed for cocktail images
class CocktailErrorPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final String? cocktailName;

  const CocktailErrorPlaceholder({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.cocktailName,
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
                  AppColors.navyDeep.withValues(alpha: 0.8),
                ]
              : [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.secondaryContainer,
                ],
        ),
        borderRadius: borderRadius,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cocktail glass icon with subtle styling
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_bar,
              size: 36,
              color: isDark
                  ? AppColors.coralPeach
                  : theme.colorScheme.primary,
            ),
          ),
          // Cocktail name fallback (if space allows)
          if (cocktailName != null && (height == null || height! > 120)) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                cocktailName!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? AppColors.gray300
                      : theme.colorScheme.onPrimaryContainer,
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
