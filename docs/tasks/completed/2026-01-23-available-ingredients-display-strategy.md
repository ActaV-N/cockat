# 칵테일 상세 페이지 "내 술장 재료 표시" 기능 구현 전략

## 개요
- **목적**: 칵테일 상세 페이지에서 사용자가 소유한 구체적인 제품/재료를 표시하여 어떤 재료로 칵테일을 만들 수 있는지 명확히 전달
- **범위**: 칵테일 재료 섹션 UI 개선, 대체재/제품 정보 표시, 데이터 구조 확장
- **예상 소요 기간**: 3-4일

## 현재 상태 분석

### 기존 구현
**재료 표시 로직** (`cocktail_detail_screen.dart`):
- `_IngredientsList` 위젯에서 재료 목록 렌더링
- `allSelectedIngredientIdsProvider`로 소유 여부 확인 (체크마크 아이콘)
- 재료명, 용량, optional 여부만 표시

**데이터 구조**:
```dart
// Ingredient Model
- id: String
- name: String
- category: String?
- substitutes: List<String>?  // 재료 레벨 대체재

// CocktailIngredient Model
- id: String (ingredient_id)
- name: String
- amount, units
- substitutes: List<String>  // 칵테일 레시피 레벨 대체재

// Product Model (product_provider.dart)
- id: String
- name: String
- brand: String?
- ingredientId: String?  // 어떤 ingredient를 대표하는지
```

**재료 매칭 로직** (`cocktail_provider.dart`):
```dart
// allSelectedIngredientIdsProvider
- 제품에서 추출된 재료 ID (ingredientIdsFromProductsProvider)
- 직접 선택한 재료 ID (selectedIngredientsProvider)
- 기타 재료 (selectedMiscItemsLocalProvider)
→ 통합하여 Set<String> 반환

// cocktailMatchesProvider
- 칵테일별로 필요한 재료와 소유 재료 매칭
- 대체재 확인 (2단계):
  1. cocktail-level substitutes (CocktailIngredient.substitutes)
  2. ingredient-level substitutes (Ingredient.substitutes)
- 결과: CocktailMatch (matchedIngredients, missingIngredients, availableSubstitutes)
```

### 문제점/한계

1. **추상적인 재료 표시만 가능**
   - 예: "Vodka 소유함"으로만 표시
   - 실제로 어떤 Vodka(Absolut, Grey Goose 등)를 가지고 있는지 알 수 없음

2. **대체재 정보 부재**
   - Campari가 없어도 Aperol로 대체 가능한 경우
   - 현재는 "없음"으로만 표시되고, 대체 가능한 재료가 무엇인지 보여주지 않음

3. **제품-재료 연결 정보 미활용**
   - `Product.ingredientId`로 연결되어 있지만 UI에서 활용 안 됨
   - 사용자가 선택한 제품 정보가 칵테일 상세 페이지에 노출되지 않음

4. **UI/UX 한계**
   - 단순 ListTile 나열로 정보 밀도 낮음
   - 확장 가능한 구조 없음 (여러 제품/대체재 표시 어려움)

### 관련 코드/모듈

**UI 레이어**:
- `lib/features/cocktails/cocktail_detail_screen.dart`
  - `_IngredientsList` 위젯 (line 244-287)

**데이터 레이어**:
- `lib/data/models/ingredient.dart` - Ingredient, CocktailIngredient
- `lib/data/models/product.dart` - Product
- `lib/data/models/cocktail.dart` - CocktailMatch

**Provider 레이어**:
- `lib/data/providers/ingredient_provider.dart`
  - `ingredientsProvider` - 모든 재료 (대체재 포함)
  - `selectedIngredientsProvider` - 직접 선택한 재료
- `lib/data/providers/product_provider.dart`
  - `productsProvider` - 모든 제품
  - `selectedProductsProvider` - 선택한 제품
  - `ingredientIdsFromProductsProvider` - 제품→재료 변환
- `lib/data/providers/cocktail_provider.dart`
  - `allSelectedIngredientIdsProvider` - 통합 재료 ID
  - `cocktailMatchesProvider` - 재료 매칭 로직

## 구현 전략

### 접근 방식

