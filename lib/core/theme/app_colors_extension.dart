import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 다크모드 지원을 위한 ThemeExtension
///
/// 사용법:
/// ```dart
/// // Context를 통해 접근
/// context.appColors.background
/// context.appColors.textPrimary
/// context.appColors.primary
/// ```
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  // Core colors
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color card;
  final Color cardElevated;

  // Text colors
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  // UI Elements
  final Color divider;
  final Color navBar;
  final Color overlay;
  final Color shimmerBase;
  final Color shimmerHighlight;

  // Accent colors
  final Color primary;
  final Color primaryVariant;
  final Color accent;
  final Color accentVariant;

  // Interactive elements
  final Color favoriteButton;
  final Color badge;

  const AppColorsExtension({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.card,
    required this.cardElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.divider,
    required this.navBar,
    required this.overlay,
    required this.shimmerBase,
    required this.shimmerHighlight,
    required this.primary,
    required this.primaryVariant,
    required this.accent,
    required this.accentVariant,
    required this.favoriteButton,
    required this.badge,
  });

  @override
  ThemeExtension<AppColorsExtension> copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? card,
    Color? cardElevated,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? divider,
    Color? navBar,
    Color? overlay,
    Color? shimmerBase,
    Color? shimmerHighlight,
    Color? primary,
    Color? primaryVariant,
    Color? accent,
    Color? accentVariant,
    Color? favoriteButton,
    Color? badge,
  }) {
    return AppColorsExtension(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      card: card ?? this.card,
      cardElevated: cardElevated ?? this.cardElevated,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      divider: divider ?? this.divider,
      navBar: navBar ?? this.navBar,
      overlay: overlay ?? this.overlay,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
      primary: primary ?? this.primary,
      primaryVariant: primaryVariant ?? this.primaryVariant,
      accent: accent ?? this.accent,
      accentVariant: accentVariant ?? this.accentVariant,
      favoriteButton: favoriteButton ?? this.favoriteButton,
      badge: badge ?? this.badge,
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
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardElevated: Color.lerp(cardElevated, other.cardElevated, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      navBar: Color.lerp(navBar, other.navBar, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight: Color.lerp(shimmerHighlight, other.shimmerHighlight, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryVariant: Color.lerp(primaryVariant, other.primaryVariant, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentVariant: Color.lerp(accentVariant, other.accentVariant, t)!,
      favoriteButton: Color.lerp(favoriteButton, other.favoriteButton, t)!,
      badge: Color.lerp(badge, other.badge, t)!,
    );
  }

  /// Light theme preset
  static const light = AppColorsExtension(
    background: AppColors.backgroundColor,
    surface: AppColors.surfaceColor,
    surfaceElevated: AppColors.white,
    card: AppColors.cardColor,
    cardElevated: AppColors.white,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textTertiary: AppColors.gray400,
    divider: AppColors.dividerColor,
    navBar: AppColors.white,
    overlay: AppColors.gray900,
    shimmerBase: AppColors.gray100,
    shimmerHighlight: AppColors.gray50,
    primary: AppColors.coralPeach,
    primaryVariant: AppColors.coralDeep,
    accent: AppColors.purple,
    accentVariant: AppColors.purpleDark,
    favoriteButton: AppColors.favoriteButton,
    badge: AppColors.badgeBackground,
  );

  /// Dark theme preset
  static const dark = AppColorsExtension(
    background: AppColors.backgroundColorDark,
    surface: AppColors.surfaceColorDark,
    surfaceElevated: AppColors.cardElevatedDark,
    card: AppColors.cardColorDark,
    cardElevated: AppColors.cardElevatedDark,
    textPrimary: AppColors.textPrimaryDark,
    textSecondary: AppColors.textSecondaryDark,
    textTertiary: AppColors.gray500,
    divider: AppColors.dividerColorDark,
    navBar: AppColors.navBarDark,
    overlay: AppColors.navy500,
    shimmerBase: AppColors.shimmerBase,
    shimmerHighlight: AppColors.shimmerHighlight,
    primary: AppColors.coralPeach,
    primaryVariant: AppColors.coralLight,
    accent: AppColors.purpleLight,
    accentVariant: AppColors.purple,
    favoriteButton: AppColors.favoriteButton,
    badge: AppColors.badgeBackground,
  );
}

/// Context extension for easy access
extension AppColorsContext on BuildContext {
  AppColorsExtension get appColors =>
      Theme.of(this).extension<AppColorsExtension>() ?? AppColorsExtension.light;
}
