import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SelectionIndicator extends StatelessWidget {
  final bool isSelected;
  final double size;
  final Color? selectedColor;
  final Color? unselectedColor;

  const SelectionIndicator({
    super.key,
    required this.isSelected,
    this.size = 24,
    this.selectedColor,
    this.unselectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveSelectedColor = selectedColor ?? theme.colorScheme.primary;
    final effectiveUnselectedColor = unselectedColor ??
        theme.colorScheme.onSurface.withValues(alpha: 0.3);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Selected: filled with primary color
        color: isSelected ? effectiveSelectedColor : theme.colorScheme.surface,
        // Unselected: outlined
        border: isSelected
            ? null
            : Border.all(
                color: effectiveUnselectedColor,
                width: 2,
              ),
        // Shadow for better visibility on any background
        boxShadow: [
          BoxShadow(
            color: AppColors.gray900.withValues(alpha: 0.2),
            blurRadius: 4,
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
