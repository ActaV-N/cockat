import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 다크모드 지원을 위한 ThemeExtension
///
/// 사용법:
/// ```dart
/// // Context를 통해 접근
/// context.appColors.background
/// context.appColors.textPrimary
/// ```
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color background;
  final Color textPrimary;
  final Color textSecondary;
  final Color card;
  final Color divider;
  final Color navBar;
  final Color overlay;

  const AppColorsExtension({
    required this.background,
    required this.textPrimary,
    required this.textSecondary,
    required this.card,
    required this.divider,
    required this.navBar,
    required this.overlay,
  });

  @override
  ThemeExtension<AppColorsExtension> copyWith({
    Color? background,
    Color? textPrimary,
    Color? textSecondary,
    Color? card,
    Color? divider,
    Color? navBar,
    Color? overlay,
  }) {
    return AppColorsExtension(
      background: background ?? this.background,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      card: card ?? this.card,
      divider: divider ?? this.divider,
      navBar: navBar ?? this.navBar,
      overlay: overlay ?? this.overlay,
    );
  }

  @override
  ThemeExtension<AppColorsExtension> lerp(
    ThemeExtension<AppColorsExtension>? other,
    double t,
  ) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      background: Color.lerp(background, other.background, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      card: Color.lerp(card, other.card, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      navBar: Color.lerp(navBar, other.navBar, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
    );
  }

  /// Light theme preset
  static const light = AppColorsExtension(
    background: AppColors.backgroundColor,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    card: AppColors.cardColor,
    divider: AppColors.dividerColor,
    navBar: AppColors.white,
    overlay: AppColors.gray900,
  );

  /// Dark theme preset
  static const dark = AppColorsExtension(
    background: AppColors.backgroundColorDark,
    textPrimary: AppColors.textPrimaryDark,
    textSecondary: AppColors.textSecondaryDark,
    card: AppColors.cardColorDark,
    divider: AppColors.dividerColorDark,
    navBar: AppColors.navBarDark,
    overlay: AppColors.gray900,
  );
}

/// Context extension for easy access
extension AppColorsContext on BuildContext {
  AppColorsExtension get appColors =>
      Theme.of(this).extension<AppColorsExtension>() ?? AppColorsExtension.light;
}
