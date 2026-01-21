# Search Bar Clear Button 버그 수정 전략

## 개요
- **목적**: 검색창 클리어 버튼(X)을 누르면 입력 필드도 함께 초기화되도록 수정
- **범위**: Products Screen, Cocktails Screen의 검색 바
- **예상 소요 기간**: 30분 - 1시간

## 현재 상태 분석

### 문제 상황
사용자가 검색어를 입력 후 클리어 버튼(X)을 누르면:
- ✅ **Provider 상태는 초기화됨**: 검색 필터링이 해제되어 전체 목록 표시
- ❌ **TextField 입력값은 그대로 유지**: 사용자가 본 화면에는 검색어가 남아있음

**사용자 혼란**:
- 검색어가 화면에 남아있는데 전체 목록이 표시됨
- 클리어 버튼을 눌렀는데 입력 필드가 비워지지 않아 혼란스러움

### 현재 코드 분석

#### Products Screen (lines 121-137)
```dart
Padding(
  padding: const EdgeInsets.all(16),
  child: TextField(
    decoration: InputDecoration(
      hintText: l10n.searchProducts,
      prefixIcon: const Icon(Icons.search),
      suffixIcon: ref.watch(productSearchQueryProvider).isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                // ❌ 문제: Provider만 초기화, TextField는 그대로
                ref.read(productSearchQueryProvider.notifier).state = '';
              },
            )
          : null,
    ),
    onChanged: (value) {
      ref.read(productSearchQueryProvider.notifier).state = value;
    },
  ),
),
```

#### Cocktails Screen (lines 28-44)
```dart
Padding(
  padding: const EdgeInsets.all(16),
  child: TextField(
    decoration: InputDecoration(
      hintText: l10n.searchCocktails,
      prefixIcon: const Icon(Icons.search),
      suffixIcon: ref.watch(cocktailSearchQueryProvider).isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                // ❌ 문제: Provider만 초기화, TextField는 그대로
                ref.read(cocktailSearchQueryProvider.notifier).state = '';
              },
            )
          : null,
    ),
    onChanged: (value) {
      ref.read(cocktailSearchQueryProvider.notifier).state = value;
    },
  ),
),
```

### 근본 원인
**TextField와 Provider의 불일치**:
- `TextField`는 자체 내부 상태(`TextEditingController`)를 가지고 있음
- `onChanged` 콜백으로 Provider에 값을 전달하지만, 역방향(Provider → TextField)은 자동으로 동기화되지 않음
- `TextEditingController`를 사용하지 않아 프로그래밍 방식으로 TextField 값을 제어할 수 없음

## 구현 전략

### 접근 방식
**TextEditingController 도입**: TextField의 입력값을 프로그래밍 방식으로 제어하기 위해 controller 사용

### 핵심 원칙
1. **Single Source of Truth**: Provider가 검색 상태의 유일한 진실 소스
2. **양방향 동기화**: Provider ↔ TextField 양방향 동기화
3. **메모리 관리**: Controller의 적절한 생명주기 관리 (dispose)

### 세부 구현 단계

#### 1단계: SearchBar 컴포넌트 분리 (권장)

**재사용 가능한 SearchBar 위젯 생성**:

```dart
// lib/core/widgets/search_bar_field.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchBarField extends ConsumerStatefulWidget {
  final String hintText;
  final StateProvider<String> searchQueryProvider;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  const SearchBarField({
    super.key,
    required this.hintText,
    required this.searchQueryProvider,
    this.keyboardType,
    this.textInputAction,
  });

  @override
  ConsumerState<SearchBarField> createState() => _SearchBarFieldState();
}

class _SearchBarFieldState extends ConsumerState<SearchBarField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Provider의 초기값으로 controller 초기화
    final initialQuery = ref.read(widget.searchQueryProvider);
    _controller = TextEditingController(text: initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose(); // 메모리 누수 방지
    super.dispose();
  }

  void _clearSearch() {
    _controller.clear(); // TextField 초기화
    ref.read(widget.searchQueryProvider.notifier).state = ''; // Provider 초기화
  }

  @override
  Widget build(BuildContext context) {
    // Provider 변경 감지하여 TextField 동기화
    ref.listen<String>(widget.searchQueryProvider, (previous, next) {
      if (next != _controller.text) {
        _controller.text = next;
      }
    });

    final query = ref.watch(widget.searchQueryProvider);

    return TextField(
      controller: _controller,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction ?? TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: query.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _clearSearch,
                tooltip: 'Clear search',
              )
            : null,
      ),
      onChanged: (value) {
        // TextField → Provider 동기화
        ref.read(widget.searchQueryProvider.notifier).state = value;
      },
    );
  }
}
```

