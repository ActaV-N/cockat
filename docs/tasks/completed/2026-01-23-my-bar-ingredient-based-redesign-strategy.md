# 내 술장 Ingredient 기반 리스팅 개편 구현 전략

## 개요
- **목적**: 내 술장 화면을 Product 단위에서 Ingredient 단위 그룹핑으로 변경하고, Product 상세 페이지 구현
- **범위**: MyBarScreen 전면 개편, ProductDetailScreen 신규 구현, 네비게이션 추가
- **예상 소요 기간**: 4-6시간

## 현재 상태 분석

### 기존 구현
**파일**: `lib/features/products/my_bar_screen.dart`

**현재 UI 구조**:
```
MyBarScreen
├── AppBar (제목 + "모두 삭제" 액션)
└── GridView (2열 그리드)
    └── ProductCard (각 상품)
        ├── 상품 이미지
        ├── 제거 버튼 (우측 상단)
        ├── 브랜드명
        ├── 상품명
        └── 용량/도수 정보
```

**현재 기능**:
- 소유한 상품을 2열 그리드로 표시
- 카드 클릭 시: 상품 제거 (`toggle` 동작)
- 우측 상단 아이콘: 제거 시각적 표시
- "모두 삭제" 버튼: 전체 상품 제거

**데이터 흐름**:
```
effectiveSelectedProductsListProvider
  → List<Product>
    → GridView
      → ProductCard (onTap: toggle)
```

### 문제점/한계

#### 1. Product 중심 구조
- 동일한 ingredient를 가진 여러 product가 분산되어 표시
- 예: Bombay Sapphire, Tanqueray, Hendrick's가 각각 별도 카드로 표시
- 사용자가 "어떤 재료로 무엇을 만들 수 있는지" 파악하기 어려움

#### 2. 제거 기능만 제공
- 카드 클릭 시 즉시 제거되어 실수로 삭제 가능
- 상품 상세 정보를 확인할 방법이 없음
- 선택 해제 기능이 주 기능이 되어 UX 저하

#### 3. 상세 정보 부족
- 상품 설명, 원산지 등 추가 정보를 볼 수 없음
- 바코드, 외부 링크 등 메타데이터 활용 불가

## 구현 전략

### 접근 방식
**핵심 변경**:
1. **Ingredient 그룹핑**: 동일 재료의 상품들을 그룹화하여 표시
2. **확장/축소 UI**: ExpansionTile 또는 2단계 네비게이션으로 구현
3. **Product Detail Screen**: 상품 상세 페이지 신규 구현
4. **제거 기능 이동**: 상세 페이지의 하단 고정 버튼으로 이동

### 세부 구현 단계

#### Phase 1: 데이터 구조 및 Provider 구현

**1-1. Product를 Ingredient별로 그룹화하는 Provider 추가**

파일: `lib/data/providers/product_provider.dart`

```dart
/// Ingredient별로 그룹화된 소유 상품
/// Map<ingredientId, List<Product>>
final ownedProductsByIngredientProvider = Provider<AsyncValue<Map<String, List<Product>>>>((ref) {
  final productsAsync = ref.watch(effectiveSelectedProductsListProvider);
  final ingredientsAsync = ref.watch(ingredientsProvider);

  return productsAsync.whenData((products) {
    final ingredientsList = ingredientsAsync.valueOrNull ?? [];
    final grouped = <String, List<Product>>{};

    for (final product in products) {
      if (product.ingredientId != null) {
        grouped.putIfAbsent(product.ingredientId!, () => []).add(product);
      } else {
        // ingredientId가 없는 경우 "기타" 그룹
        grouped.putIfAbsent('_other', () => []).add(product);
      }
    }

    // 각 그룹을 상품명으로 정렬
    for (final entry in grouped.entries) {
      entry.value.sort((a, b) => a.name.compareTo(b.name));
    }

    return grouped;
  });
});

/// Ingredient 정보와 함께 그룹화된 데이터
/// 화면 표시에 최적화된 구조
final ingredientGroupsForMyBarProvider = Provider<AsyncValue<List<IngredientGroup>>>((ref) {
  final groupedAsync = ref.watch(ownedProductsByIngredientProvider);
  final ingredientsAsync = ref.watch(ingredientsProvider);

  return groupedAsync.whenData((grouped) {
    final ingredientsList = ingredientsAsync.valueOrNull ?? [];
    final ingredientsMap = {for (var i in ingredientsList) i.id: i};

    final groups = <IngredientGroup>[];

    for (final entry in grouped.entries) {
      final ingredientId = entry.key;
      final products = entry.value;

      if (ingredientId == '_other') {
        groups.add(IngredientGroup(
          ingredientId: ingredientId,
          ingredientName: '기타',
          products: products,
        ));
      } else {
        final ingredient = ingredientsMap[ingredientId];
        if (ingredient != null) {
          groups.add(IngredientGroup(
            ingredientId: ingredientId,
            ingredientName: ingredient.name,
            ingredientNameKo: ingredient.nameKo,
            ingredient: ingredient,
            products: products,
          ));
        }
      }
    }

    // Ingredient 이름으로 정렬 (기타는 맨 뒤)
    groups.sort((a, b) {
      if (a.ingredientId == '_other') return 1;
      if (b.ingredientId == '_other') return -1;
      return a.ingredientName.compareTo(b.ingredientName);
    });

    return groups;
  });
});
```

