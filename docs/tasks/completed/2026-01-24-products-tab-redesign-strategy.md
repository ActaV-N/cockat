# 상품 선택 탭(Products Tab) 디자인 개편 전략

## 개요
- **목적**: 사용자가 보유한 술/재료를 선택하는 경험을 직관적이고 즐겁게 개선
- **범위**: Products Screen, Products Catalog Screen, My Bar Screen, Onboarding Products Page
- **예상 소요 기간**: 2-3주 (디자인 1주 + 구현 1-2주)

## 현재 상태 분석

### 기존 구현 현황

**관련 화면**:
1. `ProductsScreen` (lib/features/products/products_screen.dart)
   - My Bar 메인 화면
   - 검색바 + 2열 그리드 레이아웃
   - "재료로 선택하기" 폴백 버튼 제공

2. `ProductsCatalogScreen` (lib/features/products/products_catalog_screen.dart)
   - 전체 상품 카탈로그
   - 카테고리 필터 칩 (수평 스크롤)
   - 검색 + 카테고리 필터링

3. `MyBarScreen` (lib/features/products/my_bar_screen.dart)
   - 선택된 상품을 재료 그룹별로 표시
   - 섹션 헤더 + 그리드 레이아웃
   - 상품 상세로 이동 가능

4. `OnboardingProductsPage` (lib/features/onboarding/pages/products_page.dart)
   - 온보딩 중 상품 선택
   - 리스트 레이아웃 (체크박스)
   - 검색 기능 포함

**Product 데이터 모델**:
```dart
class Product {
  String id, name;
  String? brand, ingredientId;
  String? description, country;
  int? volumeMl;
  double? abv;
  String? imageUrl, thumbnailUrl;
  String? barcode, externalId;
  String dataSource;
}
```

### 문제점 및 한계

#### 1. **정보 계층 구조 불명확**
- 상품명이 가장 위에 위치하여 브랜드보다 먼저 읽힘
- 일반적으로 술은 "브랜드 → 상품명 → 스펙" 순서로 인지됨
- 현재: 상품명 → 이미지 → 브랜드 → 스펙 (역방향 구조)

#### 2. **카테고리 필터 UX 문제**
- 수평 스크롤 칩은 전체 카테고리를 한눈에 파악하기 어려움
- 선택된 카테고리 시각적 강조가 약함
- "All" 옵션이 다른 카테고리와 동등한 위치에 있어 계층이 불명확

#### 3. **검색 경험 제한적**
- 기본 텍스트 검색만 지원
- 최근 검색어, 인기 검색어 등 보조 기능 없음
- 검색 결과 정렬 옵션 없음 (브랜드별, 인기도별 등)

#### 4. **선택 상태 피드백 개선 필요**
- 선택된 상품의 시각적 구분이 약함 (테두리 2px)
- 선택/해제 시 햅틱 피드백 없음
- 대량 선택 시 진행 상황 파악 어려움

#### 5. **온보딩 경험 일관성 부족**
- OnboardingProductsPage는 리스트 레이아웃 사용
- 메인 앱은 그리드 레이아웃 사용
- 사용자가 온보딩과 메인 앱 간 인지 단절 경험

#### 6. **빈 상태(Empty State) 개선 필요**
- 현재: 단순한 아이콘 + 텍스트
- 사용자를 다음 액션으로 유도하는 동기부여 부족

#### 7. **이미지 표시 최적화 부족**
- 썸네일/풀 이미지 구분은 있으나 일관된 활용 전략 없음
- 로딩 상태와 에러 상태 플레이스홀더가 단순함

## 디자인 레퍼런스 분석

### 2026 모바일 UI/UX 트렌드

#### 핵심 원칙 ([출처](https://uidesignz.com/blogs/mobile-ui-design-best-practices))
1. **사용자 우선 디자인**: 사용자를 직접 돕지 않는 요소 제거
2. **명확한 시각적 계층**: 의도가 분명한 레이아웃
3. **접근성 최우선**: 대비, 가독성, 터치 타겟 크기
4. **성능 최적화**: 39%의 사용자가 로딩이 느리면 앱을 떠남

#### 시각적 디자인 트렌드 ([출처](https://www.promodo.com/blog/key-ux-ui-design-trends))
- **부드러운 투명도와 레이어드 깊이**: 계층 구조와 공간 관계 이해 향상
- **가벼운 3D 요소**: 섹션 구분과 인터랙션 강화
- **깔끔한 미니멀 디자인**: 핵심 기능에 집중

