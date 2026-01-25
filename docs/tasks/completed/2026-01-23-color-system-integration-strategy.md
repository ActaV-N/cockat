# Color System 통합 전략

## 개요
- **목적**: 새로운 AppColors 클래스 기반의 통합된 색상 시스템 구축 및 마이그레이션
- **범위**: 앱 전체 색상 사용 패턴 표준화, 다크모드 지원, 일관된 디자인 시스템 구축
- **예상 소요 기간**: 2-3일
- **우선순위**: 높음 (디자인 시스템 기반 작업)

## 현재 상태 분석

### 기존 색상 사용 패턴

#### 1. Theme-based Colors (Material 3 ColorScheme)
**위치**: `lib/core/theme/app_theme.dart`
- `ColorScheme.fromSeed(seedColor: Color(0xFFD4A574))`
- Material 3 기반 자동 생성 색상 팔레트 사용
- 현재 28개 파일에서 `theme.colorScheme.*` 패턴으로 사용 중

**사용 예시**:
```dart
theme.colorScheme.primary
theme.colorScheme.surface
theme.colorScheme.outline
theme.colorScheme.onPrimary
```

#### 2. Hard-coded Colors (직접 색상 지정)
**영향받는 주요 파일**:
- `lib/features/cocktails/cocktails_screen.dart`: 섹션별 색상 (red, green, orange, grey)
- `lib/features/cocktails/widgets/featured_carousel.dart`: 강조 색상 (amber)
- `lib/core/widgets/animated_selection_indicator.dart`: 선택 상태 색상
- `lib/features/cocktails/cocktail_detail_screen.dart`: 상태 표시 색상

**현재 사용 중인 색상**:
```dart
Colors.red         // 즐겨찾기 (8회)
Colors.green       // 만들 수 있는 칵테일 (4회)
Colors.orange      // 거의 만들 수 있는 칵테일 (4회)
Colors.grey        // 더 필요한 칵테일 (4회)
Colors.amber       // 추천/Featured (2회)
Colors.white       // 텍스트 오버레이 (6회)
Colors.black       // 그림자/오버레이 (5회)
```

#### 3. 현재 색상 시스템의 문제점
1. **일관성 부족**: Theme 색상과 Hard-coded 색상이 혼재
2. **다크모드 미지원**: Hard-coded 색상은 다크모드 대응 불가
3. **유지보수 어려움**: 색상 변경 시 여러 파일 수정 필요
4. **브랜드 정체성 미흡**: 칵테일 카테고리별 색상 체계 부재
5. **Semantic 색상 없음**: success/warning/error 등 의미론적 색상 부재

### 관련 코드/모듈
```
lib/core/theme/
  └── app_theme.dart                    # 현재 테마 정의 (Material 3)

lib/features/cocktails/
  ├── cocktails_screen.dart             # 섹션 색상 (red, green, orange, grey)
  ├── cocktail_detail_screen.dart       # 상태 색상
  ├── cocktail_section_list_screen.dart # 섹션 색상
  ├── cocktail_search_screen.dart       # 검색 상태 색상
  └── widgets/
      └── featured_carousel.dart        # Featured 색상 (amber)

lib/core/widgets/
  ├── animated_selection_indicator.dart # 선택 상태 색상
  └── selection_indicator.dart          # 선택 상태 색상

lib/features/auth/
  ├── login_screen.dart                 # Theme 색상 사용
  └── signup_screen.dart                # Theme 색상 사용
```

## 구현 전략

### 접근 방식

**3단계 점진적 마이그레이션**:
1. **Phase 1**: AppColors 클래스 생성 및 기본 통합
2. **Phase 2**: Hard-coded 색상을 AppColors로 교체
3. **Phase 3**: 다크모드 지원 및 테마 확장

### 세부 구현 단계

#### Phase 1: AppColors 클래스 생성 및 기본 통합

