# Cockat UI 모던화 전략

## 개요
- **목적**: Shop 앱의 모던한 디자인을 참고하여 Cockat 앱의 UI를 고급스럽고 세련된 칵테일 앱에 어울리는 스타일로 개선
- **범위**: 홈 화면, 칵테일 목록/상세, My Bar, 제품 카드, 네비게이션 등 전체 UI 컴포넌트
- **예상 소요 기간**: 3-4주 (단계별 구현)
- **디자인 철학**: Luxury & Modern - 고급스러운 바 분위기 + 모던한 사용성

## 현재 상태 분석

### 기존 색상 시스템 (AppColors)
```dart
// Primary Colors
- coralLight: #FFD4BC
- coralPeach: #FFB088 (Primary)
- coralDeep: #E8956A

// Dark Colors
- navyLight: #2D2D3F
- navyDeep: #1E1E2E
- navyDark: #141420

// Semantic Colors
- success: #5BBD72 (green)
- warning: #F5A623 (orange)
- error: #E85A5A (red)
```

**문제점**:
- Coral 계열이 칵테일 앱의 고급스러움을 표현하기에는 다소 캐주얼함
- Navy 계열이 다소 무겁고 Shop 앱과 같은 세련미 부족
- 카테고리 색상(whiskey, gin, rum 등)이 활용되지 않음

### 기존 UI 구조
1. **홈 화면** (`home_screen.dart`): 4개 탭 네비게이션 (Cocktails, MyBar, Products, Profile)
2. **칵테일 화면** (`cocktails_screen.dart`): 섹션별 그리드 레이아웃, 카드 기반
3. **칵테일 상세** (`cocktail_detail_screen.dart`): SliverAppBar + 콘텐츠
4. **My Bar** (`my_bar_screen.dart`): 재료 그룹별 제품 목록
5. **제품 카드** (`product_card.dart`): 이미지 + 브랜드 + 이름 + 스펙

**장점**:
- Material 3 디자인 시스템 적용
- 다크/라이트 테마 지원
- 구조화된 색상 시스템
- 반응형 그리드 레이아웃

**개선 필요 사항**:
- 카드 스타일이 평면적 (Shop 앱의 입체감 부족)
- 섹션 구분이 약함 (배경색 활용 부족)
- 네비게이션이 일반적 (플로팅 스타일 부재)
- 프로모션/특별 섹션 시각적 강조 부족

## Shop 앱 디자인 분석

### 핵심 디자인 원칙
1. **카드 중심 레이아웃**: 큰 둥근 모서리 (16-20px), 명확한 그림자/경계
2. **배경색 구분**: 섹션별로 다른 배경색으로 시각적 계층 구조
3. **프리미엄 컬러**: 다크 네이비 + 골드/앰버 조합으로 고급스러움 표현
4. **플로팅 네비게이션**: 하단 네비게이션 바가 화면에서 분리되어 있음
5. **수평 스크롤**: 상품 리스트를 수평 스크롤로 배치하여 공간 효율성
6. **아이콘 오버레이**: 이미지 위에 반투명 배경의 아이콘 (좋아요, 카트 등)
7. **브랜드 로고 표시**: 각 카드에 브랜드 로고 명확히 표시
8. **가격 태그**: 이미지 위에 가격 태그 오버레이

### 레이아웃 패턴
```
┌─────────────────────────────┐
│   [Promo Card - Full Width] │ ← 골드/앰버 배경
│     Golden Hour Sale 🎉     │
└─────────────────────────────┘
┌─────────────────────────────┐
│ Section Title      [View >] │ ← 다크 네이비 배경
│ ┌───┐ ┌───┐ ┌───┐ ┌───┐   │ ← 수평 스크롤
│ │ 1 │ │ 2 │ │ 3 │ │ 4 │ → │
│ └───┘ └───┘ └───┘ └───┘   │
└─────────────────────────────┘
```

## 칵테일 앱 맞춤 Color Palette 제안

### 새로운 컬러 시스템

