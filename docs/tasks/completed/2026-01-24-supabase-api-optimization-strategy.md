# Supabase API 호출 최적화 전략

## 개요
- **목적**: 불필요한 전체 데이터 로드를 제거하고 화면별 필요 데이터만 lazy loading
- **범위**: Cocktail, Ingredient, Product Provider 최적화
- **예상 소요 기간**: 2-3일
- **우선순위**: 높음 (성능 및 서버 부하 문제)

## 현재 상태 분석

### 주요 문제점

#### 1. cocktail_ingredients 전체 로드 (치명적)
**파일**: `lib/data/providers/cocktail_provider.dart:23-27`

```dart
final ingredientsResponse = await supabase
    .from('cocktail_ingredients')
    .select('*, ingredients(name, name_ko)')
    .order('sort_order')
    .limit(10000);  // 2,735개 전체 로드
```

**문제**:
- 2,735개 전체 cocktail_ingredients를 앱 시작 시 한 번에 로드
- Supabase의 서버 max_rows 제한이 1000개로 설정되어 데이터 누락 발생
- 칵테일 상세 페이지에서는 해당 칵테일(평균 5-8개)의 재료만 필요함
- 메모리 낭비 및 초기 로딩 시간 증가

**영향 범위**:
- `cocktailsProvider` → 모든 칵테일 목록 화면
- `cocktailByIdProvider` → 칵테일 상세 화면
- `cocktailMatchesProvider` → 매칭 로직

#### 2. 전체 Provider 구조의 Eager Loading 패턴
**파일**: `lib/data/providers/cocktail_provider.dart:12-54`

```dart
final cocktailsProvider = FutureProvider<List<Cocktail>>((ref) async {
  // 모든 칵테일 + 모든 재료를 한 번에 로드
  // 613개 칵테일 × 평균 4.5개 재료 = 2,735개
});
```

**문제**:
- FutureProvider는 한 번 로드되면 전체 데이터를 메모리에 유지
- 칵테일 목록 화면에서는 재료 상세 정보가 불필요함
- 검색, 필터링 시에도 전체 데이터를 메모리에서 처리

#### 3. 중복 데이터 로드
**파일**: `lib/data/providers/ingredient_availability_provider.dart`

```dart
final cocktailIngredientAvailabilityProvider = Provider.family<...>(
  (ref, cocktailId) {
    // cocktail의 재료는 이미 cocktailsProvider에 로드되어 있지만
    // 여기서 다시 전체 ingredients, products를 watch
    final ingredientsAsync = ref.watch(ingredientsProvider);
    final productsAsync = ref.watch(productsProvider);
  }
);
```

**문제**:
- 재료 가용성 체크를 위해 전체 ingredients, products를 매번 참조
- 이미 로드된 데이터를 재사용하지만 불필요한 의존성

### 현재 데이터 로딩 플로우

```
앱 시작
  ├─ cocktailsProvider (FutureProvider)
  │   ├─ cocktails 테이블 전체 (613개)
  │   └─ cocktail_ingredients 테이블 전체 (2,735개) ← 문제!
  │
  ├─ ingredientsProvider (FutureProvider)
  │   ├─ ingredients 테이블 전체 (260개)
  │   └─ ingredient_substitutes 테이블 전체 (6개)
  │
  └─ productsProvider (FutureProvider)
      └─ products 테이블 전체 (99개)

칵테일 상세 화면 진입
  └─ cocktailByIdProvider(id)
      └─ cocktailsProvider에서 필터링 (이미 로드됨)
          └─ 해당 칵테일의 재료 5-8개만 필요하지만 2,735개 모두 로드됨
```

### 성능 영향 분석

**네트워크 데이터 전송량**:
- cocktails: 613개 × ~500 bytes = ~300 KB
- cocktail_ingredients: 2,735개 × ~200 bytes = ~550 KB ← 최적화 대상
- ingredients: 260개 × ~300 bytes = ~80 KB
- products: 99개 × ~400 bytes = ~40 KB
- **총 초기 로딩**: ~970 KB

