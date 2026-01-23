# 칵테일 앱 UI/UX 개선 구현 전략

## 개요
- **목적**: 사용자 경험 개선을 위한 UI/UX 전면 개편
- **범위**: 검색 기능, 메인 페이지 캐러셀, 칵테일 카드 UI, 섹션 구조, 상세 화면
- **예상 소요 기간**: 5-7일 (각 기능별 1-2일)

## 현재 상태 분석

### 기존 구현
- **검색**: 상단에 항상 표시되는 SearchBarField 위젯
- **메인 페이지**: 섹션별 그리드 레이아웃 (즐겨찾기, 만들 수 있어요, 거의 다 됐어요, 2개 더 필요)
- **칵테일 카드**: 작은 이미지(48x48), 이름, 상태 칩
- **상세 화면**: SliverAppBar(expandedHeight: 200), 정보 칩, 재료 목록

### 문제점/한계
1. **검색 바가 항상 화면 공간 차지** → 효율성 저하
2. **추천/선정 칵테일 노출 부재** → 사용자 engagement 낮음
3. **칵테일 이미지 너무 작음(48x48)** → 시각적 구분 어려움
4. **ABV(도수) 정보 미노출** → 중요 정보 누락
5. **섹션 확장 불가** → 10개 이상 데이터 탐색 제한
6. **상세 화면 이미지 영역 작음** → 칵테일 비주얼 강조 부족

### 관련 코드/모듈
- `/lib/features/cocktails/cocktails_screen.dart` - 메인 칵테일 화면
- `/lib/features/cocktails/cocktail_detail_screen.dart` - 칵테일 상세 화면
- `/lib/core/widgets/search_bar_field.dart` - 검색 바 위젯
- `/lib/core/widgets/cocktail_image.dart` - 칵테일 이미지 위젯
- `/lib/data/models/cocktail.dart` - 칵테일 데이터 모델 (abv 필드 존재 확인)

## 구현 전략

### 접근 방식
**단계별 점진적 개선 전략** - 각 기능을 독립적으로 구현하여 리스크 최소화

1. **Phase 1**: 검색 기능 개선 (우선순위: 높음)
2. **Phase 2**: 칵테일 카드 UI 개선 (우선순위: 높음)
3. **Phase 3**: 메인 페이지 캐러셀 추가 (우선순위: 중간)
4. **Phase 4**: 섹션 구조 개편 및 더보기 기능 (우선순위: 중간)
5. **Phase 5**: 상세 화면 개선 (우선순위: 낮음)

### 세부 구현 단계

#### Phase 1: 검색 기능 개선 (1-2일)

**목표**: 검색 바 → 검색 아이콘 버튼 전환, 별도 검색 페이지 구현

**작업 항목**:
1. **검색 페이지 생성** (`lib/features/cocktails/search/cocktail_search_screen.dart`)
   - 전체 화면 검색 인터페이스
   - 검색 바 + 결과 리스트
   - 최근 검색어 기능 (SharedPreferences)
   - 검색 제안/자동완성 (선택사항)

2. **AppBar 수정** (`cocktails_screen.dart`)
   - SearchBarField 제거
   - 검색 아이콘 버튼 추가 (actions)
   - 버튼 클릭 시 검색 페이지로 네비게이션

3. **상태 관리**
   - `cocktailSearchQueryProvider` 유지
   - 검색 페이지에서만 활성화
   - 뒤로가기 시 검색어 초기화 옵션

**파일 변경**:
- `lib/features/cocktails/cocktails_screen.dart` - 검색 바 제거, 아이콘 추가
- `lib/features/cocktails/search/cocktail_search_screen.dart` - 신규 생성
- `lib/data/providers/search_history_provider.dart` - 신규 생성 (선택사항)

**UI 상세**:
```dart
// AppBar actions
actions: [
  IconButton(
    icon: const Icon(Icons.search),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CocktailSearchScreen(),
        ),
      );
    },
  ),
],
```

---