#### Primary Colors (고급 바 분위기)
```dart
// Deep Luxury Navy (Shop 앱 스타일)
static const Color navyPrimary = Color(0xFF1A1F2E);     // 메인 배경
static const Color navySecondary = Color(0xFF242B3D);   // 카드 배경
static const Color navyTertiary = Color(0xFF2D3548);    // 강조 카드

// Premium Gold/Amber (프리미엄 강조)
static const Color goldPrimary = Color(0xFFD4AF37);     // 골드 (프리미엄)
static const Color amberAccent = Color(0xFFC4A052);     // 앰버 (프로모션)
static const Color copperAccent = Color(0xFFB87333);    // 구리 (따뜻함)

// Sophisticated Purple (Shop 앱 액센트)
static const Color purplePrimary = Color(0xFF6366F1);   // 액션 버튼
static const Color purpleLight = Color(0xFF8B5CF6);     // 하이라이트
static const Color purpleDark = Color(0xFF4C51BF);      // 선택 상태
```

#### Semantic Colors (칵테일 상태)
```dart
// 기능적 색상 (가독성 개선)
static const Color successGreen = Color(0xFF10B981);    // 만들 수 있음
static const Color warningAmber = Color(0xFFF59E0B);    // 거의 가능
static const Color errorRose = Color(0xFFEF4444);       // 재료 부족
static const Color infoSky = Color(0xFF0EA5E9);         // 정보 표시
```

#### Cocktail Category Colors (칵테일 카테고리)
```dart
// 주류별 시그니처 색상 (개선)
static const Color whiskeyBrown = Color(0xFFB8860B);    // 다크 골든로드
static const Color ginMint = Color(0xFF2DD4BF);         // 민트 그린
static const Color rumCaramel = Color(0xFFD97706);      // 카라멜
static const Color vodkaClear = Color(0xFF60A5FA);      // 클리어 블루
static const Color tequilaLime = Color(0xFF84CC16);     // 라임 그린
static const Color nonAlcoholPink = Color(0xFFF472B6);  // 핑크
```

#### Neutral Colors (텍스트 & UI 요소)
```dart
static const Color white = Color(0xFFFFFFFF);
static const Color gray50 = Color(0xFFF9FAFB);
static const Color gray100 = Color(0xFFF3F4F6);
static const Color gray200 = Color(0xFFE5E7EB);
static const Color gray300 = Color(0xFFD1D5DB);
static const Color gray400 = Color(0xFF9CA3AF);
static const Color gray600 = Color(0xFF6B7280);
static const Color gray700 = Color(0xFF374151);
static const Color gray900 = Color(0xFF111827);
```

### 다크 테마 적용 (기본)
```dart
// Background Layers
- Level 0 (Scaffold): navyPrimary (#1A1F2E)
- Level 1 (Card): navySecondary (#242B3D)
- Level 2 (Elevated): navyTertiary (#2D3548)

// Text Hierarchy
- Primary Text: white (#FFFFFF)
- Secondary Text: gray300 (#D1D5DB)
- Tertiary Text: gray400 (#9CA3AF)

// Accents
- Primary Action: purplePrimary (#6366F1)
- Premium Feature: goldPrimary (#D4AF37)
- Success State: successGreen (#10B981)
```

### 라이트 테마 (선택적)
```dart
// Background Layers
- Level 0 (Scaffold): gray50 (#F9FAFB)
- Level 1 (Card): white (#FFFFFF)
- Level 2 (Elevated): gray100 (#F3F4F6)

// Text Hierarchy
- Primary Text: gray900 (#111827)
- Secondary Text: gray600 (#6B7280)
- Tertiary Text: gray400 (#9CA3AF)

// Accents
- Primary Action: purplePrimary (#6366F1)
- Premium Feature: goldPrimary (#D4AF37)
- Success State: successGreen (#10B981)
```

## 컴포넌트별 UI 개선 사항

### 1. NavigationBar (Bottom Navigation)

**현재**: 기본 Material 3 NavigationBar
```dart
NavigationBar(
  backgroundColor: colorScheme.surface,
  indicatorColor: AppColors.coralPeach.withValues(alpha: 0.2),
)
```