**최적화 후 예상**:
- 목록 화면: cocktails만 로드 = ~300 KB
- 상세 화면: 필요한 재료만 로드 = ~1-2 KB per cocktail
- **80% 이상 감소 예상**

## 구현 전략

### 1단계: cocktail_ingredients Lazy Loading 도입

#### 목표
칵테일 상세 페이지에서만 해당 칵테일의 재료를 로드하도록 변경

#### 구현 방안

**A. cocktailsProvider 분리 (권장)**

```dart
// 기본 칵테일 정보만 로드 (재료 제외)
final cocktailsProvider = FutureProvider<List<Cocktail>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);

  final cocktailsResponse = await supabase
      .from('cocktails')
      .select()
      .order('name');

  return (cocktailsResponse as List)
      .map((row) => Cocktail.fromSupabase(
            row as Map<String, dynamic>,
            ingredients: [], // 빈 리스트로 초기화
          ))
      .toList();
});

// 특정 칵테일의 재료만 로드
final cocktailIngredientsProvider =
    FutureProvider.family<List<CocktailIngredient>, String>(
  (ref, cocktailId) async {
    final supabase = ref.watch(supabaseClientProvider);

    final response = await supabase
        .from('cocktail_ingredients')
        .select('*, ingredients(name, name_ko)')
        .eq('cocktail_id', cocktailId)
        .order('sort_order');

    return (response as List)
        .map((row) => CocktailIngredient.fromSupabase(
              row as Map<String, dynamic>,
            ))
        .toList();
  },
);

// 재료를 포함한 완전한 칵테일 정보
final cocktailWithIngredientsProvider =
    Provider.family<AsyncValue<Cocktail?>, String>(
  (ref, cocktailId) {
    final cocktailAsync = ref.watch(cocktailByIdProvider(cocktailId));
    final ingredientsAsync = ref.watch(cocktailIngredientsProvider(cocktailId));

    return cocktailAsync.whenData((cocktail) {
      if (cocktail == null) return null;

      return ingredientsAsync.maybeWhen(
        data: (ingredients) => cocktail.copyWith(ingredients: ingredients),
        orElse: () => cocktail,
      );
    });
  },
);
```

**장점**:
- 목록 화면에서는 재료 데이터 로드 불필요
- 상세 화면에서만 필요한 재료(5-8개)만 로드
- Supabase limit 문제 완전 해결
- 메모리 사용량 대폭 감소

**단점**:
- cocktailMatchesProvider 로직 수정 필요
- 재료 정보가 필요한 다른 화면에서 추가 로딩 필요

#### 구현 세부사항

**1) Cocktail 모델 수정**

```dart
// lib/data/models/cocktail.dart
class Cocktail {
  // ...existing fields...
  final List<CocktailIngredient> ingredients;
  final bool ingredientsLoaded; // 재료 로드 여부 플래그

  Cocktail copyWith({
    // ...existing params...
    List<CocktailIngredient>? ingredients,
    bool? ingredientsLoaded,
  }) {
    return Cocktail(
      // ...existing copying...
      ingredients: ingredients ?? this.ingredients,
      ingredientsLoaded: ingredientsLoaded ?? this.ingredientsLoaded,
    );
  }
}
```

**2) cocktailMatchesProvider 최적화**

현재는 모든 칵테일의 재료를 미리 로드하여 매칭하지만, 이를 두 단계로 분리:

