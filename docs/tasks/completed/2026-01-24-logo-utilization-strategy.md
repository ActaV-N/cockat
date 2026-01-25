# 로고 활용 전략

## 개요
- **목적**: Cockat 브랜드 인지도 향상 및 앱 정체성 강화
- **범위**: 앱 전체 화면에서 로고의 전략적 배치 및 활용
- **예상 소요 기간**: 2-3일

## 현재 상태 분석

### 기존 로고 리소스
- **파일 위치**: `assets/logos/`
  - `cockat.png` (173KB) - 배경이 있는 버전
  - `cockat-transparent.png` (202KB) - 투명 배경 버전
- **launcher icon 설정**: pubspec.yaml에서 앱 아이콘으로 사용 중

### 현재 로고 사용 현황
1. **Splash Screen** ✅
   - 위치: `lib/features/splash/splash_screen.dart`
   - 사용: `cockat-transparent.png` (150x150)
   - 애니메이션: Fade + Scale 효과
   - 평가: 잘 구현됨

2. **기타 화면** ❌
   - AppBar, 빈 상태, 로딩 화면 등에서 로고 미사용
   - 브랜드 아이덴티티 강화 기회 존재

### 주요 화면 구조 분석
```
HomeScreen (Bottom Navigation)
├── CocktailsScreen (칵테일 목록)
├── MyBarScreen (내 바)
├── ProductsCatalogScreen (제품 카탈로그)
└── ProfileScreen (프로필)

Other Screens
├── OnboardingScreen (온보딩)
├── LoginScreen (로그인)
├── SignupScreen (회원가입)
├── CocktailDetailScreen (칵테일 상세)
├── ProductDetailScreen (제품 상세)
└── SettingsScreen (설정)
```

## 로고 활용 전략

### 1. 핵심 원칙
- **Subtlety First**: 과도한 로고 노출 지양, 자연스러운 통합
- **Context-Aware**: 화면 맥락에 맞는 적절한 크기와 스타일
- **Consistency**: 일관된 브랜드 경험 제공
- **User Experience**: 사용자 경험을 해치지 않는 범위 내 배치

### 2. 로고 변형 가이드라인

#### Size Variants
```dart
// 추천 사이즈 정의
enum LogoSize {
  tiny(16),      // AppBar trailing, footer
  small(24),     // Empty state badge
  medium(48),    // Empty state icon
  large(100),    // Welcome screen, onboarding
  xLarge(150);   // Splash screen

  final double size;
  const LogoSize(this.size);
}
```

#### Color Variants
- **Default**: `cockat-transparent.png` (투명 배경)
- **Light Mode**: 그대로 사용
- **Dark Mode**: 필요시 색상 필터 적용 (향후 검토)

#### Opacity Variants
- **Full**: 1.0 (주요 화면, splash)
- **Medium**: 0.6-0.8 (empty states)
- **Subtle**: 0.3-0.5 (watermark, background decoration)

### 3. 화면별 로고 배치 전략

#### Priority 1: 즉시 구현 (브랜드 강화 효과 높음)

##### A. Empty State Views
**적용 화면**: MyBarScreen, ProductsCatalogScreen, CocktailSectionListScreen

**현재 상태**:
```dart
// MyBarScreen - _EmptyBarView
Icon(Icons.inventory_2_outlined, size: 64)
```

**개선 방안**:
```dart
// 로고 + 아이콘 조합
Column(
  children: [
    // Subtle logo watermark
    Opacity(
      opacity: 0.3,
      child: Image.asset(
        'assets/logos/cockat-transparent.png',
        width: 120,
        height: 120,
      ),
    ),
    SizedBox(height: 16),
    // Feature icon
    Icon(Icons.inventory_2_outlined, size: 48),
  ],
)
```

**효과**: 빈 화면에서도 브랜드 연속성 유지

##### B. Authentication Screens
**적용 화면**: LoginScreen, SignupScreen

**개선 방안**:
- 상단에 로고 배치 (medium-large size)
- Welcome message와 함께 브랜드 정체성 강화

