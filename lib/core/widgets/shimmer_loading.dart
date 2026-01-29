import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_colors_extension.dart';
import '../theme/app_theme.dart';

/// Shimmer effect widget for loading states
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.isLoading = true,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      colors.card,
                      AppColors.navy200,
                      colors.card,
                    ]
                  : [
                      AppColors.gray200,
                      AppColors.gray100,
                      AppColors.gray200,
                    ],
              stops: [
                0.0,
                0.5 + _animation.value * 0.25,
                1.0,
              ],
              transform: _SlidingGradientTransform(_animation.value),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

/// Shimmer placeholder box
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = AppTheme.radiusSm,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Shimmer skeleton for cocktail card
class CocktailCardSkeleton extends StatelessWidget {
  const CocktailCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ShimmerLoading(
      child: Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusMd),
                  ),
                ),
              ),
            ),
            // Content placeholder
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(
                    width: double.infinity,
                    height: 16,
                    borderRadius: AppTheme.radiusXs,
                  ),
                  const SizedBox(height: 8),
                  ShimmerBox(
                    width: 80,
                    height: 12,
                    borderRadius: AppTheme.radiusXs,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer skeleton for product card
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ShimmerLoading(
      child: Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusMd),
                  ),
                ),
              ),
            ),
            // Content placeholder
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(
                    width: 60,
                    height: 10,
                    borderRadius: AppTheme.radiusXs,
                  ),
                  const SizedBox(height: 8),
                  ShimmerBox(
                    width: double.infinity,
                    height: 14,
                    borderRadius: AppTheme.radiusXs,
                  ),
                  const SizedBox(height: 4),
                  ShimmerBox(
                    width: 100,
                    height: 14,
                    borderRadius: AppTheme.radiusXs,
                  ),
                  const SizedBox(height: 8),
                  ShimmerBox(
                    width: 70,
                    height: 10,
                    borderRadius: AppTheme.radiusXs,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer grid for loading state
class ShimmerGrid extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final double childAspectRatio;
  final Widget Function(BuildContext, int) itemBuilder;

  const ShimmerGrid({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.72,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: AppTheme.spacingSm,
        mainAxisSpacing: AppTheme.spacingSm,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}

/// Sliver version of shimmer grid
class SliverShimmerGrid extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final double childAspectRatio;
  final Widget Function(BuildContext, int) itemBuilder;

  const SliverShimmerGrid({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.72,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: AppTheme.spacingSm,
          mainAxisSpacing: AppTheme.spacingSm,
        ),
        delegate: SliverChildBuilderDelegate(
          itemBuilder,
          childCount: itemCount,
        ),
      ),
    );
  }
}

/// Shimmer list item skeleton
class ListItemSkeleton extends StatelessWidget {
  final double height;
  final bool hasLeading;
  final bool hasTrailing;

  const ListItemSkeleton({
    super.key,
    this.height = 72,
    this.hasLeading = true,
    this.hasTrailing = false,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
        child: Row(
          children: [
            if (hasLeading) ...[
              ShimmerBox(
                width: 48,
                height: 48,
                borderRadius: AppTheme.radiusSm,
              ),
              const SizedBox(width: AppTheme.spacingSm),
            ],
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(
                    width: double.infinity,
                    height: 16,
                    borderRadius: AppTheme.radiusXs,
                  ),
                  const SizedBox(height: 8),
                  ShimmerBox(
                    width: 120,
                    height: 12,
                    borderRadius: AppTheme.radiusXs,
                  ),
                ],
              ),
            ),
            if (hasTrailing) ...[
              const SizedBox(width: AppTheme.spacingSm),
              ShimmerBox(
                width: 24,
                height: 24,
                borderRadius: AppTheme.radiusXs,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