```dart
// 1단계: 기본 칵테일 정보로 빠른 필터링
final cocktailBasicMatchesProvider = Provider<AsyncValue<List<String>>>((ref) {
  final cocktailsAsync = ref.watch(cocktailsProvider);
  final selectedIngredients = ref.watch(allSelectedIngredientIdsProvider);

  // 여기서는 칵테일 ID만 반환 (빠른 필터링)
  // 실제 매칭 로직은 각 칵테일별로 lazy load
});

// 2단계: 필요한 칵테일만 재료 로드하여 정확한 매칭
final cocktailDetailedMatchProvider =
    Provider.family<AsyncValue<CocktailMatch>, String>(
  (ref, cocktailId) {
    final cocktailAsync = ref.watch(cocktailWithIngredientsProvider(cocktailId));
    final selectedIngredients = ref.watch(allSelectedIngredientIdsProvider);

    return cocktailAsync.whenData((cocktail) {
      // 재료 기반 매칭 계산
      // ...matching logic...
    });
  },
);
```

**대안: 점진적 로딩 (Progressive Loading)**

```dart
// 화면에 보이는 칵테일의 재료만 순차적으로 로드
final visibleCocktailIdsProvider = StateProvider<Set<String>>((ref) => {});

final cocktailsWithProgressiveLoadingProvider =
    Provider<AsyncValue<List<Cocktail>>>((ref) {
  final cocktails = ref.watch(cocktailsProvider);
  final visibleIds = ref.watch(visibleCocktailIdsProvider);

  return cocktails.whenData((list) {
    // 보이는 칵테일만 재료 로드
    return list.map((c) {
      if (visibleIds.contains(c.id)) {
        final ingredients = ref.watch(cocktailIngredientsProvider(c.id));
        return c.copyWith(
          ingredients: ingredients.valueOrNull ?? [],
          ingredientsLoaded: ingredients.hasValue,
        );
      }
      return c;
    }).toList();
  });
});
```

### 2단계: 페이지네이션 및 캐싱 전략

#### A. Supabase 페이지네이션

```dart
final cocktailsPaginatedProvider =
    FutureProvider.family<List<Cocktail>, int>(
  (ref, page) async {
    final supabase = ref.watch(supabaseClientProvider);
    const pageSize = 50;

    final response = await supabase
        .from('cocktails')
        .select()
        .order('name')
        .range(page * pageSize, (page + 1) * pageSize - 1);

    return (response as List)
        .map((row) => Cocktail.fromSupabase(row, ingredients: []))
        .toList();
  },
);
```

#### B. 캐싱 전략

```dart
// Riverpod의 keepAlive를 활용한 캐싱
final cocktailIngredientsProvider =
    FutureProvider.family<List<CocktailIngredient>, String>(
  (ref, cocktailId) async {
    // 5분간 캐시 유지
    ref.cacheFor(const Duration(minutes: 5));

    final supabase = ref.watch(supabaseClientProvider);
    final response = await supabase
        .from('cocktail_ingredients')
        .select('*, ingredients(name, name_ko)')
        .eq('cocktail_id', cocktailId)
        .order('sort_order');

    return (response as List)
        .map((row) => CocktailIngredient.fromSupabase(row))
        .toList();
  },
);

// Extension for cache control
extension CacheControlRefExtension on Ref {
  void cacheFor(Duration duration) {
    final link = keepAlive();
    final timer = Timer(duration, link.close);
    onDispose(timer.cancel);
  }
}
```

### 3단계: 배치 로딩 최적화

여러 칵테일의 재료를 한 번에 로드해야 하는 경우:

```dart
final batchCocktailIngredientsProvider =
    FutureProvider.family<Map<String, List<CocktailIngredient>>, List<String>>(
  (ref, cocktailIds) async {
    final supabase = ref.watch(supabaseClientProvider);

    // IN 쿼리로 여러 칵테일의 재료를 한 번에 로드
    final response = await supabase
        .from('cocktail_ingredients')
        .select('*, ingredients(name, name_ko)')
        .in_('cocktail_id', cocktailIds)
        .order('sort_order');

    // cocktail_id별로 그룹화
    final Map<String, List<CocktailIngredient>> grouped = {};
    for (final row in response) {
      final cocktailId = row['cocktail_id'] as String;
      grouped.putIfAbsent(cocktailId, () => [])
          .add(CocktailIngredient.fromSupabase(row));
    }

    return grouped;
  },
);
```

