import 'package:flutter/material.dart';

import '../../data/models/cocktail.dart';
import 'storage_image.dart';

/// Cocktail-specific image widget with appropriate placeholder
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
      placeholder: _CocktailPlaceholder(
        width: width,
        height: height,
        borderRadius: borderRadius,
      ),
      errorWidget: _CocktailPlaceholder(
        width: width,
        height: height,
        borderRadius: borderRadius,
      ),
    );
  }
}

class _CocktailPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const _CocktailPlaceholder({
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Icon(
          Icons.local_bar,
          size: 48,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