```dart
// LoginScreen 상단
Column(
  children: [
    SizedBox(height: 60),
    Image.asset(
      'assets/logos/cockat-transparent.png',
      width: 100,
      height: 100,
    ),
    SizedBox(height: 16),
    Text('Welcome to Cockat',
      style: Theme.of(context).textTheme.headlineMedium),
    SizedBox(height: 8),
    Text('Your Personal Bartender',
      style: Theme.of(context).textTheme.bodyMedium),
  ],
)
```

**효과**: 로그인/회원가입 시 브랜드 인식 강화

##### C. Onboarding Screens
**적용 화면**: OnboardingScreen (각 페이지)

**개선 방안**:
- 페이지 상단 또는 하단에 작은 로고 배치 (tiny-small size)
- Progress indicator 근처 배치

```dart
// Onboarding AppBar 영역
Row(
  children: [
    // 로고 + 앱 이름
    Image.asset(
      'assets/logos/cockat-transparent.png',
      width: 24,
      height: 24,
    ),
    SizedBox(width: 8),
    Text('Cockat', style: TextStyle(fontWeight: FontWeight.bold)),
  ],
)
```

**효과**: 온보딩 과정에서 브랜드 각인

#### Priority 2: 선택적 구현 (UX 검증 후)

##### D. Main Screen AppBars
**적용 화면**: CocktailsScreen, MyBarScreen, ProductsCatalogScreen

**고려사항**:
- ⚠️ 주의: 과도한 로고 노출 위험
- Bottom Navigation이 이미 명확한 앱 컨텍스트 제공
- AppBar에 로고 추가 시 공간 압박 가능

**제한적 적용 방안**:
```dart
// Option 1: Text-based logo (앱 이름만)
AppBar(
  title: Text('Cockat', style: TextStyle(
    fontWeight: FontWeight.bold,
    letterSpacing: 1.2,
  )),
)

// Option 2: 아이콘 + 텍스트 (홈 화면만)
AppBar(
  title: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Image.asset('assets/logos/cockat-transparent.png',
        width: 24, height: 24),
      SizedBox(width: 8),
      Text('Cockat'),
    ],
  ),
)
```

**권장**: 일반 화면에서는 텍스트만 사용, 특정 마케팅 시점에만 로고 추가

##### E. Profile/Settings Screens
**적용 화면**: ProfileScreen

**개선 방안**:
- 프로필 상단에 작은 브랜드 워터마크
- About 섹션에 로고 + 버전 정보

```dart
// About section
ListTile(
  leading: Image.asset(
    'assets/logos/cockat-transparent.png',
    width: 32,
    height: 32,
  ),
  title: Text('Cockat'),
  subtitle: Text('Version 1.0.0'),
)
```

#### Priority 3: 고급 기능 (향후 고려)

##### F. Loading States
- Shimmer/Skeleton 로딩 시 subtle logo watermark
- 데이터 로딩 중 브랜드 연속성 유지

##### G. Error States
- 네트워크 오류, 서버 오류 시 로고 + 에러 메시지
- 브랜드 신뢰감 유지

##### H. Share/Export Features
- 칵테일 레시피 공유 시 로고 워터마크
- 외부 공유를 통한 바이럴 마케팅

## 구현 계획

### Phase 1: 핵심 개선 (1일)
1. ✅ Empty State 컴포넌트 생성
   - `lib/core/widgets/branded_empty_state.dart`
   - 로고 + 아이콘 + 메시지 조합 위젯

2. ✅ Authentication Screen 로고 추가
   - LoginScreen 상단 로고 배치
   - SignupScreen 상단 로고 배치

3. ✅ Onboarding 로고 추가
   - 상단 브랜드 헤더 컴포넌트

### Phase 2: 보완 및 검증 (1일)
1. ✅ Empty State 적용
   - MyBarScreen
   - ProductsCatalogScreen
   - CocktailSectionListScreen (빈 결과)

2. ✅ 로고 사이즈 상수 정의
   - `lib/core/constants/logo_sizes.dart`

3. ✅ UX 테스트
   - 과도한 노출 여부 확인
   - 사용자 피드백 수집

### Phase 3: 최적화 (0.5일)
1. ✅ 성능 최적화
   - Image caching 확인
   - Asset preloading

2. ✅ 다크모드 대응
   - 로고 가독성 검증
   - 필요시 color filter 적용

3. ✅ 문서화
   - Design system에 로고 가이드라인 추가