#### Phase 2: 칵테일 카드 UI 개선 (1일)

**목표**: 이미지 크기 확대, ABV 정보 추가

**작업 항목**:
1. **이미지 크기 확대**
   - 현재: 48x48 픽셀
   - 변경: 전체 카드 상단 영역 (높이 120-150 픽셀)
   - childAspectRatio 조정 (1.2 → 0.75-0.8)

2. **ABV 정보 표시**
   - 위치: 카드 하단, 상태 칩 옆 또는 이름 아래
   - 형식: "12% ABV" 또는 아이콘 + 퍼센트
   - 조건부 렌더링: cocktail.abv가 null이 아닐 때

3. **레이아웃 재구성**
   ```
   [====================]
   [    이미지 영역      ]  (120-150px)
   [====================]
   [ 칵테일 이름         ]
   [ ABV: 15% | 상태칩  ]
   ```

**파일 변경**:
- `lib/features/cocktails/cocktails_screen.dart` - `_CocktailCard` 위젯 수정

**UI 상세**:
```dart
class _CocktailCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () { /* ... */ },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. 이미지 영역 (확대)
            Expanded(
              flex: 3,
              child: CocktailImage(
                cocktail: cocktail,
                mode: ImageDisplayMode.thumbnail,
                fit: BoxFit.cover,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
            ),
            // 2. 정보 영역
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cocktail.name,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        if (cocktail.abv != null)
                          _AbvChip(abv: cocktail.abv!),
                        const SizedBox(width: 4),
                        if (showStatus)
                          Expanded(child: _StatusChip(/* ... */)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AbvChip extends StatelessWidget {
  final double abv;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.percent, size: 10),
          const SizedBox(width: 2),
          Text(
            '${abv.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
```

**그리드 델리게이트 조정**:
```dart
SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 2,
  childAspectRatio: 0.75, // 1.2 → 0.75 (더 세로로 긴 카드)
  crossAxisSpacing: 12,
  mainAxisSpacing: 12,
),
```

---

#### Phase 3: 메인 페이지 캐러셀 추가 (2일)

**목표**: 상단에 "MD's Pick" 칵테일 캐러셀 구현

**작업 항목**:
1. **선정 칵테일 데이터**
   - 하드코딩된 칵테일 ID 리스트
   - Provider로 관리 (`featuredCocktailsProvider`)
   - 5-10개 칵테일 선정

2. **캐러셀 위젯 구현**
   - 패키지: `carousel_slider` 또는 `PageView` + `smooth_page_indicator`
   - 자동 스크롤 (3-5초 간격)
   - 인디케이터 표시
   - 카드 클릭 시 상세 페이지 이동

3. **레이아웃 통합**
   - CustomScrollView 최상단에 배치
   - 높이: 200-250 픽셀
   - 좌우 패딩 고려

**파일 변경**:
- `lib/features/cocktails/cocktails_screen.dart` - 캐러셀 섹션 추가
- `lib/features/cocktails/widgets/featured_carousel.dart` - 신규 생성
- `lib/data/providers/cocktail_provider.dart` - `featuredCocktailIdsProvider` 추가
- `pubspec.yaml` - `carousel_slider: ^4.2.1` 추가

**의존성 추가**:
```yaml
dependencies:
  carousel_slider: ^4.2.1
  smooth_page_indicator: ^1.1.0  # 선택사항
```

**UI 상세**:
```dart
// lib/features/cocktails/widgets/featured_carousel.dart
class FeaturedCocktailCarousel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featuredCocktails = ref.watch(featuredCocktailsProvider);

    return featuredCocktails.when(
      data: (cocktails) {
        if (cocktails.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    "MD's Pick",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            CarouselSlider(
              options: CarouselOptions(
                height: 200,
                viewportFraction: 0.85,
                enlargeCenterPage: true,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 4),
              ),
              items: cocktails.map((cocktail) {
                return _FeaturedCard(cocktail: cocktail);
              }).toList(),
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final Cocktail cocktail;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CocktailDetailScreen(
              cocktailId: cocktail.id,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 배경 이미지
              CocktailImage(
                cocktail: cocktail,
                mode: ImageDisplayMode.full,
                fit: BoxFit.cover,
              ),
              // 그라데이션 오버레이
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
              // 텍스트
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cocktail.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (cocktail.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        cocktail.description!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Provider 구현**:
```dart
// lib/data/providers/cocktail_provider.dart