#### AI와 개인화 ([출처](https://natively.dev/blog/best-mobile-app-design-trends-2026))
- **하이퍼 개인화**: 사용자 선호도 기반 상품 추천
- **마찰 제거**: 불필요한 단계와 인터랙션 최소화

#### 반응형 및 적응형 디자인 ([출처](https://www.eitbiz.com/blog/mobile-app-design-best-practices-and-tools/))
- 폴더블, 태블릿, 대형 화면을 고려한 유연한 레이아웃
- 고정 레이아웃이 아닌 적응형 컴포넌트

### 주류 앱 UI 디자인 분석

#### Dribbble & Behance 주류 앱 디자인 패턴 ([출처](https://dribbble.com/tags/liquor_store_app))
1. **제품 중심 레이아웃**
   - 큰 제품 이미지가 카드의 60-70% 차지
   - 병 이미지는 세로 방향 강조 (실제 병 형태 반영)
   - 배경과 제품 이미지 대비로 시선 집중

2. **브랜드 우선 정보 계층**
   - 브랜드명이 가장 먼저 표시 (작은 크기, 강조 색상)
   - 제품명이 그 다음 (큰 크기, Bold)
   - 스펙은 마지막 (작은 크기, 회색)

3. **카테고리 필터 디자인**
   - 아이콘 + 레이블 조합 (시각적 인지 향상)
   - 선택된 카테고리는 배경색 + 아이콘 색상 변화
   - 하단 고정 탭 또는 상단 수평 스크롤

4. **선택 상태 표시**
   - 체크마크 오버레이 (우측 상단)
   - 카드 전체에 배경색 또는 테두리
   - 미세한 애니메이션 (선택/해제 시)

#### Figma Liquor Delivery App UI Kit 분석 ([출처](https://www.figma.com/community/file/982883568449549083))
- **검색 및 필터**: 상단 고정 검색바 + 빠른 필터 칩
- **제품 카드**: 이미지 중심, 간결한 정보, 명확한 CTA
- **리스트/그리드 전환**: 사용자 선호도에 따른 뷰 모드 제공

### 식료품 쇼핑 앱 카테고리 필터 디자인 ([출처](https://www.wavegrocery.com/blogpost/grocery-ecommerce-features))

#### 필수 필터 기능
1. **다층 필터링**: 카테고리 + 브랜드 + 가격 + 식이 선호도
2. **자동완성 검색**: 오타 수정, 키워드 발견
3. **패싯 검색**: 속성별 필터 (카테고리, 가용성, 크기, 수량, 가격)

#### 스마트 구성 ([출처](https://fitia.app/learn/article/7-meal-planning-apps-smart-grocery-lists-us/))
- **매장별 정렬**: 레이아웃에 따라 자동 카테고리 분류
- **수량 통합**: 레시피 간 중복 항목 자동 합산
- **다중 매장 리스트 분할**: 매장별 구매 리스트 생성

## 구현 전략

### 접근 방식

**핵심 가치 제안**: "내 술장을 쉽고 즐겁게 관리하자"

**디자인 철학**:
1. **제품이 주인공**: 이미지를 최대한 크게, 정보는 간결하게
2. **빠른 선택**: 최소 탭으로 원하는 제품 찾고 선택
3. **명확한 피드백**: 모든 인터랙션에 즉각적인 시각/햅틱 피드백
4. **일관된 경험**: 온보딩부터 메인 앱까지 동일한 패턴

### 세부 구현 단계

#### Phase 1: 정보 계층 구조 재설계 (1주)

**1.1 Product Card 리디자인**

```dart
// 새로운 정보 계층
┌─────────────────────┐
│  [Product Image]    │  ← 60-70% 공간
│     (세로 강조)      │
├─────────────────────┤
│ Brand Name    [✓]   │  ← 작은 크기, 브랜드 색상
│ Product Name        │  ← 중간 크기, Bold
│ Volume · ABV        │  ← 작은 크기, 회색
└─────────────────────┘
```

**변경 사항**:
- 브랜드를 맨 위로 이동 (라벨 크기, primary 색상)
- 제품명을 브랜드 아래 배치 (titleMedium, Bold)
- 이미지를 중앙에서 상단으로 이동하여 공간 확보
- 선택 인디케이터를 우측 상단 절대 위치로 변경 (브랜드와 겹치지 않게)