**데이터 우선 접근 (Data-First Approach)**
1. 재료별 소유 제품/대체재 정보를 계산하는 Provider 구축
2. 확장 가능한 UI 컴포넌트 설계
3. 점진적 개선 (기본 → 고급 기능)

### 세부 구현 단계

#### Phase 1: 데이터 구조 확장 (1일)

**1.1 재료별 소유 정보 모델 생성**

새 파일: `lib/data/models/ingredient_availability.dart`

```dart
/// 재료 소유 상태 및 사용 가능한 제품/대체재 정보
@immutable
class IngredientAvailability {
  /// 재료 ID
  final String ingredientId;

  /// 재료명
  final String ingredientName;

  /// 소유 여부
  final bool isOwned;

  /// 이 재료를 제공하는 소유 제품들
  final List<Product> ownedProducts;

  /// 사용 가능한 대체재 정보
  final List<SubstituteInfo> availableSubstitutes;

  const IngredientAvailability({
    required this.ingredientId,
    required this.ingredientName,
    required this.isOwned,
    this.ownedProducts = const [],
    this.availableSubstitutes = const [],
  });

  /// 직접 소유 또는 대체재로 사용 가능
  bool get canUse => isOwned || availableSubstitutes.isNotEmpty;

  /// 표시할 주요 제품/대체재 (최대 3개)
  List<String> get displayItems {
    final items = <String>[];

    // 직접 소유 제품
    items.addAll(ownedProducts.take(2).map((p) => p.displayName));

    // 대체재
    if (items.length < 3 && availableSubstitutes.isNotEmpty) {
      items.add(availableSubstitutes.first.displayName);
    }

    return items;
  }

  /// 추가 항목 개수 (더보기 표시용)
  int get moreCount {
    final total = ownedProducts.length + availableSubstitutes.length;
    return total > 3 ? total - 3 : 0;
  }
}

/// 대체재 정보
@immutable
class SubstituteInfo {
  /// 대체재 재료 ID
  final String substituteId;

  /// 대체재 재료명
  final String substituteName;

  /// 이 대체재를 제공하는 소유 제품들
  final List<Product> ownedProducts;

  const SubstituteInfo({
    required this.substituteId,
    required this.substituteName,
    this.ownedProducts = const [],
  });

  String get displayName {
    if (ownedProducts.isEmpty) return substituteName;
    return ownedProducts.first.displayName;
  }
}
```

**1.2 재료 가용성 Provider 생성**

새 파일: `lib/data/providers/ingredient_availability_provider.dart`

```dart
/// 칵테일의 각 재료별 소유 정보 제공
final cocktailIngredientAvailabilityProvider =
    Provider.family<AsyncValue<List<IngredientAvailability>>, String>(
  (ref, cocktailId) {
    final cocktailAsync = ref.watch(cocktailByIdProvider(cocktailId));
    final ingredientsAsync = ref.watch(ingredientsProvider);
    final productsAsync = ref.watch(productsProvider);

    final selectedProductIds = ref.watch(selectedProductsProvider);
    final selectedIngredientIds = ref.watch(selectedIngredientsProvider);

    return cocktailAsync.whenData((cocktail) {
      if (cocktail == null) return [];

      final ingredients = ingredientsAsync.valueOrNull ?? [];
      final products = productsAsync.valueOrNull ?? [];

      // 재료 ID → Ingredient 맵
      final ingredientMap = {for (var i in ingredients) i.id: i};

      // 선택된 제품들
      final ownedProducts = products
          .where((p) => selectedProductIds.contains(p.id))
          .toList();

      // 제품 그룹핑: ingredient_id → List<Product>
      final productsByIngredient = <String, List<Product>>{};
      for (final product in ownedProducts) {
        if (product.ingredientId != null) {
          productsByIngredient
              .putIfAbsent(product.ingredientId!, () => [])
              .add(product);
        }
      }

      return cocktail.ingredients.map((cocktailIngredient) {
        final ingredientId = cocktailIngredient.id;
        final ingredient = ingredientMap[ingredientId];

        // 1. 직접 소유 여부 확인
        final directlyOwned = selectedIngredientIds.contains(ingredientId);
        final ownedProductsForIngredient =
            productsByIngredient[ingredientId] ?? [];
        final isOwned = directlyOwned || ownedProductsForIngredient.isNotEmpty;

        // 2. 대체재 확인
        final availableSubstitutes = <SubstituteInfo>[];

        if (!isOwned) {
          // 칵테일 레벨 대체재
          for (final subId in cocktailIngredient.substitutes) {
            if (selectedIngredientIds.contains(subId) ||
                productsByIngredient.containsKey(subId)) {
              final subIngredient = ingredientMap[subId];
              availableSubstitutes.add(SubstituteInfo(
                substituteId: subId,
                substituteName: subIngredient?.name ?? subId,
                ownedProducts: productsByIngredient[subId] ?? [],
              ));
            }
          }

          // 재료 레벨 대체재
          if (ingredient?.substitutes != null) {
            for (final subId in ingredient!.substitutes!) {
              if (!availableSubstitutes.any((s) => s.substituteId == subId)) {
                if (selectedIngredientIds.contains(subId) ||
                    productsByIngredient.containsKey(subId)) {
                  final subIngredient = ingredientMap[subId];
                  availableSubstitutes.add(SubstituteInfo(
                    substituteId: subId,
                    substituteName: subIngredient?.name ?? subId,
                    ownedProducts: productsByIngredient[subId] ?? [],
                  ));
                }
              }
            }
          }
        }

        return IngredientAvailability(
          ingredientId: ingredientId,
          ingredientName: cocktailIngredient.name,
          isOwned: isOwned,
          ownedProducts: ownedProductsForIngredient,
          availableSubstitutes: availableSubstitutes,
        );
      }).toList();
    });
  },
);
```

