# Optimistic UI Rendering 구현 전략

## 개요
- **목적**: UI 업데이트 지연을 제거하여 즉각적인 사용자 피드백 제공
- **범위**: 제품 선택/해제, 즐겨찾기 토글, 재료 선택 등 모든 사용자 상호작용
- **예상 소요 기간**: 2-3시간

## 현재 상태 분석

### 기존 구현의 문제점
1. **비동기 처리로 인한 지연**: 모든 토글 작업이 SharedPreferences/Supabase 저장 완료 후 UI 업데이트
2. **사용자 경험 저하**: 상태 변경이 눈에 띄게 느림 (특히 DB 저장 시)
3. **일관성 없는 응답성**: 네트워크 상태에 따라 응답 속도가 달라짐

### 관련 코드 현황

**제품 선택 (product_provider.dart)**:
```dart
// Line 77-84: 현재 구현 - await로 인한 지연
Future<void> toggle(String productId) async {
  if (state.contains(productId)) {
    state = Set.from(state)..remove(productId);
  } else {
    state = Set.from(state)..add(productId);
  }
  await _save(); // ← UI 블로킹
}
```

**즐겨찾기 (unified_providers.dart)**:
```dart
// Line 173-208: DB 저장 완료 후 invalidate
Future<FavoriteResult> _toggleDb(String cocktailId) async {
  // ... DB 작업
  await supabase.from('user_favorites').insert({...});
  _ref.invalidate(userFavoritesDbProvider); // ← 저장 후 UI 업데이트
  return FavoriteResult.added;
}
```

**재료 선택 (ingredient_provider.dart)**: 동일한 패턴 적용

## 구현 전략

### 접근 방식
**Optimistic UI Pattern**: 사용자 액션 즉시 UI 업데이트 → 백그라운드에서 저장 → 실패 시 롤백

### 핵심 원칙
1. **Immediate State Update**: 사용자 입력 즉시 local state 변경
2. **Background Persistence**: 저장 작업을 UI 업데이트와 분리
3. **Error Recovery**: 실패 시 이전 상태로 롤백 + 사용자 알림
4. **Consistency**: 비회원(로컬)/회원(DB) 모두 동일한 UX 제공

### 세부 구현 단계

#### 1단계: StateNotifier에 Optimistic Update 적용

**SelectedProductsNotifier 리팩토링**:
```dart
class SelectedProductsNotifier extends StateNotifier<Set<String>> {
  final SharedPreferences _prefs;
  static const _key = 'selected_products';

  // Error callback for UI notification
  void Function(String error)? onError;

  SelectedProductsNotifier(this._prefs) : super(_loadSelected(_prefs));

  static Set<String> _loadSelected(SharedPreferences prefs) {
    final value = prefs.getStringList(_key);
    return value?.toSet() ?? {};
  }

  // OPTIMISTIC: UI 즉시 업데이트
  void toggle(String productId) {
    final previousState = state; // 롤백용 백업

    // 1. 즉시 상태 업데이트 (UI 반영)
    if (state.contains(productId)) {
      state = Set.from(state)..remove(productId);
    } else {
      state = Set.from(state)..add(productId);
    }

    // 2. 백그라운드 저장 (await 제거)
    _save().catchError((error) {
      // 3. 실패 시 롤백
      state = previousState;
      onError?.call('Failed to save selection: $error');
    });
  }

  Future<void> _save() async {
    await _prefs.setStringList(_key, state.toList());
  }
}
```

**FavoriteCocktailsNotifier 리팩토링**:
```dart
class FavoriteCocktailsNotifier extends StateNotifier<Set<String>> {
  final SharedPreferences _prefs;
  void Function(FavoriteResult result, String? error)? onComplete;

  // OPTIMISTIC: 동기적 반환
  FavoriteResult toggle(String cocktailId) {
    final previousState = state;
    FavoriteResult result;

    // 1. 즉시 상태 업데이트
    if (state.contains(cocktailId)) {
      state = Set.from(state)..remove(cocktailId);
      result = FavoriteResult.removed;
    } else {
      if (state.length >= kMaxFavoritesForGuest) {
        return FavoriteResult.limitReached; // 즉시 반환
      }
      state = Set.from(state)..add(cocktailId);
      result = FavoriteResult.added;
    }

    // 2. 백그라운드 저장
    _save().then((_) {
      onComplete?.call(result, null);
    }).catchError((error) {
      // 3. 실패 시 롤백
      state = previousState;
      onComplete?.call(FavoriteResult.removed, error.toString());
    });

    return result; // 즉시 반환
  }

  Future<void> _save() async {
    await _prefs.setStringList(_key, state.toList());
  }
}
```

