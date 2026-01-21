import 'package:flutter/material.dart';

import '../../data/models/product.dart';
import 'storage_image.dart';

/// Product-specific image widget with appropriate placeholder
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
      placeholder: _ProductPlaceholder(
        width: width,
        height: height,
        borderRadius: borderRadius,
      ),
      errorWidget: _ProductPlaceholder(
        width: width,
        height: height,
        borderRadius: borderRadius,
      ),
    );
  }
}

class _ProductPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const _ProductPlaceholder({
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Icon(
          Icons.liquor,
          size: 48,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}