**1.2 카드 비율 조정**
- 현재: childAspectRatio 0.72 → 0.7로 조정 (세로 공간 10% 증가)
- 이미지 Expanded(flex: 3) 유지, 하단 정보 공간 최소화

**1.3 선택 상태 시각 강화**
```dart
// 현재: elevation 4 + border 2px
// 개선: elevation 8 + border 3px + 배경색 살짝 변경
Card(
  elevation: isSelected ? 8 : 1,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16), // 12 → 16
    side: isSelected
        ? BorderSide(color: primary, width: 3)
        : BorderSide.none,
  ),
  color: isSelected
      ? primaryContainer.withOpacity(0.3)
      : surface,
)
```

**1.4 햅틱 피드백 추가**
```dart
import 'package:flutter/services.dart';

onTap: () {
  HapticFeedback.lightImpact(); // 선택 시 진동
  ref.read(effectiveProductsServiceProvider).toggle(product.id);
}
```

#### Phase 2: 검색 및 필터 UX 개선 (1주)

**2.1 검색바 개선**

```dart
// 기능 추가
- 검색 포커스 시 최근 검색어 표시 (SharedPreferences 저장)
- 검색 중 실시간 결과 카운트 표시
- 검색 결과 정렬 옵션 (브랜드별, 인기도별, 최신순)
```

**2.2 카테고리 필터 재디자인**

**현재 문제**:
- 수평 스크롤 칩: 전체 카테고리 파악 어려움
- "All" 옵션이 카테고리와 동급

**개선 방안 A: 확장 가능한 카테고리 그리드**
```dart
// 상단에 "카테고리" 헤더 + 접기/펼치기 버튼
// 펼쳤을 때: 2열 그리드로 모든 카테고리 표시 (아이콘 + 레이블)
// 접었을 때: 선택된 카테고리만 표시

Categories:  [All ▼]   ← 접힌 상태
Categories:              ← 펼친 상태
┌──────────┬──────────┐
│ 🥃 All   │ 🍸 Spirits│
│ 🍷 Wines │ 🍺 Beers  │
│ 🍹 Mixers│ 🥤 Juices │
└──────────┴──────────┘
```

**개선 방안 B: 하단 시트 필터**
```dart
// "필터" 버튼 클릭 시 하단 시트 표시
// 카테고리, 브랜드, 가격, ABV 범위 등 복합 필터
// 적용 버튼으로 필터 확정

[🔍 Search] [🎛️ Filters (2)]  ← 필터 개수 표시
```

**권장**: 방안 A (확장 가능한 그리드) - 빠른 접근성 + 전체 파악 용이

**2.3 필터 칩 아이콘 추가**

```dart
// 카테고리별 아이콘 매핑
final categoryIcons = {
  'spirits': Icons.liquor,
  'liqueurs': Icons.emoji_food_beverage,
  'wines': Icons.wine_bar,
  'bitters': Icons.science,
  'juices': Icons.local_drink,
  'syrups': Icons.water_drop,
  'other': Icons.more_horiz,
};

FilterChip(
  avatar: Icon(categoryIcons[category], size: 18),
  label: Text(categoryNames[category]),
  ...
)
```

#### Phase 3: 빈 상태(Empty State) 개선 (3일)

**3.1 ProductsScreen 빈 상태**

**현재**:
```dart
// 아이콘 + "No products available" + "재료로 선택하기" 버튼
```

**개선**:
```dart
// 동기부여 메시지 + 시각적 일러스트레이션 + 명확한 CTA
Column(
  children: [
    // Lottie 애니메이션 또는 SVG 일러스트레이션
    LottieBuilder.asset('assets/animations/empty_bar.json'),
    SizedBox(height: 24),
    Text('아직 술장이 비어있어요', style: headlineSmall),
    SizedBox(height: 8),
    Text(
      '보유하신 술과 재료를 추가하면\n만들 수 있는 칵테일을 추천해드려요',
      style: bodyMedium,
      textAlign: TextAlign.center,
    ),
    SizedBox(height: 32),
    Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FilledButton.icon(
          icon: Icon(Icons.add_circle_outline),
          label: Text('상품 추가하기'),
          onPressed: () => Navigator.push(...ProductsCatalogScreen),
        ),
        SizedBox(width: 12),
        OutlinedButton.icon(
          icon: Icon(Icons.category_outlined),
          label: Text('재료로 선택하기'),
          onPressed: () => Navigator.push(...IngredientsScreen),
        ),
      ],
    ),
  ],
)
```