// 하드코딩된 featured 칵테일 ID 리스트
final featuredCocktailIdsProvider = Provider<List<String>>((ref) {
  return [
    'old-fashioned',
    'negroni',
    'margarita',
    'espresso-martini',
    'mojito',
    'manhattan',
    'whiskey-sour',
  ];
});

final featuredCocktailsProvider = FutureProvider<List<Cocktail>>((ref) async {
  final cocktailsAsync = await ref.watch(allCocktailsProvider.future);
  final featuredIds = ref.watch(featuredCocktailIdsProvider);

  return cocktailsAsync
      .where((c) => featuredIds.contains(c.id))
      .toList();
});
```

---

#### Phase 4: 섹션 구조 개편 및 더보기 기능 (1-2일)

**목표**: 각 섹션 최대 10개 제한, 더보기 버튼으로 상세 목록 페이지 연결

**작업 항목**:
1. **섹션 헤더 수정**
   - 더보기 버튼 추가
   - 10개 이상일 때만 표시
   - 화살표 아이콘 + "더보기" 텍스트

2. **상세 목록 페이지 생성**
   - `lib/features/cocktails/section/cocktail_section_list_screen.dart`
   - 섹션별 필터링된 전체 리스트
   - 검색 기능 통합

3. **섹션 타입 정의**
   ```dart
   enum CocktailSection {
     favorites,
     canMake,
     almostCanMake,
     needTwoMore,
     all,
   }
   ```

**파일 변경**:
- `lib/features/cocktails/cocktails_screen.dart` - 섹션 헤더 수정, take(10) 적용
- `lib/features/cocktails/section/cocktail_section_list_screen.dart` - 신규 생성
- `lib/data/models/cocktail.dart` - CocktailSection enum 추가

**UI 상세**:
```dart
// 수정된 _SectionHeader
class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '$count',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            if (count > 10 && onViewAll != null) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onViewAll,
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('더보기'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

**섹션 그리드 수정**:
```dart
// 각 섹션에서
_CocktailGrid(matches: favorites.take(10).toList()),
```

**상세 목록 화면**:
```dart
// lib/features/cocktails/section/cocktail_section_list_screen.dart
class CocktailSectionListScreen extends ConsumerWidget {
  final String title;
  final List<CocktailMatch> matches;
  final Color sectionColor;
  final bool showStatus;

  const CocktailSectionListScreen({
    super.key,
    required this.title,
    required this.matches,
    required this.sectionColor,
    this.showStatus = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: sectionColor.withValues(alpha: 0.1),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _CocktailCard(
                  match: matches[index],
                  showStatus: showStatus,
                ),
                childCount: matches.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

**네비게이션 연결**:
```dart
onViewAll: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => CocktailSectionListScreen(
        title: l10n.favorites,
        matches: favorites,
        sectionColor: Colors.red,
        showStatus: false,
      ),
    ),
  );
},
```

---

#### Phase 5: 상세 화면 개선 (1일)

**목표**: 칵테일 이미지 영역 확대

**작업 항목**:
1. **SliverAppBar expandedHeight 증가**
   - 현재: 200
   - 변경: 300-350

2. **이미지 표시 최적화**
   - BoxFit.cover 유지
   - 그라데이션 오버레이 추가 (가독성 향상)

**파일 변경**:
- `lib/features/cocktails/cocktail_detail_screen.dart` - SliverAppBar 수정

**UI 상세**:
```dart
SliverAppBar(
  expandedHeight: 350, // 200 → 350
  pinned: true,
  actions: [
    _FavoriteButton(cocktailId: cocktail.id),
  ],
  flexibleSpace: FlexibleSpaceBar(
    title: Text(
      cocktail.name,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            offset: Offset(0, 1),
            blurRadius: 3,
            color: Colors.black45,
          ),
        ],
      ),
    ),
    background: Stack(
      fit: StackFit.expand,
      children: [
        CocktailImage(
          cocktail: cocktail,
          mode: ImageDisplayMode.full,
          fit: BoxFit.cover,
        ),
        // 그라데이션 오버레이 (텍스트 가독성)
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.3),
                Colors.black.withValues(alpha: 0.7),
              ],
              stops: const [0.0, 0.7, 1.0],
            ),
          ),
        ),
      ],
    ),
  ),
),
```

---

### 기술적 고려사항

#### 아키텍처
- **MVVM 패턴 유지**: Riverpod Provider를 통한 상태 관리
- **위젯 재사용성**: 공통 위젯 분리 (FeaturedCarousel, SectionHeader, CocktailCard)
- **라우팅**: MaterialPageRoute 사용, 향후 named routes 고려

#### 의존성
- **carousel_slider**: 캐러셀 구현 (4.2.1)
- **smooth_page_indicator**: 페이지 인디케이터 (선택사항, 1.1.0)
- 기존 의존성: flutter_riverpod, shared_preferences

#### API 설계
- **Provider 추가**:
  ```dart
  // Featured cocktails
  final featuredCocktailIdsProvider = Provider<List<String>>;
  final featuredCocktailsProvider = FutureProvider<List<Cocktail>>;

  // Search history (선택사항)
  final searchHistoryProvider = StateNotifierProvider<SearchHistoryNotifier, List<String>>;
  ```

#### 데이터 모델
- **Cocktail 모델**: 변경 불필요 (abv 필드 이미 존재)
- **새 enum**:
  ```dart
  enum CocktailSection {
    featured,
    favorites,
    canMake,
    almostCanMake,
    needTwoMore,
    all,
  }
  ```

---

## 위험 요소 및 대응 방안

| 위험 요소 | 영향도 | 대응 방안 |
|-----------|--------|----------|
| 캐러셀 성능 이슈 (이미지 로딩) | 중간 | cached_network_image 최적화, 썸네일 우선 로딩 |
| 카드 레이아웃 깨짐 (긴 이름) | 낮음 | maxLines + overflow 처리, 반응형 폰트 크기 |
| 검색 페이지 상태 관리 복잡도 | 중간 | Provider 분리, 명확한 상태 초기화 로직 |
| Featured 칵테일 하드코딩 관리 | 낮음 | 별도 상수 파일 분리, 향후 CMS 연동 고려 |
| 섹션 더보기 네비게이션 스택 깊이 | 낮음 | Hero 애니메이션 추가, 뒤로가기 처리 |
| ABV null 처리 누락 | 낮음 | 조건부 렌더링 철저히, 기본값 "-" 표시 |

---

## 테스트 전략

### 단위 테스트
- [ ] `featuredCocktailsProvider` 데이터 로딩
- [ ] `CocktailSection` enum 필터링 로직
- [ ] ABV 표시 조건부 로직

### 통합 테스트
- [ ] 검색 페이지 네비게이션 및 결과 표시
- [ ] 캐러셀 자동 스크롤 동작
- [ ] 섹션 더보기 → 상세 목록 이동
- [ ] 칵테일 카드 클릭 → 상세 화면 이동

### UI 테스트
- [ ] 다양한 화면 크기에서 카드 레이아웃 확인
- [ ] 긴 칵테일 이름 overflow 처리
- [ ] 이미지 로딩 실패 시 placeholder 표시
- [ ] 다크 모드에서 색상 대비 확인

### 성능 테스트
- [ ] 캐러셀 이미지 로딩 시간 측정 (<2초)
- [ ] 그리드 스크롤 성능 (60fps 유지)
- [ ] 검색 결과 필터링 속도 (<500ms)

---

## 성공 기준

- [ ] 검색 아이콘 버튼으로 전환, 별도 검색 페이지 동작
- [ ] 메인 상단에 Featured 캐러셀 표시 (5-10개)
- [ ] 칵테일 카드 이미지 크기 2배 이상 확대 (120px+)
- [ ] ABV 정보 카드에 표시 (null 처리 포함)
- [ ] 각 섹션 최대 10개 제한, 더보기 버튼 동작
- [ ] 상세 화면 이미지 영역 300px 이상
- [ ] 모든 화면 전환 애니메이션 부드러움 (60fps)
- [ ] 다크 모드 정상 지원
- [ ] 접근성: TalkBack/VoiceOver 테스트 통과

---

## 작업 우선순위

### 1차 (필수, 3-4일)
1. ✅ Phase 2: 칵테일 카드 UI 개선 (이미지 확대 + ABV)
2. ✅ Phase 1: 검색 기능 개선 (검색 페이지 분리)
3. ✅ Phase 3: Featured 캐러셀 추가

### 2차 (중요, 2-3일)
4. ✅ Phase 4: 섹션 더보기 기능
5. ✅ Phase 5: 상세 화면 이미지 영역 확대

### 3차 (선택, 향후)
- 검색 자동완성/제안
- 최근 검색어 저장
- Featured 칵테일 CMS 연동
- Hero 애니메이션 추가
- 칵테일 공유 기능

---

## 예상 파일 변경 목록

### 신규 생성
- `lib/features/cocktails/search/cocktail_search_screen.dart`
- `lib/features/cocktails/widgets/featured_carousel.dart`
- `lib/features/cocktails/widgets/abv_chip.dart` (선택사항)
- `lib/features/cocktails/section/cocktail_section_list_screen.dart`
- `lib/data/providers/search_history_provider.dart` (선택사항)

### 수정
- `lib/features/cocktails/cocktails_screen.dart` (주요 수정)
  - SearchBarField 제거
  - 검색 아이콘 추가
  - Featured 캐러셀 추가
  - _CocktailCard 리팩토링 (이미지 확대, ABV 추가)
  - _SectionHeader 더보기 버튼 추가
  - take(10) 제한 적용

- `lib/features/cocktails/cocktail_detail_screen.dart`
  - SliverAppBar expandedHeight 증가 (200→350)
  - 그라데이션 오버레이 추가

- `lib/data/providers/cocktail_provider.dart`
  - featuredCocktailIdsProvider 추가
  - featuredCocktailsProvider 추가

- `lib/data/models/cocktail.dart` (선택사항)
  - CocktailSection enum 추가

### 의존성
- `pubspec.yaml`
  - carousel_slider: ^4.2.1 추가
  - smooth_page_indicator: ^1.1.0 추가 (선택사항)

---

## 참고 자료

### Flutter 위젯
- [CarouselSlider 공식 문서](https://pub.dev/packages/carousel_slider)
- [SliverAppBar 가이드](https://api.flutter.dev/flutter/material/SliverAppBar-class.html)
- [CustomScrollView 패턴](https://docs.flutter.dev/cookbook/lists/mixed-list)

### 디자인 패턴
- [Material Design 3 Cards](https://m3.material.io/components/cards/overview)
- [Material Design 3 Search](https://m3.material.io/components/search/overview)
- [Carousel UI 패턴](https://www.nngroup.com/articles/designing-effective-carousels/)

### 성능 최적화
- [Flutter 이미지 최적화](https://docs.flutter.dev/perf/rendering-performance)
- [ListView vs GridView 성능](https://medium.com/flutter-community/flutter-listview-and-scrollphysics-a-detailed-look-7f0912df2754)

### 접근성
- [Flutter 접근성 가이드](https://docs.flutter.dev/ui/accessibility-and-internationalization/accessibility)
- [Semantic 위젯 사용법](https://api.flutter.dev/flutter/widgets/Semantics-class.html)
