import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/providers.dart';
import '../theme/app_colors.dart';

/// Premium floating favorite button with animation
class FavoriteButton extends ConsumerStatefulWidget {
  final String cocktailId;
  final double size;
  final bool showBackground;

  const FavoriteButton({
    super.key,
    required this.cocktailId,
    this.size = 40,
    this.showBackground = true,
  });

  @override
  ConsumerState<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends ConsumerState<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.3),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.3, end: 1.0),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleFavorite() {
    HapticFeedback.lightImpact();
    _controller.forward(from: 0);

    final favoritesService = ref.read(effectiveFavoritesServiceProvider);
    favoritesService.toggle(widget.cocktailId);
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = ref.watch(effectiveIsFavoriteProvider(widget.cocktailId));

    final iconSize = widget.size * 0.55;

    return GestureDetector(
      onTap: _toggleFavorite,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: widget.showBackground
              ? BoxDecoration(
                  color: isFavorite
                      ? AppColors.error.withValues(alpha: 0.15)
                      : AppColors.favoriteButton,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                )
              : null,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                key: ValueKey(isFavorite),
                size: iconSize,
                color: isFavorite ? AppColors.error : AppColors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