**3.2 검색 결과 없음 상태**

```dart
// 현재: "No results found" + "Try different search"
// 개선: 인기 상품 추천 또는 비슷한 상품 제안

Column(
  children: [
    Icon(Icons.search_off, size: 64),
    Text('"${searchQuery}"에 대한 검색 결과가 없어요'),
    SizedBox(height: 16),
    Text('이런 상품은 어떠세요?'),
    // 인기 상품 또는 카테고리별 추천 상품 표시
    _PopularProductsSuggestions(),
  ],
)
```

#### Phase 4: 온보딩 경험 통일 (3일)

**4.1 OnboardingProductsPage 그리드 레이아웃 전환**

```dart
// 현재: ListView (리스트 카드 + 체크박스)
// 개선: GridView (메인 앱과 동일한 카드 디자인)

// 장점:
// - 시각적 일관성 향상
// - 이미지 중심 선택 (술병은 시각적 인지가 중요)
// - 온보딩 → 메인 앱 전환 시 인지 부담 감소

GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 0.7,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
  ),
  itemBuilder: (context, index) {
    return _ProductCard(product: products[index]); // 재사용
  },
)
```

**4.2 온보딩 전용 UI 요소**

```dart
// 첫 사용 시 도움말 툴팁
Tooltip(
  message: '탭하여 선택하세요',
  child: _ProductCard(...),
)

// 스와이프 힌트 애니메이션 (첫 진입 시 1회)
if (isFirstTime) {
  AnimatedOpacity(
    opacity: showHint ? 1.0 : 0.0,
    duration: Duration(milliseconds: 500),
    child: Text('← 스와이프하여 더 많은 상품 보기'),
  ),
}
```

#### Phase 5: 이미지 최적화 및 로딩 개선 (3일)

**5.1 썸네일 전략**

```dart
// ProductCard: thumbnailUrl 우선 사용 (빠른 로딩)
// ProductDetailScreen: imageUrl 사용 (고화질)

class ProductImage extends StatelessWidget {
  final Product product;
  final ImageDisplayMode mode;

  @override
  Widget build(BuildContext context) {
    final url = mode == ImageDisplayMode.thumbnail
        ? product.thumbnailUrl ?? product.imageUrl
        : product.imageUrl ?? product.thumbnailUrl;

    if (url == null) return _Placeholder();

    return CachedNetworkImage(
      imageUrl: url,
      placeholder: (context, url) => _ShimmerPlaceholder(),
      errorWidget: (context, url, error) => _ErrorPlaceholder(),
      fadeInDuration: Duration(milliseconds: 200),
      memCacheWidth: mode == ImageDisplayMode.thumbnail ? 400 : null,
    );
  }
}
```

**5.2 플레이스홀더 개선**

```dart
// 현재: 단색 배경 + 아이콘
// 개선: Shimmer 효과 + 브랜드 색상 그라데이션

class _ShimmerPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surfaceContainerHighest,
              Theme.of(context).colorScheme.surfaceContainer,
            ],
          ),
        ),
      ),
    );
  }
}
```

**5.3 에러 상태 개선**

```dart
class _ErrorPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: 40,
            color: Theme.of(context).colorScheme.error,
          ),
          SizedBox(height: 8),
          Text(
            '이미지를 불러올 수 없어요',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }
}
```

#### Phase 6: 고급 기능 추가 (선택, 1주)

**6.1 리스트/그리드 전환**

```dart
// 사용자 선호도 저장
final viewModeProvider = StateProvider<ViewMode>((ref) => ViewMode.grid);

AppBar(
  actions: [
    IconButton(
      icon: Icon(viewMode == ViewMode.grid
          ? Icons.view_list
          : Icons.grid_view),
      onPressed: () {
        ref.read(viewModeProvider.notifier).state =
            viewMode == ViewMode.grid ? ViewMode.list : ViewMode.grid;
      },
    ),
  ],
)
```

**6.2 정렬 옵션**