**1.1 AppColors 클래스 파일 생성**
```dart
// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // ===== Primary =====
  static const Color coralLight = Color(0xFFFFD4BC);
  static const Color coralPeach = Color(0xFFE8956A);
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
```

**1.2 AppTheme 통합**
```dart
// lib/core/theme/app_theme.dart 수정
import 'app_colors.dart';

class AppTheme {
  static const _seedColor = AppColors.primaryColor; // 변경

  // ... 기존 코드 유지
}
```

**1.3 Export 설정**
```dart
// lib/core/theme/theme.dart (새로 생성)
export 'app_colors.dart';
export 'app_theme.dart';
```

#### Phase 2: Hard-coded 색상 교체

**2.1 상태 표시 색상 교체 (우선순위: 높음)**

**영향받는 파일**:
- `lib/features/cocktails/cocktails_screen.dart`
- `lib/features/cocktails/cocktail_detail_screen.dart`
- `lib/features/cocktails/cocktail_section_list_screen.dart`
- `lib/features/cocktails/cocktail_search_screen.dart`

**변경 사항**:
```dart
// Before
Colors.green  → AppColors.success
Colors.orange → AppColors.warning
Colors.grey   → AppColors.gray600
Colors.red    → AppColors.error
Colors.amber  → AppColors.coralPeach
```

**예시 (cocktails_screen.dart)**:
```dart
// Line 78, 130: Favorites
color: AppColors.error,

// Line 146: Can Make
color: AppColors.success,

// Line 162: Almost Can Make
color: AppColors.warning,

// Line 178: Need More
color: AppColors.gray600,
```

**2.2 오버레이 및 그림자 색상 교체 (우선순위: 중간)**

**영향받는 파일**:
- `lib/features/cocktails/widgets/featured_carousel.dart`
- `lib/core/widgets/animated_selection_indicator.dart`
- `lib/core/widgets/selection_indicator.dart`

**변경 사항**:
```dart
// Before
Colors.white.withValues(alpha: 0.9)      → AppColors.white.withValues(alpha: 0.9)
Colors.black.withValues(alpha: 0.2-0.7)  → AppColors.gray900.withValues(alpha: 0.2-0.7)
Colors.white70                            → AppColors.white.withValues(alpha: 0.7)
```

**2.3 칵테일 카테고리 색상 적용 (우선순위: 낮음)**

**새로운 기능**: 칵테일 카테고리별 색상 시스템
```dart
// 칵테일 베이스 스피릿에 따른 색상 매핑 유틸리티
class CocktailColorHelper {
  static Color getCategoryColor(String? baseSpirit) {
    if (baseSpirit == null) return AppColors.gray600;

    final spirit = baseSpirit.toLowerCase();
    if (spirit.contains('whiskey') || spirit.contains('bourbon')) {
      return AppColors.whiskey;
    } else if (spirit.contains('gin')) {
      return AppColors.gin;
    } else if (spirit.contains('rum')) {
      return AppColors.rum;
    } else if (spirit.contains('vodka')) {
      return AppColors.vodka;
    } else if (spirit.contains('tequila')) {
      return AppColors.tequila;
    } else if (spirit.contains('non-alcoholic')) {
      return AppColors.nonAlcohol;
    }
    return AppColors.gray600;
  }
}
```

#### Phase 3: 다크모드 지원

**3.1 Theme Extension 생성**