**1-2. IngredientGroup 모델 추가**

파일: `lib/data/models/ingredient_group.dart` (신규)

```dart
import 'package:flutter/foundation.dart';
import 'ingredient.dart';
import 'product.dart';

/// Ingredient별로 그룹화된 Product 목록
@immutable
class IngredientGroup {
  final String ingredientId;
  final String ingredientName;
  final String? ingredientNameKo;
  final Ingredient? ingredient;
  final List<Product> products;

  const IngredientGroup({
    required this.ingredientId,
    required this.ingredientName,
    this.ingredientNameKo,
    this.ingredient,
    required this.products,
  });

  /// 표시용 이름 (한국어 우선)
  String get displayName {
    return ingredientNameKo ?? ingredientName;
  }

  /// 상품 개수
  int get productCount => products.length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IngredientGroup && other.ingredientId == ingredientId;
  }

  @override
  int get hashCode => ingredientId.hashCode;
}
```

#### Phase 2: MyBarScreen UI 전면 개편

**2-1. MyBarScreen 리스트 뷰로 변경**

파일: `lib/features/products/my_bar_screen.dart`

```dart
class MyBarScreen extends ConsumerWidget {
  const MyBarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final groupsAsync = ref.watch(ingredientGroupsForMyBarProvider);
    final totalCount = ref.watch(effectiveSelectedProductCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myBar),
        actions: [
          if (totalCount > 0)
            TextButton.icon(
              onPressed: () {
                // 확인 다이얼로그 표시
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.clearAllProducts),
                    content: Text(l10n.clearAllProductsConfirm),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n.cancel),
                      ),
                      FilledButton(
                        onPressed: () {
                          ref.read(effectiveProductsServiceProvider).clear();
                          Navigator.pop(context);
                        },
                        child: Text(l10n.clear),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.delete_outline),
              label: Text(l10n.clearAll),
            ),
        ],
      ),
      body: groupsAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return _EmptyBarView(l10n: l10n);
          }
          return _IngredientGroupsList(
            groups: groups,
            totalCount: totalCount,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
```

**2-2. IngredientGroupsList 위젯**

```dart
class _IngredientGroupsList extends StatelessWidget {
  final List<IngredientGroup> groups;
  final int totalCount;

  const _IngredientGroupsList({
    required this.groups,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        // 상단 통계 정보
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Icon(
                Icons.inventory_2,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.totalProducts(totalCount),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    l10n.nIngredientTypes(groups.length),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Ingredient 그룹 리스트
        Expanded(
          child: ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              return _IngredientGroupTile(group: groups[index]);
            },
          ),
        ),
      ],
    );
  }
}
```

**2-3. IngredientGroupTile 위젯**

```dart
class _IngredientGroupTile extends StatelessWidget {
  final IngredientGroup group;

  const _IngredientGroupTile({required this.group});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Text(
          '${group.productCount}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        group.displayName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        group.products.map((p) => p.displayName).join(', '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      children: [
        ...group.products.map(
          (product) => _ProductListItem(product: product),
        ),
      ],
    );
  }
}
```

**2-4. ProductListItem 위젯**

```dart
class _ProductListItem extends StatelessWidget {
  final Product product;

  const _ProductListItem({required this.product});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _ProductThumbnail(imageUrl: product.thumbnailUrl ?? product.imageUrl),
      title: Text(product.displayName),
      subtitle: Text(
        [
          if (product.formattedVolume != null) product.formattedVolume,
          if (product.abv != null) '${product.abv}%',
          if (product.country != null) product.country,
        ].join(' | '),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(productId: product.id),
          ),
        );
      },
    );
  }
}

class _ProductThumbnail extends StatelessWidget {
  final String? imageUrl;

  const _ProductThumbnail({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(context),
            )
          : _placeholder(context),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Icon(
      Icons.liquor,
      color: Theme.of(context).colorScheme.outline,
    );
  }
}
```