```dart
enum SortOption {
  nameAsc,      // 이름 오름차순
  nameDesc,     // 이름 내림차순
  brandAsc,     // 브랜드 오름차순
  abvAsc,       // 도수 낮은순
  abvDesc,      // 도수 높은순
  recentlyAdded,// 최근 추가순
}

// 정렬 드롭다운
DropdownButton<SortOption>(
  value: currentSort,
  items: [
    DropdownMenuItem(
      value: SortOption.nameAsc,
      child: Text('이름순 (가나다)'),
    ),
    // ...
  ],
  onChanged: (value) {
    ref.read(sortOptionProvider.notifier).state = value!;
  },
)
```

**6.3 대량 선택 모드**

```dart
// 길게 누르면 대량 선택 모드 진입
LongPressDetector(
  onLongPress: () {
    ref.read(bulkSelectionModeProvider.notifier).state = true;
    HapticFeedback.mediumImpact();
  },
  child: _ProductCard(...),
)

// 대량 선택 모드 UI
if (isBulkSelectionMode)
  Container(
    color: primaryContainer,
    child: Row(
      children: [
        TextButton('모두 선택'),
        TextButton('선택 해제'),
        Spacer(),
        TextButton('완료'),
      ],
    ),
  )
```

**6.4 AI 기반 추천**

```dart
// 사용자 선택 패턴 분석하여 추천
// - 자주 함께 선택된 상품
// - 선택한 상품과 어울리는 상품
// - 인기 있는 조합

class RecommendedProductsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedProducts = ref.watch(effectiveSelectedProductsProvider);
    final recommendations = ref.watch(
      productRecommendationsProvider(selectedProducts),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('이런 상품은 어떠세요?', style: titleMedium),
        SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recommendations.length,
            itemBuilder: (context, index) {
              return _ProductCard(product: recommendations[index]);
            },
          ),
        ),
      ],
    );
  }
}
```

### 기술적 고려사항

#### 아키텍처
- **위젯 재사용성**: ProductCard를 단일 진실 공급원(Single Source of Truth)으로
- **상태 관리**: Riverpod Provider를 통한 선택 상태, 필터, 정렬 관리
- **라우팅**: 온보딩 → 메인 앱 전환 시 상태 유지

#### 의존성
```yaml
dependencies:
  # 이미지 캐싱
  cached_network_image: ^3.3.0

  # 로딩 애니메이션
  shimmer: ^3.0.0

  # 빈 상태 애니메이션
  lottie: ^3.0.0

  # 햅틱 피드백 (기본 제공)
  flutter/services.dart

  # 검색어 저장
  shared_preferences: ^2.2.2
```

#### API 설계

**Product Provider 확장**:
```dart
// 정렬 옵션 Provider
final sortOptionProvider = StateProvider<SortOption>(
  (ref) => SortOption.nameAsc,
);

// 정렬된 상품 Provider
final sortedProductsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(filteredProductsProvider).value ?? [];
  final sortOption = ref.watch(sortOptionProvider);

  return [...products]..sort((a, b) {
    switch (sortOption) {
      case SortOption.nameAsc:
        return a.name.compareTo(b.name);
      case SortOption.abvAsc:
        return (a.abv ?? 0).compareTo(b.abv ?? 0);
      // ...
    }
  });
});

// 최근 검색어 Provider
final recentSearchesProvider = StateNotifierProvider<
  RecentSearchesNotifier, List<String>
>((ref) => RecentSearchesNotifier());

class RecentSearchesNotifier extends StateNotifier<List<String>> {
  RecentSearchesNotifier() : super([]) {
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList('recent_searches') ?? [];
  }

  void addSearch(String query) async {
    if (query.isEmpty) return;
    final updated = [query, ...state.where((s) => s != query)].take(10).toList();
    state = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recent_searches', updated);
  }

  void clearAll() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
  }
}
```

#### 데이터 모델

**확장 필요성 검토**:
```dart
// Product 모델에 추가 필드 고려
class Product {
  // 기존 필드...

  // 선택적 추가 필드
  final int? popularity;        // 인기도 점수 (선택 횟수)
  final DateTime? addedAt;      // 추가 시점
  final List<String>? tags;     // 검색 태그
  final double? rating;         // 평점 (향후 리뷰 기능)
  final int? cocktailCount;     // 이 상품으로 만들 수 있는 칵테일 수
}
```

**현재 모델로 충분**: 기본 구현은 현재 모델로 가능, 고급 기능 추가 시 필드 확장 고려

## 위험 요소 및 대응 방안

