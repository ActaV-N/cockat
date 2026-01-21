import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

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
      placeholder: (context, url) =>
          placeholder ?? _buildLoadingPlaceholder(context),
      errorWidget: (context, url, error) =>
          errorWidget ?? _buildErrorPlaceholder(context),
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

  Widget _buildLoadingPlaceholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: borderRadius,
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildErrorPlaceholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 32,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}
