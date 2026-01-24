import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AnimatedSelectionIndicator extends StatelessWidget {
  final bool isSelected;
  final double size;

  const AnimatedSelectionIndicator({
    super.key,
    required this.isSelected,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected
            ? theme.colorScheme.primary
            : AppColors.white.withValues(alpha: 0.9),
        border: Border.all(
          color: isSelected
              ? AppColors.white
              : theme.colorScheme.outline,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray900.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isSelected
          ? Icon(
              Icons.check,
              size: size * 0.6,
              color: theme.colorScheme.onPrimary,
            )
          : null,
    );
  }
}