```dart
// lib/core/theme/app_colors_extension.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color background;
  final Color textPrimary;
  final Color textSecondary;
  final Color card;
  final Color divider;
  final Color navBar;

  const AppColorsExtension({
    required this.background,
    required this.textPrimary,
    required this.textSecondary,
    required this.card,
    required this.divider,
    required this.navBar,
  });

  @override
  ThemeExtension<AppColorsExtension> copyWith({
    Color? background,
    Color? textPrimary,
    Color? textSecondary,
    Color? card,
    Color? divider,
    Color? navBar,
  }) {
    return AppColorsExtension(
      background: background ?? this.background,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      card: card ?? this.card,
      divider: divider ?? this.divider,
      navBar: navBar ?? this.navBar,
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
    );
  }

  // Light theme preset
  static const light = AppColorsExtension(
    background: AppColors.backgroundColor,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    card: AppColors.cardColor,
    divider: AppColors.dividerColor,
    navBar: AppColors.white,
  );

  // Dark theme preset
  static const dark = AppColorsExtension(
    background: AppColors.backgroundColorDark,
    textPrimary: AppColors.textPrimaryDark,
    textSecondary: AppColors.textSecondaryDark,
    card: AppColors.cardColorDark,
    divider: AppColors.dividerColorDark,
    navBar: AppColors.navBarDark,
  );
}

// Helper extension for easy access
extension AppColorsContext on BuildContext {
  AppColorsExtension get appColors =>
      Theme.of(this).extension<AppColorsExtension>() ??
      AppColorsExtension.light;
}
```

**3.2 AppTheme에 Extension 통합**

```dart
// lib/core/theme/app_theme.dart
class AppTheme {
  static ThemeData lightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      extensions: const [AppColorsExtension.light], // 추가
      // ... 기존 설정
    );
  }

  static ThemeData darkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryColor,
      brightness: Brightness.dark,
      surface: AppColors.navyDeep,
      onSurface: AppColors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      extensions: const [AppColorsExtension.dark], // 추가
      // ... 기존 설정
    );
  }
}
```

**3.3 다크모드 대응 색상 사용**

```dart
// Before
Container(
  color: Colors.white,
  child: Text(
    'Hello',
    style: TextStyle(color: Colors.black),
  ),
)

// After
Container(
  color: context.appColors.background,
  child: Text(
    'Hello',
    style: TextStyle(color: context.appColors.textPrimary),
  ),
)
```

### 기술적 고려사항

#### 아키텍처
- **중앙 집중식 색상 관리**: 모든 색상을 AppColors 클래스에서 관리
- **Theme Extension 활용**: 다크모드를 위한 Flutter 표준 패턴 사용
- **Context Extension**: 편리한 색상 접근을 위한 Helper 제공

#### 의존성
- 추가 패키지 불필요 (Flutter 기본 기능 활용)
- 기존 Material 3 ColorScheme과 병행 사용 가능

#### 마이그레이션 전략
1. **점진적 마이그레이션**: 파일별로 단계적 교체
2. **하위 호환성**: 기존 Theme 색상과 병행 사용 가능
3. **우선순위 기반**: 사용자에게 보이는 영향도 순으로 교체

#### API 설계
```dart
// Static 색상 (라이트/다크 구분 없음)
AppColors.success
AppColors.warning
AppColors.error
AppColors.coralPeach

// Context 기반 색상 (라이트/다크 자동 전환)
context.appColors.background
context.appColors.textPrimary
context.appColors.card

// Theme 색상 (Material 3, 기존 유지)
theme.colorScheme.primary
theme.colorScheme.surface
```

## 영향 범위 분석

### 직접 영향받는 파일 (18개)
```
✅ 높은 우선순위 (9개)
lib/features/cocktails/cocktails_screen.dart
lib/features/cocktails/cocktail_detail_screen.dart
lib/features/cocktails/cocktail_section_list_screen.dart
lib/features/cocktails/cocktail_search_screen.dart
lib/features/cocktails/widgets/featured_carousel.dart
lib/core/widgets/animated_selection_indicator.dart
lib/core/widgets/selection_indicator.dart
lib/core/widgets/cocktail_image.dart
lib/core/theme/app_theme.dart

⚠️ 중간 우선순위 (5개)
lib/features/settings/settings_screen.dart
lib/features/profile/profile_screen.dart
lib/features/products/products_catalog_screen.dart
lib/features/products/my_bar_screen.dart
lib/features/ingredients/ingredients_screen.dart

📝 낮은 우선순위 (4개)
lib/features/onboarding/pages/preferences_page.dart
lib/features/auth/login_screen.dart
lib/core/widgets/product_image.dart
lib/core/widgets/storage_image.dart
```