### 4단계: UI 레이어 수정

#### A. CocktailDetailScreen

```dart
class CocktailDetailScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 재료를 포함한 완전한 칵테일 정보 사용
    final cocktailAsync = ref.watch(
      cocktailWithIngredientsProvider(cocktailId)
    );

    return cocktailAsync.when(
      data: (cocktail) {
        if (cocktail == null) return NotFoundScreen();

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // ...existing code...
              SliverToBoxAdapter(
                child: _IngredientsList(
                  cocktailId: cocktail.id,
                  ingredients: cocktail.ingredients, // 이미 로드됨
                ),
              ),
            ],
          ),
        );
      },
      loading: () => LoadingScreen(),
      error: (err, stack) => ErrorScreen(error: err),
    );
  }
}
```

#### B. CocktailMatchesProvider 리팩토링

```dart
// 목록 화면에서는 간단한 매칭만 수행
final quickMatchCocktailsProvider =
    Provider<AsyncValue<List<QuickMatch>>>((ref) {
  final cocktailsAsync = ref.watch(cocktailsProvider);
  final selectedIngredients = ref.watch(allSelectedIngredientIdsProvider);

  return cocktailsAsync.whenData((cocktails) {
    // 재료 로드 없이 기본 정보만으로 필터링
    // 정확한 매칭은 상세 화면에서 수행
    return cocktails.map((c) => QuickMatch(
      cocktailId: c.id,
      name: c.name,
      estimatedMatch: _estimateMatch(c, selectedIngredients),
    )).toList();
  });
});

// 상세 매칭은 필요할 때만
final detailedMatchProvider =
    Provider.family<AsyncValue<CocktailMatch>, String>(
  (ref, cocktailId) {
    final cocktailAsync = ref.watch(
      cocktailWithIngredientsProvider(cocktailId)
    );
    final selectedIngredients = ref.watch(allSelectedIngredientIdsProvider);
    final ingredientsAsync = ref.watch(ingredientsProvider);

    return cocktailAsync.whenData((cocktail) {
      // 정확한 매칭 계산
      // ...existing matching logic...
    });
  },
);
```

## 기술적 고려사항

### 1. 아키텍처 변경 영향

**변경 파일 목록**:
- `lib/data/providers/cocktail_provider.dart` - 핵심 변경
- `lib/data/models/cocktail.dart` - ingredientsLoaded 플래그 추가
- `lib/features/cocktails/cocktail_detail_screen.dart` - Provider 변경
- `lib/features/cocktails/cocktails_screen.dart` - Provider 변경
- `lib/data/providers/ingredient_availability_provider.dart` - 최적화

### 2. 데이터 일관성

**캐시 무효화 전략**:
```dart
// 재료가 변경되면 관련 칵테일 캐시 무효화
class CocktailIngredientService {
  void invalidateCocktail(Ref ref, String cocktailId) {
    ref.invalidate(cocktailIngredientsProvider(cocktailId));
    ref.invalidate(cocktailWithIngredientsProvider(cocktailId));
  }
}
```

### 3. 오프라인 지원 (선택적)

```dart
// 로컬 캐시 레이어 추가
final localCocktailIngredientsProvider =
    FutureProvider.family<List<CocktailIngredient>, String>(
  (ref, cocktailId) async {
    // 1. 로컬 캐시 확인
    final cached = await _loadFromLocalCache(cocktailId);
    if (cached != null) return cached;

    // 2. Supabase에서 로드
    final remote = await ref.watch(cocktailIngredientsProvider(cocktailId).future);

    // 3. 로컬 캐시에 저장
    await _saveToLocalCache(cocktailId, remote);

    return remote;
  },
);
```

### 4. 에러 처리