#### 2단계: Products Screen 수정

```dart
// lib/features/products/products_screen.dart

class _ProductsContent extends ConsumerWidget {
  final List<Product> products;
  final int selectedCount;

  const _ProductsContent({
    required this.products,
    required this.selectedCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        // Search Bar - CHANGE: SearchBarField 사용
        Padding(
          padding: const EdgeInsets.all(16),
          child: SearchBarField(
            hintText: l10n.searchProducts,
            searchQueryProvider: productSearchQueryProvider,
          ),
        ),

        // Selected count
        if (selectedCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Chip(
                  avatar: const Icon(Icons.check_circle, size: 18),
                  label: Text(l10n.productsSelected(selectedCount)),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const IngredientsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.fallbackToIngredients),
                ),
              ],
            ),
          ),

        // Product Grid
        Expanded(
          child: _ProductGrid(products: products),
        ),
      ],
    );
  }
}
```

#### 3단계: Cocktails Screen 수정

```dart
// lib/features/cocktails/cocktails_screen.dart

class CocktailsScreen extends ConsumerWidget {
  const CocktailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final matchesAsync = ref.watch(filteredCocktailMatchesProvider);
    final selectedCount = ref.watch(totalSelectedCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cocktails),
      ),
      body: Column(
        children: [
          // Search Bar - CHANGE: SearchBarField 사용
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBarField(
              hintText: l10n.searchCocktails,
              searchQueryProvider: cocktailSearchQueryProvider,
            ),
          ),

          // Results
          Expanded(
            child: matchesAsync.when(
              data: (matches) {
                // ... 기존 로직 유지
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}
```

#### 4단계: widgets.dart 내보내기 추가

```dart
// lib/core/widgets/widgets.dart에 추가
export 'search_bar_field.dart';
```

### 대안: 인라인 수정 (컴포넌트 분리하지 않는 경우)

컴포넌트 분리 없이 각 화면에서 직접 수정하는 방법:

```dart
// products_screen.dart 또는 cocktails_screen.dart

class _ProductsContent extends ConsumerStatefulWidget {
  final List<Product> products;
  final int selectedCount;

  const _ProductsContent({
    required this.products,
    required this.selectedCount,
  });

  @override
  ConsumerState<_ProductsContent> createState() => _ProductsContentState();
}

class _ProductsContentState extends ConsumerState<_ProductsContent> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(productSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(productSearchQueryProvider.notifier).state = '';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Provider 변경 시 TextField 동기화
    ref.listen<String>(productSearchQueryProvider, (previous, next) {
      if (next != _searchController.text) {
        _searchController.text = next;
      }
    });

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController, // ← 추가
            decoration: InputDecoration(
              hintText: l10n.searchProducts,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: ref.watch(productSearchQueryProvider).isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSearch, // ← 수정
                    )
                  : null,
            ),
            onChanged: (value) {
              ref.read(productSearchQueryProvider.notifier).state = value;
            },
          ),
        ),
        // ... 나머지 코드
      ],
    );
  }
}
```

### 기술적 고려사항

#### 위젯 생명주기
- **initState**: TextEditingController 초기화, Provider의 초기값 동기화
- **dispose**: TextEditingController 메모리 해제 (필수)
- **ref.listen**: Provider 변경 감지 및 TextField 동기화

#### 양방향 동기화
- **TextField → Provider**: `onChanged` 콜백
- **Provider → TextField**: `ref.listen` + `controller.text` 업데이트
- **무한 루프 방지**: `if (next != _controller.text)` 조건으로 중복 업데이트 방지

#### 메모리 관리
- **반드시 dispose 호출**: TextEditingController는 네이티브 리소스를 사용하므로 메모리 누수 방지 필수
- **StatefulWidget 사용**: Controller의 생명주기 관리를 위해 Stateful 필요

#### 재사용성
- **컴포넌트 분리**: SearchBarField로 분리하면 다른 화면에서도 재사용 가능
- **일관된 UX**: 모든 검색 바가 동일한 동작 보장