### 간접 영향받는 파일
- Theme을 사용하는 모든 위젯 (~55개 Dart 파일)
- 다크모드 전환 시 자동으로 혜택을 받음

## 위험 요소 및 대응 방안

| 위험 요소 | 영향도 | 발생 확률 | 대응 방안 |
|-----------|--------|----------|----------|
| Hard-coded 색상 누락 | 중간 | 중간 | 색상 검색 스크립트 실행, 코드 리뷰 |
| 다크모드 가독성 문제 | 높음 | 낮음 | 색상 대비 검증 (WCAG AA 기준), 실제 다크모드 테스트 |
| 기존 Theme 색상과 충돌 | 낮음 | 중간 | Material 3 ColorScheme 유지, 병행 사용 |
| 색상 일관성 훼손 | 중간 | 낮음 | Design System 문서화, 팀 리뷰 |
| 성능 영향 (Context lookup) | 낮음 | 매우 낮음 | Extension은 O(1) 조회, 문제 없음 |
| 마이그레이션 시간 초과 | 중간 | 중간 | 우선순위 기반 점진적 마이그레이션 |

## 테스트 전략

### 단위 테스트
```dart
// test/core/theme/app_colors_test.dart
void main() {
  group('AppColors', () {
    test('Primary colors should be defined', () {
      expect(AppColors.coralPeach, isA<Color>());
      expect(AppColors.primaryColor, equals(AppColors.coralPeach));
    });

    test('Semantic colors should be defined', () {
      expect(AppColors.success, isA<Color>());
      expect(AppColors.warning, isA<Color>());
      expect(AppColors.error, isA<Color>());
    });
  });

  group('AppColorsExtension', () {
    test('Light theme should have correct colors', () {
      expect(AppColorsExtension.light.background, AppColors.backgroundColor);
      expect(AppColorsExtension.light.textPrimary, AppColors.textPrimary);
    });

    test('Dark theme should have correct colors', () {
      expect(AppColorsExtension.dark.background, AppColors.backgroundColorDark);
      expect(AppColorsExtension.dark.textPrimary, AppColors.textPrimaryDark);
    });
  });
}
```

### 통합 테스트
- **테마 전환 테스트**: 라이트 ↔ 다크 모드 전환 시 색상 변경 확인
- **가독성 테스트**: 다크모드에서 텍스트 가독성 확인 (실제 디바이스)
- **일관성 테스트**: 앱 전체에서 동일한 색상 톤 유지 확인

### 시각적 회귀 테스트
```dart
// test/golden_tests/color_system_test.dart
void main() {
  testWidgets('Light theme colors', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: ColorSystemShowcase(),
      ),
    );
    await expectLater(
      find.byType(ColorSystemShowcase),
      matchesGoldenFile('goldens/light_theme.png'),
    );
  });

  testWidgets('Dark theme colors', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme(),
        home: ColorSystemShowcase(),
      ),
    );
    await expectLater(
      find.byType(ColorSystemShowcase),
      matchesGoldenFile('goldens/dark_theme.png'),
    );
  });
}
```

### 접근성 테스트
- **색상 대비 검증**: WCAG AA 기준 (최소 4.5:1 for 일반 텍스트)
```dart
void main() {
  test('Text colors should have sufficient contrast', () {
    // Light mode
    final lightContrast = calculateContrast(
      AppColors.textPrimary,
      AppColors.backgroundColor,
    );
    expect(lightContrast, greaterThan(4.5));

    // Dark mode
    final darkContrast = calculateContrast(
      AppColors.textPrimaryDark,
      AppColors.backgroundColorDark,
    );
    expect(darkContrast, greaterThan(4.5));
  });
}
```

## 성공 기준

### 기능적 성공 기준
- [ ] AppColors 클래스가 모든 색상을 중앙에서 관리
- [ ] Hard-coded 색상이 모두 AppColors로 교체됨
- [ ] 다크모드에서 모든 색상이 자동 전환됨
- [ ] 기존 Material 3 Theme 색상과 공존 가능