```dart
final cocktailWithIngredientsProvider =
    Provider.family<AsyncValue<Cocktail?>, String>(
  (ref, cocktailId) {
    final cocktailAsync = ref.watch(cocktailByIdProvider(cocktailId));
    final ingredientsAsync = ref.watch(cocktailIngredientsProvider(cocktailId));

    // 칵테일은 필수, 재료는 선택적
    return cocktailAsync.whenData((cocktail) {
      if (cocktail == null) return null;

      return ingredientsAsync.when(
        data: (ingredients) => cocktail.copyWith(
          ingredients: ingredients,
          ingredientsLoaded: true,
        ),
        loading: () => cocktail, // 재료 로딩 중에도 칵테일 정보 표시
        error: (err, stack) {
          debugPrint('Failed to load ingredients for $cocktailId: $err');
          return cocktail; // 재료 로드 실패해도 칵테일 정보는 표시
        },
      );
    });
  },
);
```

## 위험 요소 및 대응 방안

| 위험 요소 | 영향도 | 대응 방안 |
|-----------|--------|----------|
| cocktailMatchesProvider 로직 복잡도 증가 | 높음 | 단계적 마이그레이션, 기존 로직과 새 로직 병행 운영 후 전환 |
| 재료 로딩 지연으로 인한 UX 저하 | 중간 | 스켈레톤 UI, 낙관적 UI 업데이트, 프리페칭 |
| 캐시 일관성 문제 | 중간 | 명확한 캐시 무효화 전략, 캐시 TTL 설정 |
| 기존 화면 동작 변경 | 높음 | 철저한 테스트, Feature Flag를 통한 점진적 롤아웃 |
| Supabase 쿼리 비용 증가 | 낮음 | 배치 로딩, 적절한 인덱스 설정 |

## 테스트 전략

### 1. 단위 테스트

```dart
void main() {
  group('cocktailIngredientsProvider', () {
    test('특정 칵테일의 재료만 로드', () async {
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockSupabase),
        ],
      );

      final ingredients = await container.read(
        cocktailIngredientsProvider('negroni').future
      );

      expect(ingredients.length, 3); // Negroni는 3개 재료
      expect(ingredients.first.name, 'Gin');
    });

    test('존재하지 않는 칵테일은 빈 리스트 반환', () async {
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockSupabase),
        ],
      );

      final ingredients = await container.read(
        cocktailIngredientsProvider('non-existent').future
      );

      expect(ingredients, isEmpty);
    });
  });

  group('cocktailWithIngredientsProvider', () {
    test('칵테일과 재료를 모두 로드', () async {
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockSupabase),
        ],
      );

      final cocktail = await container.read(
        cocktailWithIngredientsProvider('negroni').future
      );

      expect(cocktail, isNotNull);
      expect(cocktail!.name, 'Negroni');
      expect(cocktail.ingredients.length, 3);
      expect(cocktail.ingredientsLoaded, true);
    });
  });
}
```

### 2. 통합 테스트

```dart
void main() {
  testWidgets('칵테일 상세 화면에서 재료 표시', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockSupabase),
        ],
        child: MaterialApp(
          home: CocktailDetailScreen(cocktailId: 'negroni'),
        ),
      ),
    );

    // 로딩 상태 확인
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    // 재료가 표시되는지 확인
    expect(find.text('Gin'), findsOneWidget);
    expect(find.text('Campari'), findsOneWidget);
    expect(find.text('Sweet Vermouth'), findsOneWidget);
  });
}
```

### 3. 성능 테스트

```dart
void main() {
  test('초기 로딩 시간 개선 확인', () async {
    final stopwatch = Stopwatch()..start();

    final container = ProviderContainer(
      overrides: [
        supabaseClientProvider.overrideWithValue(mockSupabase),
      ],
    );

    // 칵테일 목록만 로드 (재료 제외)
    await container.read(cocktailsProvider.future);

    stopwatch.stop();

    // 기존: ~2초, 최적화 후: <500ms 예상
    expect(stopwatch.elapsedMilliseconds, lessThan(500));
  });

  test('칵테일 상세 로딩 시간 확인', () async {
    final stopwatch = Stopwatch()..start();

    final container = ProviderContainer(
      overrides: [
        supabaseClientProvider.overrideWithValue(mockSupabase),
      ],
    );

    // 특정 칵테일의 재료만 로드
    await container.read(
      cocktailWithIngredientsProvider('negroni').future
    );

    stopwatch.stop();

    // 재료 5-8개만 로드: <200ms 예상
    expect(stopwatch.elapsedMilliseconds, lessThan(200));
  });
}
```