#### Phase 3: Product Detail Screen 구현

**3-1. ProductDetailScreen 신규 파일**

파일: `lib/features/products/product_detail_screen.dart` (신규)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/product_image.dart';
import '../../data/models/models.dart';
import '../../data/providers/providers.dart';
import '../../l10n/app_localizations.dart';

/// 상품 ID로 상품 가져오기
final productByIdProvider = Provider.family<AsyncValue<Product?>, String>((ref, productId) {
  return ref.watch(productsProvider).whenData(
        (products) => products.firstWhere(
          (p) => p.id == productId,
          orElse: () => throw Exception('Product not found: $productId'),
        ),
      );
});

class ProductDetailScreen extends ConsumerWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final productAsync = ref.watch(productByIdProvider(productId));
    final isOwned = ref.watch(effectiveSelectedProductIdsProvider).contains(productId);

    return Scaffold(
      body: productAsync.when(
        data: (product) {
          if (product == null) {
            return Center(child: Text(l10n.productNotFound));
          }
          return _ProductDetailContent(
            product: product,
            isOwned: isOwned,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _ProductDetailContent extends ConsumerWidget {
  final Product product;
  final bool isOwned;

  const _ProductDetailContent({
    required this.product,
    required this.isOwned,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return CustomScrollView(
      slivers: [
        // App Bar with image
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: ProductImage(
              product: product,
              mode: ImageDisplayMode.full,
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Product Information
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand
                if (product.brand != null) ...[
                  Text(
                    product.brand!,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                ],

                // Product Name
                Text(
                  product.name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),

                // Specs Grid
                _SpecsGrid(product: product),
                const SizedBox(height: 24),

                // Description
                if (product.description != null) ...[
                  Text(
                    l10n.description,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description!,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                ],

                // Ingredient Info
                _IngredientInfo(product: product),

                // Bottom spacing for fixed button
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
      // Fixed bottom button
      bottomSheet: _BottomActionButton(
        product: product,
        isOwned: isOwned,
      ),
    );
  }
}

class _SpecsGrid extends StatelessWidget {
  final Product product;

  const _SpecsGrid({required this.product});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final specs = <_SpecItem>[
      if (product.volumeMl != null)
        _SpecItem(
          icon: Icons.water_drop_outlined,
          label: l10n.volume,
          value: product.formattedVolume!,
        ),
      if (product.abv != null)
        _SpecItem(
          icon: Icons.local_bar_outlined,
          label: l10n.alcoholContent,
          value: '${product.abv}%',
        ),
      if (product.country != null)
        _SpecItem(
          icon: Icons.public,
          label: l10n.country,
          value: product.country!,
        ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: specs,
    );
  }
}

class _SpecItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SpecItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientInfo extends ConsumerWidget {
  final Product product;

  const _IngredientInfo({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    if (product.ingredientId == null) return const SizedBox.shrink();

    final ingredientAsync = ref.watch(ingredientByIdProvider(product.ingredientId!));

    return ingredientAsync.when(
      data: (ingredient) {
        if (ingredient == null) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.category_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.ingredientType,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                ingredient.nameKo ?? ingredient.name,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (ingredient.category != null) ...[
                const SizedBox(height: 4),
                Text(
                  ingredient.category!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _BottomActionButton extends ConsumerWidget {
  final Product product;
  final bool isOwned;

  const _BottomActionButton({
    required this.product,
    required this.isOwned,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: FilledButton.icon(
          onPressed: () {
            if (isOwned) {
              // 확인 다이얼로그
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.removeFromMyBar),
                  content: Text(l10n.removeProductConfirm(product.displayName)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.cancel),
                    ),
                    FilledButton(
                      onPressed: () {
                        ref.read(effectiveProductsServiceProvider).toggle(product.id);
                        Navigator.pop(context); // 다이얼로그 닫기
                        Navigator.pop(context); // 상세 화면 닫기
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                      child: Text(l10n.remove),
                    ),
                  ],
                ),
              );
            } else {
              ref.read(effectiveProductsServiceProvider).toggle(product.id);
            }
          },
          icon: Icon(isOwned ? Icons.remove_circle_outline : Icons.add_circle_outline),
          label: Text(isOwned ? l10n.removeFromMyBar : l10n.addToMyBar),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor: isOwned
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
```

**3-2. ProductImage 위젯 (기존 재사용 또는 개선)**

파일: `lib/core/widgets/product_image.dart`

- 기존 위젯 확인 후 필요시 full mode 추가

#### Phase 4: 다국어 지원

파일: `lib/l10n/intl_*.arb`

추가 필요 문자열:
```json
{
  "totalProducts": "총 {count}개 상품",
  "nIngredientTypes": "{count}종류의 재료",
  "ingredientType": "재료 분류",
  "description": "설명",
  "volume": "용량",
  "alcoholContent": "도수",
  "country": "원산지",
  "removeFromMyBar": "내 술장에서 제거",
  "addToMyBar": "내 술장에 추가",
  "removeProductConfirm": "{productName}을(를) 제거하시겠습니까?",
  "clearAllProducts": "모두 삭제",
  "clearAllProductsConfirm": "모든 상품을 내 술장에서 제거하시겠습니까?",
  "productNotFound": "상품을 찾을 수 없습니다"
}
```

### 기술적 고려사항

#### 아키텍처
- **Provider 계층 추가**: Ingredient 기반 그룹핑 로직을 Provider에서 처리
- **데이터 모델 확장**: IngredientGroup 모델 신규 추가
- **화면 분리**: Detail Screen을 별도 파일로 분리하여 재사용성 확보

#### 의존성
- 기존 의존성 사용, 추가 패키지 불필요
- Riverpod Provider 패턴 활용
- Material 3 디자인 시스템 준수

#### 네비게이션
- ProductDetailScreen은 독립적인 화면
- 여러 곳에서 재사용 가능 (내 술장, 상품 카탈로그, 칵테일 상세 등)

## 위험 요소 및 대응 방안

| 위험 요소 | 영향도 | 대응 방안 |
|-----------|--------|----------|
| Product에 ingredientId가 없는 경우 | 중간 | '기타' 그룹으로 분류하여 표시 |
| 성능 저하 (상품 수가 많은 경우) | 낮음 | Provider 캐싱 활용, 필요시 페이지네이션 |
| ExpansionTile 애니메이션 성능 | 낮음 | 상품 수가 적어 문제 없음, 필요시 ListView로 대체 |
| 다국어 누락 | 중간 | 영어/한국어 모두 추가, fallback 설정 |
| Product 이미지 로딩 실패 | 낮음 | placeholder 표시, errorBuilder 구현 |

## 테스트 전략

### 단위 테스트
- `ownedProductsByIngredientProvider` 그룹핑 로직 테스트
- `ingredientGroupsForMyBarProvider` 정렬 로직 테스트
- IngredientGroup 모델 테스트

### 통합 테스트

**시나리오 1**: Ingredient별 그룹핑 확인
1. 여러 상품 선택 (동일 Ingredient 포함)
2. 내 술장 화면 진입
3. Ingredient별로 그룹핑되었는지 확인
4. 각 그룹의 상품 개수 확인

**시나리오 2**: 상품 상세 화면 네비게이션
1. Ingredient 그룹 확장
2. 상품 선택
3. 상세 화면 진입 확인
4. 상품 정보 표시 확인

**시나리오 3**: 제거 기능
1. 상세 화면에서 "제거" 버튼 클릭
2. 확인 다이얼로그 표시 확인
3. 확인 시 상품 제거 및 화면 닫힘 확인
4. 내 술장에서 제거되었는지 확인

**시나리오 4**: 빈 상태
1. 모든 상품 제거
2. 빈 상태 화면 표시 확인

## 성공 기준
- [ ] Ingredient별로 상품이 그룹화되어 표시됨
- [ ] 각 그룹을 확장하여 소속 상품 목록 확인 가능
- [ ] 상품 클릭 시 상세 페이지로 이동
- [ ] 상세 페이지에서 모든 상품 정보 표시
- [ ] 하단 고정 버튼으로 제거 기능 작동
- [ ] 확인 다이얼로그 표시
- [ ] 다국어 지원 (한국어/영어)
- [ ] 성능 이슈 없음

## 참고 자료
- [Material 3 ExpansionTile](https://m3.material.io/components/lists/overview)
- [Flutter ListView Performance](https://docs.flutter.dev/perf/best-practices)
- [Riverpod Provider Composition](https://riverpod.dev/docs/concepts/combining_providers/)