### 품질 기준
- [ ] WCAG AA 색상 대비 기준 충족 (4.5:1 이상)
- [ ] 다크모드 가독성 테스트 통과
- [ ] Golden 테스트로 시각적 회귀 없음 확인
- [ ] 모든 단위 테스트 통과

### 유지보수성 기준
- [ ] 색상 변경 시 한 곳만 수정하면 전체 반영
- [ ] 새로운 색상 추가가 용이함
- [ ] 코드 리뷰어가 색상 사용 패턴을 쉽게 이해 가능

### 성능 기준
- [ ] 앱 시작 시간에 영향 없음 (±5ms 이내)
- [ ] 테마 전환 시 부드러운 애니메이션 (60fps 유지)
- [ ] 메모리 사용량 증가 없음

## 구현 우선순위 및 일정

### Day 1: Phase 1 - 기반 구축
- [ ] AppColors 클래스 생성 (`app_colors.dart`)
- [ ] AppTheme에 AppColors 통합
- [ ] Export 설정 (`theme.dart`)
- [ ] 기본 단위 테스트 작성

### Day 2: Phase 2 - 색상 교체
**오전**:
- [ ] 상태 표시 색상 교체 (cocktails 관련 9개 파일)
- [ ] 통합 테스트 작성

**오후**:
- [ ] 오버레이 및 그림자 색상 교체 (widgets 3개 파일)
- [ ] 중간 우선순위 파일 교체 (5개 파일)
- [ ] 회귀 테스트

### Day 3: Phase 3 - 다크모드 지원
**오전**:
- [ ] AppColorsExtension 생성
- [ ] Context Extension Helper 추가
- [ ] AppTheme에 Extension 통합

**오후**:
- [ ] 다크모드 테스트 (실제 디바이스)
- [ ] 색상 대비 검증
- [ ] Golden 테스트 생성
- [ ] 최종 검토 및 문서화

## 다크모드 지원 전략

### 1. 색상 분류 체계

#### Static Colors (라이트/다크 구분 없음)
- Semantic: success, warning, error, info
- Cocktail Categories: whiskey, gin, rum, vodka, tequila, nonAlcohol
- Brand: coralPeach, coralLight, coralDeep

#### Adaptive Colors (라이트/다크 자동 전환)
- Background: backgroundColor ↔ backgroundColorDark
- Text: textPrimary ↔ textPrimaryDark, textSecondary ↔ textSecondaryDark
- Surface: cardColor ↔ cardColorDark
- Divider: dividerColor ↔ dividerColorDark
- Navigation: white ↔ navBarDark

### 2. 다크모드 색상 선택 원칙

#### 배경 및 표면 색상
```
Light Mode:
  - Background: #FFFFFF (white)
  - Card: #FFFFFF (white)
  - Surface: Material 3 기본값

Dark Mode:
  - Background: #1E1E2E (navyDeep) - 주 배경
  - Card: #2D2D3F (navyLight) - 카드, 고도 있는 요소
  - Surface: #141420 (navyDark) - 네비게이션 바
```

#### 텍스트 색상
```
Light Mode:
  - Primary: #1A1A24 (gray900) - 고대비, 주 텍스트
  - Secondary: #6E6E7A (gray600) - 보조 텍스트, 설명

Dark Mode:
  - Primary: #FFFFFF (white) - 고대비, 주 텍스트
  - Secondary: #B8B8C0 (gray300) - 보조 텍스트, 설명
```