**파일 변경**:
- `lib/data/models/ingredient_availability.dart` - 신규 생성
- `lib/data/providers/ingredient_availability_provider.dart` - 신규 생성
- `lib/data/models/models.dart` - export 추가
- `lib/data/providers/providers.dart` - export 추가

---

#### Phase 2: UI 컴포넌트 설계 (1일)

**2.1 재료 카드 위젯 설계 - 확장 가능한 구조**

**UI 패턴 선택: Expandable ListTile**
- 아코디언보다 간결하고 Material Design 친화적
- 기본 상태: 재료명, 소유 여부, 주요 제품 1-2개 표시
- 확장 상태: 모든 소유 제품 + 대체재 목록 표시

**대안 패턴**:
1. ✅ **Expandable ListTile** (추천)
   - 장점: 간결, 표준 패턴, 직관적
   - 단점: 재료가 많으면 스크롤 길어짐

2. **Bottom Sheet**
   - 장점: 화면 공간 효율적, 상세 정보 표시 용이
   - 단점: 추가 인터랙션 필요, 한 번에 하나만 확인 가능

3. **Dialog/Modal**
   - 장점: 집중도 높음
   - 단점: 과도한 인터랙션, 맥락 전환 부담

**선택 이유**: Expandable ListTile
- 칵테일당 재료 수가 5-8개로 적당
- 빠른 확인과 비교가 중요 (여러 재료 동시 확인)
- Material Design 표준 패턴으로 학습 비용 없음

**2.2 구체적인 UI 구현**

새 파일: `lib/features/cocktails/widgets/ingredient_availability_card.dart`