**개선안**: Shop 앱 스타일 플로팅 네비게이션
```dart
Container(
  margin: EdgeInsets.all(16),  // 화면 가장자리에서 분리
  decoration: BoxDecoration(
    color: navyTertiary,
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.3),
        blurRadius: 20,
        offset: Offset(0, 10),
      ),
    ],
  ),
  child: SafeArea(
    child: NavigationBar(
      backgroundColor: Colors.transparent,
      indicatorColor: purplePrimary.withValues(alpha: 0.2),
      height: 70,
    ),
  ),
)
```

**핵심 변경**:
- 플로팅 스타일 (margin으로 분리)
- 큰 둥근 모서리 (24px)
- 그림자 효과로 입체감
- 투명 배경 + Container로 색상 제어

### 2. CocktailCard (칵테일 카드)

**현재**: 기본 Card + InkWell
```dart
Card(
  elevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  ),
)
```

**개선안**: Shop 앱 스타일 입체 카드
```dart
Card(
  elevation: 4,  // 입체감 증가
  shadowColor: Colors.black.withValues(alpha: 0.3),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),  // 더 큰 radius
  ),
  color: navySecondary,  // 다크 배경
  child: Column(
    children: [
      // Image with gradient overlay
      Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            child: CocktailImage(...),
          ),
          // Gradient overlay for better badge visibility
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.center,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Status badge (top-right)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: successGreen.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 16, color: white),
                  SizedBox(width: 4),
                  Text('Can Make', style: TextStyle(color: white)),
                ],
              ),
            ),
          ),
          // Favorite button (top-left)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.favorite_border, color: white),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
      // Card content
      Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: whiskeyBrown.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Whiskey Base',
                style: TextStyle(
                  color: whiskeyBrown,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 8),
            // Cocktail name
            Text(
              'Old Fashioned',
              style: TextStyle(
                color: white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            // ABV + Rating
            Row(
              children: [
                Icon(Icons.local_bar, size: 14, color: gray400),
                SizedBox(width: 4),
                Text('32%', style: TextStyle(color: gray400, fontSize: 12)),
                SizedBox(width: 12),
                Icon(Icons.star, size: 14, color: goldPrimary),
                SizedBox(width: 4),
                Text('4.8', style: TextStyle(color: gray400, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    ],
  ),
)
```

**핵심 변경**:
- Elevation 증가 (0 → 4)
- 그라디언트 오버레이로 배지 가독성 개선
- 좋아요 버튼을 반투명 원형 배경과 함께 표시
- 카테고리 배지 추가
- 평점 정보 추가 (추후 구현)
- 색상 대비 개선 (다크 배경 + 화이트 텍스트)

### 3. SectionHeader (섹션 헤더)

**현재**: 단순 텍스트 + View All 버튼
```dart
Row(
  children: [
    Container(width: 4, height: 24, color: color),
    Text(title),
    Text('$count'),
    Spacer(),
    TextButton('View All'),
  ],
)
```