| 위험 요소 | 영향도 | 대응 방안 |
|-----------|--------|----------|
| 온보딩 레이아웃 변경으로 기존 사용자 혼란 | 중간 | - A/B 테스트로 전환율 측정<br>- 점진적 롤아웃 (10% → 50% → 100%)<br>- 툴팁 가이드 제공 |
| 이미지 로딩 성능 저하 | 높음 | - 썸네일 우선 로딩 전략<br>- CachedNetworkImage 사용<br>- Progressive JPEG 지원<br>- 이미지 크기 최적화 (CDN 활용) |
| 검색 성능 저하 (상품 수 증가 시) | 중간 | - 클라이언트 검색 → 서버 검색 전환<br>- Debouncing (500ms)<br>- 인덱싱 최적화 |
| 카테고리 필터 복잡도 증가 | 낮음 | - 최대 2단계 계층까지만 허용<br>- "자주 사용하는 필터" 저장 기능<br>- 필터 초기화 버튼 명확히 표시 |
| 햅틱 피드백 배터리 소모 | 낮음 | - 가벼운 햅틱만 사용 (lightImpact)<br>- 설정에서 햅틱 끄기 옵션 제공 |
| 대량 선택 시 UI 응답성 저하 | 중간 | - 선택 상태를 Set<String>으로 관리<br>- 불필요한 rebuild 방지 (Consumer 최적화)<br>- 최대 선택 개수 제한 (100개) |

## 테스트 전략

### 단위 테스트
```dart
// Provider 로직 테스트
test('sortedProductsProvider sorts by name ascending', () {
  final container = ProviderContainer(
    overrides: [
      sortOptionProvider.overrideWith((ref) => SortOption.nameAsc),
    ],
  );

  final sorted = container.read(sortedProductsProvider);
  expect(sorted[0].name, lessThanOrEqualTo(sorted[1].name));
});

// 검색어 저장 테스트
test('RecentSearchesNotifier adds and deduplicates searches', () async {
  final notifier = RecentSearchesNotifier();
  notifier.addSearch('vodka');
  notifier.addSearch('vodka'); // 중복

  await Future.delayed(Duration(milliseconds: 100));
  expect(notifier.state.length, 1);
});
```

### 위젯 테스트
```dart
testWidgets('ProductCard shows brand above product name', (tester) async {
  final product = Product(
    id: '1',
    name: 'Test Product',
    brand: 'Test Brand',
  );

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: _ProductCard(product: product),
      ),
    ),
  );

  final brandFinder = find.text('Test Brand');
  final nameFinder = find.text('Test Product');

  expect(brandFinder, findsOneWidget);
  expect(nameFinder, findsOneWidget);

  // 브랜드가 상품명보다 위에 있는지 확인
  final brandY = tester.getTopLeft(brandFinder).dy;
  final nameY = tester.getTopLeft(nameFinder).dy;
  expect(brandY, lessThan(nameY));
});

testWidgets('Haptic feedback triggers on product tap', (tester) async {
  bool hapticTriggered = false;
  HapticFeedback.lightImpact = () {
    hapticTriggered = true;
  };

  await tester.tap(find.byType(_ProductCard));
  expect(hapticTriggered, isTrue);
});
```

### 통합 테스트
```dart
// 검색 → 필터 → 선택 → 확인 플로우
testWidgets('Full product selection flow', (tester) async {
  await tester.pumpWidget(MyApp());

  // 1. 검색
  await tester.enterText(find.byType(TextField), 'vodka');
  await tester.pump(Duration(milliseconds: 500)); // Debounce

  // 2. 카테고리 필터
  await tester.tap(find.text('Spirits'));
  await tester.pump();

  // 3. 상품 선택
  await tester.tap(find.byType(_ProductCard).first);
  await tester.pump();

  // 4. 선택 확인
  expect(find.text('1개 선택됨'), findsOneWidget);
});
```