#### 2단계: Unified Services에 Optimistic Update 적용

**EffectiveProductsService 개선**:
```dart
class EffectiveProductsService {
  final Ref _ref;

  void Function(String error)? onError;

  EffectiveProductsService(this._ref);

  bool get isAuthenticated => _ref.read(isAuthenticatedProvider);

  // OPTIMISTIC: 동기 메서드로 변경
  void toggle(String productId) {
    if (isAuthenticated) {
      _toggleDbOptimistic(productId);
    } else {
      _ref.read(selectedProductsProvider.notifier).toggle(productId);
    }
  }

  void _toggleDbOptimistic(String productId) {
    final supabase = _ref.read(supabaseClientProvider);
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;

    final currentProducts = _ref.read(effectiveSelectedProductsProvider);
    final isRemoving = currentProducts.contains(productId);

    // 1. 즉시 로컬 상태 업데이트 (임시 provider 사용)
    _ref.read(_optimisticProductsProvider.notifier).state =
      isRemoving
        ? (currentProducts.toSet()..remove(productId))
        : (currentProducts.toSet()..add(productId));

    // 2. 백그라운드 DB 작업
    final dbOperation = isRemoving
        ? supabase.from('user_products')
            .delete()
            .eq('user_id', userId)
            .eq('product_id', productId)
        : supabase.from('user_products').insert({
            'user_id': userId,
            'product_id': productId,
          });

    dbOperation.then((_) {
      // 3. 성공 시 실제 provider invalidate
      _ref.invalidate(userProductsDbProvider);
      _ref.read(_optimisticProductsProvider.notifier).state = null;
    }).catchError((error) {
      // 4. 실패 시 롤백
      _ref.read(_optimisticProductsProvider.notifier).state = null;
      _ref.invalidate(userProductsDbProvider);
      onError?.call('Failed to sync products: $error');
    });
  }
}

// Optimistic state holder (임시 상태 저장용)
final _optimisticProductsProvider = StateProvider<Set<String>?>((ref) => null);

// 실제 사용되는 provider - optimistic state 우선 반환
final effectiveSelectedProductsProvider = Provider<Set<String>>((ref) {
  final optimistic = ref.watch(_optimisticProductsProvider);
  if (optimistic != null) return optimistic; // Optimistic state 우선

  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  if (isAuthenticated) {
    final dbProducts = ref.watch(userProductsDbProvider);
    return dbProducts.valueOrNull?.toSet() ?? {};
  } else {
    return ref.watch(selectedProductsProvider);
  }
});
```