**개선안**: Shop 앱 스타일 강조 헤더
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  decoration: BoxDecoration(
    color: navyTertiary,  // 섹션별 배경색 구분
    borderRadius: BorderRadius.circular(16),
  ),
  child: Row(
    children: [
      // Section icon
      Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      SizedBox(width: 12),
      // Title
      Text(
        title,
        style: TextStyle(
          color: white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      SizedBox(width: 8),
      // Count badge
      Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      Spacer(),
      // View All button
      if (count > 10)
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: purplePrimary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'View All',
                style: TextStyle(color: white, fontSize: 13),
              ),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward, color: white, size: 16),
            ],
          ),
        ),
    ],
  ),
)
```

**핵심 변경**:
- 배경색이 있는 컨테이너로 섹션 구분
- 아이콘 추가로 시각적 식별성 향상
- Count를 배지 스타일로 변경
- View All 버튼을 pill 스타일로 변경
- 더 큰 폰트와 굵은 weight로 계층 구조 강화

### 4. ProductCard (제품 카드)

**현재**: 잘 구조화된 카드 (이미지 + 브랜드 + 이름 + 스펙)

**개선안**: Shop 앱 스타일 적용
```dart
Card(
  elevation: 3,
  shadowColor: Colors.black.withValues(alpha: 0.2),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  ),
  color: navySecondary,
  child: InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Column(
      children: [
        // Product Image with overlay
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                child: Container(
                  color: navyTertiary,  // 배경색
                  child: ProductImage(
                    product: product,
                    mode: ImageDisplayMode.thumbnail,
                    fit: BoxFit.contain,  // contain으로 제품 전체 표시
                  ),
                ),
              ),
              // Selection indicator (top-right)
              if (showSelectionIndicator)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected
                        ? purplePrimary
                        : Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: white.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      isSelected ? Icons.check : Icons.add,
                      color: white,
                      size: 18,
                    ),
                  ),
                ),
              // Price tag (bottom-right) - 추후 가격 정보 추가 시
              if (product.price != null)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: goldPrimary,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Text(
                      '\$${product.price}',
                      style: TextStyle(
                        color: navyPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Product info
        Padding(
          padding: EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Brand with logo (if available)
              if (product.brand != null)
                Row(
                  children: [
                    if (product.brandLogo != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          product.brandLogo!,
                          width: 20,
                          height: 20,
                          fit: BoxFit.cover,
                        ),
                      ),
                    if (product.brandLogo != null) SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        product.brand!,
                        style: TextStyle(
                          color: goldPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              if (product.brand != null) SizedBox(height: 6),
              // Product name
              Text(
                product.getLocalizedName(locale),
                style: TextStyle(
                  color: white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 6),
              // Specs
              Row(
                children: [
                  Icon(Icons.liquor, size: 12, color: gray400),
                  SizedBox(width: 4),
                  Text(
                    _formatSpecs(),
                    style: TextStyle(
                      color: gray400,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  ),
)
```

**핵심 변경**:
- 선택 인디케이터를 원형 버튼 스타일로 변경
- 브랜드 로고 표시 (있을 경우)
- 가격 태그 오버레이 (추후 가격 정보 추가 시)
- 제품 이미지 배경색 추가
- 브랜드 텍스트를 골드 색상으로 강조

### 5. FeaturedCarousel (Featured 캐러셀)

**현재**: 기본 PageView 캐러셀

**개선안**: Shop 앱 스타일 프로모션 카드
```dart
Container(
  height: 200,
  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  child: PageView.builder(
    itemCount: featured.length,
    controller: PageController(viewportFraction: 0.92),
    itemBuilder: (context, index) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              goldPrimary,
              amberAccent,
              copperAccent,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: goldPrimary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Background pattern or image
              Positioned.fill(
                child: Opacity(
                  opacity: 0.2,
                  child: Image.asset(
                    'assets/patterns/cocktail_pattern.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Content
              Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '🎉 FEATURED',
                        style: TextStyle(
                          color: white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    // Title
                    Text(
                      'Signature Cocktails',
                      style: TextStyle(
                        color: navyPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 4),
                    // Subtitle
                    Text(
                      'Discover our bartender\'s special selection',
                      style: TextStyle(
                        color: navyPrimary.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 16),
                    // CTA Button
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: navyPrimary,
                        foregroundColor: goldPrimary,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Explore Now',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  ),
)
```

**핵심 변경**:
- 골드 그라디언트 배경으로 프리미엄 느낌
- 패턴 이미지 오버레이
- 큰 타이틀과 CTA 버튼
- viewportFraction으로 옆 카드가 살짝 보이는 효과
- 그림자 효과로 입체감

### 6. CocktailDetailScreen (상세 화면)

**개선안**: 더 풍부한 정보 표현
```dart
CustomScrollView(
  slivers: [
    // Hero Image with expanded height
    SliverAppBar(
      expandedHeight: 400,  // 350 → 400
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            CocktailImage(...),
            // Better gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  stops: [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
      // Floating buttons
      leading: Container(
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back, color: white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
          child: _FavoriteButton(cocktailId: cocktail.id),
        ),
      ],
    ),

    // Content with better spacing
    SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          color: navyPrimary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row with category
            Row(
              children: [
                Expanded(
                  child: Text(
                    cocktail.name,
                    style: TextStyle(
                      color: white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: whiskeyBrown.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'WHISKEY',
                    style: TextStyle(
                      color: whiskeyBrown,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Stats row
            Row(
              children: [
                _StatChip(
                  icon: Icons.local_bar,
                  label: '${cocktail.abv}%',
                  color: gray400,
                ),
                SizedBox(width: 12),
                _StatChip(
                  icon: Icons.star,
                  label: '4.8',
                  color: goldPrimary,
                ),
                SizedBox(width: 12),
                _StatChip(
                  icon: Icons.access_time,
                  label: '5 min',
                  color: gray400,
                ),
              ],
            ),
            SizedBox(height: 24),

            // Description
            Text(
              cocktail.description,
              style: TextStyle(
                color: gray300,
                fontSize: 16,
                height: 1.6,
              ),
            ),
            SizedBox(height: 32),

            // Ingredients section with cards
            Text(
              'Ingredients',
              style: TextStyle(
                color: white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ...cocktail.ingredients.map((ing) =>
              Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: navySecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: ing.isAvailable
                    ? Border.all(color: successGreen.withValues(alpha: 0.3))
                    : null,
                ),
                child: Row(
                  children: [
                    // Product image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 60,
                        height: 60,
                        color: navyTertiary,
                        child: ProductImage(...),
                      ),
                    ),
                    SizedBox(width: 16),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ing.name,
                            style: TextStyle(
                              color: white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            ing.amount,
                            style: TextStyle(
                              color: gray400,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: ing.isAvailable
                          ? successGreen.withValues(alpha: 0.2)
                          : errorRose.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        ing.isAvailable ? Icons.check : Icons.close,
                        color: ing.isAvailable ? successGreen : errorRose,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ).toList(),
          ],
        ),
      ),
    ),
  ],
)
```

**핵심 변경**:
- 더 큰 이미지 영역 (400px)
- 플로팅 버튼 (반투명 원형 배경)
- 상단 둥근 모서리로 콘텐츠 영역 구분
- 통계 정보를 칩 스타일로 표시
- 재료를 카드 형태로 표시 (이미지 + 정보 + 상태)
- 더 나은 타이포그래피 계층 구조

## 구현 우선순위 및 단계별 계획

### Phase 1: Color System 업데이트 (3-4일)
**우선순위**: 🔴 High - 모든 후속 작업의 기반

**작업 내용**:
1. `app_colors.dart` 업데이트
   - 새로운 컬러 팔레트 추가
   - 기존 coral 계열 유지 (하위 호환성)
   - 새로운 navy, gold, purple 계열 추가

2. `app_colors_extension.dart` 업데이트
   - 다크 테마용 색상 매핑
   - 라이트 테마용 색상 매핑 (선택적)

3. `app_theme.dart` 업데이트
   - ColorScheme 업데이트
   - 새로운 색상으로 테마 재구성

**검증 방법**:
- 모든 화면에서 색상이 올바르게 표시되는지 확인
- 다크/라이트 테마 전환 테스트
- 대비 비율 확인 (WCAG AA 기준)

**산출물**:
```
lib/core/theme/
├── app_colors.dart (updated)
├── app_colors_extension.dart (updated)
└── app_theme.dart (updated)
```

### Phase 2: Core Components 개선 (5-7일)
**우선순위**: 🔴 High - 재사용되는 핵심 컴포넌트

**작업 내용**:
1. NavigationBar 개선
   - 플로팅 스타일 적용
   - 그림자 효과 추가
   - 새로운 색상 적용

2. ProductCard 개선
   - Shop 앱 스타일 적용
   - 선택 인디케이터 개선
   - 브랜드 로고 표시 지원
   - 가격 태그 오버레이 (준비)

3. 공통 위젯 생성
   - `ModernCard` - 입체감 있는 카드
   - `StatusBadge` - 상태 배지
   - `SectionHeader` - 섹션 헤더
   - `StatChip` - 통계 칩

**검증 방법**:
- 각 컴포넌트 단위 테스트
- 다양한 상태에서 시각적 확인
- 애니메이션 부드러움 확인

**산출물**:
```
lib/core/widgets/
├── modern_card.dart (new)
├── status_badge.dart (new)
├── section_header.dart (new)
├── stat_chip.dart (new)
└── product_card.dart (updated)
```

### Phase 3: CocktailsScreen 개선 (4-5일)
**우선순위**: 🟡 Medium - 메인 화면

**작업 내용**:
1. FeaturedCarousel 개선
   - 골드 그라디언트 프로모션 카드
   - 패턴 배경 추가
   - CTA 버튼 개선

2. CocktailCard 개선
   - Shop 앱 스타일 카드
   - 그라디언트 오버레이
   - 카테고리 배지
   - 좋아요 버튼 개선

3. SectionHeader 개선
   - 배경색 있는 헤더
   - 아이콘 추가
   - Count 배지 스타일

**검증 방법**:
- 스크롤 성능 확인
- 카드 로딩 속도 확인
- 다양한 섹션에서 시각적 일관성 확인

**산출물**:
```
lib/features/cocktails/
├── cocktails_screen.dart (updated)
└── widgets/
    ├── featured_carousel.dart (updated)
    ├── cocktail_card.dart (new)
    └── cocktail_section_header.dart (new)
```

### Phase 4: CocktailDetailScreen 개선 (4-5일)
**우선순위**: 🟡 Medium - 상세 화면

**작업 내용**:
1. Hero 이미지 영역 개선
   - 더 큰 expandedHeight
   - 개선된 그라디언트
   - 플로팅 버튼

2. 콘텐츠 영역 개선
   - 상단 둥근 모서리
   - 개선된 타이포그래피
   - 통계 칩

3. 재료 섹션 개선
   - 카드 형태로 재구성
   - 이미지 + 정보 + 상태
   - 더 나은 가독성

**검증 방법**:
- Hero 애니메이션 확인
- 스크롤 성능 확인
- 다양한 칵테일에서 레이아웃 확인

**산출물**:
```
lib/features/cocktails/
├── cocktail_detail_screen.dart (updated)
└── widgets/
    ├── ingredient_card.dart (new)
    └── cocktail_stats.dart (new)
```

### Phase 5: MyBarScreen & Profile 개선 (3-4일)
**우선순위**: 🟢 Low - 보조 화면

**작업 내용**:
1. MyBarScreen 개선
   - 개선된 섹션 헤더
   - 통계 칩 표시
   - 제품 카드 개선 (Phase 2에서 완료)

2. ProfileScreen 개선
   - 프로필 헤더 개선
   - 설정 카드 스타일
   - 새로운 색상 적용

**검증 방법**:
- 빈 상태 확인
- 많은 아이템이 있을 때 확인
- 설정 변경 동작 확인

**산출물**:
```
lib/features/products/
└── my_bar_screen.dart (updated)
lib/features/profile/
└── profile_screen.dart (updated)
```

### Phase 6: 애니메이션 & 폴리싱 (2-3일)
**우선순위**: 🟢 Low - 최종 마무리

**작업 내용**:
1. 마이크로 인터랙션 추가
   - 카드 hover 효과
   - 버튼 press 효과
   - 페이지 전환 애니메이션

2. 로딩 상태 개선
   - Shimmer 효과
   - 스켈레톤 로더

3. 에러 상태 개선
   - 친근한 에러 메시지
   - 재시도 버튼

**검증 방법**:
- 60fps 유지 확인
- 다양한 네트워크 상태 테스트
- 사용자 피드백 수집

**산출물**:
```
lib/core/widgets/
├── shimmer_loading.dart (new)
├── error_view.dart (new)
└── animations/ (new directory)
```

## 기술적 고려사항

### 성능 최적화
1. **이미지 캐싱**:
   - `cached_network_image` 패키지 사용
   - 썸네일 이미지 최적화

2. **레이아웃 최적화**:
   - `const` 생성자 활용
   - `RepaintBoundary` 적절히 사용
   - 불필요한 rebuild 방지

3. **그라디언트 최적화**:
   - 정적 그라디언트는 캐시
   - 복잡한 그라디언트는 이미지로 대체

### 접근성
1. **색상 대비**: WCAG AA 기준 준수 (4.5:1 이상)
2. **터치 타겟**: 최소 44x44 픽셀
3. **시맨틱**: Semantics 위젯 활용

### 하위 호환성
1. **기존 색상 유지**: coral 계열 색상 유지 (deprecated 표시)
2. **점진적 적용**: 화면별로 단계적 적용
3. **테마 전환**: 사용자가 선택 가능하도록 설정 추가 (선택적)

### 다크 테마 우선
- Cockat은 바/칵테일 앱 특성상 다크 테마를 기본으로 함
- 라이트 테마는 Phase 6 이후 선택적으로 추가

## 위험 요소 및 대응 방안

| 위험 요소 | 영향도 | 대응 방안 |
|-----------|--------|----------|
| 기존 사용자의 혼란 | 중간 | 점진적 변경, 릴리즈 노트 제공 |
| 성능 저하 (그라디언트, 그림자) | 높음 | 프로파일링, 최적화, 하드웨어 가속 활용 |
| 색상 접근성 문제 | 중간 | WCAG 도구로 대비 검증, 대체 색상 준비 |
| 이미지 로딩 실패 | 낮음 | Placeholder, 에러 핸들링 강화 |
| 다양한 화면 크기 대응 | 중간 | 반응형 레이아웃, 다양한 기기 테스트 |
| 애니메이션 과다로 인한 성능 저하 | 중간 | 60fps 유지 모니터링, 불필요한 애니메이션 제거 |

## 테스트 전략

### 단위 테스트
- 색상 시스템 테스트
- 위젯 렌더링 테스트
- 상태 관리 테스트

### 통합 테스트
- 화면 전환 테스트
- 네비게이션 테스트
- 데이터 로딩 테스트

### 시각적 회귀 테스트
- Golden test로 UI 변경 감지
- 다양한 화면 크기 스냅샷

### 성능 테스트
- Flutter DevTools로 프레임 드롭 확인
- 메모리 사용량 모니터링
- 빌드 시간 측정

### 사용자 테스트
- 베타 테스터 모집
- A/B 테스트 (선택적)
- 피드백 수집 및 반영

## 성공 기준

- [ ] 색상 시스템이 WCAG AA 기준을 충족함
- [ ] 모든 화면에서 60fps 유지
- [ ] 카드 elevation과 그림자가 일관되게 적용됨
- [ ] 플로팅 네비게이션이 모든 화면에서 정상 작동
- [ ] 이미지 로딩이 부드럽고 placeholder가 적절함
- [ ] 다크 테마가 고급스럽고 읽기 편함
- [ ] 섹션 구분이 명확하고 시각적 계층이 잘 드러남
- [ ] 터치 인터랙션이 직관적이고 반응성이 좋음
- [ ] 다양한 화면 크기에서 레이아웃이 올바름
- [ ] 기존 기능이 모두 정상 작동함
- [ ] 빌드 크기 증가가 5% 미만
- [ ] 앱 시작 시간이 유지되거나 개선됨

## 참고 자료

### 디자인 시스템
- Material Design 3: https://m3.material.io/
- Flutter Material 3: https://docs.flutter.dev/ui/design/material

### 색상 도구
- Coolors.co: 색상 팔레트 생성
- WebAIM Contrast Checker: 대비 검증
- Material Color Tool: Material 색상 생성

### 애니메이션
- Flutter Animations: https://docs.flutter.dev/ui/animations
- Rive: 복잡한 애니메이션 (선택적)

### 성능
- Flutter Performance Best Practices: https://docs.flutter.dev/perf/best-practices

### 참고 앱
- Shop 앱: 고급 UI 패턴 참고
- Behance/Dribbble: 칵테일 앱 디자인 트렌드

## 다음 단계

1. **Phase 1 시작**: Color System 업데이트
2. **디자인 리뷰**: 팀/사용자 피드백 수집
3. **프로토타입**: 주요 화면 프로토타입 작성 (Figma 또는 직접 구현)
4. **점진적 배포**: Phase별로 베타 테스트 및 피드백 반영
5. **문서화**: 새로운 디자인 시스템 가이드 작성

---

**작성일**: 2026-01-28
**버전**: 1.0
**담당**: UI/UX 개선 프로젝트