### 4. 메모리 사용량 테스트

```dart
void main() {
  test('메모리 사용량 비교', () async {
    // 기존 방식
    final beforeMemory = await _measureMemoryUsage(() async {
      final container = ProviderContainer();
      await container.read(cocktailsProvider.future);
    });

    // 최적화 후
    final afterMemory = await _measureMemoryUsage(() async {
      final container = ProviderContainer();
      await container.read(cocktailsProvider.future);
    });

    // 80% 이상 감소 예상
    expect(afterMemory, lessThan(beforeMemory * 0.2));
  });
}
```

## 성공 기준

### 필수 요구사항
- [ ] 칵테일 목록 화면에서 재료 데이터 로드 제거
- [ ] 칵테일 상세 화면에서 해당 칵테일 재료만 로드
- [ ] Supabase limit 문제 완전 해결 (더 이상 데이터 누락 없음)
- [ ] 기존 모든 화면의 기능 정상 작동
- [ ] 단위/통합 테스트 통과

### 성능 목표
- [ ] 초기 로딩 시간: 80% 이상 감소 (2초 → <500ms)
- [ ] 네트워크 데이터 전송량: 80% 이상 감소 (970KB → <200KB)
- [ ] 메모리 사용량: 70% 이상 감소
- [ ] 칵테일 상세 화면 로딩: <200ms

### UX 목표
- [ ] 칵테일 목록 화면 즉시 표시
- [ ] 상세 화면 전환 시 자연스러운 로딩 상태
- [ ] 스켈레톤 UI 또는 프로그레스 인디케이터 표시
- [ ] 오프라인 상태에서도 캐시된 데이터 표시 (선택적)

## 구현 순서

### Phase 1: 기반 작업 (0.5일)
1. CocktailIngredient 모델에 필요한 필드 추가
2. 새로운 Provider 구조 설계 및 검증
3. Feature Flag 설정

### Phase 2: 핵심 Provider 구현 (1일)
1. `cocktailIngredientsProvider` 구현
2. `cocktailWithIngredientsProvider` 구현
3. `cocktailsProvider` 수정 (재료 제외)
4. 캐싱 메커니즘 추가

### Phase 3: UI 레이어 수정 (0.5일)
1. `CocktailDetailScreen` 수정
2. 로딩 상태 UI 개선 (스켈레톤)
3. 에러 처리 강화

### Phase 4: 매칭 로직 최적화 (0.5일)
1. `cocktailMatchesProvider` 리팩토링
2. 배치 로딩 구현
3. 성능 최적화

### Phase 5: 테스트 및 검증 (0.5일)
1. 단위 테스트 작성
2. 통합 테스트 작성
3. 성능 테스트 및 벤치마크
4. 메모리 프로파일링

## 참고 자료