```dart
/// 재료별 소유 정보를 표시하는 확장 가능한 카드
class IngredientAvailabilityCard extends StatelessWidget {
  final CocktailIngredient ingredient;
  final IngredientAvailability availability;
  final String userUnit;
  final AppLocalizations l10n;

  const IngredientAvailabilityCard({
    super.key,
    required this.ingredient,
    required this.availability,
    required this.userUnit,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final canUse = availability.canUse;
    final displayItems = availability.displayItems;
    final moreCount = availability.moreCount;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(
          canUse ? Icons.check_circle : Icons.circle_outlined,
          color: canUse ? Colors.green : Theme.of(context).colorScheme.outline,
        ),
        title: Text(ingredient.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 용량 정보
            Text(
              UnitConverter.formatAmount(
                ingredient.amount,
                ingredient.units,
                userUnit,
                amountMax: ingredient.amountMax,
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),

            // 소유 제품/대체재 미리보기
            if (canUse && displayItems.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                _buildPreviewText(displayItems, moreCount),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: ingredient.optional
            ? Chip(
                label: Text(l10n.optional),
                visualDensity: VisualDensity.compact,
              )
            : null,
        children: [
          // 확장된 영역: 상세 정보
          _buildExpandedContent(context),
        ],
      ),
    );
  }

  String _buildPreviewText(List<String> items, int moreCount) {
    final preview = items.join(', ');
    if (moreCount > 0) {
      return '$preview +$moreCount';
    }
    return preview;
  }

  Widget _buildExpandedContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 직접 소유 제품
          if (availability.isOwned) ...[
            _buildSectionTitle(context, l10n.ownedProducts),
            const SizedBox(height: 8),
            ...availability.ownedProducts.map((product) =>
              _buildProductItem(context, product, isSubstitute: false),
            ),
          ],

          // 대체재
          if (availability.availableSubstitutes.isNotEmpty) ...[
            if (availability.isOwned) const SizedBox(height: 16),
            _buildSectionTitle(context, l10n.availableSubstitutes),
            const SizedBox(height: 8),
            ...availability.availableSubstitutes.map((substitute) =>
              _buildSubstituteItem(context, substitute),
            ),
          ],

          // 소유하지 않은 경우
          if (!availability.canUse) ...[
            Text(
              l10n.ingredientNotOwned,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildProductItem(
    BuildContext context,
    Product product, {
    required bool isSubstitute,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isSubstitute ? Icons.swap_horiz : Icons.liquor,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              product.displayName,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubstituteItem(
    BuildContext context,
    SubstituteInfo substitute,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.swap_horiz,
                size: 16,
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  substitute.substituteName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (substitute.ownedProducts.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: substitute.ownedProducts.map((product) =>
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '• ${product.displayName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

**2.3 기존 _IngredientsList 위젯 교체**

`lib/features/cocktails/cocktail_detail_screen.dart` 수정:

```dart
class _IngredientsList extends ConsumerWidget {
  final String cocktailId;
  final List<CocktailIngredient> ingredients;
  final AppLocalizations l10n;