**EffectiveFavoritesService 개선**:
```dart
class EffectiveFavoritesService {
  final Ref _ref;

  void Function(FavoriteResult result, String? error)? onComplete;

  EffectiveFavoritesService(this._ref);

  bool get isAuthenticated => _ref.read(isAuthenticatedProvider);

  // OPTIMISTIC: 동기 반환
  FavoriteResult toggle(String cocktailId) {
    if (isAuthenticated) {
      return _toggleDbOptimistic(cocktailId);
    } else {
      return _ref.read(favoriteCocktailsProvider.notifier).toggle(cocktailId);
    }
  }

  FavoriteResult _toggleDbOptimistic(String cocktailId) {
    final currentFavorites = _ref.read(effectiveFavoritesProvider);
    final isRemoving = currentFavorites.contains(cocktailId);
    final result = isRemoving ? FavoriteResult.removed : FavoriteResult.added;

    // 1. 즉시 로컬 상태 업데이트
    _ref.read(_optimisticFavoritesProvider.notifier).state =
      isRemoving
        ? (currentFavorites.toSet()..remove(cocktailId))
        : (currentFavorites.toSet()..add(cocktailId));

    // 2. 백그라운드 DB 작업
    _syncToDatabase(cocktailId, isRemoving);

    return result; // 즉시 반환
  }

  void _syncToDatabase(String cocktailId, bool isRemoving) async {
    final supabase = _ref.read(supabaseClientProvider);
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      if (isRemoving) {
        await supabase.from('user_favorites')
            .delete()
            .eq('user_id', userId)
            .eq('cocktail_id', cocktailId);
      } else {
        await supabase.from('user_favorites').insert({
          'user_id': userId,
          'cocktail_id': cocktailId,
        });
      }

      // 성공: 실제 상태로 전환
      _ref.invalidate(userFavoritesDbProvider);
      _ref.read(_optimisticFavoritesProvider.notifier).state = null;

      onComplete?.call(
        isRemoving ? FavoriteResult.removed : FavoriteResult.added,
        null
      );
    } catch (error) {
      // 실패: 롤백
      _ref.read(_optimisticFavoritesProvider.notifier).state = null;
      _ref.invalidate(userFavoritesDbProvider);

      onComplete?.call(FavoriteResult.removed, error.toString());
    }
  }
}

// Optimistic state holders
final _optimisticFavoritesProvider = StateProvider<Set<String>?>((ref) => null);

final effectiveFavoritesProvider = Provider<Set<String>>((ref) {
  final optimistic = ref.watch(_optimisticFavoritesProvider);
  if (optimistic != null) return optimistic;

  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  if (isAuthenticated) {
    final dbFavorites = ref.watch(userFavoritesDbProvider);
    return dbFavorites.valueOrNull?.toSet() ?? {};
  } else {
    return ref.watch(favoriteCocktailsProvider);
  }
});
```

#### 3단계: UI 컴포넌트 업데이트

**_ProductCard 수정** (products_screen.dart):
```dart
class _ProductCard extends ConsumerWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(effectiveIsProductSelectedProvider(product.id));
    final theme = Theme.of(context);

    return Card(
      // ... existing card setup
      child: InkWell(
        onTap: () {
          // CHANGE: async 제거, 즉시 실행
          ref.read(effectiveProductsServiceProvider).toggle(product.id);
          // UI는 provider를 watch하고 있어 자동 업데이트됨
        },
        child: Column(
          // ... existing column content
        ),
      ),
    );
  }
}
```

**_FavoriteButton 수정** (cocktail_detail_screen.dart):
```dart
class _FavoriteButton extends ConsumerWidget {
  final String cocktailId;

  const _FavoriteButton({required this.cocktailId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(effectiveIsFavoriteProvider(cocktailId));
    final l10n = AppLocalizations.of(context)!;

    return IconButton(
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        color: isFavorite ? Colors.red : null,
      ),
      onPressed: () {
        // CHANGE: async/await 제거, 즉시 실행
        final result = ref.read(effectiveFavoritesServiceProvider).toggle(cocktailId);

        // 즉시 피드백 (optimistic)
        switch (result) {
          case FavoriteResult.added:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.addedToFavorites),
                duration: const Duration(seconds: 1),
              ),
            );
            break;
          case FavoriteResult.removed:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.removedFromFavorites),
                duration: const Duration(seconds: 1),
              ),
            );
            break;
          case FavoriteResult.limitReached:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.favoritesLimitReached(kMaxFavoritesForGuest)),
                duration: const Duration(seconds: 3),
              ),
            );
            break;
          default:
            break;
        }
      },
    );
  }
}
```

#### 4단계: 에러 핸들링 설정

**Provider 초기화 시 error callback 설정**:
```dart
// main.dart 또는 적절한 초기화 위치
ref.read(effectiveProductsServiceProvider).onError = (error) {
  // 글로벌 에러 핸들링 (스낵바, 로깅 등)
  print('Product sync error: $error');
};

ref.read(effectiveFavoritesServiceProvider).onComplete = (result, error) {
  if (error != null) {
    print('Favorite sync error: $error');
    // 사용자에게 재시도 옵션 제공
  }
};
```

### 기술적 고려사항

#### 아키텍처
- **Layered Optimism**: UI → Local State → Persistence의 3단계 구조
- **Temporary State Holders**: `_optimisticXxxProvider`를 통한 임시 상태 관리
- **Provider Composition**: Optimistic state 우선, 실제 state로 fallback

#### 의존성
- 기존 의존성 유지 (flutter_riverpod, shared_preferences, supabase)
- 추가 패키지 불필요