### 성능 테스트
```dart
// 대량 상품 렌더링 성능
testWidgets('Renders 100 products without jank', (tester) async {
  final products = List.generate(100, (i) => Product(
    id: '$i',
    name: 'Product $i',
  ));

  final startTime = DateTime.now();

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) => _ProductCard(product: products[index]),
        ),
      ),
    ),
  );

  final endTime = DateTime.now();
  final duration = endTime.difference(startTime);

  // 100개 렌더링이 1초 이내 완료되어야 함
  expect(duration.inMilliseconds, lessThan(1000));
});

// 이미지 로딩 성능
test('Images load with thumbnail first strategy', () async {
  final product = Product(
    id: '1',
    name: 'Test',
    imageUrl: 'https://example.com/full.jpg',
    thumbnailUrl: 'https://example.com/thumb.jpg',
  );

  final productImage = ProductImage(
    product: product,
    mode: ImageDisplayMode.thumbnail,
  );

  // 썸네일 URL이 우선 사용되는지 확인
  expect(productImage.selectedUrl, equals(product.thumbnailUrl));
});
```

### 사용성 테스트
- **대상**: 베타 사용자 10-20명
- **시나리오**:
  1. 온보딩에서 5개 이상 상품 선택
  2. 메인 앱에서 검색 → 필터 → 정렬 → 선택
  3. My Bar 화면에서 상품 삭제
  4. 빈 상태에서 첫 상품 추가
- **측정 지표**:
  - 작업 완료 시간
  - 오류 횟수
  - 만족도 (5점 척도)
  - 혼란 지점 (사용자 피드백)

### 접근성 테스트
```dart
testWidgets('ProductCard meets accessibility standards', (tester) async {
  final product = Product(id: '1', name: 'Test Product');

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: _ProductCard(product: product),
      ),
    ),
  );

  // 터치 타겟 크기 (최소 48x48)
  final cardSize = tester.getSize(find.byType(_ProductCard));
  expect(cardSize.width, greaterThanOrEqualTo(48));
  expect(cardSize.height, greaterThanOrEqualTo(48));

  // 시맨틱 레이블 확인
  expect(
    find.bySemanticsLabel('Test Product 상품 카드'),
    findsOneWidget,
  );
});

// 색상 대비 테스트
test('Brand color meets WCAG AA contrast ratio', () {
  final backgroundColor = Colors.white;
  final brandColor = Theme.of(context).colorScheme.primary;

  final contrastRatio = calculateContrastRatio(backgroundColor, brandColor);
  expect(contrastRatio, greaterThanOrEqualTo(4.5)); // WCAG AA
});
```

## 성공 기준

### 정량적 지표
- [ ] **온보딩 완료율**: 80% 이상 (현재 대비 10% 향상)
- [ ] **평균 상품 선택 시간**: 30초 → 20초 이하
- [ ] **검색 사용률**: 40% 이상 (신규 기능)
- [ ] **필터 사용률**: 30% 이상 (개선 후)
- [ ] **이미지 로딩 시간**: 썸네일 1초 이내, 풀 이미지 3초 이내
- [ ] **앱 성능**: 60fps 유지 (그리드 스크롤 시)
- [ ] **접근성 점수**: Lighthouse 90점 이상

### 정성적 지표
- [ ] **사용자 만족도**: 4.0/5.0 이상 (베타 테스트 피드백)
- [ ] **정보 계층 이해도**: "브랜드를 먼저 확인한다" 80% 이상 동의
- [ ] **온보딩 일관성**: "온보딩과 메인 앱이 비슷하다" 90% 이상 동의
- [ ] **피드백 만족도**: "선택 시 반응이 명확하다" 85% 이상 동의

### 기능 완성도
- [ ] Product Card 재디자인 완료 (브랜드 우선 계층)
- [ ] 선택 상태 시각 강화 (테두리, 배경, 햅틱)
- [ ] 카테고리 필터 UX 개선 (확장 가능한 그리드 또는 하단 시트)
- [ ] 검색 기능 고도화 (최근 검색어, 정렬)
- [ ] 빈 상태 개선 (동기부여 메시지, CTA)
- [ ] 온보딩 그리드 레이아웃 전환
- [ ] 이미지 로딩 최적화 (Shimmer, 에러 처리)
- [ ] 단위/위젯/통합 테스트 작성
- [ ] 접근성 표준 준수 (WCAG AA)

### 코드 품질
- [ ] 위젯 재사용성: ProductCard 단일 구현
- [ ] Provider 최적화: 불필요한 rebuild 최소화
- [ ] 테스트 커버리지: 80% 이상
- [ ] 성능 프로파일링: 메모리 누수 없음
- [ ] 문서화: 주요 컴포넌트 JSDoc 작성

## 우선순위 및 단계별 계획