  const _IngredientsList({
    required this.cocktailId,
    required this.ingredients,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availabilityAsync =
        ref.watch(cocktailIngredientAvailabilityProvider(cocktailId));
    final userUnit = ref.watch(effectiveUnitSystemProvider);

    return availabilityAsync.when(
      data: (availabilities) {
        return Column(
          children: List.generate(ingredients.length, (index) {
            final ingredient = ingredients[index];
            final availability = availabilities.firstWhere(
              (a) => a.ingredientId == ingredient.id,
              orElse: () => IngredientAvailability(
                ingredientId: ingredient.id,
                ingredientName: ingredient.name,
                isOwned: false,
              ),
            );

            return IngredientAvailabilityCard(
              ingredient: ingredient,
              availability: availability,
              userUnit: userUnit,
              l10n: l10n,
            );
          }),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
```

**파일 변경**:
- `lib/features/cocktails/widgets/ingredient_availability_card.dart` - 신규 생성
- `lib/features/cocktails/cocktail_detail_screen.dart` - _IngredientsList 수정

---

#### Phase 3: 다국어 지원 및 테스트 (1일)

**3.1 다국어 키 추가**

`lib/l10n/app_en.arb`:
```json
{
  "ownedProducts": "Your Products",
  "availableSubstitutes": "Available Substitutes",
  "ingredientNotOwned": "You don't have this ingredient",
  "tapToSeeDetails": "Tap to see details"
}
```

`lib/l10n/app_ko.arb`:
```json
{
  "ownedProducts": "내 술장 보유",
  "availableSubstitutes": "사용 가능한 대체재",
  "ingredientNotOwned": "이 재료를 보유하고 있지 않습니다",
  "tapToSeeDetails": "탭하여 상세 보기"
}
```

**3.2 엣지 케이스 테스트**

테스트 시나리오:
1. ✅ 모든 재료 소유
2. ✅ 일부 재료만 소유
3. ✅ 대체재만 소유 (원재료 없음)
4. ✅ 여러 제품으로 같은 재료 소유 (예: Vodka 3종)
5. ✅ 제품 없이 재료만 직접 선택
6. ✅ 아무것도 소유하지 않음
7. ✅ Optional 재료 처리
8. ✅ 데이터 로딩 중/에러 상태

**파일 변경**:
- `lib/l10n/app_en.arb` - 키 추가
- `lib/l10n/app_ko.arb` - 키 추가

---

#### Phase 4: 성능 최적화 및 개선 (0.5일)

**4.1 Provider 캐싱**
- `cocktailIngredientAvailabilityProvider`는 family provider로 cocktailId별 캐싱
- 불필요한 재계산 방지

**4.2 UI 최적화**
- ExpansionTile 초기 상태: 모두 접힘
- 사용자가 펼칠 때만 상세 위젯 렌더링 (children 지연 빌드)

**4.3 메모리 최적화**
- Product 객체 전체 저장 대신 필요한 필드만 추출 (선택사항)
- 현재 구조로도 충분히 가벼움 (칵테일당 재료 5-8개)

---

## 기술적 고려사항

### 아키텍처

**레이어 분리**:
```
UI Layer (Widget)
    ↓
Provider Layer (IngredientAvailabilityProvider)
    ↓
Data Layer (Models: IngredientAvailability, SubstituteInfo)
    ↓
Source Layer (Existing Providers: products, ingredients, selections)
```

**데이터 흐름**:
1. 사용자가 제품/재료 선택 (Product/Ingredient Selection)
2. Provider가 선택 상태 변화 감지
3. `cocktailIngredientAvailabilityProvider` 재계산
4. UI 자동 업데이트 (Riverpod watch)

### 의존성

**새로운 의존성**: 없음 (기존 패키지로 충분)

**기존 의존성 활용**:
- `flutter_riverpod` - 상태 관리
- `collection` - firstWhereOrNull 등

### API 설계

**새 Provider**:
```dart
// 칵테일별 재료 가용성 정보
Provider.family<AsyncValue<List<IngredientAvailability>>, String>

// 입력: cocktailId
// 출력: List<IngredientAvailability>
```

**새 Model**:
```dart
IngredientAvailability {
  ingredientId, ingredientName, isOwned,
  ownedProducts, availableSubstitutes,
  canUse, displayItems, moreCount
}

SubstituteInfo {
  substituteId, substituteName, ownedProducts,
  displayName
}
```

### 데이터 모델

**변경 없음** - 기존 모델 구조 그대로 활용
- Ingredient.substitutes (재료 레벨)
- CocktailIngredient.substitutes (레시피 레벨)
- Product.ingredientId (제품-재료 연결)

**새 모델**: IngredientAvailability, SubstituteInfo (UI 표현용)

---

## 위험 요소 및 대응 방안

| 위험 요소 | 영향도 | 대응 방안 |
|-----------|--------|----------|
| Provider 계산 복잡도로 성능 저하 | 중간 | - Family provider로 cocktailId별 캐싱<br>- 필요한 데이터만 계산 (filter 최소화)<br>- 로딩 상태 명시적 표시 |
| 대체재 매칭 로직 오류 (중복/누락) | 높음 | - 단위 테스트 작성 (대체재 매칭 로직)<br>- 엣지 케이스 시나리오 검증<br>- 중복 제거 로직 강화 |
| UI 확장 시 스크롤 길이 증가 | 낮음 | - 기본 접힌 상태 유지<br>- 필요시 한 번에 하나만 확장되도록 설정 가능 |
| 제품명이 너무 긴 경우 레이아웃 깨짐 | 낮음 | - Text overflow: ellipsis 적용<br>- maxLines 제한 |
| 데이터 로딩 실패 시 빈 화면 | 중간 | - Error boundary 처리<br>- 기본값으로 fallback (단순 소유 여부만 표시) |

---

## 테스트 전략

### 단위 테스트

**Provider 로직 테스트** (`test/providers/ingredient_availability_provider_test.dart`):
```dart
group('IngredientAvailabilityProvider', () {
  test('직접 소유한 재료 정확히 표시', () { ... });
  test('제품 기반 재료 소유 정확히 표시', () { ... });
  test('대체재 탐지 (칵테일 레벨)', () { ... });
  test('대체재 탐지 (재료 레벨)', () { ... });
  test('중복 대체재 제거', () { ... });
  test('여러 제품으로 같은 재료 소유', () { ... });
});
```

**Model 테스트** (`test/models/ingredient_availability_test.dart`):
```dart
group('IngredientAvailability', () {
  test('canUse - 직접 소유', () { ... });
  test('canUse - 대체재만', () { ... });
  test('displayItems - 최대 3개', () { ... });
  test('moreCount 계산', () { ... });
});
```

### 통합 테스트

**Widget 테스트** (`test/widgets/ingredient_availability_card_test.dart`):
```dart
group('IngredientAvailabilityCard', () {
  testWidgets('소유 재료 - 체크 아이콘 표시', (tester) async { ... });
  testWidgets('미소유 재료 - 빈 아이콘 표시', (tester) async { ... });
  testWidgets('확장 시 제품 목록 표시', (tester) async { ... });
  testWidgets('대체재 정보 표시', (tester) async { ... });
  testWidgets('Optional 칩 표시', (tester) async { ... });
});
```

### 시나리오 테스트

**실제 사용 시나리오**:
1. Negroni 칵테일 상세 페이지
   - Campari 없음, Aperol 소유 → 대체재 표시
   - Gin 소유 (Tanqueray, Bombay 2개) → 제품 2개 표시
   - Sweet Vermouth 소유 (Martini) → 제품 1개 표시

2. Mojito 칵테일 상세 페이지
   - White Rum 소유 (Bacardi, Havana Club, Diplomatico) → 2개 표시 + "더보기 +1"
   - Lime, Sugar, Mint 직접 선택 → "소유" 표시만

3. 아무것도 없을 때
   - 모든 재료 미소유 아이콘 + "이 재료를 보유하고 있지 않습니다" 메시지

---

## 성공 기준

### 기능 완성도
- [x] 직접 소유 제품 정확히 표시
- [x] 대체재 자동 탐지 및 표시
- [x] 확장/접기 인터랙션 정상 동작
- [x] 다국어 지원 (한국어/영어)
- [x] 모든 엣지 케이스 처리

### 성능
- [x] 페이지 로딩 시간 < 300ms (초기 계산 포함)
- [x] 확장/접기 애니메이션 60fps 유지
- [x] Provider 재계산 최소화 (캐싱 활용)

### 사용성
- [x] 첫 화면에서 소유 제품 미리보기 표시
- [x] 확장하지 않아도 핵심 정보 파악 가능
- [x] 확장 시 모든 제품/대체재 명확히 표시
- [x] 아이콘으로 상태 직관적 표현 (소유/미소유/대체재)

### 코드 품질
- [x] 단위 테스트 커버리지 >80%
- [x] Widget 테스트 주요 시나리오 커버
- [x] Provider 로직과 UI 분리
- [x] 재사용 가능한 컴포넌트 설계

---

## 참고 자료

### 기존 코드 패턴
- `lib/features/cocktails/cocktail_detail_screen.dart` - ExpansionTile 없지만 Card + ListTile 패턴
- `lib/data/providers/cocktail_provider.dart` - 대체재 매칭 로직 (참고)

### Flutter Widget
- [ExpansionTile](https://api.flutter.dev/flutter/material/ExpansionTile-class.html) - 확장 가능한 리스트 타일
- [Card](https://api.flutter.dev/flutter/material/Card-class.html) - 카드 컨테이너

### Material Design
- [Lists](https://m3.material.io/components/lists/overview) - 리스트 디자인 가이드
- [Expansion panels](https://m3.material.io/components/expansion-panels/overview) - 확장 패널 패턴

### Riverpod Best Practices
- [Family providers](https://riverpod.dev/docs/concepts/modifiers/family) - 파라미터 기반 provider
- [Provider dependencies](https://riverpod.dev/docs/concepts/provider_dependencies) - provider 간 의존성

---

## 구현 순서 요약

1. **Phase 1**: 데이터 구조 (Models + Provider) → 핵심 로직 완성
2. **Phase 2**: UI 컴포넌트 (Widget) → 사용자 경험 구현
3. **Phase 3**: 다국어 + 테스트 → 품질 보증
4. **Phase 4**: 최적화 → 성능 개선

**총 예상 기간**: 3-4일 (Phase별 1일씩, 최적화 0.5일)