## 위험 요소 및 대응 방안

| 위험 요소 | 영향도 | 대응 방안 |
|-----------|--------|----------|
| TextEditingController dispose 누락 | 높음 | dispose() 메서드에서 반드시 controller.dispose() 호출 |
| Provider ↔ TextField 무한 루프 | 중간 | ref.listen에서 값이 다를 때만 업데이트 |
| StatelessWidget → StatefulWidget 변경 | 낮음 | 기존 로직은 그대로 유지, 생명주기만 추가 |
| 다른 화면의 검색 바 일관성 | 낮음 | SearchBarField 컴포넌트로 통일 |

## 테스트 전략

### 단위 테스트
- [ ] `SearchBarField` 초기값 설정 확인
- [ ] `_clearSearch` 호출 시 controller와 provider 모두 초기화 확인
- [ ] dispose 시 controller 해제 확인

### 통합 테스트
- [ ] 검색어 입력 → Provider 업데이트 확인
- [ ] Provider 외부 변경 → TextField 동기화 확인
- [ ] 클리어 버튼 → TextField + Provider 모두 초기화 확인

### UI 테스트
- [ ] Products Screen: 검색어 입력 후 X 버튼 누르면 입력 필드 비워짐
- [ ] Cocktails Screen: 검색어 입력 후 X 버튼 누르면 입력 필드 비워짐
- [ ] 검색 결과 목록이 전체 목록으로 복구됨
- [ ] 여러 번 검색/초기화 반복 시 메모리 누수 없음

### 엣지 케이스
- [ ] 빈 검색어에서 클리어 버튼 동작
- [ ] 빠른 연속 입력 후 클리어
- [ ] 화면 전환 후 돌아왔을 때 검색 상태 유지

## 성공 기준
- [x] Products Screen 검색 바의 X 버튼이 입력 필드를 초기화함
- [x] Cocktails Screen 검색 바의 X 버튼이 입력 필드를 초기화함
- [x] Provider와 TextField가 항상 동기화된 상태 유지
- [x] 메모리 누수 없음 (controller 적절히 dispose)
- [x] 모든 검색 바가 일관된 동작 제공

## 수정할 파일 목록

### 옵션 1: 컴포넌트 분리 (권장)
1. **lib/core/widgets/search_bar_field.dart** (NEW): 재사용 가능한 검색 바 위젯
2. **lib/core/widgets/widgets.dart**: SearchBarField export 추가
3. **lib/features/products/products_screen.dart**:
   - `_ProductsContent`를 SearchBarField 사용하도록 수정
4. **lib/features/cocktails/cocktails_screen.dart**:
   - `CocktailsScreen`을 SearchBarField 사용하도록 수정

### 옵션 2: 인라인 수정
1. **lib/features/products/products_screen.dart**:
   - `_ProductsContent`를 StatefulWidget으로 변경
   - TextEditingController 추가 및 관리
2. **lib/features/cocktails/cocktails_screen.dart**:
   - `CocktailsScreen`을 StatefulWidget으로 변경
   - TextEditingController 추가 및 관리

## 추가 개선 제안 (선택사항)

### Phase 2 개선사항
1. **검색 히스토리**: 최근 검색어 저장 및 제안
2. **디바운싱**: 입력 완료 후 300ms 후 검색 실행 (성능 최적화)
```dart
Timer? _debounce;

void _onSearchChanged(String value) {
  if (_debounce?.isActive ?? false) _debounce!.cancel();
  _debounce = Timer(const Duration(milliseconds: 300), () {
    ref.read(productSearchQueryProvider.notifier).state = value;
  });
}

@override
void dispose() {
  _debounce?.cancel();
  _searchController.dispose();
  super.dispose();
}
```

3. **검색 분석**: 인기 검색어, 검색 결과 없는 쿼리 트래킹

## 참고 자료
- [Flutter TextField Documentation](https://api.flutter.dev/flutter/material/TextField-class.html)
- [TextEditingController Best Practices](https://docs.flutter.dev/cookbook/forms/text-input)
- [Riverpod ref.listen Documentation](https://riverpod.dev/docs/concepts/reading#using-reflisten-to-react-to-a-provider-change)
- [Widget Lifecycle in Flutter](https://docs.flutter.dev/development/ui/widgets-intro#stateful-and-stateless-widgets)