### Riverpod Best Practices
- [Riverpod 공식 문서 - FutureProvider](https://riverpod.dev/docs/providers/future_provider)
- [Riverpod 공식 문서 - Family Modifier](https://riverpod.dev/docs/concepts/modifiers/family)
- [Riverpod 공식 문서 - Caching](https://riverpod.dev/docs/concepts/reading#caching)

### Supabase 최적화
- [Supabase 쿼리 최적화](https://supabase.com/docs/guides/database/query-optimization)
- [Supabase 페이지네이션](https://supabase.com/docs/guides/database/pagination)
- [Supabase Indexes](https://supabase.com/docs/guides/database/indexes)

### Flutter 성능 최적화
- [Flutter 성능 best practices](https://docs.flutter.dev/perf/best-practices)
- [Flutter 메모리 프로파일링](https://docs.flutter.dev/tools/devtools/memory)

## 추가 개선 사항 (선택적)

### 1. GraphQL 고려
Supabase는 PostgREST를 사용하지만, 필요 시 GraphQL 레이어 추가 고려:
- 필요한 필드만 선택적으로 요청
- 중첩된 관계를 한 번의 쿼리로 처리
- 오버페칭/언더페칭 최소화

### 2. 서버 사이드 인덱스 최적화

```sql
-- cocktail_ingredients 테이블에 인덱스 추가
CREATE INDEX idx_cocktail_ingredients_cocktail_id
ON cocktail_ingredients(cocktail_id);

-- 복합 인덱스 (자주 함께 사용되는 경우)
CREATE INDEX idx_cocktail_ingredients_cocktail_ingredient
ON cocktail_ingredients(cocktail_id, ingredient_id);
```

### 3. Real-time 구독 활용 (선택적)

```dart
// 재료 변경 시 자동 업데이트
final cocktailIngredientsStreamProvider =
    StreamProvider.family<List<CocktailIngredient>, String>(
  (ref, cocktailId) {
    final supabase = ref.watch(supabaseClientProvider);

    return supabase
        .from('cocktail_ingredients')
        .stream(primaryKey: ['id'])
        .eq('cocktail_id', cocktailId)
        .map((data) => data
            .map((row) => CocktailIngredient.fromSupabase(row))
            .toList());
  },
);
```

### 4. 프리페칭 전략

```dart
// 사용자가 칵테일 카드를 보면 자동으로 재료 프리페칭
class CocktailCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 화면에 나타나면 재료 미리 로드 (백그라운드)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cocktailIngredientsProvider(cocktailId).future);
    });

    return Card(...);
  }
}
```

## 마이그레이션 체크리스트

### 개발 단계
- [ ] Feature Flag 구현 (`use_lazy_loading_ingredients`)
- [ ] 새로운 Provider 구조 구현
- [ ] 기존 Provider와 병행 운영
- [ ] 단위 테스트 작성 및 통과
- [ ] 통합 테스트 작성 및 통과
- [ ] 성능 벤치마크 수행
- [ ] 코드 리뷰 완료

### QA 단계
- [ ] 모든 칵테일 화면 정상 작동 확인
- [ ] 검색 기능 정상 작동 확인
- [ ] 필터링 기능 정상 작동 확인
- [ ] 즐겨찾기 기능 정상 작동 확인
- [ ] 재료 가용성 표시 정상 작동 확인
- [ ] 오프라인 동작 확인 (선택적)
- [ ] 다양한 네트워크 속도에서 테스트

### 배포 단계
- [ ] Feature Flag 활성화 (10% 사용자)
- [ ] 에러 모니터링 설정
- [ ] 성능 메트릭 수집
- [ ] 점진적 롤아웃 (10% → 50% → 100%)
- [ ] 기존 Provider 제거 (완전 마이그레이션 후)
- [ ] Feature Flag 제거

## 롤백 계획

문제 발생 시 즉시 롤백 가능하도록:

```dart
// Feature Flag 기반 롤백
final useLazyLoadingIngredients = StateProvider<bool>((ref) => false);

final cocktailsProvider = FutureProvider<List<Cocktail>>((ref) async {
  final useLazyLoading = ref.watch(useLazyLoadingIngredients);

  if (useLazyLoading) {
    // 새로운 방식 (재료 제외)
    return _loadCocktailsWithoutIngredients(ref);
  } else {
    // 기존 방식 (재료 포함)
    return _loadCocktailsWithIngredients(ref);
  }
});
```

**롤백 트리거 조건**:
- 크래시 발생률 10% 이상 증가
- API 에러율 5% 이상 증가
- 사용자 컴플레인 급증
- 성능 저하 (로딩 시간 2배 이상 증가)