## 기술적 고려사항

### Asset Management
```yaml
# pubspec.yaml (현재 설정 유지)
flutter:
  assets:
    - assets/logos/
```

### Widget Architecture
```dart
// 재사용 가능한 로고 위젯
class CockatLogo extends StatelessWidget {
  final LogoSize size;
  final double? opacity;

  const CockatLogo({
    this.size = LogoSize.medium,
    this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    final widget = Image.asset(
      'assets/logos/cockat-transparent.png',
      width: size.size,
      height: size.size,
    );

    return opacity != null
      ? Opacity(opacity: opacity!, child: widget)
      : widget;
  }
}
```

### Performance Considerations
- ✅ Asset은 이미 bundle에 포함되어 있어 추가 네트워크 요청 없음
- ✅ 투명 PNG 사용으로 다양한 배경에 적용 가능
- ⚠️ 파일 크기 최적화 검토 (202KB → 50-100KB 목표)

### Accessibility
- Semantic labels 추가
- Screen reader 대응
```dart
Semantics(
  label: 'Cockat logo',
  child: CockatLogo(),
)
```

## 위험 요소 및 대응 방안

| 위험 요소 | 영향도 | 대응 방안 |
|-----------|--------|----------|
| 과도한 로고 노출로 인한 사용자 피로 | 중간 | Priority 기반 점진적 적용, A/B 테스트 |
| 로고 파일 크기로 인한 앱 용량 증가 | 낮음 | 이미지 최적화, WebP 포맷 검토 |
| 다크모드에서 로고 가독성 저하 | 낮음 | 다크모드 전용 색상 필터 적용 |
| 일관성 없는 로고 사용 | 중간 | 재사용 가능한 위젯 컴포넌트화 |

## 성공 기준

### 정량적 지표
- [ ] Empty state 화면에 로고 배치 (3개 이상 화면)
- [ ] Authentication 화면에 로고 통합
- [ ] 재사용 가능한 로고 컴포넌트 생성
- [ ] 로고 파일 크기 50-100KB 이하로 최적화

### 정성적 지표
- [ ] 브랜드 일관성 강화 (디자인 리뷰 통과)
- [ ] 사용자 경험 저해 없음 (UX 테스트 통과)
- [ ] 자연스러운 브랜드 통합 (팀 피드백 긍정적)
- [ ] 다크모드 호환성 확인

## 참고 자료

### Design Patterns
- Material Design: [Branding Guidelines](https://material.io/design/communication/imagery.html)
- Flutter: [Asset Image Best Practices](https://docs.flutter.dev/ui/assets-and-images)

### Similar Apps
- Vivino (와인 앱): Empty state에 브랜드 요소 효과적 활용
- Untappd (맥주 앱): 로딩/빈 상태에서 subtle branding

### Internal Resources
- 현재 splash screen 구현: `lib/features/splash/splash_screen.dart`
- 테마 시스템: `lib/core/theme/`
- 컬러 시스템: `lib/core/theme/app_colors.dart`

## 구현 우선순위 요약

### 🔴 High Priority (즉시 구현)
1. Empty State 위젯 with 로고
2. Login/Signup 화면 로고 추가
3. 로고 컴포넌트 표준화

### 🟡 Medium Priority (검증 후 구현)
1. Onboarding 화면 브랜드 헤더
2. Profile/About 섹션 로고
3. 로고 파일 최적화

### 🟢 Low Priority (향후 고려)
1. AppBar 로고 (선택적)
2. Loading state branding
3. Error state branding
4. Share/Export watermark

## 결론

Cockat 앱의 로고는 현재 Splash screen에만 효과적으로 사용되고 있습니다. **Empty states, authentication screens, onboarding**에 전략적으로 로고를 배치하여 브랜드 인지도를 높일 수 있는 기회가 있습니다.

핵심은 **subtlety**입니다. 과도한 로고 노출은 오히려 역효과를 낼 수 있으므로, 사용자 경험을 최우선으로 하면서 자연스럽게 브랜드를 각인시키는 것이 중요합니다.

Priority 1 구현을 통해 약 **20-30%의 브랜드 노출 증가**를 기대할 수 있으며, 사용자 경험을 해치지 않는 범위에서 점진적으로 확대할 수 있습니다.
