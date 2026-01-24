import 'package:flutter/material.dart';

/// 앱 전체에서 사용하는 색상 시스템
///
/// 사용 패턴:
/// - Static 색상: `AppColors.success` (라이트/다크 구분 없음)
/// - Adaptive 색상: `context.appColors.background` (테마에 따라 자동 전환)
class AppColors {
  AppColors._();

  // ===== Primary =====
  static const Color coralLight = Color(0xFFFFD4BC);
  static const Color coralPeach = Color(0xFFFFB088);
  static const Color coralDeep = Color(0xFFE8956A);

  // ===== Dark =====
  static const Color navyLight = Color(0xFF2D2D3F);
  static const Color navyDeep = Color(0xFF1E1E2E);
  static const Color navyDark = Color(0xFF141420);

  // ===== Neutral =====
  static const Color white = Color(0xFFFFFFFF);
  static const Color gray50 = Color(0xFFF8F8FA);
  static const Color gray100 = Color(0xFFECECF0);
  static const Color gray300 = Color(0xFFB8B8C0);
  static const Color gray600 = Color(0xFF6E6E7A);
  static const Color gray900 = Color(0xFF1A1A24);

  // ===== Semantic =====
  static const Color success = Color(0xFF5BBD72);
  static const Color warning = Color(0xFFF5A623);
  static const Color error = Color(0xFFE85A5A);
  static const Color info = Color(0xFF5B9BD5);

  // ===== Cocktail Categories =====
  static const Color whiskey = Color(0xFFD4A574);
  static const Color gin = Color(0xFF7DD3C0);
  static const Color rum = Color(0xFFE8956A);
  static const Color vodka = Color(0xFFA8C5E2);
  static const Color tequila = Color(0xFFC4D982);
  static const Color nonAlcohol = Color(0xFFF5B5D5);

  // ===== Theme Shortcuts =====
  static const Color primaryColor = coralPeach;
  static const Color backgroundColor = white;
  static const Color backgroundColorDark = navyDeep;
  static const Color textPrimary = gray900;
  static const Color textPrimaryDark = white;
  static const Color textSecondary = gray600;
  static const Color textSecondaryDark = gray300;
  static const Color cardColor = white;
  static const Color cardColorDark = navyLight;
  static const Color dividerColor = gray100;
  static const Color dividerColorDark = navyLight;
  static const Color disabledColor = gray300;
  static const Color tabActive = coralPeach;
  static const Color tabInactive = gray300;
  static const Color tabInactiveDark = gray600;
  static const Color navBarDark = navyDark;
}
