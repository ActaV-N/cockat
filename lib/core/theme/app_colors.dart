import 'package:flutter/material.dart';

/// 앱 전체에서 사용하는 색상 시스템
///
/// 사용 패턴:
/// - Static 색상: `AppColors.success` (라이트/다크 구분 없음)
/// - Adaptive 색상: `context.appColors.background` (테마에 따라 자동 전환)
class AppColors {
  AppColors._();

  // ===== Primary - Premium Gold =====
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFE5C565);
  static const Color goldDark = Color(0xFFC4A052);
  static const Color amber = Color(0xFFB8956A);

  // ===== Accent - Sophisticated Purple =====
  static const Color purple = Color(0xFF6366F1);
  static const Color purpleLight = Color(0xFF818CF8);
  static const Color purpleDark = Color(0xFF4F46E5);

  // ===== Dark - Deep Luxury Navy =====
  static const Color navy50 = Color(0xFF3D4663);
  static const Color navy100 = Color(0xFF2D3548);
  static const Color navy200 = Color(0xFF242B3D);
  static const Color navy300 = Color(0xFF1A1F2E);
  static const Color navy400 = Color(0xFF141820);
  static const Color navy500 = Color(0xFF0F1218);

  // ===== Legacy Primary (하위 호환성) =====
  static const Color coralLight = Color(0xFFFFD4BC);
  static const Color coralPeach = Color(0xFFFFB088);
  static const Color coralDeep = Color(0xFFE8956A);

  // ===== Legacy Dark =====
  static const Color navyLight = navy200;
  static const Color navyDeep = navy300;
  static const Color navyDark = navy400;

  // ===== Neutral =====
  static const Color white = Color(0xFFFFFFFF);
  static const Color gray50 = Color(0xFFF8F8FA);
  static const Color gray100 = Color(0xFFECECF0);
  static const Color gray200 = Color(0xFFD8D8E0);
  static const Color gray300 = Color(0xFFB8B8C0);
  static const Color gray400 = Color(0xFF9898A0);
  static const Color gray500 = Color(0xFF78788A);
  static const Color gray600 = Color(0xFF6E6E7A);
  static const Color gray700 = Color(0xFF4A4A5A);
  static const Color gray800 = Color(0xFF2A2A3A);
  static const Color gray900 = Color(0xFF1A1A24);

  // ===== Semantic =====
  static const Color success = Color(0xFF5BBD72);
  static const Color successLight = Color(0xFF7DD394);
  static const Color warning = Color(0xFFF5A623);
  static const Color warningLight = Color(0xFFFFBE4D);
  static const Color error = Color(0xFFE85A5A);
  static const Color errorLight = Color(0xFFFF7B7B);
  static const Color info = Color(0xFF5B9BD5);
  static const Color infoLight = Color(0xFF7DB8E8);

  // ===== Cocktail Categories =====
  static const Color whiskey = Color(0xFFD4A574);
  static const Color gin = Color(0xFF7DD3C0);
  static const Color rum = Color(0xFFE8956A);
  static const Color vodka = Color(0xFFA8C5E2);
  static const Color tequila = Color(0xFFC4D982);
  static const Color nonAlcohol = Color(0xFFF5B5D5);

  // ===== Gradients =====
  static const List<Color> goldGradient = [
    Color(0xFFD4AF37),
    Color(0xFFC4A052),
    Color(0xFFB8956A),
  ];

  static const List<Color> purpleGradient = [
    Color(0xFF6366F1),
    Color(0xFF818CF8),
  ];

  static const List<Color> navyGradient = [
    Color(0xFF1A1F2E),
    Color(0xFF242B3D),
  ];

  // ===== Theme Shortcuts - Light =====
  static const Color primaryColor = coralPeach;
  static const Color accentColor = purple;
  static const Color backgroundColor = white;
  static const Color surfaceColor = gray50;
  static const Color cardColor = white;
  static const Color textPrimary = gray900;
  static const Color textSecondary = gray600;
  static const Color dividerColor = gray100;
  static const Color disabledColor = gray300;

  // ===== Theme Shortcuts - Dark =====
  static const Color primaryColorDark = coralPeach;
  static const Color accentColorDark = purpleLight;
  static const Color backgroundColorDark = navy300;
  static const Color surfaceColorDark = navy200;
  static const Color cardColorDark = navy200;
  static const Color cardElevatedDark = navy100;
  static const Color textPrimaryDark = white;
  static const Color textSecondaryDark = gray300;
  static const Color dividerColorDark = navy100;
  static const Color navBarDark = navy400;

  // ===== Special UI Elements =====
  static const Color favoriteButton = Color(0x4D6E6E7A); // 반투명 회색
  static const Color favoriteButtonActive = error;
  static const Color shimmerBase = navy200;
  static const Color shimmerHighlight = navy100;
  static const Color badgeBackground = purple;

  // ===== Tab Navigation =====
  static const Color tabActive = coralPeach;
  static const Color tabInactive = gray300;
  static const Color tabInactiveDark = gray600;
}