### Phase 1 (필수, 1주) - MVP
1. ✅ Product Card 정보 계층 재설계
2. ✅ 선택 상태 시각 강화
3. ✅ 햅틱 피드백 추가
4. ✅ 온보딩 그리드 레이아웃 전환

**목표**: 사용자가 체감할 수 있는 핵심 UX 개선

### Phase 2 (중요, 1주) - 검색 및 필터
1. ✅ 카테고리 필터 UX 개선 (확장 가능한 그리드)
2. ✅ 검색바 고도화 (최근 검색어)
3. ✅ 정렬 옵션 추가
4. ✅ 빈 상태 개선

**목표**: 상품 발견성(Discoverability) 향상

### Phase 3 (선택, 3-5일) - 이미지 및 성능
1. ⭕ 이미지 로딩 최적화 (CachedNetworkImage, Shimmer)
2. ⭕ 플레이스홀더 개선
3. ⭕ 성능 프로파일링 및 최적화

**목표**: 앱 품질 및 성능 향상

### Phase 4 (선택, 1주) - 고급 기능
1. ⭕ 리스트/그리드 전환
2. ⭕ 대량 선택 모드
3. ⭕ AI 기반 추천 (데이터 수집 후)

**목표**: 파워 유저를 위한 편의 기능

## 참고 자료

### 디자인 트렌드
- [Best UI Design Practices for Mobile Apps in 2026](https://uidesignz.com/blogs/mobile-ui-design-best-practices)
- [Mobile App Design in 2026: Best Practices & Top Tools](https://www.eitbiz.com/blog/mobile-app-design-best-practices-and-tools/)
- [Key Mobile App UI/UX Design Trends for 2026](https://www.elinext.com/services/ui-ux-design/trends/key-mobile-app-ui-ux-design-trends/)
- [9 Mobile App Design Trends for 2026](https://uxpilot.ai/blogs/mobile-app-design-trends)
- [UX/UI Design Trends 2026: 11 Essentials](https://www.promodo.com/blog/key-ux-ui-design-trends)
- [Best Mobile App UI/UX Design Trends for 2026](https://natively.dev/blog/best-mobile-app-design-trends-2026)

### 주류 앱 디자인
- [Dribbble - Liquor Store Designs](https://dribbble.com/tags/liquor-store)
- [Dribbble - Liquor App Designs](https://dribbble.com/tags/liquor_app)
- [Dribbble - Liquor Store App Designs](https://dribbble.com/tags/liquor_store_app)
- [Behance - Online Liquor Store UI/UX Design](https://www.behance.net/gallery/89254045/Online-Liquor-Store-UIUX-Design)
- [Figma - Liquor Delivery App UI Kit](https://www.figma.com/community/file/982883568449549083)

### 식료품 앱 필터 디자인
- [8 Must-Have Features For Your Grocery Ecommerce Store](https://www.wavegrocery.com/blogpost/grocery-ecommerce-features)
- [Grocery Delivery App Development Guide](https://intellias.com/grocery-delivery-app-development/)
- [5 Features to Include in Grocery Shopping App Development](https://medium.com/@devstree.au/5-features-to-include-in-grocery-shopping-app-development-7d433471d237)
- [Top Meal Planning Apps with Grocery Lists](https://fitia.app/learn/article/7-meal-planning-apps-smart-grocery-lists-us/)

### Flutter 리소스
- [Material Design 3](https://m3.material.io/)
- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices)
- [Flutter Accessibility Guide](https://docs.flutter.dev/development/accessibility-and-localization/accessibility)
- [Riverpod Documentation](https://riverpod.dev/)

## 다음 단계

1. **디자인 프로토타입 작성** (Figma)
   - ProductCard 디자인 시안 3가지
   - 카테고리 필터 A/B 안 비교
   - 온보딩 플로우 전체 화면

2. **팀 리뷰 및 피드백**
   - 디자인 시안 공유
   - 기술적 실행 가능성 검토
   - 우선순위 재조정

3. **Phase 1 구현 시작**
   - ProductCard 위젯 재설계
   - 햅틱 피드백 통합
   - 온보딩 레이아웃 전환

4. **베타 테스트 준비**
   - TestFlight 빌드
   - 사용성 테스트 시나리오 작성
   - 피드백 수집 폼 준비

---

**작성일**: 2026-01-24
**작성자**: Strategic Implementation Architect
**버전**: 1.0
**상태**: 전략 수립 완료, 구현 대기