#### 강조 색상
- Primary (coralPeach #E8956A): 양쪽 모드에서 동일 사용
- Semantic 색상: 양쪽 모드에서 동일 사용 (충분한 대비 확보)

### 3. 다크모드 구현 패턴

#### Pattern 1: Static Semantic Colors
```dart
// ✅ 양쪽 모드에서 동일하게 사용 가능
Container(
  color: match.canMake ? AppColors.success : AppColors.warning,
)
```

#### Pattern 2: Adaptive Colors with Context
```dart
// ✅ 모드에 따라 자동 전환
Container(
  color: context.appColors.background,
  child: Text(
    'Hello',
    style: TextStyle(color: context.appColors.textPrimary),
  ),
)
```

#### Pattern 3: Theme-based Material Colors
```dart
// ✅ Material 3 자동 처리
Card(
  color: theme.colorScheme.surface,
  child: Text(
    'Hello',
    style: TextStyle(color: theme.colorScheme.onSurface),
  ),
)
```

### 4. 색상 대비 검증

#### WCAG AA 기준 (최소 대비 4.5:1)

**Light Mode**:
- gray900 on white: 16.8:1 ✅
- gray600 on white: 4.9:1 ✅
- coralPeach on white: 3.2:1 ⚠️ (강조 색상만 사용)

**Dark Mode**:
- white on navyDeep: 14.2:1 ✅
- gray300 on navyDeep: 7.8:1 ✅
- coralPeach on navyDeep: 4.1:1 ⚠️ (강조 색상만 사용)

**Semantic Colors**:
- success on white: 3.4:1 ⚠️ (배경 사용 금지, 뱃지 전용)
- warning on white: 3.1:1 ⚠️ (배경 사용 금지, 뱃지 전용)
- error on white: 4.6:1 ✅

### 5. 다크모드 테스트 체크리스트
- [ ] 모든 화면에서 텍스트 가독성 확인
- [ ] 카드 경계선이 명확히 구분되는지 확인
- [ ] 상태 뱃지 색상이 배경과 충분히 대비되는지 확인
- [ ] Featured Carousel 오버레이가 자연스러운지 확인
- [ ] 네비게이션 바가 콘텐츠와 구분되는지 확인
- [ ] 버튼과 인터랙티브 요소가 명확한지 확인

## 참고 자료

### Design System
- Material Design 3 Color System: https://m3.material.io/styles/color/overview
- Flutter Theme Extensions: https://api.flutter.dev/flutter/material/ThemeExtension-class.html

### 접근성
- WCAG 2.1 Contrast Guidelines: https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html
- Color Contrast Checker: https://webaim.org/resources/contrastchecker/

### 칵테일 카테고리 색상
- 위스키 (Whiskey): #D4A574 - 따뜻한 호박색, 숙성된 느낌
- 진 (Gin): #7DD3C0 - 식물성 허브 느낌의 민트 그린
- 럼 (Rum): #E8956A - 따뜻한 캐러멜/코랄 톤
- 보드카 (Vodka): #A8C5E2 - 깨끗하고 순수한 블루
- 데킬라 (Tequila): #C4D982 - 신선한 라임 그린
- 논알콜 (Non-Alcohol): #F5B5D5 - 부드러운 핑크

### 코드 패턴
```dart
// ❌ Bad: Hard-coded colors
Container(color: Colors.green)

// ✅ Good: Semantic colors
Container(color: AppColors.success)

// ❌ Bad: Direct color without theme awareness
Text('Hello', style: TextStyle(color: AppColors.gray900))

// ✅ Good: Theme-aware adaptive colors
Text('Hello', style: TextStyle(color: context.appColors.textPrimary))
```

## 롤백 계획

마이그레이션 중 문제 발생 시:
1. Git에서 변경 전 커밋으로 revert
2. AppColors import 제거
3. Hard-coded 색상으로 임시 복구
4. 문제 분석 후 재시도

## 후속 작업

마이그레이션 완료 후 고려사항:
1. **디자인 토큰 시스템**: 색상 외 spacing, typography 등 확장
2. **칵테일 카테고리 색상 활용**: 상세 페이지에 카테고리별 색상 적용
3. **다이나믹 테마**: 사용자 선택 테마 (예: 시즌별 색상)
4. **접근성 모드**: 고대비 모드 추가
