import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';

/// Image display mode based on context
enum ImageDisplayMode {
  /// For lists, grids, cards (uses thumbnail, ~300px)
  thumbnail,

  /// For detail screens, full view (uses original)
  full,
}

/// Cached image widget for Supabase Storage images
///
/// Automatically selects between thumbnail and original based on [mode].
/// Provides fallback logic when one URL is missing.
/// Features shimmer loading animation and improved error states.
class StorageImage extends StatelessWidget {
  final String? imageUrl;
  final String? thumbnailUrl;
  final ImageDisplayMode mode;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const StorageImage({
    super.key,
    this.imageUrl,
    this.thumbnailUrl,
    this.mode = ImageDisplayMode.thumbnail,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  /// Determine which URL to display based on mode and availability
  String? get _displayUrl {
    switch (mode) {
      case ImageDisplayMode.thumbnail:
        // Prefer thumbnail, fallback to original
        if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) {
          return thumbnailUrl;
        }
        return imageUrl;
      case ImageDisplayMode.full:
        // Prefer original, fallback to thumbnail
        if (imageUrl != null && imageUrl!.isNotEmpty) {
          return imageUrl;
        }
        return thumbnailUrl;
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = _displayUrl;

    if (url == null || url.isEmpty) {
      return _buildPlaceholder(context);
    }

    Widget image = CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (context, url) =>
          placeholder ?? ShimmerPlaceholder(
            width: width,
            height: height,
            borderRadius: borderRadius,
          ),
      errorWidget: (context, url, error) =>
          errorWidget ?? ErrorPlaceholder(
            width: width,
            height: height,
            borderRadius: borderRadius,
          ),
      // Memory cache optimization for thumbnails
      memCacheWidth: mode == ImageDisplayMode.thumbnail ? 300 : null,
      memCacheHeight: mode == ImageDisplayMode.thumbnail ? 300 : null,
    );

    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 32,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}

/// Shimmer loading placeholder with smooth animation
class ShimmerPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final IconData? icon;

  const ShimmerPlaceholder({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Use theme-appropriate shimmer colors
    final baseColor = isDark
        ? AppColors.navyLight
        : theme.colorScheme.surfaceContainerHighest;
    final highlightColor = isDark
        ? AppColors.gray600
        : theme.colorScheme.surfaceContainerLow;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: borderRadius,
        ),
        child: icon != null
            ? Center(
                child: Icon(
                  icon,
                  size: 48,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              )
            : null,
      ),
    );
  }
}

/// Error placeholder with improved visual feedback
class ErrorPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final String? message;
  final VoidCallback? onRetry;

  const ErrorPlaceholder({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.navyLight.withValues(alpha: 0.5)
            : theme.colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: borderRadius,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: 40,
            color: isDark
                ? AppColors.gray300
                : theme.colorScheme.error.withValues(alpha: 0.7),
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                message!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? AppColors.gray300
                      : theme.colorScheme.onErrorContainer,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('다시 시도'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