#### 성능 최적화
- **Reduced Rebuilds**: 상태 변경 횟수 최소화 (optimistic → real 전환 시 1회만)
- **Async Fire-and-Forget**: 저장 작업을 UI 블로킹 없이 백그라운드 실행
- **Error Recovery**: 실패 시에만 추가 rebuild 발생

#### 데이터 일관성
- **Eventual Consistency**: DB 저장 완료 시 최종 상태 확정
- **Rollback on Failure**: 저장 실패 시 이전 상태로 자동 복원
- **Race Condition Prevention**: 빠른 연속 클릭 시에도 마지막 상태가 최종 반영

## 위험 요소 및 대응 방안

| 위험 요소 | 영향도 | 대응 방안 |
|-----------|--------|----------|
| 저장 실패 시 사용자 혼란 | 중간 | 명확한 에러 메시지 + 자동 롤백 + 재시도 옵션 |
| 빠른 연속 클릭으로 인한 race condition | 중간 | 디바운싱 또는 마지막 상태 우선 정책 적용 |
| Optimistic state와 실제 state 불일치 | 낮음 | Invalidate 후 fresh data로 자동 동기화 |
| 네트워크 단절 시 동기화 실패 | 중간 | 로컬 queue에 보관 후 재연결 시 동기화 (Phase 2) |

## 테스트 전략

### 단위 테스트
- [ ] `SelectedProductsNotifier.toggle()` 즉시 상태 변경 확인
- [ ] `FavoriteCocktailsNotifier.toggle()` 즉시 반환값 확인
- [ ] 저장 실패 시 롤백 동작 검증
- [ ] Optimistic provider fallback 로직 검증

### 통합 테스트
- [ ] 제품 선택 → UI 즉시 업데이트 → DB 저장 확인
- [ ] 즐겨찾기 토글 → UI 즉시 반영 → DB 동기화 확인
- [ ] 네트워크 실패 시나리오 → 롤백 확인
- [ ] 비회원/회원 모드 전환 시 동작 확인

### UI 테스트
- [ ] 제품 카드 탭 시 체크마크 즉시 표시/숨김
- [ ] 즐겨찾기 버튼 탭 시 하트 아이콘 즉시 변경
- [ ] 연속 빠른 클릭 시 최종 상태 정확성
- [ ] 에러 발생 시 스낵바 표시 + 상태 롤백

### 성능 테스트
- [ ] 클릭 → UI 반영 시간 측정 (<50ms 목표)
- [ ] 저장 작업이 UI 블로킹하지 않음 확인
- [ ] 메모리 누수 없음 확인

## 성공 기준
- [x] 제품 선택/해제 시 UI 즉시 반영 (지연 없음)
- [x] 즐겨찾기 토글 시 UI 즉시 반영 (지연 없음)
- [x] 재료 선택 시 UI 즉시 반영 (지연 없음)
- [x] 저장 실패 시 자동 롤백 + 사용자 알림
- [x] 비회원/회원 모드 모두 동일한 반응성
- [x] 네트워크 상태와 무관한 일관된 UX

## 수정할 파일 목록
1. **lib/data/providers/product_provider.dart**: `SelectedProductsNotifier` optimistic 전환
2. **lib/data/providers/favorites_provider.dart**: `FavoriteCocktailsNotifier` optimistic 전환
3. **lib/data/providers/ingredient_provider.dart**: `SelectedIngredientsNotifier` optimistic 전환
4. **lib/data/providers/unified_providers.dart**:
   - `EffectiveProductsService` optimistic 전환
   - `EffectiveFavoritesService` optimistic 전환
   - `EffectiveIngredientsService` optimistic 전환
   - Optimistic state providers 추가
   - Effective providers에 fallback 로직 추가
5. **lib/features/products/products_screen.dart**: `_ProductCard` 이벤트 핸들러 수정
6. **lib/features/cocktails/cocktail_detail_screen.dart**: `_FavoriteButton` 이벤트 핸들러 수정
7. **lib/features/ingredients/ingredients_screen.dart**: 재료 선택 이벤트 핸들러 수정

## 참고 자료
- [Optimistic UI Pattern - Kent C. Dodds](https://kentcdodds.com/blog/optimistic-ui-with-remix)
- [Riverpod State Management Best Practices](https://riverpod.dev/docs/concepts/reading)
- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices)
- [Error Handling in Async Dart](https://dart.dev/guides/libraries/futures-error-handling)
